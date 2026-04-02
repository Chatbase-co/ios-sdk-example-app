# Chatbase iOS Example App

A sample iOS app that demonstrates how to build a chat interface using the [ChatbaseSDK](https://github.com/Chatbase-co/chatbase-ios-sdk). Built with SwiftUI.

## What it does

- Sends messages to a Chatbase agent and streams responses in real time
- Lists and loads previous conversations with paginated message history
- Handles client-side tool calls (the agent can trigger actions on the device, like opening a color picker)
- Supports message feedback (thumbs up/down) and message retry
- Demonstrates multiple tool call patterns: resolve, fail, ignore, deferred UI

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

5. The ChatbaseSDK package should resolve automatically. If not, go to File > Packages > Resolve Package Versions.

6. Build and run (Cmd+R).

## Project structure

```
tatbeeqMa7mool/
  ViewModels/
    ChatViewModel.swift
    ConversationListViewModel.swift
  Views/
    ChatView.swift
    ConversationListView.swift
    MessageBubble.swift
    TypingIndicator.swift
  tatbeeqMa7moolApp.swift
  Info.plist
```

The app depends on [ChatbaseSDK](https://github.com/Chatbase-co/chatbase-ios-sdk) for all API communication, models, and streaming.

## Preview
<img width="301" height="655" alt="image" src="https://github.com/user-attachments/assets/383d910a-294c-4008-a41f-75528c14197f" />
