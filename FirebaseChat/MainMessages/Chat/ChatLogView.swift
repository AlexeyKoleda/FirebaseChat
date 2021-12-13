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
    
    var firestoreListener: ListenerRegistration?
    var chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
    
        fetchMessages()
    }
    
    func fetchMessages() {
        firestoreListener?.remove()
        chatMessages.removeAll()
        
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        self.firestoreListener = FirebaseManager.shared.firestore.collection(FBConst.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FBConst.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for: \(error)"
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        do {
                            if let cm = try change.document.data(as: ChatMessage.self) {
                                self.chatMessages.append(cm)
                                print("Appending chatMessage in chatLogView \(Date())")
                            }
                        } catch {
                            print("Failed to decore message: \(error)")
                        }
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
        
        let document = FirebaseManager.shared.firestore.collection(FBConst.messages)
            .document(fromId)
            .collection(toId)
            .document()
        
        let msg = ChatMessage(id: nil, fromId: fromId, toId: toId, text: chatText, timestamp: Date())
        
        try? document.setData(from: msg) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            print("Successfully saved current user sending message")
            
            self.persistRecentMessage()
            
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection(FBConst.messages)
            .document(toId)
            .collection(fromId)
            .document()

        try? recipientMessageDocument.setData(from: msg) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            print("Recipient saved message as well")
        }
    }
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore.collection(FBConst.recentMessages)
            .document(uid)
            .collection(FBConst.messages)
            .document(toId)
        
        let data = [
             FBConst.timestamp: Timestamp(),
             FBConst.text: self.chatText,
             FBConst.fromId: uid,
             FBConst.toId: toId,
             FBConst.profileImageUrl: chatUser.profileImageUrl,
             FBConst.email: chatUser.email
         ] as [String : Any]

         document.setData(data) { error in
             if let error = error {
                 self.errorMessage = "Failed to save recent message: \(error)"
                 print("Failed to save recent message: \(error)")
                 return
             }
         }
    }
}

struct ChatLogView: View {
    
    static var emptyScrollToString = "Empty"
    
    @ObservedObject var vm: ChatLogViewModel
    
//    let chatUser: ChatUser?
//
//    init(chatUser: ChatUser?) {
//        self.chatUser = chatUser
//        self.vm = .init(chatUser: chatUser)
//    }
    
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
