//
//  GameView.swift
//  MazeHamster
//
//  Created by Ali zaenal on 21/07/25.
//

import SwiftUI
import RealityKit


struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel() // Create fresh instance
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var hasNavigatedToGameOver = false
    @State private var hasNavigatedToCompleted = false
    @State private var hasNavigatedAway = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main game content
                AnimatedBackgroundView()
                RealityView { content in
                    // Initialize the game scene through ViewModel
                    let scene = gameViewModel.initializeScene()
                    content.add(scene)
                } update: { content in
                    // Update the game on each frame
                    gameViewModel.updateGame(deltaTime: 1.0/60.0)
                }
                .realityViewCameraControls(.none)
                .disabled(gameViewModel.isLoading)
                .frame(
                    width: geometry.size.width - 16,  // Slightly reduced horizontal padding
                    height: geometry.size.height - 8  // Much smaller vertical padding
                )
                .clipped()
                .onAppear {
                    gameViewModel.viewDidAppear()
                    // Reset navigation flags
                    hasNavigatedToGameOver = false
                    hasNavigatedToCompleted = false
                    
                    // Update game configuration with screen dimensions and aspect ratio
                    let screenSize = SIMD2<Float>(
                        Float(geometry.size.width),
                        Float(geometry.size.height)
                    )
                    let aspectRatio = Float(geometry.size.width / geometry.size.height)
                    gameViewModel.updateScreenDimensions(screenSize, aspectRatio: aspectRatio)
                }
                .onDisappear {
                    gameViewModel.viewWillDisappear()
                }
                .environmentObject(gameViewModel)
                // gameOverlay (if you want to keep it)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .edgesIgnoringSafeArea(.all) // Make it truly fullscreen
        .onChange(of: gameViewModel.gameState) { oldValue, newValue in
            handleGameStateChange(newValue)
        }
    }
    
    
    // In GameView.swift, update handleGameStateChange:
    private func handleGameStateChange(_ state: GameState) {
        guard !hasNavigatedAway else { return }
        
        switch state {
        case .failed:
            hasNavigatedAway = true
            // Pass score to coordinator before navigating
            navigationCoordinator.gameScore = gameViewModel.score
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationCoordinator.navigateToGameOver()
            }
        case .completed:
            hasNavigatedAway = true
            // Pass score to coordinator before navigating
            navigationCoordinator.gameScore = gameViewModel.score
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationCoordinator.navigateToGameCompleted()
            }
        default:
            break
        }
    }

}




extension GameView {
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
    GameView()
        .environmentObject(GameViewModel())
        .environmentObject(NavigationCoordinator())
}
