//
//  ChatService.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 14/03/2026.
//

import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "tatbeeqMa7mool", category: "ChatService")

// MARK: - Public Types

struct ToolCall: Sendable {
    let toolCallId: String
    let toolName: String
    let input: JSONValue
}

/// A type-safe, Sendable representation of arbitrary JSON.
enum JSONValue: Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    var stringValue: String? { if case .string(let v) = self { return v }; return nil }
    var numberValue: Double? { if case .number(let v) = self { return v }; return nil }
    var boolValue: Bool? { if case .bool(let v) = self { return v }; return nil }
    var objectValue: [String: JSONValue]? { if case .object(let v) = self { return v }; return nil }
    var arrayValue: [JSONValue]? { if case .array(let v) = self { return v }; return nil }

    subscript(key: String) -> JSONValue? {
        if case .object(let dict) = self { return dict[key] }
        return nil
    }
}

struct StreamFinishInfo: Sendable {
    let conversationId: String?
    let messageId: String?
    let userMessageId: String?
    let userId: String?
    let finishReason: FinishReason?
    let usage: Usage?
}

enum StreamEvent: Sendable {
    case messageStarted(id: String)
    case textChunk(String)
    case toolCall(ToolCall)
    case finished(StreamFinishInfo)
}

struct ChatResponse: Sendable {
    let message: Message
    let conversationId: String
    let userMessageId: String?
    let finishReason: FinishReason
    let usage: Usage
}

enum ChatError: Error, LocalizedError {
    case noContent
    case streamTimeout
    case noConversation
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noContent: return "No content in response"
        case .streamTimeout: return "Stream timed out — no response from server"
        case .noConversation: return "No active conversation"
        case .decodingFailed(let detail): return "Failed to decode response: \(detail)"
        }
    }
}

// MARK: - Request DTOs

private struct ChatRequestDTO: Encodable {
    let message: String?
    let conversationId: String?
    let stream: Bool
}

private struct ToolResultRequestDTO: Encodable {
    let toolCallId: String
    let output: [String: String]
}

private struct RetryRequestDTO: Encodable {
    let messageId: String
    let stream: Bool
}

private struct UpdateFeedbackRequestDTO: Encodable {
    let feedback: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(feedback, forKey: .feedback)
    }

    enum CodingKeys: String, CodingKey {
        case feedback
    }
}

// MARK: - Response DTOs

private struct ToolResultResponseDTO: Decodable {
    let data: ToolResultSuccessDTO
    struct ToolResultSuccessDTO: Decodable { let success: Bool }
}

private struct ChatResponseDTO: Decodable {
    let data: ChatResponseDataDTO
}

private struct ChatResponseDataDTO: Decodable {
    let id: String
    let role: String
    let parts: [MessagePartDTO]
    let metadata: ChatResponseMetadataDTO
}

private struct ChatResponseMetadataDTO: Decodable {
    let conversationId: String
    let userMessageId: String?
    let userId: String?
    let finishReason: String
    let usage: UsageDTO
}

private struct UsageDTO: Decodable {
    let credits: Double
}

// MARK: - Shared Part DTO

private enum MessagePartDTO: Decodable {
    case text(String)
    case toolCall(toolCallId: String, toolName: String, input: AnyCodableValue)
    case toolResult(toolCallId: String, toolName: String, output: AnyCodableValue)

    enum CodingKeys: String, CodingKey {
        case type, text, toolCallId, toolName, input, output
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try container.decode(String.self, forKey: .text))
        case "tool-call":
            self = .toolCall(
                toolCallId: try container.decode(String.self, forKey: .toolCallId),
                toolName: try container.decode(String.self, forKey: .toolName),
                input: (try? container.decode(AnyCodableValue.self, forKey: .input)) ?? .object([:])
            )
        case "tool-result":
            self = .toolResult(
                toolCallId: try container.decode(String.self, forKey: .toolCallId),
                toolName: try container.decode(String.self, forKey: .toolName),
                output: (try? container.decode(AnyCodableValue.self, forKey: .output)) ?? .object([:])
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container,
                debugDescription: "Unknown part type: \(type)"
            )
        }
    }
}

/// Decodes arbitrary JSON values (objects, arrays, strings, numbers, bools, null).
private enum AnyCodableValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: AnyCodableValue])
    case array([AnyCodableValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Double.self) {
            self = .number(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([String: AnyCodableValue].self) {
            self = .object(v)
        } else if let v = try? container.decode([AnyCodableValue].self) {
            self = .array(v)
        } else {
            self = .null
        }
    }

    var toJSONValue: JSONValue {
        switch self {
        case .string(let v): return .string(v)
        case .number(let v): return .number(v)
        case .bool(let v): return .bool(v)
        case .object(let v): return .object(v.mapValues { $0.toJSONValue })
        case .array(let v): return .array(v.map { $0.toJSONValue })
        case .null: return .null
        }
    }
}

// MARK: - Conversation DTOs

private struct ConversationDTO: Decodable {
    let id: String
    let title: String?
    let createdAt: Double
    let updatedAt: Double
    let userId: String?
    let status: String
}

private struct ConversationMessageDTO: Decodable {
    let id: String
    let role: String
    let parts: [MessagePartDTO]
    let createdAt: Double?
    let feedback: String?
    let metadata: ConversationMessageMetadataDTO?
}

private struct ConversationMessageMetadataDTO: Decodable {
    let score: Double?
}

private struct PaginationDTO: Decodable {
    let cursor: String?
    let hasMore: Bool
    let total: Int
}

private struct ListConversationsResponseDTO: Decodable {
    let data: [ConversationDTO]
    let pagination: PaginationDTO
}

private struct GetConversationResponseDTO: Decodable {
    let data: GetConversationDataDTO
    let pagination: PaginationDTO

    struct GetConversationDataDTO: Decodable {
        let id: String
        let title: String?
        let createdAt: Double
        let updatedAt: Double
        let userId: String?
        let status: String
        let messages: [ConversationMessageDTO]
    }
}

private struct ListMessagesResponseDTO: Decodable {
    let data: [ConversationMessageDTO]
    let pagination: PaginationDTO
}

private struct UpdateFeedbackResponseDTO: Decodable {
    let data: ConversationMessageDTO
}

// MARK: - SSE Stream DTOs

private enum StreamEventDTO: Decodable {
    case start(messageId: String)
    case textDelta(delta: String)
    case toolCall(toolCallId: String, toolName: String, input: AnyCodableValue)
    case finish(metadata: StreamFinishMetadataDTO)
    case other

    enum CodingKeys: String, CodingKey {
        case type, messageId, delta, messageMetadata, toolName, toolCallId, input
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "start":
            self = .start(messageId: try container.decode(String.self, forKey: .messageId))
        case "text-delta":
            self = .textDelta(delta: try container.decode(String.self, forKey: .delta))
        case "finish":
            self = .finish(metadata: try container.decode(StreamFinishMetadataDTO.self, forKey: .messageMetadata))
        case "tool-input-available":
            self = .toolCall(
                toolCallId: try container.decode(String.self, forKey: .toolCallId),
                toolName: try container.decode(String.self, forKey: .toolName),
                input: (try? container.decode(AnyCodableValue.self, forKey: .input)) ?? .object([:])
            )
        default:
            self = .other
        }
    }
}

private struct StreamFinishMetadataDTO: Decodable {
    let conversationId: String?
    let messageId: String?
    let userMessageId: String?
    let userId: String?
    let finishReason: String?
    let usage: UsageDTO?
}

// MARK: - ChatService

class ChatService {
    private let client: APIClient
    private let baseURL: String
    private let agentId: String
    private let apiKey: String

    init?(client: APIClient) {
        guard
            let agentId = Bundle.main.infoDictionary?["AGENT_ID"] as? String,
            let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String
        else { return nil }

        self.client = client
        self.baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? "https://www.chatbase.co/api/v2"
        self.agentId = agentId
        self.apiKey = apiKey
    }

    init(client: APIClient, baseURL: String, agentId: String, apiKey: String) {
        self.client = client
        self.baseURL = baseURL
        self.agentId = agentId
        self.apiKey = apiKey
    }

    // MARK: - Chat

    func sendMessage(_ text: String, conversationId: String? = nil) async throws -> ChatResponse {
        let request = try buildChatRequest(message: text, conversationId: conversationId, stream: false)
        let response: ChatResponseDTO
        do {
            response = try await client.send(request: request)
        } catch let error as DecodingError {
            throw ChatError.decodingFailed(String(describing: error))
        }

        let parts = mapParts(response.data.parts)
        let text = extractText(from: response.data.parts)
        let meta = response.data.metadata

        return ChatResponse(
            message: Message(
                id: response.data.id,
                text: text ?? "",
                sender: .agent,
                date: .now,
                parts: parts
            ),
            conversationId: meta.conversationId,
            userMessageId: meta.userMessageId,
            finishReason: FinishReason(rawValue: meta.finishReason) ?? .stop,
            usage: Usage(credits: meta.usage.credits)
        )
    }

    func streamMessage(_ text: String, conversationId: String? = nil) -> AsyncThrowingStream<StreamEvent, Error> {
        do {
            return streamSSE(request: try buildChatRequest(message: text, conversationId: conversationId, stream: true))
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
    }

    func continueConversation(_ conversationId: String) -> AsyncThrowingStream<StreamEvent, Error> {
        do {
            return streamSSE(request: try buildChatRequest(message: nil, conversationId: conversationId, stream: true))
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
    }

    // MARK: - Tool Results

    func submitToolResult(conversationId: String, toolCall: ToolCall, output: [String: String], maxRetries: Int = 3) async throws {
        let request = try buildJSONRequest(
            method: "POST",
            path: "/agents/\(agentId)/conversations/\(conversationId)/tool-result",
            body: ToolResultRequestDTO(toolCallId: toolCall.toolCallId, output: output)
        )

        var lastError: Error = APIError.invalidResponse
        var delay: Duration = .milliseconds(300)

        for attempt in 1...maxRetries {
            do {
                let _: ToolResultResponseDTO = try await client.send(request: request)
                return
            } catch let error as APIError where error.statusCode == 404 && attempt < maxRetries {
                lastError = error
                logger.warning("Tool result not ready (attempt \(attempt)/\(maxRetries)), retrying in \(delay)...")
                try await Task.sleep(for: delay)
                delay *= 2
            }
        }
        throw lastError
    }

    // MARK: - Conversations

    func listConversations(cursor: String? = nil, limit: Int? = nil) async throws -> PaginatedResponse<Conversation> {
        let request = buildGETRequest(path: "/agents/\(agentId)/conversations", query: paginationQuery(cursor: cursor, limit: limit))
        let response: ListConversationsResponseDTO = try await client.send(request: request)
        return PaginatedResponse(
            data: response.data.map { mapConversation($0) },
            pagination: mapPagination(response.pagination)
        )
    }

    func getConversation(_ conversationId: String) async throws -> (Conversation, [Message], Pagination) {
        let request = buildGETRequest(path: "/agents/\(agentId)/conversations/\(conversationId)")
        let response: GetConversationResponseDTO = try await client.send(request: request)
        let d = response.data
        return (
            Conversation(
                id: d.id, title: d.title,
                createdAt: Date(timeIntervalSince1970: d.createdAt),
                updatedAt: Date(timeIntervalSince1970: d.updatedAt),
                userId: d.userId,
                status: ConversationStatus(rawValue: d.status) ?? .ongoing
            ),
            d.messages.compactMap { mapMessage($0) },
            mapPagination(response.pagination)
        )
    }

    func listMessages(conversationId: String, cursor: String? = nil, limit: Int? = nil) async throws -> PaginatedResponse<Message> {
        let request = buildGETRequest(
            path: "/agents/\(agentId)/conversations/\(conversationId)/messages",
            query: paginationQuery(cursor: cursor, limit: limit)
        )
        let response: ListMessagesResponseDTO = try await client.send(request: request)
        return PaginatedResponse(
            data: response.data.compactMap { mapMessage($0) },
            pagination: mapPagination(response.pagination)
        )
    }

    func listUserConversations(userId: String, cursor: String? = nil, limit: Int? = nil) async throws -> PaginatedResponse<Conversation> {
        let request = buildGETRequest(
            path: "/agents/\(agentId)/users/\(userId)/conversations",
            query: paginationQuery(cursor: cursor, limit: limit)
        )
        let response: ListConversationsResponseDTO = try await client.send(request: request)
        return PaginatedResponse(
            data: response.data.map { mapConversation($0) },
            pagination: mapPagination(response.pagination)
        )
    }

    // MARK: - Feedback

    func updateFeedback(conversationId: String, messageId: String, feedback: MessageFeedback?) async throws -> Message {
        let request = try buildJSONRequest(
            method: "PATCH",
            path: "/agents/\(agentId)/conversations/\(conversationId)/messages/\(messageId)/feedback",
            body: UpdateFeedbackRequestDTO(feedback: feedback?.rawValue)
        )
        let response: UpdateFeedbackResponseDTO = try await client.send(request: request)
        guard let message = mapMessage(response.data) else { throw ChatError.noContent }
        return message
    }

    // MARK: - Retry

    func retryMessage(conversationId: String, messageId: String) -> AsyncThrowingStream<StreamEvent, Error> {
        do {
            let request = try buildJSONRequest(
                method: "POST",
                path: "/agents/\(agentId)/conversations/\(conversationId)/retry",
                body: RetryRequestDTO(messageId: messageId, stream: true)
            )
            return streamSSE(request: request)
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
    }

    // MARK: - Private: Mapping

    private func extractText(from parts: [MessagePartDTO]) -> String? {
        let text = parts.compactMap { part -> String? in
            if case .text(let t) = part, !t.isEmpty { return t }
            return nil
        }.joined(separator: "\n")
        return text.isEmpty ? nil : text
    }

    private func mapParts(_ dtos: [MessagePartDTO]) -> [MessagePart] {
        dtos.map { dto in
            switch dto {
            case .text(let text):
                return MessagePart(kind: .text(text))
            case .toolCall(let id, let name, let input):
                return MessagePart(kind: .toolCall(toolCallId: id, toolName: name, input: input.toJSONValue))
            case .toolResult(let id, let name, let output):
                return MessagePart(kind: .toolResult(toolCallId: id, toolName: name, output: output.toJSONValue))
            }
        }
    }

    private func mapMessage(_ dto: ConversationMessageDTO) -> Message? {
        let text = extractText(from: dto.parts)
        let parts = mapParts(dto.parts)

        // Skip messages with no displayable content and no tool interactions
        let hasToolParts = parts.contains { part in
            if case .toolCall = part.kind { return true }
            if case .toolResult = part.kind { return true }
            return false
        }
        if text == nil && !hasToolParts { return nil }

        return Message(
            id: dto.id,
            text: text ?? "",
            sender: dto.role == "user" ? .user : .agent,
            date: dto.createdAt.map { Date(timeIntervalSince1970: $0) } ?? .now,
            feedback: dto.feedback.flatMap { MessageFeedback(rawValue: $0) },
            score: dto.metadata?.score,
            parts: parts
        )
    }

    private func mapConversation(_ dto: ConversationDTO) -> Conversation {
        Conversation(
            id: dto.id,
            title: dto.title,
            createdAt: Date(timeIntervalSince1970: dto.createdAt),
            updatedAt: Date(timeIntervalSince1970: dto.updatedAt),
            userId: dto.userId,
            status: ConversationStatus(rawValue: dto.status) ?? .ongoing
        )
    }

    private func mapPagination(_ dto: PaginationDTO) -> Pagination {
        Pagination(cursor: dto.cursor, hasMore: dto.hasMore, total: dto.total)
    }

    // MARK: - Private: Request Builders

    private func buildChatRequest(message: String? = nil, conversationId: String? = nil, stream: Bool) throws -> URLRequest {
        var request = URLRequest(url: url("/agents/\(agentId)/chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            ChatRequestDTO(message: message, conversationId: conversationId, stream: stream)
        )
        return request
    }

    private func buildJSONRequest<T: Encodable>(method: String, path: String, body: T) throws -> URLRequest {
        var request = URLRequest(url: url(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func buildGETRequest(path: String, query: [URLQueryItem] = []) -> URLRequest {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func url(_ path: String) -> URL {
        URL(string: "\(baseURL)\(path)")!
    }

    private func paginationQuery(cursor: String?, limit: Int?) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        if let limit { items.append(URLQueryItem(name: "limit", value: String(limit))) }
        return items
    }

    // MARK: - Private: SSE Stream

    private func streamSSE(request: URLRequest) -> AsyncThrowingStream<StreamEvent, Error> {
        let (stream, continuation) = AsyncThrowingStream<StreamEvent, Error>.makeStream()

        Task {
            do {
                let (bytes, _) = try await client.streamLines(request: request)
                var lastKnownEventTime = ContinuousClock.now

                for try await line in bytes.lines {
                    guard line.hasPrefix("data: ") else { continue }
                    let payload = String(line.dropFirst(6))
                    if payload == "[DONE]" { break }
                    guard let data = payload.data(using: .utf8) else { continue }

                    do {
                        let event = try JSONDecoder().decode(StreamEventDTO.self, from: data)
                        switch event {
                        case .start(let messageId):
                            lastKnownEventTime = .now
                            continuation.yield(.messageStarted(id: messageId))
                        case .textDelta(let delta):
                            lastKnownEventTime = .now
                            continuation.yield(.textChunk(delta))
                        case .finish(let metadata):
                            lastKnownEventTime = .now
                            continuation.yield(.finished(StreamFinishInfo(
                                conversationId: metadata.conversationId,
                                messageId: metadata.messageId,
                                userMessageId: metadata.userMessageId,
                                userId: metadata.userId,
                                finishReason: metadata.finishReason.flatMap { FinishReason(rawValue: $0) },
                                usage: metadata.usage.map { Usage(credits: $0.credits) }
                            )))
                        case .toolCall(let toolCallId, let toolName, let input):
                            lastKnownEventTime = .now
                            continuation.yield(.toolCall(ToolCall(
                                toolCallId: toolCallId,
                                toolName: toolName,
                                input: input.toJSONValue
                            )))
                        case .other:
                            if ContinuousClock.now - lastKnownEventTime > .seconds(10) {
                                continuation.finish(throwing: ChatError.streamTimeout)
                                return
                            }
                        }
                    } catch {
                        logger.error("Failed to decode SSE event: \(error.localizedDescription)")
                        logger.debug("Raw payload: \(payload)")
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        return stream
    }
}
