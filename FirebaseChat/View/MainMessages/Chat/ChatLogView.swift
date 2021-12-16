//
//  ChatLogView.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 06.12.2021.
//

import SwiftUI
import Firebase

struct ChatLogView: View {
    
    static var emptyScrollToString = "Empty"
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        VStack {
            ZStack {
                messagesView
                Text(vm.errorMessage)
            }
            sendMessageBar
        }
        .navigationTitle(vm.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear(perform: {
            vm.firestoreListener?.remove()
        })
    }
    
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader { scrollViewProxy in
                VStack {
                    ForEach(vm.chatMessages) { message in
                        MessagesView(message: message)
                    }

                    HStack{ Spacer() }
                    .id(Self.emptyScrollToString)
                }
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.init(white: 0.90, alpha: 1)))
    }
    
    private var sendMessageBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            ZStack(alignment: .leading) {
                Text("Message...")
                    .foregroundColor(Color(.lightGray))
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
                    .frame(height: 40)
            }

            Button {
                vm.handleSend()
            } label: {
                Text("Send")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct MessagesView: View {
    
    var message: ChatMessage
    
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    MessageView(text: message.text, backgroundColor: Color.blue, foregroundColor: Color.white)
                }
            } else {
                HStack {
                    MessageView(text: message.text, backgroundColor: Color.white, foregroundColor: Color.black)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct MessageView: View {
    
    let text: String
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(text: String, backgroundColor: Color, foregroundColor: Color) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        HStack {
            Text(text)
                .foregroundColor(foregroundColor)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
        NavigationView {
            ChatLogView(vm: ChatLogViewModel(chatUser:
                            .init(data: [
                                        "uid": "4agMe757TQUeMiW9sbysYDhZGk73",
                                        "email": "waterfall@gmail.com"
            ])))
        }
    }
}
