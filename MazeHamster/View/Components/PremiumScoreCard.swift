//
//  PremiumScoreCardView.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//


import SwiftUI

struct PremiumScoreCard: View {
    let title: String
    let score: Int
    let subtitle: String?
    let accentColor: Color
    let isHighlighted: Bool
    @State private var animateGlow = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                if isHighlighted {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow, radius: 4)
                }

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .textCase(.uppercase)
                    .tracking(1.2)
            }
            Text("\(score)")
                .font(.system(size: isHighlighted ? 56 : 32, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: isHighlighted ? [.yellow, .orange, .yellow] : [.white, .white.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: accentColor.opacity(0.5), radius: animateGlow ? 15 : 8)
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 2)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(accentColor)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 28)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.6),
                                accentColor.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )

                if isHighlighted {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow.opacity(0.6), lineWidth: 3)
                        .shadow(color: .yellow, radius: animateGlow ? 20 : 10)
                }
            }
        }
        .onAppear {
            if isHighlighted {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateGlow.toggle()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PremiumScoreCard(
            title: "Best Score",
            score: 1200,
            subtitle: "New Record!",
            accentColor: .orange,
            isHighlighted: true
        )
    }
}
