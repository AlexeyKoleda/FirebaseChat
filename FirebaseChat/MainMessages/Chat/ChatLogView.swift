//
//  ChatLogView.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 06.12.2021.
//

import SwiftUI
import Firebase

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var count = 0
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    private func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for: \(error)"
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        let docId = change.document.documentID
                        self.chatMessages.append(.init(documentId: docId, data: data))
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: self.chatText, FirebaseConstants.timestamp: Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            print("Successfully saved current user sending message")
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()

        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            print("Recipient saved message as well")
        }
    }
}

struct ChatLogView: View {
    
    static var emptyScrollToString = "Empty"
    
    @ObservedObject private var vm: ChatLogViewModel
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    var body: some View {
        VStack {
            ZStack {
                messagesView
                Text(vm.errorMessage)
            }
            sendMessageBar
        }
        .navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
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
            ChatLogView(chatUser:
                            .init(data: [
                                        "uid": "4agMe757TQUeMiW9sbysYDhZGk73",
                                        "email": "waterfall@gmail.com"
            ]))
        }
    }
}
