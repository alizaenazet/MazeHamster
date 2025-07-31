//
//  MainMenuScene.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct MainMenuScene: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var showContent = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var isButtonPressed = false
    
    var body: some View {
        ZStack {
            // Background
            AnimatedBackgroundView()
            
            // Main Content
            VStack(spacing: 0) {
                // Logo Section
                VStack {
                    Image("MazeHamsterText")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 120)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showContent)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Instructions Section
                VStack(spacing: 20) {
                    Text("How to Play")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showContent)
                    
                    VStack(spacing: 16) {
                        InstructionRow(
                            icon: "🎯",
                            text: "Guide the ball to the exit",
                            delay: 0.5
                        )
                        
                        InstructionRow(
                            icon: "🐱",
                            text: "Avoid the cat",
                            delay: 0.6
                        )
                        
                        InstructionRow(
                            icon: "📱",
                            text: "Tilt your device to move",
                            delay: 0.7
                        )
                        
                        InstructionRow(
                            icon: "🏃‍♂️",
                            text: "Cat spawns after 2 seconds",
                            delay: 0.8
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Start Button Section
                VStack(spacing: 20) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isButtonPressed = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                isButtonPressed = false
                            }
                            // Reset game state before navigating
                            // Navigate to game
                            navigationCoordinator.navigateToGame()
                        }
                    } ){
                        ZStack {
                                                    Image("HamsterButton")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 140, height: 140)
                                                        .scaleEffect(isButtonPressed ? 0.95 : buttonScale)
                                                        .shadow(color: .pink.opacity(0.5), radius: 20, x: 0, y: 10)
                                                }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isButtonPressed = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isButtonPressed = false
                            }
                        }
                        
                        print("START GAME")
                    })
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(1.0), value: showContent)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            buttonScale = 1.1
                        }
                    }
                }
                .padding(.bottom, 40)
        
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    let delay: Double
    @State private var showRow = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .scaleEffect(showRow ? 1.0 : 0.8)
        .opacity(showRow ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: showRow)
        .onAppear {
            showRow = true
        }
    }
}

#Preview {
    MainMenuScene()
        .environmentObject(NavigationCoordinator())
}
