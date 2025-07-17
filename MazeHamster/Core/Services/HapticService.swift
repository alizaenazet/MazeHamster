//
//  HapticService.swift
//  MazeHamster
//
//  Created by Darmawan on 16/07/25.
//

import Foundation
import UIKit

/// Service for providing haptic feedback throughout the game
class HapticService: BaseService {
    
    // MARK: - Haptic Generators
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - Service Setup
    
    override func setupService() {
        super.setupService()
        prepareHaptics()
        // print("✅ HapticService configured successfully")
    }
    
    private func prepareHaptics() {
        // Prepare generators for reduced latency
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Game Event Haptics
    
    /// Haptic feedback for game start
    func gameStarted() {
        notificationGenerator.notificationOccurred(.success)
        // print("🔸 Haptic: Game Started")
    }
    
    /// Haptic feedback for game pause
    func gamePaused() {
        impactMedium.impactOccurred()
        // print("🔸 Haptic: Game Paused")
    }
    
    /// Haptic feedback for game resume
    func gameResumed() {
        selectionGenerator.selectionChanged()
        // print("🔸 Haptic: Game Resumed")
    }
    
    /// Haptic feedback for game reset
    func gameReset() {
        impactLight.impactOccurred()
        // print("🔸 Haptic: Game Reset")
    }
    
    /// Haptic feedback for level completion
    func levelCompleted() {
        // Success pattern: light-medium-heavy
        impactLight.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactMedium.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impactHeavy.impactOccurred()
        }
        
        // Final success notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.notificationGenerator.notificationOccurred(.success)
        }
        
        // print("🔸 Haptic: Level Completed (Success Pattern)")
    }
    
    /// Haptic feedback for game over (caught by cat)
    func gameOver() {
        // Failure pattern: heavy-heavy-heavy with decreasing intervals
        impactHeavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.impactHeavy.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.impactHeavy.impactOccurred()
        }
        
        // Final failure notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.notificationGenerator.notificationOccurred(.error)
        }
        
        // print("🔸 Haptic: Game Over (Failure Pattern)")
    }
    
    /// Haptic feedback for cat spawn warning
    func catSpawnWarning() {
        notificationGenerator.notificationOccurred(.warning)
        // print("🔸 Haptic: Cat Spawn Warning")
    }
    
    /// Haptic feedback for collectible pickup
    func collectiblePickup() {
        impactLight.impactOccurred()
        // print("🔸 Haptic: Collectible Pickup")
    }
    
    /// Haptic feedback for key pickup (special collectible)
    func keyPickup() {
        impactMedium.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.selectionGenerator.selectionChanged()
        }
        // print("🔸 Haptic: Key Pickup")
    }
    
    /// Haptic feedback for power-up activation
    func powerUpActivated() {
        impactMedium.impactOccurred()
        // print("🔸 Haptic: Power-up Activated")
    }
    
    /// Haptic feedback for shield activation
    func shieldActivated() {
        impactLight.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.impactLight.impactOccurred()
        }
        // print("🔸 Haptic: Shield Activated")
    }
    
    /// Haptic feedback for near miss with cat
    func nearMiss() {
        impactMedium.impactOccurred()
        // print("🔸 Haptic: Near Miss")
    }
    
    /// Haptic feedback for button interactions
    func buttonTapped() {
        selectionGenerator.selectionChanged()
        // print("🔸 Haptic: Button Tapped")
    }
    
    /// Haptic feedback for maze generation
    func mazeGenerated() {
        impactLight.impactOccurred()
        // print("🔸 Haptic: Maze Generated")
    }
    
    /// Haptic feedback for countdown
    func countdownTick() {
        selectionGenerator.selectionChanged()
        // print("🔸 Haptic: Countdown Tick")
    }
    
    /// Haptic feedback for final countdown
    func finalCountdown() {
        impactMedium.impactOccurred()
        // print("🔸 Haptic: Final Countdown")
    }
    
    // MARK: - Custom Haptic Patterns
    
    /// Custom haptic pattern for special events
    func customPattern(_ pattern: HapticPattern) {
        switch pattern {
        case .celebration:
            celebrationPattern()
        case .warning:
            warningPattern()
        case .heartbeat:
            heartbeatPattern()
        case .rising:
            risingPattern()
        case .falling:
            fallingPattern()
        }
    }
    
    private func celebrationPattern() {
        // Celebration pattern: rapid light impacts followed by success
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                self.impactLight.impactOccurred()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.notificationGenerator.notificationOccurred(.success)
        }
        // print("🔸 Haptic: Celebration Pattern")
    }
    
    private func warningPattern() {
        // Warning pattern: alternating medium impacts
        for i in 0..<2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                self.impactMedium.impactOccurred()
            }
        }
        // print("🔸 Haptic: Warning Pattern")
    }
    
    private func heartbeatPattern() {
        // Heartbeat pattern: double thump
        impactMedium.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactMedium.impactOccurred()
        }
        // print("🔸 Haptic: Heartbeat Pattern")
    }
    
    private func risingPattern() {
        // Rising pattern: light to heavy
        impactLight.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactMedium.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impactHeavy.impactOccurred()
        }
        // print("🔸 Haptic: Rising Pattern")
    }
    
    private func fallingPattern() {
        // Falling pattern: heavy to light
        impactHeavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactMedium.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impactLight.impactOccurred()
        }
        // print("🔸 Haptic: Falling Pattern")
    }
    
    // MARK: - Haptic Settings
    
    private var isHapticsEnabled: Bool = true
    
    /// Enable or disable haptic feedback
    func setHapticsEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
        // print("🔸 Haptics \(enabled ? "enabled" : "disabled")")
    }
    
    /// Check if haptics are enabled
    func areHapticsEnabled() -> Bool {
        return isHapticsEnabled && UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - Conditional Haptic Execution
    
    private func executeHaptic(_ hapticBlock: @escaping () -> Void) {
        guard areHapticsEnabled() else { return }
        hapticBlock()
    }
    
    // MARK: - Cleanup
    
    deinit {
        // print("🧹 HapticService deallocated")
    }
}

// MARK: - Haptic Patterns

enum HapticPattern {
    case celebration
    case warning
    case heartbeat
    case rising
    case falling
}

// MARK: - Haptic Service Protocol

protocol HapticServiceProtocol: ObservableObject {
    func gameStarted()
    func gamePaused()
    func gameResumed()
    func gameReset()
    func levelCompleted()
    func gameOver()
    func catSpawnWarning()
    func collectiblePickup()
    func keyPickup()
    func powerUpActivated()
    func buttonTapped()
    func mazeGenerated()
    func countdownTick()
    func finalCountdown()
    func customPattern(_ pattern: HapticPattern)
    func setHapticsEnabled(_ enabled: Bool)
    func areHapticsEnabled() -> Bool
}
