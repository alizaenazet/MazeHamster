//
//  ContentView.swift
//  MazeBall
//
//  Created by Ali zaenal on 10/07/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    
    // MARK: - ViewModel
    
    @StateObject private var gameViewModel = GameViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main Game View
            if gameViewModel.gameState == .menu {
                MenuView()
                    .environmentObject(gameViewModel)
            } else if gameViewModel.gameState == .completed {
                GameCompletedView()
                    .environmentObject(gameViewModel)
            } else if gameViewModel.gameState == .failed {
                GameOverView()
                    .environmentObject(gameViewModel)
            } else {
                GameView()
                    .environmentObject(gameViewModel)
            }
            
            // UI Overlay (only show during gameplay)
            if gameViewModel.gameState == .playing || gameViewModel.gameState == .paused {
                gameOverlay
            }
        }
        .background(Color.black)
        .onAppear {
            gameViewModel.viewDidAppear()
        }
        .onDisappear {
            gameViewModel.viewWillDisappear()
        }

    }
    
    private var gameOverlay: some View {
        VStack {
            // Top HUD
            topHUD
            
            Spacer()
            
            // Game Controls
            gameControls
        }
        .padding()
    }
    
    private var topHUD: some View {
        HStack {
            // Score Display
            VStack(alignment: .leading) {
                Text("Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(gameViewModel.score)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            // Cat Status
            VStack(alignment: .center) {
                Text("Cat Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(gameViewModel.catStatusDescription)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(gameViewModel.showCatCountdown ? .orange : .red)
            }
            Spacer()
            // Game State Display
            VStack(alignment: .trailing) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(gameStateText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(gameStateColor)
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var gameControls: some View {
        VStack(spacing: 20) {
            // Loading Indicator
            if gameViewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            // Error Message
            if let errorMessage = gameViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(5)
            }
            
            // Cat Countdown
            if gameViewModel.showCatCountdown {
                Text(gameViewModel.catCountdownText)
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(10)
                    .animation(.easeInOut, value: gameViewModel.catSpawnCountdown)
            }
            
            // Game Control Buttons
            HStack(spacing: 20) {
                // Pause Button
                if gameViewModel.canPauseGame {
                    Button("Pause") {
                        HapticManager.impact(.light)
                        gameViewModel.pauseGame()
                    }
                    .buttonStyle(GameButtonStyle(color: .orange))
                }
                
                // Resume Button
                if gameViewModel.canResumeGame {
                    Button("Resume") {
                        HapticManager.impact(.light)
                        gameViewModel.resumeGame()
                    }
                    .buttonStyle(GameButtonStyle(color: .blue))
                }
                
                // Reset Button
                Button("Reset") {
                    HapticManager.impact(.medium)
                    gameViewModel.resetGame()
                }
                .buttonStyle(GameButtonStyle(color: .red))
            }
            
            // New Maze Button
            Button("New Maze") {
                HapticManager.impact(.medium)
                gameViewModel.generateNewMaze()
            }
            .buttonStyle(GameButtonStyle(color: .purple))
            .disabled(gameViewModel.isGameActive)
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Computed Properties
    
    private var gameStateText: String {
        switch gameViewModel.gameState {
        case .menu:
            return "Menu"
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed!"
        case .failed:
            return "Failed"
        }
    }
    
    private var gameStateColor: Color {
        switch gameViewModel.gameState {
        case .menu:
            return .primary
        case .playing:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .blue
        case .failed:
            return .red
        }
    }
}

// MARK: - Custom Button Style

struct GameButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .frame(minWidth: 80, minHeight: 44)
            .background(color)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Haptic Feedback Manager

class HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
}

#Preview {
    ContentView()
}
