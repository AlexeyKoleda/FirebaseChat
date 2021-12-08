//
//  RecentMessage.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 08.12.2021.
//

import Foundation
import Firebase

struct RecentMessage: Identifiable {

    var id: String { documentId }

    let documentId: String
    let text, email: String
    let fromId, toId: String
    let profileImageUrl: String
    let timestamp: Timestamp

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.text = data[FBConst.text] as? String ?? ""
        self.fromId = data[FBConst.fromId] as? String ?? ""
        self.toId = data[FBConst.toId] as? String ?? ""
        self.profileImageUrl = data[FBConst.profileImageUrl] as? String ?? ""
        self.email = data[FBConst.email] as? String ?? ""
        self.timestamp = data[FBConst.timestamp] as? Timestamp ?? Timestamp(date: Date())
    }
}
