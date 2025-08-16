//
//  ChatAppApp.swift
//  ChatApp
//
//  Created by Sayan  Maity  on 11/08/25.
//

import SwiftUI

@main
struct ChatAppApp: App {
    var body: some Scene {
        WindowGroup {
            if FirebaseManager.shared.auth.currentUser != nil {
                MainMessageView()
            } else {
                LoginView(showStatus: false)
            }
        }
    }
}
