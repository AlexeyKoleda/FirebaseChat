//
//  CreateNewMessageViewModel.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 16.12.2021.
//

import SwiftUI

class CreateNewMessageViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var users = [ChatUser]()
    
    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        FirebaseManager.shared.firestore.collection(FBConst.users).getDocuments { documentsSnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch users: \(error)"
                return
            }
            
            documentsSnapshot?.documents.forEach({ snapshot in
                let data = snapshot.data()
                let user = ChatUser(data: data)
                if user.uid != FirebaseManager.shared.auth.currentUser?.uid {
                    self.users.append(.init(data: data))
                }
            })
        }
    }
}
