//
//  ContentView.swift
//  FirebaseChat
//
//  Created by Alexey Koleda on 24.11.2021.
//

import SwiftUI
import Firebase

class FirebaseManager: NSObject {
    
    let auth: Auth
    
    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        
        super.init()
    }
}

struct LoginView: View {
    
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    
    init() {
        
    }
    
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
                            
                        } label: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 64))
                                .padding()
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
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, err in
            if let err = err {
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            self.loginStatusMessage = "Successfully create user: \(result?.user.uid ?? "")"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
