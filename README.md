# Chatbase iOS Example App

A sample iOS app that demonstrates how to build a chat interface powered by the Chatbase API v2. Built with SwiftUI.

## What it does

- Sends messages to a Chatbase agent and streams responses in real time
- Lists and loads previous conversations with paginated message history
- Handles client-side tool calls (the agent can trigger actions on the device, like changing the background color)
- Supports message feedback (thumbs up/down) and message retry

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

1. Make sure the test target `tatbeeqMa7moolTests` exists. If not, create it via File, New, Target, Unit Testing Bundle.

2. Add `MockAPIClient.swift` and `ChatServiceTests.swift` to the test target.

3. Run with Cmd+U.

Tests use a mock API client and do not hit real servers.

## Project structure

```
tatbeeqMa7mool/
  Models/
    Message.swift
    Conversation.swift
    PaginatedResponse.swift
  Services/
    APIClient.swift
    ChatService.swift
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

## Preview
<img width="301" height="655" alt="image" src="https://github.com/user-attachments/assets/383d910a-294c-4008-a41f-75528c14197f" />

