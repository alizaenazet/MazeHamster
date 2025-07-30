//
//  GameView.swift
//  MazeHamster
//
//  Created by Ali zaenal on 21/07/25.
//

import SwiftUI
import RealityKit


struct GameView: View {
    @StateObject var gameViewModel  = GameViewModel()
    
    var body: some View {
        ZStack{
            
      
            
        if gameViewModel.isGameFailed {
            GameOverScene()
                .environmentObject(gameViewModel)
        }else if gameViewModel.isGameCompleted {
            GameCompletedScene()
                .environmentObject(gameViewModel)
        }else  {
            
            ZStack{
                AnimatedBackgroundView()
                
                // Show loading screen when isLoading is true
                if gameViewModel.isLoading {
                    loadingView
                } else {
                    // Only render RealityView when loading is complete
                    RealityView { content in
                        // Initialize the game scene through ViewModel
                        let scene = gameViewModel.initializeScene()
                        content.add(scene)
                    } update: { content in
                        // Update the game on each frame
                        gameViewModel.updateGame(deltaTime: 1.0/60.0)
                    }
                    .realityViewCameraControls(.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all)
                    .onAppear {
                        gameViewModel.viewDidAppear()
                    }
                    .onDisappear {
                        gameViewModel.viewWillDisappear()
                    }
                }
                
//                gameOverlay
            }
        }
        }
    }
}

extension GameView {
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Loading Animation with SF Symbol
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(gameViewModel.isLoading ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: gameViewModel.isLoading)
                
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .opacity(0.3)
                        .scaleEffect(1.5)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false).delay(0.0), value: gameViewModel.isLoading)
                    
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .opacity(0.3)
                        .scaleEffect(1.5)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false).delay(0.2), value: gameViewModel.isLoading)
                    
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .opacity(0.3)
                        .scaleEffect(1.5)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false).delay(0.4), value: gameViewModel.isLoading)
                }
            }
            
            // Loading Text with SF Symbols
            VStack(spacing: 15) {
                HStack(spacing: 10) {
                    Image(systemName: "maze")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Loading Game...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Preparing your maze adventure")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Additional loading tips
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text("Tip: Use swipe gestures to move the hamster")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "cat.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        
                        Text("Avoid the cats and reach the cheese!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
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
//            .disabled(gameViewModel.isGameActive)
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
    @Previewable @StateObject var gameViewModel = GameViewModel()
    GameView()
        .environmentObject(gameViewModel)
}
