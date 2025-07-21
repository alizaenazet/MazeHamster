import Foundation
import RealityKit
import SwiftUI
import Combine

/// Adaptive ViewModel for the maze game with screen detection and optimal sizing
class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var gameState: GameState = .menu
    @Published var score: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var debugInfo: String = ""
    @Published var catSpawnCountdown: Int = 0
    @Published var currentMazeSize: SIMD2<Int> = SIMD2<Int>(6, 8)
    @Published var adaptiveInfo: String = ""
    @Published var screenInfo: String = ""
    
    // MARK: - Adaptive Coordinator
    
    private let gameCoordinator: GameCoordinator
    
    // MARK: - Game Entities
    
    private var sceneEntity: Entity?
    
    // MARK: - Combine
    
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        // Initialize adaptive game coordinator
        self.gameCoordinator = GameCoordinator()
        
        setupBindings()
        
        print("🎮 Adaptive GameViewModel with screen detection initialized")
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind coordinator state to view model
        gameCoordinator.getGameService().$gameState
            .receive(on: DispatchQueue.main)
            .assign(to: \.gameState, on: self)
            .store(in: &cancellables)
        
        gameCoordinator.getGameService().$score
            .receive(on: DispatchQueue.main)
            .assign(to: \.score, on: self)
            .store(in: &cancellables)
        
        // Bind adaptive properties
        gameCoordinator.$currentMazeSize
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentMazeSize, on: self)
            .store(in: &cancellables)
        
        gameCoordinator.$adaptiveInfo
            .receive(on: DispatchQueue.main)
            .assign(to: \.adaptiveInfo, on: self)
            .store(in: &cancellables)
        
        // Screen info updates
        gameCoordinator.getScreenAdaptiveService().$currentScreenInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] screenInfo in
                self?.updateScreenInfo(screenInfo)
            }
            .store(in: &cancellables)
        
        // Debug info updates on background queue
        Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] _ in
                self?.updateDebugInfo()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Initialize the game scene with adaptive sizing
    func initializeScene() -> Entity {
        isLoading = true
        defer { isLoading = false }
        
        // Create scene through adaptive coordinator
        let scene = gameCoordinator.createGameScene()
        sceneEntity = scene
        
        // Auto-start the game with spawn countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startGameWithCountdown()
        }
        
        print("🏗️ Adaptive scene initialized")
        print("   Maze Size: \(currentMazeSize.x)x\(currentMazeSize.y)")
        
        return scene
    }
    
    /// Start the game with cat spawn countdown
    func startGame() {
        startGameWithCountdown()
    }
    
    private func startGameWithCountdown() {
        gameCoordinator.startCoordinator()
        gameCoordinator.getGameService().startGame()
        
        // Start countdown for cat spawn
        startCatSpawnCountdown()
        
        print("🎮 Adaptive game started")
        print("   Screen-optimized maze: \(currentMazeSize.x)x\(currentMazeSize.y)")
    }
    
    /// Pause the game
    func pauseGame() {
        gameCoordinator.getGameService().pauseGame()
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        print("⏸️ Adaptive game paused")
    }
    
    /// Resume the game
    func resumeGame() {
        gameCoordinator.getGameService().resumeGame()
        
        // Restart countdown if needed
        if catSpawnCountdown > 0 {
            startCatSpawnCountdown()
        }
        
        print("▶️ Adaptive game resumed")
    }
    
    /// Reset the game with adaptive sizing
    func resetGame() {
        gameCoordinator.resetGame()
        
        // Reset countdown
        countdownTimer?.invalidate()
        countdownTimer = nil
        catSpawnCountdown = 0
        
        print("🔄 Adaptive game reset")
    }
    
    /// Clear all audio in Mazeworld
    func clearAudio() {
        gameCoordinator.clearMazeWorldGameAudio()
        print("🔇 Audio clearing requested from GameViewModel")
    }
    
    /// Generate a new maze with current screen-optimal size
    func generateNewMaze() {
        isLoading = true
        defer { isLoading = false }
        
        // Stop countdown during maze generation
        countdownTimer?.invalidate()
        countdownTimer = nil
        catSpawnCountdown = 0
        
        // Generate new adaptive maze
        gameCoordinator.generateNewMaze()
        
        print("🌀 New adaptive maze generated: \(currentMazeSize.x)x\(currentMazeSize.y)")
    }
    
    /// Force refresh adaptive configuration (useful on orientation change)
    func refreshAdaptiveConfiguration() {
        gameCoordinator.refreshAdaptiveConfiguration()
        print("🔄 Adaptive configuration refreshed for current screen")
    }
    
    /// Update game (called from view's update loop)
    func updateGame(deltaTime: TimeInterval) {
        // Update through adaptive coordinator
        gameCoordinator.updateCoordinator(deltaTime: deltaTime)
    }
    
    /// Handle view appearing
    func viewDidAppear() {
        // Refresh adaptive configuration when view appears
        refreshAdaptiveConfiguration()
        print("📱 Adaptive view appeared")
    }
    
    /// Handle view disappearing
    func viewWillDisappear() {
        // Clear audio first before stopping coordinator
        clearAudio()
        
        gameCoordinator.stopCoordinator()
        countdownTimer?.invalidate()
        countdownTimer = nil
        print("📱 Adaptive view disappeared - audio cleared")
    }
    
    // MARK: - Cat Spawn Countdown
    
    private func startCatSpawnCountdown() {
        catSpawnCountdown = 2 // 2 seconds countdown
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                if self.catSpawnCountdown > 0 {
                    self.catSpawnCountdown -= 1
                    print("🐱 Cat spawning in: \(self.catSpawnCountdown)")
                } else {
                    self.catSpawnCountdown = 0
                    timer.invalidate()
                    self.countdownTimer = nil
                    print("🐱 Cat is now active!")
                }
            }
        }
    }
    
    // MARK: - Screen and Debug Info Updates
    
    private func updateScreenInfo(_ screenInfo: ScreenAdaptiveService.ScreenInfo?) {
        guard let info = screenInfo else {
            self.screenInfo = "No screen info available" // ✅ FIXED
            return
        }

        var infoText = "📱 Screen Info:\n"
        infoText += "Device: \(info.deviceType)\n"
        infoText += "Size: \(Int(info.size.width))x\(Int(info.size.height))\n"
        infoText += "Orientation: \(info.orientation)\n"
        infoText += "Optimal Maze: \(info.deviceType.defaultMazeSize.x)x\(info.deviceType.defaultMazeSize.y)\n"
        
        self.screenInfo = infoText
    }

    
    private func updateDebugInfo() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var info = "=== Adaptive Debug Info ===\n"
            info += "Game State: \(self.gameState)\n"
            info += "Score: \(self.score)\n"
            info += "Maze Size: \(self.currentMazeSize.x)x\(self.currentMazeSize.y)\n"
            info += "Cat Spawn Countdown: \(self.catSpawnCountdown)s\n"
            
            // Add adaptive coordinator debug info
            info += "\n" + self.gameCoordinator.getAdaptiveDebugInfo()
            
            self.debugInfo = info
        }
    }
    
    // MARK: - Adaptive Controls
    
    /// Test different maze sizes (for debugging)
    func testMazeSize(_ size: MazeSizePreset) {
        let config: GameConfiguration
        
        switch size {
        case .small:
            config = .phone
        case .medium:
            config = .phonePlus
        case .large:
            config = .tablet
        }
        
        gameCoordinator.updateConfiguration(config)
        generateNewMaze()
        
        print("🧪 Testing maze size: \(size)")
    }
    
    /// Get available maze size options based on current screen
    func getAvailableMazeSizes() -> [MazeSizeOption] {
        guard let screenInfo = gameCoordinator.getScreenAdaptiveService().getScreenInfo() else {
            return [MazeSizeOption(name: "Default", size: SIMD2<Int>(6, 8))]
        }
        
        switch screenInfo.deviceType {
        case .phone:
            return [
                MazeSizeOption(name: "Tiny", size: SIMD2<Int>(4, 6)),
                MazeSizeOption(name: "Small", size: SIMD2<Int>(5, 7)),
                MazeSizeOption(name: "Optimal", size: SIMD2<Int>(6, 8))
            ]
        case .phonePlus:
            return [
                MazeSizeOption(name: "Small", size: SIMD2<Int>(5, 7)),
                MazeSizeOption(name: "Optimal", size: SIMD2<Int>(7, 9)),
                MazeSizeOption(name: "Large", size: SIMD2<Int>(8, 10))
            ]
        case .pad, .padPro:
            return [
                MazeSizeOption(name: "Medium", size: SIMD2<Int>(7, 9)),
                MazeSizeOption(name: "Large", size: SIMD2<Int>(10, 12)),
                MazeSizeOption(name: "Huge", size: SIMD2<Int>(12, 15))
            ]
        case .unknown:
            return [MazeSizeOption(name: "Default", size: SIMD2<Int>(6, 8))]
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
            print("❌ Adaptive Error: \(error)")
        }
    }
    
    private func clearError() {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = nil
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Ensure audio is cleared on deallocation
        clearAudio()
        gameCoordinator.stopCoordinator()
        countdownTimer?.invalidate()
        cancellables.removeAll()
        print("🧹 Adaptive GameViewModel deallocated with audio cleanup")
    }
}

// MARK: - Game State Helpers

extension GameViewModel {
    
    var isGameActive: Bool {
        return gameState == .playing
    }
    
    var isGamePaused: Bool {
        return gameState == .paused
    }
    
    var isGameCompleted: Bool {
        return gameState == .completed
    }
    
    var isGameFailed: Bool {
        return gameState == .failed
    }
    
    var canStartGame: Bool {
        return gameState == .menu || gameState == .failed
    }
    
    var canPauseGame: Bool {
        return gameState == .playing
    }
    
    var canResumeGame: Bool {
        return gameState == .paused
    }
    
    var gameStateDescription: String {
        switch gameState {
        case .menu: return "Ready to Start"
        case .playing:
            if catSpawnCountdown > 0 {
                return "Playing - Cat spawning in \(catSpawnCountdown)s"
            } else {
                return "Playing - Cat Active!"
            }
        case .paused: return "Paused"
        case .completed: return "Completed!"
        case .failed: return "Game Over"
        }
    }
    
    var adaptiveStatusDescription: String {
        return "Maze: \(currentMazeSize.x)×\(currentMazeSize.y) (Screen Optimized)"
    }
    
    var catStatusDescription: String {
        switch gameState {
        case .menu, .paused, .completed, .failed:
            return "Cat Inactive"
        case .playing:
            if catSpawnCountdown > 0 {
                return "Cat spawning in \(catSpawnCountdown)s"
            } else {
                return "Cat is hunting!"
            }
        }
    }
    
    var gameInstructions: String {
        switch gameState {
        case .menu:
            return "Tilt your device to move the ball through the \(currentMazeSize.x)×\(currentMazeSize.y) maze"
        case .playing:
            if catSpawnCountdown > 0 {
                return "Get ready! Cat will start chasing you in \(catSpawnCountdown) seconds"
            } else {
                return "Avoid the cat and reach the exit!"
            }
        case .paused:
            return "Game paused"
        case .completed:
            return "Congratulations! You escaped the \(currentMazeSize.x)×\(currentMazeSize.y) maze!"
        case .failed:
            return "Game Over! The cat caught you in the \(currentMazeSize.x)×\(currentMazeSize.y) maze"
        }
    }
    
    var showCatCountdown: Bool {
        return gameState == .playing && catSpawnCountdown > 0
    }
    
    var catCountdownText: String {
        return "Cat spawning in \(catSpawnCountdown)s"
    }
    
    var shouldShowPathVisualization: Bool {
        return gameState == .playing && catSpawnCountdown == 0
    }
}

// MARK: - Adaptive UI Properties

extension GameViewModel {
    
    /// Get UI scaling factor for current screen
    var uiScalingFactor: Float {
        return gameCoordinator.getScreenAdaptiveService().getUIScalingFactor()
    }
    
    /// Get optimal button size for current screen
    var buttonSize: CGSize {
        let baseSizes = CGSize(width: 80, height: 44)
        let scale = CGFloat(uiScalingFactor)
        return CGSize(width: baseSizes.width * scale, height: baseSizes.height * scale)
    }
    
    /// Get optimal font size for current screen
    var fontSize: CGFloat {
        let baseSize: CGFloat = 16
        return baseSize * CGFloat(uiScalingFactor)
    }
    
    /// Get adaptive colors based on screen size
    var adaptiveColors: AdaptiveColors {
        guard let screenInfo = gameCoordinator.getScreenAdaptiveService().getScreenInfo() else {
            return AdaptiveColors.default
        }
        
        switch screenInfo.deviceType {
        case .phone:
            return AdaptiveColors.highContrast
        case .phonePlus:
            return AdaptiveColors.default
        case .pad, .padPro:
            return AdaptiveColors.vibrant
        case .unknown:
            return AdaptiveColors.default
        }
    }
}

// MARK: - Performance and Analytics

extension GameViewModel {
    
    func getAdaptivePerformanceMetrics() -> AdaptiveGameMetrics {
        return AdaptiveGameMetrics(
            gameState: gameState,
            score: score,
            mazeSize: currentMazeSize,
            catSpawnCountdown: catSpawnCountdown,
            pathfindingActive: shouldShowPathVisualization,
            screenOptimized: true,
            deviceType: gameCoordinator.getScreenAdaptiveService().getScreenInfo()?.deviceType.description ?? "Unknown"
        )
    }
    
    func logAdaptiveGameEvent(_ event: AdaptiveGameEvent) {
        let timestamp = Date()
        let metrics = getAdaptivePerformanceMetrics()
        print("📊 Adaptive Game Event [\(timestamp)]: \(event)")
        print("   Metrics: \(metrics)")
        
        // Here you could send to analytics service
        // Analytics.track(event: event, properties: metrics)
    }
}

// MARK: - Debug and Testing Methods

extension GameViewModel {
    
    func getDetailedAdaptiveDebugInfo() -> String {
        var info = "=== Detailed Adaptive Debug ===\n"
        info += "Game State: \(gameState) (\(gameStateDescription))\n"
        info += "Score: \(score)\n"
        info += "Maze Size: \(currentMazeSize.x)×\(currentMazeSize.y)\n"
        info += "Loading: \(isLoading)\n"
        info += "Cat Spawn Countdown: \(catSpawnCountdown)s\n"
        
        if let error = errorMessage {
            info += "Error: \(error)\n"
        }
        
        // Screen information
        info += "\n--- Screen Info ---\n"
        info += screenInfo
        
        // Adaptive coordinator debug info
        info += "\n" + gameCoordinator.getAdaptiveDebugInfo()
        
        return info
    }
    
    /// Test different screen configurations (for debugging)
    func simulateDeviceType(_ deviceType: ScreenAdaptiveService.DeviceType) {
        // This would be used for testing different configurations
        print("🧪 Simulating device type: \(deviceType)")
        
        let testConfig: GameConfiguration
        switch deviceType {
        case .phone:
            testConfig = .phone
        case .phonePlus:
            testConfig = .phonePlus
        case .pad, .padPro:
            testConfig = .tablet
        case .unknown:
            testConfig = .default
        }
        
        gameCoordinator.updateConfiguration(testConfig)
        generateNewMaze()
    }
}

// MARK: - Supporting Types

struct AdaptiveGameMetrics {
    let gameState: GameState
    let score: Int
    let mazeSize: SIMD2<Int>
    let catSpawnCountdown: Int
    let pathfindingActive: Bool
    let screenOptimized: Bool
    let deviceType: String
}

enum AdaptiveGameEvent {
    case adaptiveGameStarted(mazeSize: SIMD2<Int>)
    case screenConfigurationChanged
    case adaptiveMazeGenerated(size: SIMD2<Int>)
    case catSpawned
    case catPathCalculated
    case playerCaught
    case levelCompleted(mazeSize: SIMD2<Int>)
    case gameReset
}

enum MazeSizePreset {
    case small, medium, large
}

struct MazeSizeOption {
    let name: String
    let size: SIMD2<Int>
}

struct AdaptiveColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    
    static let `default` = AdaptiveColors(
        primary: .primary,
        secondary: .secondary,
        accent: .accentColor,
        background: .clear
    )
    
    static let highContrast = AdaptiveColors(
        primary: .black,
        secondary: .gray,
        accent: .blue,
        background: .white
    )
    
    static let vibrant = AdaptiveColors(
        primary: .primary,
        secondary: .secondary,
        accent: .purple,
        background: .clear
    )
}

// MARK: - Extensions for Device Type

extension ScreenAdaptiveService.DeviceType {
    var description: String {
        switch self {
        case .phone: return "iPhone"
        case .phonePlus: return "iPhone Plus"
        case .pad: return "iPad"
        case .padPro: return "iPad Pro"
        case .unknown: return "Unknown"
        }
    }
}
