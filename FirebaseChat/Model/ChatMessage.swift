//
//  ChatMessage.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 08.12.2021.
//

import Foundation

struct ChatMessage: Identifiable {
    
    var id: String { documentId }
    
    let documentId: String
    let fromId, toId, text: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FBConst.fromId] as? String ?? ""
        self.toId = data[FBConst.toId] as? String ?? ""
        self.text = data[FBConst.text] as? String ?? ""
    }
}
