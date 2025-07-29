//
//  NavigationCoordinator.swift
//  MazeHamster
//
//  Created by Ali zaenal on 21/07/25.
//

import SwiftUI

enum NavigationDestination: Hashable {
    case menu
    case game
    case gameOver
    case gameCompleted
}

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateToMenu() {
        path = NavigationPath() // Reset to root (menu)
    }
    
    func navigateToGame() {
        path.append(NavigationDestination.game)
    }
    
    func navigateToGameOver() {
        path.append(NavigationDestination.gameOver)
    }
    
    func navigateToGameCompleted() {
        path.append(NavigationDestination.gameCompleted)
    }
    
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func resetToRoot() {
        path = NavigationPath()
    }
}
