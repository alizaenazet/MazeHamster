//
//  GameOverScene.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct GameOverScene: View {

    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @AppStorage("highScore") private var highScore: Int = 0
    @State private var isNewHighScore: Bool = false
    @State private var currentScore: Int = 0
    @State private var showContent = false
    @State private var animateTitle = false
    @State private var showScores = false
    @State private var showButtons = false
    @State private var particleAnimations: [Bool] = Array(repeating: false, count: 15)
    
    private func checkForNewHighScore() {
            currentScore = navigationCoordinator.gameScore
            if currentScore > highScore {
                isNewHighScore = true
                highScore = currentScore
            }
        }
    
    private func startAnimationSequence() {
        // Title animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            animateTitle = true
        }
        
        // Score cards animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
            showScores = true
        }
        
        // Buttons animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.0)) {
            showButtons = true
        }
        
        // Particle animations
        for i in 0..<particleAnimations.count {
            withAnimation(.easeInOut(duration: 0.8).delay(Double(i) * 0.1 + 0.2)) {
                particleAnimations[i] = true
            }
        }
    }

    
    var body: some View {
        ZStack {
            // Animated Background
            AnimatedBackgroundView()
            
            VStack(spacing: 0) {
                VStack {
                    Image("GameOverText")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .scaleEffect(animateTitle ? 1.0 : 0.3)
                        .opacity(animateTitle ? 1.0 : 0.0)
        
                }
                .padding(.top, 60)
                
                Spacer()
            
                VStack(spacing: 24) {
                    PremiumScoreCard(
                        title: "Final Score",
                        score: currentScore, subtitle: "Never give up",
                        accentColor: .cyan,
                        isHighlighted: isNewHighScore
                    )
                    .scaleEffect(showScores ? 1.0 : 0.5)
                    .opacity(showScores ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showScores)

                    PremiumScoreCard(
                        title: "Best Score",
                        score: highScore,
                        subtitle: "Personal Record",
                        accentColor: .yellow,
                        isHighlighted: false
                    )
                    .scaleEffect(showScores ? 1.0 : 0.5)
                    .opacity(showScores ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showScores)

                    if isNewHighScore {
                        HighScoreCelebration()
                            .scaleEffect(showScores ? 1.0 : 0.1)
                            .opacity(showScores ? 1.0 : 0.0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5), value: showScores)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                HStack(spacing: 40) {
                    // Home Button (Reset to Main Menu)
                    AnimatedGameButton(
                        icon: "house.fill",
                        title: "Home",
                        isVisible: showButtons,
                        delay: 0.0
                    ) {
                        HapticManager.impact(.medium)
                        navigationCoordinator.navigateToMenu()
                        // Navigate to main menu - you'll need to implement this navigation
                        print("Navigate to main menu")
                    }

                    // Restart Button (Try Again)
                    AnimatedGameButton(
                        icon: "arrow.counterclockwise",
                        title: "Restart",
                        isVisible: showButtons,
                        delay: 0.1
                    ) {
                        HapticManager.impact(.heavy)
                        navigationCoordinator.restartGame()
//                        navigationCoordinator.goBack() // Go back to game
                    }
                    
                    // New Maze Button
                    AnimatedGameButton(
                        icon: "shuffle",
                        title: "New Maze",
                        isVisible: showButtons,
                        delay: 0.2
                    ) {
                        HapticManager.impact(.medium)
                        navigationCoordinator.restartGame()
//                        navigationCoordinator.goBack() // Go back to game
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            checkForNewHighScore()
            showContent = true
            startAnimationSequence()
            HapticManager.error()
        }
    }
}

struct AnimatedGameButton: View {
    let icon: String
    let title: String
    let isVisible: Bool
    let delay: Double
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                    action()
                }
            }) {
                ZStack {
                    Image("ButtonBackground")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .opacity(0.8)
        }
        .scaleEffect(isVisible ? 1.0 : 0.5)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: isVisible)
    }
}

#Preview {
    GameOverScene()
        .environmentObject(GameViewModel())
        .environmentObject(NavigationCoordinator())
}
