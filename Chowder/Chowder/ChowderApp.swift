//
//  ChowderApp.swift
//  Chowder
//
//  Created by Gabriel Mitchell on 2/10/26.
//

import SwiftUI

@main
struct ChowderApp: App {
    init() {
        print("🟢 APP LAUNCHED — if you see this, print() works")

        // Start observing push-to-start tokens for Live Activities (iOS 17.2+)
        LiveActivityManager.shared.observePushToStartToken()
        
        // Observe for activities started via push notification
        LiveActivityManager.shared.observeActivityUpdates()
    }

    var body: some Scene {
        WindowGroup {
            ChatView()
        }
    }
}
