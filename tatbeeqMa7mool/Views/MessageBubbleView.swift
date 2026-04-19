//
//  MessageBubbleView.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 14/03/2026.
//

import SwiftUI
import ChatbaseSDK

struct MessageBubble: View {
    let message: Message
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.sender == .user {
                    Spacer()
                    Text(message.date, style: .time)
                        .font(.caption)
                }

                Group {
                    if message.sender == .agent && message.text.isEmpty {
                        TypingIndicator()
                    } else {
                        Text(LocalizedStringKey(message.text))
                            .foregroundStyle(.white)
                            .tint(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(message.sender == .user ? Color.green : Color.blue)
                            .cornerRadius(10)
                    }
                }

                if message.sender == .agent {
                    Text(message.date, style: .time)
                        .font(.caption)
                    Spacer()
                }
            }

            if message.sender == .agent && !message.text.isEmpty {
                Button {
                    onRetry?()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
        }
    }
}

#Preview {
    VStack {
        MessageBubble(message: Message(id: "1", text: "Hi!", sender: .user, date: .now))
        MessageBubble(message: Message(id: "2", text: "Hello! How can I help?", sender: .agent, date: .now))
    }
    .padding()
}
