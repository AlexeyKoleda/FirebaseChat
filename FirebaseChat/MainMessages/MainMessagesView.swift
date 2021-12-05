//
//  MainMessagesView.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 30.11.2021.
//

import SwiftUI
import SDWebImageSwiftUI

class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLiggedOut = false
    
    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLiggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find firebase uid"
            return
        }
       
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failet to fetch current user: \(error)"
                return
            }
            guard let data = snapshot?.data() else {
                self.errorMessage = "No data found"
                return
            }
            self.chatUser = .init(data: data)
        }
    }
    
    func handleSignOut() {
        isUserCurrentlyLiggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    
    @State var shouldShowLogoutOptions = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messagesView
            }
            .overlay(newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    
    private var customNavBar: some View {
        HStack(spacing: 16) {
            
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .clipped()
                .frame(width: 50, height: 50)
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 32)
                            .stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 5)

            VStack(alignment: .leading, spacing: 4) {
                let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                Text(email)
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            Spacer()
            Button {
                shouldShowLogoutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogoutOptions) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sigh Out"), action: {
                    print("handle sign out")
                    vm.handleSignOut()
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLiggedOut, onDismiss: nil) {
            LoginView(didCompleteLiginProcess: {
                self.vm.isUserCurrentlyLiggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 32)
                                        .stroke(Color(.label), lineWidth: 1))
                        
                        VStack(alignment: .leading) {
                            Text("Anonimous")
                                .font(.system(size: 16, weight: .bold))
                            Text("Message sent to user")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.lightGray))
                        }
                        Spacer()
                        Text("2d")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Divider()
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
    }
    
    private var newMessageButton: some View {
        Button{
            
        } label: {
            HStack {
                Spacer()
                Text("+ New message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .padding(.vertical)
            .foregroundColor(.white)
            .background(Color.blue).cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
        
        MainMessagesView()
            .preferredColorScheme(.dark)
    }
}
