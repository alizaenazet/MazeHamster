//
//  ContentView.swift
//  MazeBall
//
//  Created by Ali zaenal on 10/07/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var gameViewModel: GameViewModel
    // MARK: - ViewModel
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            // Main Game View
                MainMenuScene()
                .navigationBarHidden(true)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .menu:
                        MainMenuScene()
                            .navigationBarHidden(true)
                    case .game:
                        GameView()
                            .id(UUID())
                            .navigationBarHidden(true)
                    case .gameOver:
                        GameOverScene()
                            .navigationBarHidden(true)
                    case .gameCompleted:
                        GameCompletedScene()
                            .navigationBarHidden(true)
                    }
                }
            
        }
        
        
    }
}
    

#Preview {
    ContentView()
        .environmentObject(NavigationCoordinator())
        .environmentObject(GameViewModel())
}
