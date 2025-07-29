import Foundation
import RealityKit
import simd
import GameplayKit

// MARK: - ECS Component Protocol

/// Base protocol for all ECS components
protocol GameComponent {
    var entityId: UUID { get }
}

// MARK: - Core Components

/// Component for tracking entity transform data
struct TransformComponent: GameComponent {
    let entityId: UUID
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var scale: SIMD3<Float>
    
    init(entityId: UUID, position: SIMD3<Float> = SIMD3<Float>(0, 0, 0), rotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1), scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
        self.entityId = entityId
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
}

/// Component for physics properties
struct PhysicsComponent: GameComponent {
    let entityId: UUID
    var mass: Float
    var physicsMaterial: PhysicsMaterialResource
    var bodyMode: PhysicsBodyMode
    var shapes: [ShapeResource]
    
    init(entityId: UUID, mass: Float = 1.0, physicsMaterial: PhysicsMaterialResource, bodyMode: PhysicsBodyMode = .dynamic, shapes: [ShapeResource]) {
        self.entityId = entityId
        self.mass = mass
        self.physicsMaterial = physicsMaterial
        self.bodyMode = bodyMode
        self.shapes = shapes
    }
}

/// Component for collision detection
struct GameCollisionComponent: GameComponent {
    let entityId: UUID
    var shapes: [ShapeResource]
    var isStatic: Bool
    var isTrigger: Bool
    
    init(entityId: UUID, shapes: [ShapeResource], isStatic: Bool = false, isTrigger: Bool = false) {
        self.entityId = entityId
        self.shapes = shapes
        self.isStatic = isStatic
        self.isTrigger = isTrigger
    }
}

/// Component for visual rendering
struct RenderComponent: GameComponent {
    let entityId: UUID
    var mesh: MeshResource
    var materials: [Material]
    var isVisible: Bool
    
    init(entityId: UUID, mesh: MeshResource, materials: [Material], isVisible: Bool = true) {
        self.entityId = entityId
        self.mesh = mesh
        self.materials = materials
        self.isVisible = isVisible
    }
}

/// Component for input handling
struct InputComponent: GameComponent {
    let entityId: UUID
    var isControllable: Bool
    var inputSensitivity: Float
    
    init(entityId: UUID, isControllable: Bool = false, inputSensitivity: Float = 1.0) {
        self.entityId = entityId
        self.isControllable = isControllable
        self.inputSensitivity = inputSensitivity
    }
}

/// Component for game entities (ball, walls, etc.)
struct GameEntityComponent: GameComponent {
    let entityId: UUID
    var entityType: GameEntityType
    var isActive: Bool
    var isCollectable: Bool
    
    init(entityId: UUID, entityType: GameEntityType, isActive: Bool = true, isCollectable: Bool = false) {
        self.entityId = entityId
        self.entityType = entityType
        self.isActive = isActive
        self.isCollectable = isCollectable
    }
}

/// Component for AI agent behavior
struct AIAgentComponent: GameComponent {
    let entityId: UUID
    var agent: GKAgent3D
    var behavior: GKBehavior
    var maxSpeed: Float
    var maxAcceleration: Float
    var targetEntityId: UUID?
    var lastKnownTargetPosition: SIMD3<Float>?
    
    // Sleep mechanism
    var sleepDuration: TimeInterval
    var sleepStartTime: Date?
    var isSleeping: Bool
    
    // === NEW: Rotation properties ===
    var rotationSpeed: Float = 6.0  // Radians per second
    var currentRotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    
    init(entityId: UUID, maxSpeed: Float = 0.3, maxAcceleration: Float = 0.8, sleepDuration: TimeInterval = 3.0) {
        self.entityId = entityId
        self.maxSpeed = maxSpeed
        self.maxAcceleration = maxAcceleration
        self.sleepDuration = sleepDuration
        self.sleepStartTime = nil
        self.isSleeping = false
        
        // Create GameplayKit agent
        let agent = GKAgent3D()
        agent.maxSpeed = maxSpeed
        agent.maxAcceleration = maxAcceleration
        agent.radius = 0.3
        agent.mass = 1.0
        
        self.agent = agent
        self.behavior = GKBehavior()
        
        // Initialize rotation
        self.currentRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    }
    
    // Existing methods...
    mutating func startSleep() {
        isSleeping = true
        sleepStartTime = Date()
    }
    
    func isSleepFinished() -> Bool {
        guard let startTime = sleepStartTime else { return false }
        return Date().timeIntervalSince(startTime) >= sleepDuration
    }
    
    mutating func wakeUp() {
        isSleeping = false
        sleepStartTime = nil
    }
}

/// Component for pathfinding data
struct PathfindingComponent: GameComponent {
    let entityId: UUID
    var currentPath: [SIMD3<Float>]
    var currentPathIndex: Int
    var isFollowingPath: Bool
    var pathfindingRadius: Float
    
    init(entityId: UUID, pathfindingRadius: Float = 0.5) {
        self.entityId = entityId
        self.currentPath = []
        self.currentPathIndex = 0
        self.isFollowingPath = false
        self.pathfindingRadius = pathfindingRadius
    }
}

// CameraComponent removed - using simplified fixed camera approach

// MARK: - Game Entity Types

enum GameEntityType {
    case ball
    case wall
    case floor
    case exit
    case maze
    case camera
    case light
    case cat
    case collectible
}

// MARK: - Component Storage

/// ECS Component manager for storing and retrieving components
class ComponentManager: ObservableObject {
    private var components: [String: [UUID: Any]] = [:]
    
    /// Add a component to an entity
    func addComponent<T: GameComponent>(_ component: T, to entityId: UUID) {
        let componentType = String(describing: T.self)
        if components[componentType] == nil {
            components[componentType] = [:]
        }
        components[componentType]?[entityId] = component
    }
    
    /// Get a component from an entity
    func getComponent<T: GameComponent>(_ type: T.Type, for entityId: UUID) -> T? {
        let componentType = String(describing: type)
        return components[componentType]?[entityId] as? T
    }
    
    /// Remove a component from an entity
    func removeComponent<T: GameComponent>(_ type: T.Type, from entityId: UUID) {
        let componentType = String(describing: type)
        components[componentType]?.removeValue(forKey: entityId)
    }
    
    /// Check if entity has a specific component
    func hasComponent<T: GameComponent>(_ type: T.Type, for entityId: UUID) -> Bool {
        let componentType = String(describing: type)
        return components[componentType]?[entityId] != nil
    }
    
    /// Get all entities with a specific component
    func getAllEntitiesWithComponent<T: GameComponent>(_ type: T.Type) -> [UUID] {
        let componentType = String(describing: type)
        guard let componentDict = components[componentType] else { return [] }
        return Array(componentDict.keys)
    }
    
    /// Remove all components for an entity
    func removeAllComponents(for entityId: UUID) {
        for componentType in components.keys {
            components[componentType]?.removeValue(forKey: entityId)
        }
    }
} 
