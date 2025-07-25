import Foundation
import RealityKit
import Combine

// MARK: - Base Service Class

/// Base class for all game services providing common functionality
class BaseService: ObservableObject {
    internal var cancellables = Set<AnyCancellable>()
    
    init() {
        setupService()
    }
    
    /// Override this method in subclasses to setup service-specific initialization
    func setupService() {
        // Default implementation - override in subclasses
    }
    
    /// Clean up resources when service is deallocated
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Entity Extensions

extension Entity {
    /// Add a name tag to the entity for easier identification
    func named(_ name: String) -> Entity {
        self.name = name
        return self
    }
    
    /// Add physics body component with simplified parameters
    func withPhysics(shapes: [ShapeResource], mass: Float, mode: PhysicsBodyMode, material: PhysicsMaterialResource? = nil) -> Entity {
        let physicsBody = PhysicsBodyComponent(
            shapes: shapes,
            mass: mass,
            material: material,
            mode: mode
        )
        self.components.set(physicsBody)
        return self
    }
    
    /// Add collision component with simplified parameters
    func withCollision(shapes: [ShapeResource]) -> Entity {
        let collision = CollisionComponent(shapes: shapes)
        self.components.set(collision)
        return self
    }
    
    /// Add both physics and collision components
    func withPhysicsAndCollision(shapes: [ShapeResource], mass: Float, mode: PhysicsBodyMode, material: PhysicsMaterialResource? = nil) -> Entity {
        return self
            .withPhysics(shapes: shapes, mass: mass, mode: mode, material: material)
            .withCollision(shapes: shapes)
    }
    
    /// Set position with fluent interface
    func at(position: SIMD3<Float>) -> Entity {
        self.position = position
        return self
    }
    
    /// Set rotation with fluent interface
    func rotated(by rotation: simd_quatf) -> Entity {
        self.transform.rotation = rotation
        return self
    }
    
    /// Set scale with fluent interface
    func scaled(by scale: SIMD3<Float>) -> Entity {
        self.transform.scale = scale
        return self
    }
    
    /// Add child entity with fluent interface
    func with(child: Entity) -> Entity {
        self.addChild(child)
        return self
    }
}

// MARK: - SIMD Extensions

extension SIMD3<Float> {
    /// Create a position with Y offset
    func withY(_ y: Float) -> SIMD3<Float> {
        return SIMD3<Float>(self.x, y, self.z)
    }
    
    /// Add Y offset to existing position
    func offsetY(_ offset: Float) -> SIMD3<Float> {
        return SIMD3<Float>(self.x, self.y + offset, self.z)
    }
}

extension SIMD2<Int> {
    /// Convert to SIMD3<Float> with Y=0
    func to3D(y: Float = 0) -> SIMD3<Float> {
        return SIMD3<Float>(Float(self.x), y, Float(self.y))
    }
}

// MARK: - Combine Extensions

extension Publisher {
    /// Throttle publisher to specific frame rate
    func throttle(fps: Double) -> Publishers.Throttle<Self, RunLoop> {
        return self.throttle(for: .seconds(1.0 / fps), scheduler: RunLoop.main, latest: true)
    }
} 
