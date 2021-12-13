//
//  ChatMessage.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 08.12.2021.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
}
