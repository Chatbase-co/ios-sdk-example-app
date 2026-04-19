//
//  MessageBubbleView.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 14/03/2026.
//

import SwiftUI
import ChatbaseSDK

struct MessageBubble: View {
    let message: ConversationState.UiMessage
    var onRetry: (() -> Void)?

    var body: some View {
        switch message.kind {
        case .text(let text):
            TextBubble(
                text: text,
                sender: message.sender,
                date: message.date,
                isStreaming: message.isStreaming,
                isError: message.isError,
                canRetry: message.sender == .agent && message.messageId != nil && !text.isEmpty,
                onRetry: onRetry
            )
        case .toolCall(let card):
            ToolCallBubble(name: card.toolName, status: card.status)
        }
    }
}

private struct TextBubble: View {
    let text: String
    let sender: MessageSender
    let date: Date
    let isStreaming: Bool
    let isError: Bool
    let canRetry: Bool
    let onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: sender == .user ? .trailing : .leading, spacing: 4) {
            HStack {
                if sender == .user {
                    Spacer()
                    Text(date, style: .time).font(.caption)
                }

                Group {
                    if sender == .agent && text.isEmpty && isStreaming {
                        TypingIndicator()
                    } else {
                        Text(LocalizedStringKey(text))
                            .foregroundStyle(.white)
                            .tint(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(background)
                            .cornerRadius(10)
                    }
                }

                if sender == .agent {
                    Text(date, style: .time).font(.caption)
                    Spacer()
                }
            }

            if canRetry {
                Button { onRetry?() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
        }
    }

    private var background: Color {
        if isError { return .red }
        return sender == .user ? .green : .blue
    }
}

private struct ToolCallBubble: View {
    let name: String
    let status: ConversationState.ToolCallCard.Status

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
            Text(name).font(.caption).monospaced()
            if status == .executing { ProgressView().controlSize(.mini) }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var iconName: String {
        switch status {
        case .executing: return "gearshape.2.fill"
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .executing: return .orange
        case .success: return .green
        case .failure: return .red
        }
    }
}
