//
//  RecentChatsViewModel.swift
//  ChatApp
//
//  Created by Sayan  Maity  on 16/08/25.
//

import SwiftUI
import Firebase

struct RecentChat: Identifiable {
    var id: String // other user id
    var fullName: String
    var initials: String
    var colorHex: String
    var lastMessage: String
    var timestamp: Date
}

class RecentChatsViewModel: ObservableObject {
    @Published var recentChats: [RecentChat] = []
    private var db = FirebaseManager.shared.firestore
    
    init() {
        fetchRecentChats()
    }
    
    func fetchRecentChats() {
        guard let currentUid = FirebaseManager.shared.auth.currentUser?.uid else { return }

        db.collection("users").getDocuments { usersSnapshot, _ in
            guard let usersData = usersSnapshot?.documents else { return }
            
            var chats: [RecentChat] = []
            let group = DispatchGroup()
            
            for userDoc in usersData {
                let partnerId = userDoc.documentID
                guard partnerId != currentUid else { continue }
                
                group.enter()
                self.db.collection("messages")
                    .document(currentUid)
                    .collection(partnerId)
                    .order(by: "timestamp", descending: true)
                    .limit(to: 1)
                    .getDocuments { snapshot, _ in
                        if let msgData = snapshot?.documents.first?.data() {
                            let lastMsg = msgData["text"] as? String ?? ""
                            let time = (msgData["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            
                            let userData = userDoc.data()
                            chats.append(RecentChat(
                                id: partnerId,
                                fullName: userData["fullName"] as? String ?? "",
                                initials: userData["initials"] as? String ?? "",
                                colorHex: userData["color"] as? String ?? "#808080",
                                lastMessage: lastMsg,
                                timestamp: time
                            ))
                        }
                        group.leave()
                    }
            }
            
            group.notify(queue: .main) {
                self.recentChats = chats.sorted(by: { $0.timestamp > $1.timestamp })
            }
        }
    }
}
