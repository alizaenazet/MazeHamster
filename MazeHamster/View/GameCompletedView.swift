//
//  GameCompletedView.swift
//  MazeHamster
//
//  Created by Ali zaenal on 21/07/25.
//

import SwiftUI

struct GameCompletedView: View {
    @EnvironmentObject var gameViewModel: GameViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success Animation
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(gameViewModel.isGameCompleted ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: gameViewModel.isGameCompleted)
                
                Text("Congratulations!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("You Escaped the Maze!")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Score Display
            VStack(spacing: 10) {
                Text("Final Score")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("\(gameViewModel.score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                
                Text("Maze Size: \(gameViewModel.currentMazeSize.x)×\(gameViewModel.currentMazeSize.y)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 15) {
                Button("Play Again") {
                    HapticManager.success()
                    gameViewModel.resetGame()
                }
                .buttonStyle(GameButtonStyle(color: .green))
                
                Button("New Maze") {
                    HapticManager.impact(.medium)
                    gameViewModel.generateNewMaze()
                }
                .buttonStyle(GameButtonStyle(color: .blue))
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.green.opacity(0.3), .blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            HapticManager.success()
        }
    }
}

#Preview {
    GameCompletedView()
}
