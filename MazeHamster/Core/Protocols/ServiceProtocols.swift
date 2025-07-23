import Foundation
import GameplayKit
import RealityKit
import CoreMotion
import Combine

// MARK: - Core Service Protocols

/// Protocol defining the interface for input handling services
protocol InputServiceProtocol: ObservableObject {
    var tiltData: AnyPublisher<TiltData, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

/// Protocol defining the interface for physics management
protocol PhysicsServiceProtocol: ObservableObject {
    func setupBallPhysics(for entity: Entity, withMaterial material: PhysicsMaterialResource)
    func setupWallPhysics(for entity: Entity, size: SIMD3<Float>)
    func setupFloorPhysics(for entity: Entity, size: SIMD3<Float>)
    func applyTiltToBall(_ ball: Entity, tiltData: TiltData)
}

/// Protocol defining the interface for maze generation and management
protocol MazeServiceProtocol: ObservableObject {
    var maze: MazeData { get }
    var _gridGraph: GKGridGraph<GKGridGraphNode>? { get set }
    var gridGraph: GKGridGraph<GKGridGraphNode> { get }
    func generateMaze(width: Int, height: Int) -> MazeData
    func createMazeEntities() -> [Entity]
}

/// Protocol defining the interface for game state management
protocol GameServiceProtocol: ObservableObject {
    var gameState: GameState { get }
    var score: Int { get }
    func startGame()
    func pauseGame()
    func resetGame()
    func updateGameState()
}

/// Protocol defining the interface for entity creation
protocol EntityFactoryProtocol {
    func createBall(radius: Float, material: SimpleMaterial) -> Entity
    func createWall(size: SIMD3<Float>, material: SimpleMaterial) -> Entity
    func createFloor(size: SIMD3<Float>, material: SimpleMaterial) -> Entity
    func createExit(radius: Float, material: SimpleMaterial) -> Entity
}

/// Protocol defining the interface for camera management
protocol CameraServiceProtocol: ObservableObject {
    func setupCamera(mazeSize: SIMD2<Int>, cellSize: Float, gameConfiguration: GameConfiguration) -> Entity
    func updateCameraPosition(following entity: Entity?)
} 
