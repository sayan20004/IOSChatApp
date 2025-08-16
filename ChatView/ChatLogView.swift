//
//  ChatLogView.swift
//  ChatApp
//
//  Created by Sayan  Maity  on 16/08/25.
//

import SwiftUI
import Firebase

struct ChatLogView: View {
    let recipient: User
    @StateObject private var vm: ChatLogViewModel
    @State private var messageText = ""

    init(recipient: User) {
        self.recipient = recipient
        _vm = StateObject(wrappedValue: ChatLogViewModel(recipient: recipient))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(vm.messages) { msg in
                        HStack {
                            if msg.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(msg.text)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    Text(formatTime(msg.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                VStack(alignment: .leading) {
                                    Text(msg.text)
                                        .padding()
                                        .background(Color(.systemGray4))
                                        .cornerRadius(12)
                                    Text(formatTime(msg.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                        }
                        .id(msg.id)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    Color.clear.frame(height: 1).id("Bottom")
                }
                .onChange(of: vm.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("Bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    if !vm.messages.isEmpty {
                        proxy.scrollTo("Bottom", anchor: .bottom)
                    }
                }
            }
            HStack {
                TextField("Message...", text: $messageText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        vm.sendMessage(text: messageText)
                        messageText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .rotationEffect(.degrees(45))
                            .font(.system(size: 20))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(recipient.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.fetchMessages() }
    }
}

//
//#Preview {
//    ChatLogView()
//}
