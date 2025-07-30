//
//  AnimatedIconButton.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//


//
//  AnimatedIconButton.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct AnimatedIconButton: View {
    let imageName: String
    let title: String
    let isVisible: Bool
    let delay: Double
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
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
                    // Background with glow effect
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .white.opacity(0.3), radius: pulseAnimation ? 15 : 8)
                    
                    // Icon
                    Image(systemName: imageName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.9 : (pulseAnimation ? 1.05 : 1.0))
            
            // Title
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .scaleEffect(isVisible ? 1.0 : 0.3)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: isVisible)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(delay + 0.5)) {
                pulseAnimation = true
            }
        }
    }
}
