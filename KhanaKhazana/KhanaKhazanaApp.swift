//
//  KhanaKhazanaApp.swift
//  KhanaKhazana
//
//  Created by Harshit Gupta on 07/05/25.
//

import SwiftUI

@main
struct KhanaKhazanaApp: App {
    // Initialize the data controller
    @StateObject private var dataController = DataController.shared
    
    // Create app lifecycle event observer
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataController)
        }
        .onChange(of: scenePhase) { phase in
            // Save data when app moves to background or inactive state
            if phase == .background || phase == .inactive {
                print("App entering background/inactive state - saving data")
                dataController.saveAllData()
            }
            
            // Log app lifecycle states
            switch phase {
            case .active:
                print("App became active")
            case .inactive:
                print("App became inactive")
            case .background:
                print("App moved to background")
            @unknown default:
                print("App entered unknown state")
            }
        }
    }
}
