//
//  ChatView.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 12/03/2026.
//

import SwiftUI


struct ChatView: View {
    
    @State var currentUserMessage = ""
    
    @State var messages: [Message] = [
        Message(id: "1", text: "Hi!", sender: .user, date: .now - 60000),
        Message(id: "2", text: "Hello, How can I help!", sender: .agent, date: .now - 50000)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                Text("AI Chat")
                    .font(Font.largeTitle.bold())
                ForEach(messages) { message in
                    HStack(){
                        if message.sender == .user {
                            Spacer()
                            Text(message.date, style: .time)
                                .font(.caption)
                        }
                        
                            VStack{
                                Text(message.text)
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(message.sender == .user ? Color.green : Color.blue)
                            .cornerRadius(10)
                        

                        if message.sender == .agent {
                            Text(message.date, style: .time)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        
        HStack {
            TextField("Enter your message", text: $currentUserMessage)
                .padding(.horizontal)
                .textFieldStyle(.roundedBorder)
            
            Button("Send"){
                if currentUserMessage.isEmpty {return}
                messages.append(Message(id: UUID().uuidString, text: currentUserMessage, sender: .user, date: .now))
                currentUserMessage = ""
            }
        }
        .padding()
    }
}

#Preview {
    ChatView()
}
