# Chatbase iOS Example App

A sample iOS app showing how to build a chat interface on the [ChatbaseSDK](https://github.com/Chatbase-co/chatbase-ios-sdk). Built with SwiftUI.

## What it does

- Streams agent responses in real time into SwiftUI bindings via `ConversationState`
- Lists previous conversations with paginated message history
- Registers client-side tools the agent can invoke mid-turn:
  - `package_status` — a synchronous tool that returns an object payload (or `{"error": ...}` for missing input)
  - `change_background` — an async tool that opens a color picker, suspends until the user picks, and surfaces cancel as an error payload
- Identifies the end user via a JWT (agent identity verification)
- Supports message feedback (thumbs up/down) and message retry

## Setup

1. Open `tatbeeqMa7mool.xcodeproj` in Xcode.

2. Create a file called `Secrets.xcconfig` in the project root (next to `.xcodeproj`):

```
AGENT_ID = your-chatbase-agent-id
API_BASE_URL = https://www.chatbase.co/api/sdk
```

For local development against a local Chatbase instance, set `API_BASE_URL = http://localhost:3000/api/sdk`.

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
    AuthViewModel.swift
    ChatViewModel.swift
    ConversationListViewModel.swift
  Views/
    AuthSheet.swift
    ChatView.swift
    ConversationListView.swift
    MessageBubbleView.swift
    TypingIndicator.swift
  tatbeeqMa7moolApp.swift
  Info.plist
```

The app depends on [ChatbaseSDK](https://github.com/Chatbase-co/chatbase-ios-sdk) for all API communication, models, streaming, and the observable `ConversationState`.

## Preview
<img width="301" height="655" alt="image" src="https://github.com/user-attachments/assets/383d910a-294c-4008-a41f-75528c14197f" />
