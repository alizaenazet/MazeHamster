//
//  HighScoreCelebration.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct HighScoreCelebration: View {
    @State private var sparkleRotation = 0.0
    @State private var pulseScale = 1.0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.yellow)
                .rotationEffect(.degrees(sparkleRotation))
                .shadow(color: .yellow, radius: 6)
            
            Text("🎉 NEW HIGH SCORE! 🎉")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange, .pink, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .yellow.opacity(0.8), radius: 8)
            
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.yellow)
                .rotationEffect(.degrees(-sparkleRotation))
                .shadow(color: .yellow, radius: 6)
        }
        .scaleEffect(pulseScale)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.2),
                            Color.orange.opacity(0.1),
                            Color.pink.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.yellow.opacity(0.8), .orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .yellow.opacity(0.4), radius: 15)
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}
