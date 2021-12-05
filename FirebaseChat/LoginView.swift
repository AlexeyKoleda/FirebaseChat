//
//  ContentView.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 24.11.2021.
//

import SwiftUI

struct LoginView: View {
    
    let didCompleteLiginProcess: () -> ()
    
    @State var image: UIImage?
    @State private var isLoginMode = false
    @State private var shouldShowInagePicker = false
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Login").tag(true)
                        Text("Create account").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            shouldShowInagePicker.toggle()
                        } label: {
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                        .stroke(Color.black, lineWidth: 3))
                        }
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(Color.white)

                    Button {
                        handleAction()
                    } label: {
                        Text(isLoginMode ? "Log In" : "Create Account")
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.white)
                            .font(.system(size: 14, weight: .semibold))
                            .background(Color.blue)
                    }
                    Text(self.loginStatusMessage)
                        .foregroundColor(Color.red)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                            .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowInagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    private func handleAction() {
        if isLoginMode {
            loginUser()
//            print("Should log into Firebase with existed credentials")
        } else {
            createNewAccount()
//            print("Register a new account incide of Firebase Auth and then store image in Storage somehow...")
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }

        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, error in
            if let error = error {
                self.loginStatusMessage = "Failed to create user: \(error)"
                return
            }
            self.loginStatusMessage = "Successfully create user: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, error in
            if let error = error {
                self.loginStatusMessage = "Failed to login user: \(error)"
                return
            }
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            
            self.didCompleteLiginProcess()
        }
    }
    
    private func persistImageToStorage() {
//        let fileName = UUID().uuidString
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        
        ref.putData(imageData, metadata: nil) { imageData, error in
            if let error = error {
                self.loginStatusMessage = "Failed to push image to Storage: \(error)"
                return
            }
            
            ref.downloadURL { url, error in
                if let error = error {
                    self.loginStatusMessage = "Failed to retrive download URL: \(error)"
                    return
                }
                
                self.loginStatusMessage = "Successfully stored image with URL: \(url?.absoluteString ?? "")"
                
                guard let url = url else { return }
                storeUserInfo(imageProfileUrl: url)
                
            }
        }
    }
    
    private func storeUserInfo(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                self.loginStatusMessage = "\(error)"
                return
            }
        }
        print("Success")
        self.didCompleteLiginProcess()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLiginProcess: {})
    }
}
