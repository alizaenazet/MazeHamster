import Foundation
import RealityKit
import simd
import MazeHamsterAssets

/// Concrete implementation of EntityFactory for centralized entity creation
class EntityFactory: EntityFactoryProtocol {
    
    // MARK: - Private Properties
    
    private let gameConfig = GameConfiguration.default
    private let visualMaterials = VisualMaterials.default
    private let physicsMaterials = PhysicsMaterials.default
    
    // MARK: - Protocol Methods
    
    func createBall(radius: Float, material: SimpleMaterial) -> Entity {
        var ball = Entity()
        ball.name = "MazeBall"
        
        if let ballEntity = try? Entity.load(named: "Hamster", in: mazeHamsterAssetsBundle) {
            ball = ballEntity
            ball.name = "MazeBall" // Ensure name is set
            
            // Remove any existing physics components from the loaded model
            ball.components.remove(PhysicsBodyComponent.self)
            ball.components.remove(CollisionComponent.self)
//            
            print("🐹 Hamster model loaded and existing physics cleared")
            
//
//            
        } else {
            // Create ball mesh with sphere collision (fallback)
            let ballMesh = MeshResource.generateSphere(radius: radius)
            ball.components.set(ModelComponent(mesh: ballMesh, materials: [material]))
        }
        
        let physicsRadius = radius /** 0.9*/  // Consistent with Hamster model
        
        print("Radius: \(physicsRadius) for fallback sphere")
        print("Radius: \(radius) for fallback sphere")
        var physicsBody = PhysicsBodyComponent(
            shapes: [.generateSphere(radius: physicsRadius)],
            mass: 1.5,
            material: physicsMaterials.ball,
            mode: .dynamic
        )
        
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.9
        
        let collision = CollisionComponent(
            shapes: [.generateSphere(radius: physicsRadius)]
        )
        
        ball.components.set(physicsBody)
        ball.components.set(collision)
        
        print("🎯 Fallback sphere with natural physics: radius \(physicsRadius), mass: 1.5")
        
        return ball
    }
    
    func createWall(size: SIMD3<Float>, material: SimpleMaterial) -> Entity {
        let wall = Entity()
        wall.name = "MazeWall"
        
        // Create wall mesh
        let wallMesh = MeshResource.generateBox(size: size)
        wall.components.set(ModelComponent(mesh: wallMesh, materials: [material]))
        
        // Add physics components for static wall
        let physicsBody = PhysicsBodyComponent(
            shapes: [.generateBox(size: size)],
            mass: 0.0,
            material: physicsMaterials.wall,
            mode: .static
        )
        
        let collision = CollisionComponent(
            shapes: [.generateBox(size: size)]
        )
        
        wall.components.set(physicsBody)
        wall.components.set(collision)
        
        print("🧱 Wall entity created with size: \(size)")
        return wall
    }
    
    func createFloor(size: SIMD3<Float>, material: SimpleMaterial) -> Entity {
        let floor = Entity()
        floor.name = "MazeFloor"
        
        // Create floor mesh
        let floorMesh = MeshResource.generateBox(size: size)
        floor.components.set(ModelComponent(mesh: floorMesh, materials: [material]))
        
        // Add physics components for static floor
        let physicsBody = PhysicsBodyComponent(
            shapes: [.generateBox(size: size)],
            mass: 0.0,
            material: physicsMaterials.floor,
            mode: .static
        )
        
        let collision = CollisionComponent(
            shapes: [.generateBox(size: size)]
        )
        
        floor.components.set(physicsBody)
        floor.components.set(collision)
        
        print("🏢 Floor entity created with size: \(size)")
        return floor
    }
    
    func createExit(radius: Float, material: SimpleMaterial) -> Entity {
        let exit = Entity()
        exit.name = "MazeExit"
        
        // Create exit mesh
        let exitMesh = MeshResource.generateSphere(radius: radius)
        exit.components.set(ModelComponent(mesh: exitMesh, materials: [material]))
        
        // Add trigger collision for exit detection
        let collision = CollisionComponent(
            shapes: [.generateSphere(radius: radius)]
        )
        
        exit.components.set(collision)
        
        print("🚪 Exit entity created with radius: \(radius)")
        return exit
    }
    
    // MARK: - Extended Factory Methods
    
    /// Create a complete maze ball with default settings
    func createMazeBall() -> Entity {
        return createBall(
            radius: gameConfig.ballRadius,
            material: visualMaterials.ball
        )
    }
    
    /// Create a wall at specific position with automatic positioning
    func createWallAt(position: SIMD3<Float>, size: SIMD3<Float>) -> Entity {
        let wall = createWall(size: size, material: visualMaterials.wall)
        wall.position = position + SIMD3<Float>(0, size.y * 0.5, 0) // Raise wall to sit on floor
        return wall
    }
    
    /// Create a floor with automatic centering
    func createFloorAt(center: SIMD3<Float>, size: SIMD3<Float>) -> Entity {
        let floor = createFloor(size: size, material: visualMaterials.floor)
        floor.position = center.offsetY(-0.05) // Slightly below ground level
        return floor
    }
    
    /// Create an exit with default settings
    func createMazeExit() -> Entity {
        return createExit(
            radius: gameConfig.exitRadius,
            material: visualMaterials.exit
        )
    }
    
    /// Create a cat agent with green box appearance
    func createCatAgent() -> Entity {
        var cat = Entity()
        cat.name = "CatAgent"
        let catSize = SIMD3<Float>(0.4, 0.4, 0.4)
        
        if let catEntity = try? Entity.load(named: "Cat", in: mazeHamsterAssetsBundle) {
            print("🐱 Cat agent loaded from model")
            cat = catEntity
        }else {
            // Create box shape with green color
            
            let catMesh = MeshResource.generateBox(size: catSize)
            let catMaterial = SimpleMaterial(color: .green, isMetallic: false)
            cat.components.set(ModelComponent(mesh: catMesh, materials: [catMaterial]))
        }
        
        
        // Add physics components with proper collision setup
        var physicsBody = PhysicsBodyComponent(
            shapes: [.generateBox(size: catSize)],
            mass: 1.0,
            material: physicsMaterials.ball, // Using ball material for similar behavior
            mode: .dynamic
        )
        
        // Add velocity damping to prevent excessive speed
        physicsBody.linearDamping = 0.8  // Higher damping for more controlled movement
        physicsBody.angularDamping = 0.9  // Prevent excessive rotation
        
        let collision = CollisionComponent(
            shapes: [.generateBox(size: catSize)]
        )
        
        cat.components.set(physicsBody)
        cat.components.set(collision)
        
        print("🐱 Cat agent entity created with green box appearance")
        return cat
    }
    
    /// Create a cat entity with all ECS components for AI behavior
    func createCatWithECS(componentManager: ComponentManager, startPosition: SIMD3<Float>, sleepDuration: TimeInterval = 3.0) -> (Entity, UUID) {
        let cat = createCatAgent()
        let entityId = UUID()
        
        // Set initial position
        cat.position = startPosition
        
        // Create and add transform component
        let transformComponent = TransformComponent(
            entityId: entityId,
            position: startPosition,
            rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
            scale: SIMD3<Float>(1, 1, 1)
        )
        componentManager.addComponent(transformComponent, to: entityId)
        
        // Create and add game entity component
        let gameEntityComponent = GameEntityComponent(
            entityId: entityId,
            entityType: .cat,
            isActive: true,
            isCollectable: false
        )
        componentManager.addComponent(gameEntityComponent, to: entityId)
        
        // Create and add AI agent component
        let aiAgentComponent = AIAgentComponent(
            entityId: entityId,
            maxSpeed: 0.3,  // Much slower - was 0.8, now 0.3
            maxAcceleration: 0.8,  // Much gentler acceleration
            sleepDuration: sleepDuration
        )
        componentManager.addComponent(aiAgentComponent, to: entityId)
        
        // Create and add pathfinding component
        let pathfindingComponent = PathfindingComponent(
            entityId: entityId,
            pathfindingRadius: 0.5
        )
        componentManager.addComponent(pathfindingComponent, to: entityId)
        
        // Create and add physics component
        let catSize = SIMD3<Float>(0.4, 0.4, 0.4)
        let physicsComponent = PhysicsComponent(
            entityId: entityId,
            mass: 1.0,
            physicsMaterial: physicsMaterials.ball,
            bodyMode: .dynamic,
            shapes: [.generateBox(size: catSize)]
        )
        componentManager.addComponent(physicsComponent, to: entityId)
        
        // Create and add render component
        let renderComponent = RenderComponent(
            entityId: entityId,
            mesh: MeshResource.generateBox(size: catSize),
            materials: [SimpleMaterial(color: .green, isMetallic: false)],
            isVisible: true
        )
        componentManager.addComponent(renderComponent, to: entityId)
        
        // NEW: Tambahkan CatStatusComponent ke entitas kucing di sini
        let catStatusComponent = CatStatusComponent(entityId: entityId)
        componentManager.addComponent(catStatusComponent, to: entityId)
        
        print("🐱 Cat entity with ECS components created at position: \(startPosition)")
        return (cat, entityId)
    }
    
    /// Create a light entity for scene illumination
    func createLight(type: LightType = .directional, intensity: Float = 1000) -> Entity {
        let light = Entity()
        light.name = "SceneLight"
        
        switch type {
        case .directional:
            var directionalLight = DirectionalLightComponent()
            directionalLight.color = .white
            directionalLight.intensity = intensity
            directionalLight.isRealWorldProxy = false
            light.components.set(directionalLight)
            
        case .point:
            var pointLight = PointLightComponent()
            pointLight.color = .white
            pointLight.intensity = intensity
            pointLight.attenuationRadius = 10.0
            light.components.set(pointLight)
            
        case .spot:
            var spotLight = SpotLightComponent()
            spotLight.color = .white
            spotLight.intensity = intensity
            spotLight.attenuationRadius = 10.0
            spotLight.innerAngleInDegrees = 30
            spotLight.outerAngleInDegrees = 45
            light.components.set(spotLight)
        }
        
        print("💡 Light entity created with type: \(type)")
        return light
    }
    
    /// Create a camera entity
    func createCamera(fov: Float = 45.0) -> Entity {
        let camera = Entity()
        camera.name = "GameCamera"
        
        var cameraComponent = PerspectiveCameraComponent()
        cameraComponent.near = 1.0
        cameraComponent.far = 1000.0
        cameraComponent.fieldOfViewInDegrees = fov
        camera.components.set(cameraComponent)
        
        print("📷 Camera entity created with FOV: \(fov)°")
        return camera
    }
    
    /// Create a container entity for grouping related entities
    func createContainer(name: String) -> Entity {
        let container = Entity()
        container.name = name
        
        print("📦 Container entity created: \(name)")
        return container
    }
    
    /// Create a particle system entity (for effects)
    func createParticleSystem(name: String) -> Entity {
        let particles = Entity()
        particles.name = name
        
        // Note: Particle systems would be configured based on specific needs
        // This is a placeholder for particle system creation
        
        print("✨ Particle system entity created: \(name)")
        return particles
    }
    
    // MARK: - Helper Methods
    
    /// Apply common transformations to an entity
    func applyTransform(to entity: Entity, position: SIMD3<Float>, rotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1), scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
        entity.position = position
        entity.transform.rotation = rotation
        entity.transform.scale = scale
    }
    
    /// Set entity visibility
    func setVisibility(of entity: Entity, isVisible: Bool) {
        entity.isEnabled = isVisible
    }
    
    /// Clone an existing entity
    func cloneEntity(_ entity: Entity, withName name: String) -> Entity {
        let clone = entity.clone(recursive: true)
        clone.name = name
        
        print("🔄 Entity cloned: \(name)")
        return clone
    }
    
    /// Remove entity from scene
    func removeEntity(_ entity: Entity) {
        entity.removeFromParent()
        print("🗑️ Entity removed: \(entity.name)")
    }
}

// MARK: - Light Types

enum LightType {
    case directional
    case point
    case spot
}

// MARK: - Entity Extensions for Factory

extension Entity {
    /// Convenience method to set entity name with fluent interface
    func withName(_ name: String) -> Entity {
        self.name = name
        return self
    }
    
    /// Convenience method to set entity position with fluent interface
    func withPosition(_ position: SIMD3<Float>) -> Entity {
        self.position = position
        return self
    }
    
    /// Convenience method to set entity rotation with fluent interface
    func withRotation(_ rotation: simd_quatf) -> Entity {
        self.transform.rotation = rotation
        return self
    }
    
    /// Convenience method to set entity scale with fluent interface
    func withScale(_ scale: SIMD3<Float>) -> Entity {
        self.transform.scale = scale
        return self
    }
} 
