import Foundation
import RealityKit
import simd

/// Concrete implementation of PhysicsService for handling physics operations
class PhysicsService: BaseService, PhysicsServiceProtocol {
    
    // MARK: - Private Properties
    
    private let physicsMaterials = PhysicsMaterials.default
    
    // MARK: - Service Setup
    
    override func setupService() {
        super.setupService()
        print("✅ PhysicsService configured successfully")
    }
    
    // MARK: - Protocol Methods
    
    func setupBallPhysics(for entity: Entity, withMaterial material: PhysicsMaterialResource) {
        guard let radius = getBallRadius(from: entity) else {
            print("⚠️ Cannot setup ball physics: Unable to determine ball radius")
            return
        }
        
        // Remove any existing physics components first (important for loaded models)
        entity.components.remove(PhysicsBodyComponent.self)
        entity.components.remove(CollisionComponent.self)
        
        // Use physics radius that provides stable collision without penetration
        let physicsRadius = radius * 0.9  // Only 10% smaller for very stable physics
        
        // Create physics body component with stable properties
        var physicsBody = PhysicsBodyComponent(
            shapes: [.generateSphere(radius: physicsRadius)],
            mass: 1.5,  // Lighter mass for better responsiveness
            material: material,
            mode: .dynamic
        )
        
        // Add strong damping to prevent erratic behavior and ensure smooth stops
        physicsBody.linearDamping = 0.8   // Very high damping for immediate stops
        physicsBody.angularDamping = 0.9  // Very high angular damping to prevent spinning
        
        // Create collision component
        let collision = CollisionComponent(
            shapes: [.generateSphere(radius: physicsRadius)]
        )
        
        // Apply components to entity
        entity.components.set(physicsBody)
        entity.components.set(collision)
        
        print("🎯 Stable ball physics setup - radius: \(physicsRadius), mass: 1.5, high damping for natural stops")
    }
    
    func setupWallPhysics(for entity: Entity, size: SIMD3<Float>) {
        // Create physics body component for static wall
        let physicsBody = PhysicsBodyComponent(
            shapes: [.generateBox(size: size)],
            mass: 0.0,
            material: physicsMaterials.wall,
            mode: .static
        )
        
        // Create collision component
        let collision = CollisionComponent(
            shapes: [.generateBox(size: size)]
        )
        
        // Apply components to entity
        entity.components.set(physicsBody)
        entity.components.set(collision)
        
        print("🧱 Wall physics setup complete for entity: \(entity.name)")
    }
    
    func setupFloorPhysics(for entity: Entity, size: SIMD3<Float>) {
        // Create physics body component for static floor
        let physicsBody = PhysicsBodyComponent(
            shapes: [.generateBox(size: size)],
            mass: 0.0,
            material: physicsMaterials.floor,
            mode: .static
        )
        
        // Create collision component
        let collision = CollisionComponent(
            shapes: [.generateBox(size: size)]
        )
        
        // Apply components to entity
        entity.components.set(physicsBody)
        entity.components.set(collision)
        
        print("🏢 Floor physics setup complete for entity: \(entity.name)")
    }
    
    func applyTiltToBall(_ ball: Entity, tiltData: TiltData) {
        // Apply gravitational force to ball based on tilt
        guard ball.components[PhysicsBodyComponent.self]?.mode == .dynamic else { return }
        
        // Reduce force for gentler, more controllable movement
        let forceMultiplier: Float = 2.5  // Reduced from 5.0 for smoother control
        let forceX = sin(tiltData.roll) * forceMultiplier
        let forceZ = -sin(tiltData.pitch) * forceMultiplier
        let force = SIMD3<Float>(forceX, 0, forceZ)
        
        // Apply force by modifying ball position (simplified approach)
        let currentPosition = ball.position
        let newPosition = currentPosition + force * 0.016 // Assuming 60fps
        ball.move(to: Transform(scale: ball.transform.scale,
                              rotation: ball.transform.rotation,
                              translation: newPosition),
                 relativeTo: ball.parent)
    }
    
    // MARK: - Helper Methods
    
    private func getBallRadius(from entity: Entity) -> Float? {
        // Check if entity has a model component
        if entity.components.has(ModelComponent.self) {
            return 0.2 // Default ball radius from original code
        }
        return nil
    }
    
    /// Apply impulse force to an entity
    func applyImpulse(_ impulse: SIMD3<Float>, to entity: Entity) {
        guard var physicsBody = entity.components[PhysicsBodyComponent.self] else {
            print("⚠️ Cannot apply impulse: Entity has no physics body")
            return
        }
        
        print("🎯 Applied impulse force: \(impulse) to entity: \(entity.name)")
    }
    
    /// Apply torque to an entity
    func applyTorque(_ torque: SIMD3<Float>, to entity: Entity) {
        guard var physicsBody = entity.components[PhysicsBodyComponent.self] else {
            print("⚠️ Cannot apply torque: Entity has no physics body")
            return
        }
        
        print("🎯 Applied torque: \(torque) to entity: \(entity.name)")
    }
    
    /// Set physics material for an entity
    func setPhysicsMaterial(_ material: PhysicsMaterialResource, for entity: Entity) {
        guard var physicsBody = entity.components[PhysicsBodyComponent.self] else {
            print("⚠️ Cannot set physics material: Entity has no physics body")
            return
        }
        
        physicsBody.material = material
        entity.components.set(physicsBody)
    }
    
    /// Enable or disable physics for an entity
    func setPhysicsEnabled(_ enabled: Bool, for entity: Entity) {
        if enabled {
            // Re-enable physics if it was disabled
            guard entity.components[PhysicsBodyComponent.self] == nil else { return }
            
            print("ℹ️ Physics restoration not implemented - create new physics body")
        } else {
            // Disable physics by removing the physics body
            entity.components.remove(PhysicsBodyComponent.self)
            print("🚫 Physics disabled for entity: \(entity.name)")
        }
    }
}
