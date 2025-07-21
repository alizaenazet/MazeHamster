import Foundation
import UIKit
import RealityKit
import simd

/// Concrete implementation of CameraService for handling camera management
class CameraService: BaseService, CameraServiceProtocol {
    
    // MARK: - Private Properties
    
    private var cameraEntity: Entity?
    private var followTarget: Entity?
    private let gameConfig = GameConfiguration.default
    
    // MARK: - Service Setup
    
    override func setupService() {
        super.setupService()
        print("✅ CameraService configured successfully")
    }
    
    // MARK: - Protocol Methods
    
    func setupCamera(mazeSize: SIMD2<Int>, cellSize: Float, gameConfiguration: GameConfiguration) -> Entity {
        let camera = Entity()
        camera.name = "MainCamera"
        
        // Setup camera component
        var cameraComponent = PerspectiveCameraComponent()
        cameraComponent.near = 1.0
//        cameraComponent.far = 1500.0
        cameraComponent.fieldOfViewInDegrees = 45.0
        camera.components.set(cameraComponent)
        
        // Calculate optimal camera position based on maze size
        let cameraPosition = calculateOptimalCameraPosition(mazeSize: mazeSize, cellSize: cellSize, gameConfiguration: gameConfiguration)
        let lookAtPosition = calculateLookAtPosition(mazeSize: mazeSize, cellSize: cellSize)
        
        // Set camera position and orientation
        camera.position = cameraPosition
        camera.look(at: lookAtPosition, from: cameraPosition, relativeTo: nil)
        
        // Store reference
        cameraEntity = camera
        
        print("📷 Camera setup complete at position: \(cameraPosition)")
        return camera
    }
    
    func updateCameraPosition(following entity: Entity?) {
        // Camera stays fixed in simplified version
        // No camera following needed
    }
    
    // MARK: - Private Methods
    
    private func calculateOptimalCameraPosition(mazeSize: SIMD2<Int>, cellSize: Float, gameConfiguration: GameConfiguration) -> SIMD3<Float> {
        let mazeCenterX = Float(mazeSize.x - 1) * cellSize * 0.5
        let mazeCenterZ = Float(mazeSize.y - 1) * cellSize * 0.5
        
        // Calculate height based on maze size to ensure full view and proper centering
        let maxDimension = max(Float(mazeSize.x), Float(mazeSize.y))
//        let baseCameraHeight = maxDimension * cellSize * 2.0 + (gameConfiguration.cameraHeight)
        let aspectRatio = Float(UIScreen.main.bounds.width / UIScreen.main.bounds.height)
        let baseCameraHeight = maxDimension * cellSize * (aspectRatio > 1.5 ? 1.8 : 2.2) * 1.5

        let finalCameraHeight = baseCameraHeight * gameConfiguration.cameraHeightMultiplier
        print("Camera Height - Base: \(baseCameraHeight), Multiplier: \(gameConfiguration.cameraHeightMultiplier), Final: \(finalCameraHeight)")
        return SIMD3<Float>(mazeCenterX, finalCameraHeight, mazeCenterZ)
    }
    
    private func calculateLookAtPosition(mazeSize: SIMD2<Int>, cellSize: Float) -> SIMD3<Float> {
        let mazeCenterX = Float(mazeSize.x - 1) * cellSize * 0.5
        let mazeCenterZ = Float(mazeSize.y - 1) * cellSize * 0.5
        
        return SIMD3<Float>(mazeCenterX, 0, mazeCenterZ)
    }
    
    // Removed complex follow camera logic - camera stays fixed
    
    // MARK: - Simplified Camera Control (fixed position only)
    
    /// Get current camera position
    func getCameraPosition() -> SIMD3<Float>? {
        return cameraEntity?.position
    }
    
    // MARK: - Update Loop
    
    /// Update camera (simplified - no updates needed)
    func updateCamera() {
        // Camera stays fixed in simplified version
    }
} 
