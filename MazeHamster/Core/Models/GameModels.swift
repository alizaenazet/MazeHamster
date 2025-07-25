import Foundation
import RealityKit
import simd
import SwiftUI

// MARK: - Game State Models

/// Represents the current state of the game
enum GameState {
    case menu
    case playing
    case paused
    case completed
    case failed
}

/// Represents tilt data from device motion
struct TiltData {
    let roll: Float
    let pitch: Float
    let timestamp: TimeInterval
    
    /// Create tilt data with clamped values to prevent extreme rotations
    init(roll: Float, pitch: Float, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        let maxTilt: Float = .pi / 4  // 45 degrees
        self.roll = max(-maxTilt, min(maxTilt, roll))
        self.pitch = max(-maxTilt, min(maxTilt, pitch))
        self.timestamp = timestamp
    }
    
    /// Convert tilt data to quaternion rotation
    var quaternion: simd_quatf {
        let rotationX = simd_quatf(angle: -pitch, axis: [1, 0, 0])
        let rotationZ = simd_quatf(angle: -roll, axis: [0, 0, 1])
        return rotationZ * rotationX
    }
}

/// Represents the configuration for the maze with adaptive sizing support
struct MazeConfiguration {
    let width: Int
    let height: Int
    let cellSize: Float
    let wallHeight: Float
    let wallThickness: Float
    
    static let `default` = MazeConfiguration(
        width: 6,      // Smaller default for mobile
        height: 8,     // Taller than wide for portrait
        cellSize: 0.8, // Smaller cells for better fit
        wallHeight: 1.0,
        wallThickness: 0.1
    )
    
    /// Create small maze configuration for phones
    static let small = MazeConfiguration(
        width: 5,
        height: 7,
        cellSize: 0.7,
        wallHeight: 1.0,
        wallThickness: 0.1
    )
    
    /// Create medium maze configuration for larger phones
    static let medium = MazeConfiguration(
        width: 7,
        height: 9,
        cellSize: 0.9,
        wallHeight: 1.0,
        wallThickness: 0.1
    )
    
    /// Create large maze configuration for tablets
    static let large = MazeConfiguration(
        width: 10,
        height: 12,
        cellSize: 1.0,
        wallHeight: 1.0,
        wallThickness: 0.1
    )
    
    /// Get the total world size of the maze
    var worldSize: SIMD2<Float> {
        return SIMD2<Float>(
            Float(width) * cellSize,
            Float(height) * cellSize
        )
    }
    
    /// Get the center position of the maze
    var centerPosition: SIMD3<Float> {
        return SIMD3<Float>(
            Float(width - 1) * cellSize * 0.5,
            0,
            Float(height - 1) * cellSize * 0.5
        )
    }
    
    /// Check if this configuration fits within given screen bounds
    func fitsInBounds(_ bounds: SIMD2<Float>) -> Bool {
        let worldSize = self.worldSize
        return worldSize.x <= bounds.x && worldSize.y <= bounds.y
    }
}

/// Enhanced maze data structure that includes generation metadata
struct MazeData {
    let configuration: MazeConfiguration
    let cells: [[MazeCell]]
    let startPosition: SIMD2<Int>
    let exitPosition: SIMD2<Int>
    let generationSeed: UInt32
    
    init(configuration: MazeConfiguration, cells: [[MazeCell]], seed: UInt32 = 0) {
        self.configuration = configuration
        self.cells = cells
        self.startPosition = SIMD2<Int>(0, 0)
        self.exitPosition = SIMD2<Int>(configuration.width - 1, configuration.height - 1)
        self.generationSeed = seed
    }
    
    /// Get world position for a maze cell
    func worldPosition(for cell: SIMD2<Int>) -> SIMD3<Float> {
        return SIMD3<Float>(
            Float(cell.x) * configuration.cellSize,
            0,
            Float(cell.y) * configuration.cellSize
        )
    }
    
    /// Get the center position of the maze
    var centerPosition: SIMD3<Float> {
        return configuration.centerPosition
    }
}

/// Represents physics material configurations
struct PhysicsMaterials {
    let ball: PhysicsMaterialResource
    let wall: PhysicsMaterialResource
    let floor: PhysicsMaterialResource
    
    static let `default` = PhysicsMaterials(
        ball: PhysicsMaterialResource.generate(
            staticFriction: 0.9,
            dynamicFriction: 0.7,
            restitution: 0.1
        ),
        wall: PhysicsMaterialResource.generate(
            staticFriction: 0.8,
            dynamicFriction: 0.6,
            restitution: 0.2
        ),
        floor: PhysicsMaterialResource.generate(
            staticFriction: 0.7,
            dynamicFriction: 0.5,
            restitution: 0.1
        )
    )
}

/// Represents visual material configurations with adaptive colors
struct VisualMaterials {
    let ball: SimpleMaterial
    let wall: SimpleMaterial
    let floor: SimpleMaterial
    let exit: SimpleMaterial
    
    static let `default` = VisualMaterials(
        ball: SimpleMaterial(color: .systemRed, isMetallic: true),
        wall: SimpleMaterial(color: .systemBlue, isMetallic: false),
        floor: SimpleMaterial(color: .systemGray2, isMetallic: false),
        exit: SimpleMaterial(color: .systemGreen, isMetallic: false)
    )
    
    /// Create high contrast materials for better visibility on small screens
    static let highContrast = VisualMaterials(
        ball: SimpleMaterial(color: .red, isMetallic: true),
        wall: SimpleMaterial(color: .blue, isMetallic: false),
        floor: SimpleMaterial(color: .lightGray, isMetallic: false),
        exit: SimpleMaterial(color: .green, isMetallic: false)
    )
    
    /// Create dark theme materials
    static let dark = VisualMaterials(
        ball: SimpleMaterial(color: .systemOrange, isMetallic: true),
        wall: SimpleMaterial(color: .systemIndigo, isMetallic: false),
        floor: SimpleMaterial(color: .systemGray6, isMetallic: false),
        exit: SimpleMaterial(color: .systemMint, isMetallic: false)
    )
}


/// Represents adaptive game configuration that adjusts to screen size
struct GameConfiguration {
    let maze: MazeConfiguration
    let physicsMaterials: PhysicsMaterials
    let visualMaterials: VisualMaterials
    let ballRadius: Float
    let exitRadius: Float
    let cameraHeight: Float
    let cameraHeightMultiplier: Float  // Multiplier to easily adjust zoom level
    let catSleepDuration: TimeInterval
    
    static let `default` = GameConfiguration(
        maze: .default,
        physicsMaterials: .default,
        visualMaterials: .default,
        ballRadius: 0.15,  // Smaller for better proportions
        exitRadius: 0.25,  // Smaller exit
        cameraHeight: 6.0, // Lower camera for smaller mazes
        cameraHeightMultiplier: 1.5, // ADJUST THIS VALUE: 1.0=normal, 2.0=zoom out, 0.5=zoom in
        catSleepDuration: 2.0
    )
    
    /// Create configuration optimized for phones
    static let phone = GameConfiguration(
        maze: .small,
        physicsMaterials: .default,
        visualMaterials: .highContrast,
        ballRadius: 0.12,
        exitRadius: 0.2,
        cameraHeight: 5.0,
        cameraHeightMultiplier: 1.5,
        catSleepDuration: 2.0
    )
    
    /// Create configuration optimized for larger phones
    static let phonePlus = GameConfiguration(
        maze: .medium,
        physicsMaterials: .default,
        visualMaterials: .default,
        ballRadius: 0.15,
        exitRadius: 0.25,
        cameraHeight: 6.5,
        cameraHeightMultiplier: 1.5,
        catSleepDuration: 2.0
    )
    
    /// Create configuration optimized for tablets
    static let tablet = GameConfiguration(
        maze: .large,
        physicsMaterials: .default,
        visualMaterials: .default,
        ballRadius: 0.2,
        exitRadius: 0.3,
        cameraHeight: 10.0,
        cameraHeightMultiplier: 1.0,
        catSleepDuration: 2.0
    )
    
    /// Create adaptive configuration based on screen bounds
    static func adaptive(screenBounds: SIMD2<Float>, isTablet: Bool = false) -> GameConfiguration {
        if isTablet {
            return .tablet
        } else if screenBounds.x > 400 || screenBounds.y > 700 {
            return .phonePlus
        } else {
            return .phone
        }
    }
    
    /// Get optimal field of view for the camera based on maze size
    var optimalFOV: Float {
        let mazeWorldSize = maze.worldSize
        let maxDimension = max(mazeWorldSize.x, mazeWorldSize.y)
        
        // Calculate FOV based on maze size (larger mazes need wider FOV)
        let baseFOV: Float = 45.0
        let scaleFactor = maxDimension / 8.0 // Normalize to 8x8 reference
        return min(baseFOV * scaleFactor, 75.0) // Cap at 75 degrees
    }
    
    /// Get UI scaling factor for this configuration
    var uiScale: Float {
        switch maze.cellSize {
        case ..<0.8:
            return 0.8  // Smaller UI for tiny mazes
        case 0.8..<1.0:
            return 1.0  // Standard UI
        case 1.0...:
            return 1.2  // Larger UI for big mazes
        default:
            return 1.0
        }
    }
}

// MARK: - Adaptive Configuration Factory

/// Factory for creating adaptive configurations based on device capabilities
struct AdaptiveConfigurationFactory {
    
    /// Create optimal game configuration for current device
    static func createOptimalConfiguration() -> GameConfiguration {
        let screenBounds = getCurrentScreenBounds()
        let isTablet = UIDevice.current.userInterfaceIdiom == .pad
        
        return GameConfiguration.adaptive(screenBounds: screenBounds, isTablet: isTablet)
    }
    
    /// Get current screen bounds in world units (approximate)
    private static func getCurrentScreenBounds() -> SIMD2<Float> {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return SIMD2<Float>(6.0, 8.0) // Default bounds
        }
        
        let screen = window.screen
        let size = screen.bounds.size
        
        // Convert screen points to approximate world units
        let worldWidth = Float(size.width) / 100.0  // Rough conversion
        let worldHeight = Float(size.height) / 100.0
        
        return SIMD2<Float>(worldWidth, worldHeight)
    }
    
    /// Test if a maze configuration would fit well on current screen
    static func validateConfiguration(_ config: MazeConfiguration) -> Bool {
        let screenBounds = getCurrentScreenBounds()
        return config.fitsInBounds(screenBounds)
    }
}
