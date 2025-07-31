//
//  MazeBallApp.swift
//  MazeBall
//
//  Created by Ali zaenal on 15/07/25.
//

import SwiftUI

@main
struct MazeBallApp: App {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationCoordinator)
        }
    }
}
