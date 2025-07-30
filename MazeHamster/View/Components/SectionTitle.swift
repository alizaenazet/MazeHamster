//
//  SectionTitle.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//


//
//  SectionTitle.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct SectionTitle: View {
    let text: String
    let isVisible: Bool
    let delay: Double
    
    @State private var glowAnimation = false
    
    var body: some View {
        Text(text)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .white.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: .white.opacity(glowAnimation ? 0.6 : 0.3), radius: glowAnimation ? 8 : 4)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: isVisible)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(delay + 0.5)) {
                    glowAnimation = true
                }
            }
    }
}
