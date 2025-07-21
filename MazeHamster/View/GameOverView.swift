//
//  GameOverView.swift
//  MazeHamster
//
//  Created by Ali zaenal on 21/07/25.
//

import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Game Over Animation
            VStack(spacing: 20) {
                Text("😿")
                    .font(.system(size: 80))
                    .scaleEffect(gameViewModel.isGameFailed ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: gameViewModel.isGameFailed)
                
                Text("Game Over")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("The Cat Caught You!")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Score Display
            VStack(spacing: 10) {
                Text("Score")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("\(gameViewModel.score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                Text("Maze Size: \(gameViewModel.currentMazeSize.x)×\(gameViewModel.currentMazeSize.y)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            Spacer()
            
            // Motivational Message
            VStack(spacing: 10) {
                Text("Don't Give Up!")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Try different strategies:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("• Move quickly when cat spawns")
                    Text("• Use maze walls to block the cat")
                    Text("• Plan your route to the exit")
                }
                .font(.caption)
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 15) {
                Button("Try Again") {
                    HapticManager.impact(.heavy)
                    gameViewModel.resetGame()
                }
                .buttonStyle(GameButtonStyle(color: .orange))
                
                Button("New Maze") {
                    HapticManager.impact(.medium)
                    gameViewModel.generateNewMaze()
                }
                .buttonStyle(GameButtonStyle(color: .purple))
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.red.opacity(0.3), .orange.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            HapticManager.error()
        }
    }
}

#Preview {
    GameOverView()
}
