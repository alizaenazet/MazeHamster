import Foundation
import RealityKit
import Combine

/// Concrete implementation of GameService for handling game state management
class GameService: BaseService, GameServiceProtocol {
    
    // MARK: - Published Properties
    
    @Published var gameState: GameState = .menu
    @Published var score: Int = 0
    
    // MARK: - Private Properties
    
    private var gameStartTime: Date?
    private var gameTimer: Timer?
    private var ballEntity: Entity?
    private var mazeService: MazeService?
    
    // MARK: - Service Setup
    
    override func setupService() {
        super.setupService()
        // print("✅ GameService configured successfully")
    }
    
    // MARK: - Protocol Methods
    
    func startGame() {
        guard gameState == .menu || gameState == .failed else {
            // print("⚠️ Cannot start game: Current state is \(gameState)")
            return
        }
        
        gameState = .playing
        score = 0
        gameStartTime = Date()
        
        // Start game update timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateGameState()
        }
        
        // print("🎮 Game started")
    }
    
    func pauseGame() {
        guard gameState == .playing else {
            // print("⚠️ Cannot pause game: Current state is \(gameState)")
            return
        }
        
        gameState = .paused
        gameTimer?.invalidate()
        gameTimer = nil
        
        // print("⏸️ Game paused")
    }
    
    func resetGame() {
        gameState = .menu
        score = 0
        gameStartTime = nil
        gameTimer?.invalidate()
        gameTimer = nil
        
        // print("🔄 Game reset")
    }
    
    func updateGameState() {
        guard gameState == .playing else { return }
        
        // Check win condition
        if checkWinCondition() {
            completeGame()
            return
        }
        
        // Check fail condition (ball fell off the maze)
        if checkFailCondition() {
            failGame()
            return
        }
        
        // Update score based on time
        updateScore()
    }
    
    // MARK: - Game Logic Methods
    
    private func checkWinCondition() -> Bool {
        guard let ballEntity = ballEntity,
              let mazeService = mazeService else { return false }
        
        return mazeService.isNearExit(ballEntity.position, threshold: 0.5)
    }
    
    private func checkFailCondition() -> Bool {
        guard let ballEntity = ballEntity else { return false }
        
        // Check if ball has fallen below the maze floor
        let floorThreshold: Float = -2.0
        return ballEntity.position.y < floorThreshold
    }
    
    private func updateScore() {
        guard let startTime = gameStartTime else { return }
        
        let currentTime = Date()
        let elapsedTime = currentTime.timeIntervalSince(startTime)
        
        // Score based on time (faster completion = higher score)
        let baseScore = 1000
        let timeBonus = max(0, 600 - Int(elapsedTime)) // Bonus for completing under 10 minutes
        score = baseScore + timeBonus
    }
    
    private func completeGame() {
        gameState = .completed
        gameTimer?.invalidate()
        gameTimer = nil
        
        // Calculate final score
        updateScore()
        
        // print("🎉 Game completed! Final score: \(score)")
    }
    
    private func failGame() {
        gameState = .failed
        gameTimer?.invalidate()
        gameTimer = nil
        
        // print("💥 Game failed!")
    }
    
    // MARK: - Configuration Methods
    
    /// Set the ball entity to track for win/fail conditions
    func setBallEntity(_ entity: Entity) {
        ballEntity = entity
        // print("🎯 Ball entity set for tracking")
    }
    
    /// Set the maze service for win condition checking
    func setMazeService(_ service: MazeService) {
        mazeService = service
        // print("🏗️ Maze service set for game logic")
    }
    
    /// Resume game from paused state
    func resumeGame() {
        guard gameState == .paused else {
            // print("⚠️ Cannot resume game: Current state is \(gameState)")
            return
        }
        
        gameState = .playing
        
        // Restart game timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateGameState()
        }
        
        // print("▶️ Game resumed")
    }
    
    /// Get game statistics
    func getGameStats() -> GameStats {
        let elapsedTime = gameStartTime?.timeIntervalSinceNow ?? 0
        return GameStats(
            score: score,
            elapsedTime: abs(elapsedTime),
            state: gameState
        )
    }
    
    /// Add points to the current score
    func addPoints(_ points: Int) {
        score += points
        // print("🏆 Added \(points) points. Total score: \(score)")
    }
    
    /// Subtract points from the current score
    func subtractPoints(_ points: Int) {
        score = max(0, score - points)
        // print("⚠️ Subtracted \(points) points. Total score: \(score)")
    }
    
    /// Set game state directly
    func setGameState(_ newState: GameState) {
        let previousState = gameState
        gameState = newState
        
        // Handle state transitions
        handleStateTransition(from: previousState, to: newState)
        
        // print("🎮 Game state changed to: \(newState)")
    }
    
    // MARK: - State Transition Handling
    
    private func handleStateTransition(from previousState: GameState, to newState: GameState) {
        // Handle specific state transitions
        switch (previousState, newState) {
        case (_, .completed):
            // Game completed
            completeGame()
            
        case (_, .failed):
            // Game failed
            failGame()
            
        case (.paused, .playing):
            // Resume game
            resumeGame()
            
        case (.playing, .paused):
            // Pause game
            pauseGame()
            
        case (_, .menu):
            // Reset to menu
            resetGame()
            
        default:
            break
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        gameTimer?.invalidate()
    }
}

// MARK: - Game Statistics

/// Structure to hold game statistics
struct GameStats {
    let score: Int
    let elapsedTime: TimeInterval
    let state: GameState
    
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
