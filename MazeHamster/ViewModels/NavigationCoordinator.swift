// ViewModels/NavigationCoordinator.swift
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
    @Published var gameScore: Int = 0 // Store score temporarily
    // Navigation methods
    func navigateToMenu() {
        path = NavigationPath() // Reset to root
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
    
    func goBackToRoot() {
        path = NavigationPath()
    }
    
    func goBackBy(_ count: Int) {
        let removeCount = min(count, path.count)
        path.removeLast(removeCount)
    }
    
    func restartGame() {
        // Remove game over/completed screen and game screen
        if path.count >= 2 {
            path.removeLast(2)
        }
        // Navigate to fresh game instance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.navigateToGame()
        }
    }
}
