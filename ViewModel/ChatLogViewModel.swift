//
//  ChatLogViewModel.swift
//  ChatApp
//
//  Created by Sayan  Maity  on 16/08/25.
//

import SwiftUI
import Firebase

struct ChatMessage: Identifiable {
    var id: String
    var fromId: String
    var toId: String
    var text: String
    var timestamp: Date
}

class ChatLogViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var recipient: User
    private var db = FirebaseManager.shared.firestore

    init(recipient: User) {
        self.recipient = recipient
    }

    func fetchMessages() {
        guard let currentUid = FirebaseManager.shared.auth.currentUser?.uid else { return }

        db.collection("messages")
            .document(currentUid)
            .collection(recipient.id)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                self.messages = documents.map { doc in
                    let data = doc.data()
                    return ChatMessage(
                        id: doc.documentID,
                        fromId: data["fromId"] as? String ?? "",
                        toId: data["toId"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            }
    }

    func sendMessage(text: String) {
        guard let currentUid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let messageData: [String: Any] = [
            "fromId": currentUid,
            "toId": recipient.id,
            "text": text,
            "timestamp": Timestamp()
        ]

        // Save to sender's collection
        db.collection("messages").document(currentUid).collection(recipient.id).addDocument(data: messageData)

        // Save to recipient's collection
        db.collection("messages").document(recipient.id).collection(currentUid).addDocument(data: messageData)
    }
}
