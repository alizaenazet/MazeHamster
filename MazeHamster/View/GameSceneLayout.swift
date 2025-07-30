//
//  GameSceneLayout.swift
//  MazeHamsterGame
//
//  Created by Darmawan on 30/07/25.
//

import SwiftUI

struct GameSceneLayout<Content: View, Buttons: View>: View {
    let headerImage: String
    let content: Content
    let buttons: Buttons

    init(
        headerImage: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder buttons: () -> Buttons
    ) {
        self.headerImage = headerImage
        self.content = content()
        self.buttons = buttons()
    }

    var body: some View {
        VStack(spacing: 40) {
            Image(headerImage)
                .resizable()
                .scaledToFit()
                .padding(.top, 40)

            VStack(spacing: 24) {
                content

                HStack(spacing: 40) {
                    buttons
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 30)
        }
        .padding(.bottom, 40)
        .padding(.horizontal, 20)
        .padding(.vertical,32)
    }
}
