//
//  GameOverParticle.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//


//
//  GameOverParticle.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct GameOverParticle: View {
    let delay: Double
    let isAnimating: Bool
    @State private var localAnimation = false
    @State private var rotationAnimation = 0.0
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.red.opacity(0.6),
                            Color.orange.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 25
                    )
                )
                .frame(width: 20, height: 20)
                .blur(radius: 3)
            
            // Main particle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.orange,
                            Color.red
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 8, height: 8)
                .shadow(color: .red, radius: 4)
            
            // Sparkle effect
            Image(systemName: "sparkle")
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotationAnimation))
        }
        .scaleEffect(localAnimation ? 1.2 : 0.3)
        .opacity(localAnimation ? 0.8 : 0.0)
        .animation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
            .delay(delay),
            value: localAnimation
        )
        .onAppear {
            localAnimation = true
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotationAnimation = 360
            }
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    localAnimation = true
                }
            }
        }
    }
}
