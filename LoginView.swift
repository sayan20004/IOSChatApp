//
//  ContentView.swift
//  ChatApp
//
//  Created by Sayan  Maity  on 11/08/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import PhotosUI
import FirebaseFirestore

class FirebaseManager: NSObject{
    let auth: Auth
//    let storage: Storage
    let firestore: Firestore
    
    static let shared = FirebaseManager()
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
//        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(showStatus: false)
    }
}
struct LoginView: View {
    @State var isLogin = false
    @State var email = ""
    @State var password = ""
    @State var fullName = ""
    @State var loginStatus = ""
    @State var showStatus: Bool
    @State private var shouldNavigate = false   // ← Navigation trigger
    
    var randomColor: Color {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow, .gray]
        return colors.randomElement() ?? .blue
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Hidden NavigationLink that triggers navigation
                    NavigationLink(destination: MainMessageView(), isActive: $shouldNavigate) {
                        EmptyView()
                    }.hidden()
                    
                    Picker(selection: $isLogin, label: Text("Picker")) {
                        Text("Login")
                            .tag(true)
                        Text("Create account")
                            .tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if !isLogin {
                        let initials = fullName.split(separator: " ").compactMap { $0.first }.prefix(2).map { String($0) }.joined().uppercased()
                        Text(initials)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(randomColor)
                            .clipShape(Circle())
                        
                        TextField("Full Name", text: $fullName)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                    
                    Button {
                        handleAuth()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLogin ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    if showStatus {
                        Text(loginStatus)
                            .padding()
                            .background(Color.red.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 10)
                            .zIndex(1)
                    }
                    
                }
                .padding()
            }
            .navigationTitle(isLogin ? "Log in" : "Create account")
            .background(Color.gray.opacity(0.2))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func handleAuth() {
        if isLogin {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Login of user failed: ", err)
                showTempStatus("Unable to Login")
                return
            }
            
            showTempStatus("Logged in")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                shouldNavigate = true
            }
        }
    }
    
    private func createNewAccount() {
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Register unsuccessful: ", err)
                showTempStatus("Unable to register")
                return
            }
            
            showTempStatus("Registered")
            
            let initials = fullName.split(separator: " ").compactMap { $0.first }.prefix(2).map { String($0) }.joined().uppercased()
            let colorHex = "#\(String(format: "%06X", Int.random(in: 0x000000...0xFFFFFF)))"
            
            Firestore.firestore().collection("users").document(result?.user.uid ?? "").setData([
                "fullName": fullName,
                "initials": initials,
                "color": colorHex,
                "email": email
            ]) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shouldNavigate = true
                }
            }
        }
    }
    
    private func showTempStatus(_ message: String) {
        loginStatus = message
        withAnimation { showStatus = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showStatus = false }
        }
    }
}


