//
//  AnimatedBackgroundView.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct AnimatedBackgroundView: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(red: 0.45, green: 0.12, blue: 0.35),
                    Color(red: 0.20, green: 0.05, blue: 0.25),
                    Color(red: 0.10, green: 0.05, blue: 0.20),
                    Color.black
                ],
                center: .center,
                startRadius: 50,
                endRadius: 800
            )
            
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.clear,
                    Color.pink.opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            ForEach(0..<30, id: \.self) { index in
                FloatingParticle(delay: Double(index) * 0.3)
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...700)
                    )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AnimatedBackgroundView()
}
