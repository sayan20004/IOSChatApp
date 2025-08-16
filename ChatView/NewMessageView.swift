//
//  NewMessageView.swift
//  ChatApp
//
//  Created by Sayan  Maity  on 15/08/25.
//

import SwiftUI

struct NewMessageView: View {
    var didSelectUser: (User) -> Void
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm = FetchAllUsersViewModel()
    
    var body: some View {
        NavigationView {
            List(vm.users) { user in
                Button {
                    presentationMode.wrappedValue.dismiss()
                    didSelectUser(user)
                } label: {
                    HStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: user.colorHex))
                                .frame(width: 50, height: 50)
                            Text(user.initials)
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.fullName)
                                .font(.system(size: 16, weight: .semibold))
                            Text(user.email)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationBarTitle("New Message", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: 1)
    }
}

#Preview {
//    NewMessageView()
}
