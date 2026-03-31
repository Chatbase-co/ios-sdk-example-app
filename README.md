# Chatbase iOS Example App

A sample iOS app that demonstrates how to integrate with the Chatbase API v2. Built with SwiftUI, it shows how to build a chat interface with streaming responses, client-side tool calls, conversation history, and message feedback.

## What it does

- Sends messages to a Chatbase agent and streams responses in real time
- Lists and loads previous conversations with paginated message history
- Handles client-side tool calls (the agent can trigger actions on the device, like changing the background color)
- Submits tool call results back to the API so the agent can continue naturally
- Supports message feedback (thumbs up/down) and message retry
- Continues conversations after tool call execution without adding phantom user messages

## Project structure

```
tatbeeqMa7mool/
  Models/
    Message.swift          -- Message, MessagePart, FinishReason, Usage, JSONValue
    Conversation.swift     -- Conversation, ConversationStatus
    PaginatedResponse.swift
  Services/
    APIClient.swift        -- Protocol, URLSession implementation, error types
    ChatService.swift      -- Stateless service covering all API v2 endpoints
  ViewModels/
    ChatViewModel.swift
    ConversationListViewModel.swift
  Views/
    ChatView.swift
    ConversationListView.swift
    MessageBubble.swift
    TypingIndicator.swift
tatbeeqMa7moolTests/
  MockAPIClient.swift
  ChatServiceTests.swift
```

## Setup

1. Open `tatbeeqMa7mool.xcodeproj` in Xcode.

2. Create a file called `Secrets.xcconfig` in the project root (next to `.xcodeproj`):

```
API_KEY = your-chatbase-api-key
AGENT_ID = your-chatbase-agent-id
API_BASE_URL = https://www.chatbase.co/api/v2
```

For local development against a local Chatbase instance, set `API_BASE_URL = http://localhost:3000/api/v2`.

3. In Xcode, wire the xcconfig to your build configuration:
   - Click the blue project icon in the navigator
   - Go to Info tab, then Configurations
   - Set Debug to use `Secrets`

4. Make sure `Info.plist` is registered in Build Settings (search "Info.plist File" and set it to `tatbeeqMa7mool/Info.plist`).

5. Build and run (Cmd+R).

## Running tests

1. Make sure the test target `tatbeeqMa7moolTests` exists. If not, create it: File, New, Target, Unit Testing Bundle.

2. Add `MockAPIClient.swift` and `ChatServiceTests.swift` to the test target.

3. Run with Cmd+U.

Tests use a mock API client and do not hit any real servers.

## API coverage

The `ChatService` covers all Chatbase API v2 consumer endpoints:

| Endpoint | Method |
|----------|--------|
| POST /agents/{agentId}/chat | sendMessage, streamMessage, continueConversation |
| POST /.../tool-result | submitToolResult |
| POST /.../retry | retryMessage |
| GET /agents/{agentId}/conversations | listConversations |
| GET /.../conversations/{id} | getConversation |
| GET /.../conversations/{id}/messages | listMessages |
| GET /.../users/{userId}/conversations | listUserConversations |
| PATCH /.../messages/{id}/feedback | updateFeedback |

## Tool call flow

1. User sends a message. The agent decides to call a client-side tool.
2. The app receives a `toolCall` stream event with `toolCallId`, `toolName`, and `input`.
3. The app executes the tool locally (e.g. changes background color).
4. The app submits the result via `submitToolResult`.
5. The app calls `continueConversation` to resume the agent, which responds naturally with the tool result in context.

## Notes

- `ChatService` is stateless. Conversation state is owned by the ViewModel.
- The service can be extracted into a standalone Swift package for use as an SDK.
- `JSONValue` is used instead of `[String: Any]` for type-safe, Sendable JSON handling.
- Streaming uses `AsyncThrowingStream` with SSE parsing. The timeout (10 seconds of no known events) prevents indefinite hangs.
- Tool result submission retries up to 3 times with exponential backoff (300ms, 600ms, 1200ms) to handle the race condition where the server hasn't finished saving the tool call data.
