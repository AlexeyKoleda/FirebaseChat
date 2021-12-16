//
//  ChatLogViewModel.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 16.12.2021.
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
