//
//  MenuView.swift
//  MazeHamster
//
//  Created by Ali zaenal on 21/07/25.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Game Title
            VStack(spacing: 10) {
                Text("MazeBall")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tilt to Navigate")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Instructions
            VStack(spacing: 15) {
                Text("🎯 Guide the ball to the exit")
                Text("🐱 Avoid the cat")
                Text("📱 Tilt your device to move")
                Text("🏃‍♂️ Cat spawns after 2 seconds")
            }
            .font(.body)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            
            Spacer()
            
            // Start Button
            Button("Start Game") {
                HapticManager.impact(.medium)
                gameViewModel.startGame()
            }
            .buttonStyle(GameButtonStyle(color: .green))
            .scaleEffect(1.2)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    MenuView()
}
