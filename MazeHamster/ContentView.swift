//
//  ContentView.swift
//  MazeBall
//
//  Created by Ali zaenal on 10/07/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    
    // MARK: - ViewModel    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            // Main Game View
                MenuView()
                .background(Color.black)
            
        }
        
        
    }
}
    

#Preview {
    ContentView()
}
