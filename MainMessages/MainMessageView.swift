//
//  MainMessageView.swift
//  ChatApp
//
//  Created by Sayan Maity on 14/08/25.
//

import SwiftUI
import Firebase

// MARK: - User Model
struct User: Identifiable {
    var id: String
    var fullName: String
    var initials: String
    var colorHex: String
    var email: String
}

// MARK: - ViewModel for Current User
class MainMessageViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var initials = ""
    @Published var color: Color = .gray
    @Published var email = ""
    
    init() {
        fetchCurrentUser()
    }
    
    private func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user:", error)
                return
            }
            
            guard let data = snapshot?.data() else { return }
            self.fullName = data["fullName"] as? String ?? ""
            self.initials = data["initials"] as? String ?? ""
            
            if let hex = data["color"] as? String, let uiColor = UIColor(hex: hex) {
                self.color = Color(uiColor)
            }
        }
    }
}

// MARK: - ViewModel for All Users
class FetchAllUsersViewModel: ObservableObject {
    @Published var users: [User] = []
    
    init() {
        fetchAllUsers()
    }
    
    func fetchAllUsers() {
        guard let currentUid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users:", error)
                return
            }
            
            self.users = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                let uid = doc.documentID
                guard uid != currentUid else { return nil }
                
                return User(
                    id: uid,
                    fullName: data["fullName"] as? String ?? "",
                    initials: data["initials"] as? String ?? "",
                    colorHex: data["color"] as? String ?? "#808080",
                    email: data["email"] as? String ?? ""
                )
            } ?? []
        }
    }
}

// MARK: - Main Message View
struct MainMessageView: View {
    @State private var showLogout = false
    @State private var showNewMessageScreen = false
    @State private var selectedChatUser: User? = nil
    @State private var showChatLogView = false
    
    @ObservedObject private var vm = MainMessageViewModel()
//    @ObservedObject private var usersVM = FetchAllUsersViewModel()
    @ObservedObject private var chatsVM = RecentChatsViewModel()
    
    private var customNavbar: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .foregroundColor(vm.color)
                    .frame(width: 50, height: 50)
                Text(vm.initials)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.fullName)
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            Spacer()
            Button {
                showLogout.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $showLogout) {
            .init(
                title: Text("Settings"),
                message: Text("What do you want to do?"),
                buttons: [
                    .destructive(Text("Sign Out"), action: {
                        do {
                            try FirebaseManager.shared.auth.signOut()
                            UIApplication.shared.windows.first?.rootViewController =
                                UIHostingController(rootView: LoginView(showStatus: false))
                        } catch {
                            print("Failed to sign out:", error)
                        }
                    }),
                    .cancel()
                ]
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                customNavbar
                messageView
            }
            .overlay(newMessageButton, alignment: .bottom)
            .navigationDestination(isPresented: $showChatLogView) {
                if let user = selectedChatUser {
                    ChatLogView(recipient: user)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    // MARK: - Users List
    private var messageView: some View {
        ScrollView {
            ForEach(chatsVM.recentChats) { chat in
                NavigationLink(destination: ChatLogView(recipient: User(
                    id: chat.id,
                    fullName: chat.fullName,
                    initials: chat.initials,
                    colorHex: chat.colorHex,
                    email: "" // not needed
                ))) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .foregroundColor(Color(UIColor(hex: chat.colorHex) ?? .gray))
                                .frame(width: 44, height: 44)
                            Text(chat.initials)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading) {
                            Text(chat.fullName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(.label))
                            Text(chat.lastMessage)
                                .font(.system(size: 14))
                                .foregroundColor(Color(.lightGray))
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(formatTime(chat.timestamp))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    Divider().padding(.leading, 60)
                }
            }
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - New Message Button
    private var newMessageButton: some View {
        Button {
            showNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .shadow(radius: 15)
            .padding(.horizontal)
        }
        .fullScreenCover(isPresented: $showNewMessageScreen) {
            NewMessageView { selectedUser in
                self.showNewMessageScreen = false
                // Open chat log after selection
                // Assuming you add a @State var selectedChatUser: User? and @State var showChatLogView: Bool
                self.selectedChatUser = selectedUser
                self.showChatLogView = true
            }
        }
    }
}
func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
}
// MARK: - UIColor Extension
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
