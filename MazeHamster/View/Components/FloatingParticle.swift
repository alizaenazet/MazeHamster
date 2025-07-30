//
//  FloatingParticle.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct FloatingParticle: View {
    @State private var isAnimating = false
    let delay: Double
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.8),
                        Color.purple.opacity(0.3),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 10
                )
            )
            .frame(width: 6, height: 6)
            .scaleEffect(isAnimating ? 1.5 : 0.5)
            .opacity(isAnimating ? 0 : 1)
            .animation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: false)
                .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

