//
//  ChatLogView.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 06.12.2021.
//

import SwiftUI

struct ChatLogView: View {
    
    let chatUser: ChatUser?
    
    @State var chatText = ""
    
    var body: some View {
        VStack {
            messagesView
            sendMessageBar
        }
        .navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(0..<20) { num in
                
                HStack {
                    Spacer()
                    HStack {
                        Text("Fake message for now")
                            .foregroundColor(Color.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            HStack { Spacer() }
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
    }
    
    private var sendMessageBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            TextField("Message...", text: $chatText)
            Button {
                
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

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatLogView(chatUser:
                            .init(data: [
                                        "uid": "4agMe757TQUeMiW9sbysYDhZGk73",
                                        "email": "waterfall@gmail.com",
                                        "profileImageUrl": "https://firebasestorage.googleapis.com:443/v0/b/fb-swiftui-chat.appspot.com/o/4agMe757TQUeMiW9sbysYDhZGk73?alt=media&token=5446ef33-147e-409c-98fa-305e63a16c1e"
            ]))
        }
    }
}
