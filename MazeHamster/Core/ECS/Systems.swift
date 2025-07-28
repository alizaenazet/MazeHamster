import Foundation
import RealityKit
import simd
import CoreMotion
import GameplayKit

// MARK: - ECS System Protocol

/// Base protocol for all ECS systems
protocol GameSystem {
    var componentManager: ComponentManager { get }
    func update(deltaTime: TimeInterval)
    func initialize()
    func shutdown()
}

// MARK: - Core Systems

/// System for handling physics updates
class PhysicsSystem: GameSystem {
    let componentManager: ComponentManager
    private var realityEntities: [UUID: Entity] = [:]
    
    init(componentManager: ComponentManager) {
        self.componentManager = componentManager
    }
    
    func initialize() {
        // Initialize physics world settings
    }
    func update(deltaTime: TimeInterval) {
        let physicsEntities = componentManager.getAllEntitiesWithComponent(PhysicsComponent.self)
        
        for entityId in physicsEntities {
            guard let _ = componentManager.getComponent(PhysicsComponent.self, for: entityId),
                  let transformComponent = componentManager.getComponent(TransformComponent.self, for: entityId),
                  let realityEntity = realityEntities[entityId] else { continue }
            
            // Update RealityKit entity physics from component
            if realityEntity.components[PhysicsBodyComponent.self] != nil {
                // Sync component data to RealityKit
                realityEntity.position = transformComponent.position
                realityEntity.transform.rotation = transformComponent.rotation
            }
        }
    }
    
    func shutdown() {
        realityEntities.removeAll()
    }
    
    /// Register a RealityKit entity with the physics system
    func registerEntity(_ entity: Entity, with entityId: UUID) {
        realityEntities[entityId] = entity
    }
    
    /// Apply physics forces to an entity
    func applyForce(_ force: SIMD3<Float>, to entityId: UUID) {
        guard let realityEntity = realityEntities[entityId],
              realityEntity.components[PhysicsBodyComponent.self] != nil else { return }
        
        // Apply force to RealityKit entity by modifying transform
        let currentTransform = realityEntity.transform
        let newPosition = currentTransform.translation + force * 0.016 // Assuming 60fps
        realityEntity.move(to: Transform(scale: currentTransform.scale, rotation: currentTransform.rotation, translation: newPosition),
                          relativeTo: realityEntity.parent)
    }
}

/// System for handling input and motion
class InputSystem: GameSystem {
    let componentManager: ComponentManager
    private var motionManager = CMMotionManager()
    private var currentTiltData: TiltData?
    
    init(componentManager: ComponentManager) {
        self.componentManager = componentManager
    }
    
    func initialize() {
        startMotionUpdates()
    }
    
    func update(deltaTime: TimeInterval) {
        guard let tiltData = currentTiltData else { return }
        
        let inputEntities = componentManager.getAllEntitiesWithComponent(InputComponent.self)
        
        for entityId in inputEntities {
            guard let inputComponent = componentManager.getComponent(InputComponent.self, for: entityId),
                  inputComponent.isControllable else { continue }
            
            // Process input for controllable entities
            processInputForEntity(entityId, tiltData: tiltData)
        }
    }
    
    func shutdown() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            let gravity = motion.gravity
            let roll = Float(atan2(gravity.x, sqrt(gravity.y * gravity.y + gravity.z * gravity.z)))
            let pitch = Float(atan2(gravity.y, sqrt(gravity.x * gravity.x + gravity.z * gravity.z)))
            
            self.currentTiltData = TiltData(roll: roll, pitch: pitch)
        }
    }
    
    private func processInputForEntity(_ entityId: UUID, tiltData: TiltData) {
        guard let inputComponent = componentManager.getComponent(InputComponent.self, for: entityId) else { return }
        
        // Apply input sensitivity
        let adjustedTiltData = TiltData(
            roll: tiltData.roll * inputComponent.inputSensitivity,
            pitch: tiltData.pitch * inputComponent.inputSensitivity
        )
        
        // Update transform component based on input
        if var transformComponent = componentManager.getComponent(TransformComponent.self, for: entityId) {
            transformComponent.rotation = adjustedTiltData.quaternion
            componentManager.addComponent(transformComponent, to: entityId)
        }
    }
}

/// System for handling rendering updates
class RenderSystem: GameSystem {
    let componentManager: ComponentManager
    private var realityEntities: [UUID: Entity] = [:]
    
    init(componentManager: ComponentManager) {
        self.componentManager = componentManager
    }
    
    func initialize() {
        // Initialize rendering settings
    }
    
    func update(deltaTime: TimeInterval) {
        let renderEntities = componentManager.getAllEntitiesWithComponent(RenderComponent.self)
        
        for entityId in renderEntities {
            guard let renderComponent = componentManager.getComponent(RenderComponent.self, for: entityId),
                  let transformComponent = componentManager.getComponent(TransformComponent.self, for: entityId),
                  let realityEntity = realityEntities[entityId] else { continue }
            
            // Update RealityKit entity rendering from component
            realityEntity.position = transformComponent.position
            realityEntity.transform.rotation = transformComponent.rotation
            realityEntity.transform.scale = transformComponent.scale
            realityEntity.isEnabled = renderComponent.isVisible
        }
    }
    
    func shutdown() {
        realityEntities.removeAll()
    }
    
    /// Register a RealityKit entity with the render system
    func registerEntity(_ entity: Entity, with entityId: UUID) {
        realityEntities[entityId] = entity
    }
}

/// System for handling game logic
class GameLogicSystem: GameSystem {
    let componentManager: ComponentManager
    private var gameState: GameState = .menu
    
    init(componentManager: ComponentManager) {
        self.componentManager = componentManager
    }
    
    func initialize() {
        gameState = .menu
    }
    
    func update(deltaTime: TimeInterval) {
        // Update game logic based on current state
        switch gameState {
        case .playing:
            updateGameplay(deltaTime: deltaTime)
        case .paused:
            // Handle pause state
            break
        case .completed:
            // Handle completion state
            break
        case .failed:
            // Handle failure state
            break
        case .menu:
            // Handle menu state
            break
        }
    }
    
    func shutdown() {
        // Clean up game logic
    }
    
    private func updateGameplay(deltaTime: TimeInterval) {
        // Check for win conditions, collisions, etc.
        checkWinCondition()
        checkCollisions()
    }
    
    private func checkWinCondition() {
        // Check if ball has reached the exit
        let ballEntities = componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
            .filter { entityId in
                guard let gameEntity = componentManager.getComponent(GameEntityComponent.self, for: entityId) else { return false }
                return gameEntity.entityType == .ball
            }
        
        let exitEntities = componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
            .filter { entityId in
                guard let gameEntity = componentManager.getComponent(GameEntityComponent.self, for: entityId) else { return false }
                return gameEntity.entityType == .exit
            }
        
        // Check distance between ball and exit
        for ballId in ballEntities {
            for exitId in exitEntities {
                guard let ballTransform = componentManager.getComponent(TransformComponent.self, for: ballId),
                      let exitTransform = componentManager.getComponent(TransformComponent.self, for: exitId) else { continue }
                
                let distance = simd_distance(ballTransform.position, exitTransform.position)
                if distance < 0.5 { // Within exit radius
                    gameState = .completed
                    return
                }
            }
        }
    }
    
    private func checkCollisions() {
        // Handle collision detection and response
        // This would integrate with RealityKit's collision system
    }
    
    /// Get current game state
    func getCurrentGameState() -> GameState {
        return gameState
    }
    
    /// Set game state
    func setGameState(_ newState: GameState) {
        gameState = newState
    }
}

/// System for handling AI agent behavior
/// System for handling AI agent behavior with pathfinding
/// Enhanced System for handling AI agent behavior with proper pathfinding
class AISystem: GameSystem {
    let componentManager: ComponentManager
    private var realityEntities: [UUID: Entity] = [:]
    private var agentSystem: GKComponentSystem<GKAgent3D>
    private var pathfindingService: PathfindingService
    private var gameStartTime: Date?
    private var catSpawnDelay: TimeInterval = 2.0 // Cat spawns after 2 seconds
    private var sceneEntity: Entity?
    
    init(componentManager: ComponentManager, pathfindingService: PathfindingService) {
        self.componentManager = componentManager
        self.agentSystem = GKComponentSystem(componentClass: GKAgent3D.self)
        self.pathfindingService = pathfindingService
    }
    
    func initialize() {
        gameStartTime = Date()
        // print("🤖 Enhanced AI System with pathfinding initialized")
    }
    
    func update(deltaTime: TimeInterval) {
        let aiEntities = componentManager.getAllEntitiesWithComponent(AIAgentComponent.self)
        
        // Check if cat should start moving (after spawn delay)
        let timeSinceStart = Date().timeIntervalSince(gameStartTime ?? Date())
        let shouldCatBeActive = timeSinceStart >= catSpawnDelay
        
        for entityId in aiEntities {
            guard var aiComponent = componentManager.getComponent(AIAgentComponent.self, for: entityId),
                  var transformComponent = componentManager.getComponent(TransformComponent.self, for: entityId),
                  var pathfindingComponent = componentManager.getComponent(PathfindingComponent.self, for: entityId) else { continue }
            
            // NEW: Dapatkan CatStatusComponent
            var catStatus: CatStatusComponent? = componentManager.getComponent(CatStatusComponent.self, for: entityId)
            
            // Update CatStatusComponent effects (memastikan timer berjalan)
            if var currentCatStatus = catStatus {
                currentCatStatus.updateEffects()
                componentManager.addComponent(currentCatStatus, to: entityId)
                catStatus = currentCatStatus // Update optional var agar selalu paling baru
            }

            // NEW: Jika kucing ter-stun, jangan lakukan pergerakan AI
            if let currentCatStatus = catStatus, currentCatStatus.isStunned {
                // print("😴 Cat \(entityId) is stunned! Remaining time: \(String(format: "%.1f", max(0, currentCatStatus.stunEndTime?.timeIntervalSinceNow ?? 0)))s")
                continue // Lewati sisa logika update untuk kucing ini
            }
            
            // Don't activate cat until spawn delay has passed
            if !shouldCatBeActive {
                // print("😴 Cat waiting for spawn delay: \(String(format: "%.1f", catSpawnDelay - timeSinceStart))s remaining")
                continue
            }
            
            // Handle sleep state (initial sleep after spawn delay)
            if aiComponent.isSleeping {
                if aiComponent.isSleepFinished() {
                    aiComponent.wakeUp()
                    componentManager.addComponent(aiComponent, to: entityId)
                    // print("🐱 Cat \(entityId) woke up and started pathfinding!")
                    
                    // Clear any existing path visualization and start fresh
                    pathfindingService.clearPathVisualization()
                } else {
                    let remainingSleep = aiComponent.sleepDuration - (aiComponent.sleepStartTime?.timeIntervalSinceNow ?? 0)
                    // print("😴 Cat \(entityId) still sleeping for \(String(format: "%.1f", remainingSleep))s")
                    continue
                }
            }
            
            // Update agent position
            let currentPosition = transformComponent.position
            aiComponent.agent.position = vector_float3(currentPosition)
            
            // Get target position
            guard let targetId = aiComponent.targetEntityId,
                  let targetTransform = componentManager.getComponent(TransformComponent.self, for: targetId) else {
                // print("⚠️ Cat \(entityId) has no target or target not found")
                continue
            }
            
            let targetPosition = targetTransform.position
            
            // Update pathfinding with enhanced system
            updateEnhancedPathfinding(
                for: entityId,
                aiComponent: &aiComponent,
                pathfindingComponent: &pathfindingComponent,
                currentPosition: currentPosition,
                targetPosition: targetPosition
            )
            
            // Move along path with enhanced movement
            moveAlongEnhancedPath(
                for: entityId,
                aiComponent: &aiComponent,
                pathfindingComponent: &pathfindingComponent,
                transformComponent: &transformComponent,
                deltaTime: deltaTime,
                catStatus: catStatus // NEW: Passing catStatus to movement method
            )
            
            // Update components
            componentManager.addComponent(aiComponent, to: entityId)
            componentManager.addComponent(pathfindingComponent, to: entityId)
            componentManager.addComponent(transformComponent, to: entityId)
        }
    }
    
    func shutdown() {
        pathfindingService.clearPathVisualization()
        realityEntities.removeAll()
        // print("🤖 Enhanced AI System shut down")
    }
    
    /// Register a RealityKit entity with the AI system
    func registerEntity(_ entity: Entity, with entityId: UUID) {
        realityEntities[entityId] = entity
    }
    
    /// Set scene entity for path visualization
    func setSceneEntity(_ scene: Entity) {
        sceneEntity = scene
    }
    
    /// Set up chase behavior for a cat entity
    func setupChaseForCat(catEntityId: UUID, targetEntityId: UUID) {
        guard var aiComponent = componentManager.getComponent(AIAgentComponent.self, for: catEntityId) else { return }
        
        // Set the target
        aiComponent.targetEntityId = targetEntityId
        
        // Start the cat in sleeping state (will activate after spawn delay)
        aiComponent.startSleep()
        
        // Update the component
        componentManager.addComponent(aiComponent, to: catEntityId)
        
        // print("🐱 Chase behavior set up for cat - will start after \(catSpawnDelay)s spawn delay + \(aiComponent.sleepDuration)s sleep")
    }
    
    /// Reset game timing (call when game restarts)
    func resetGameTiming() {
        gameStartTime = Date()
        pathfindingService.clearPathVisualization()
        // print("⏰ AI System timing reset")
    }
    
    // MARK: - Enhanced Pathfinding Logic
    
    private func updateEnhancedPathfinding(
        for entityId: UUID,
        aiComponent: inout AIAgentComponent,
        pathfindingComponent: inout PathfindingComponent,
        currentPosition: SIMD3<Float>,
        targetPosition: SIMD3<Float>
    ) {
        let distanceToTarget = simd_distance(currentPosition, targetPosition)
        
        // Check if we need to recalculate path
        let shouldRecalculatePath =
            !pathfindingComponent.isFollowingPath || // No current path
            pathfindingComponent.currentPath.isEmpty || // Empty path
            hasTargetMovedSignificantly(currentPath: pathfindingComponent.currentPath, targetPosition: targetPosition) ||
            hasReachedEndOfPath(pathfindingComponent: pathfindingComponent)
        
        if shouldRecalculatePath {
            // print("🔄 Recalculating path for cat \(entityId)")
            // print("   Current: \(currentPosition)")
            // print("   Target: \(targetPosition)")
            // print("   Distance: \(distanceToTarget)")
            
            // Find new path using enhanced pathfinding
            let newPath = pathfindingService.findPath(from: currentPosition, to: targetPosition)
            
            if !newPath.isEmpty {
                pathfindingComponent.currentPath = newPath
                pathfindingComponent.currentPathIndex = 0
                pathfindingComponent.isFollowingPath = true
                
                // Visualize the path
                if let scene = sceneEntity {
                    pathfindingService.visualizePath(newPath, in: scene)
                }
                
                // print("🗺️ Cat \(entityId) found new path with \(newPath.count) waypoints")
                // print("   Path preview: \(newPath.prefix(3).map { "(\(String(format: "%.1f", $0.x)),\(String(format: "%.1f", $0.z)))" })")
            } else {
                // No path found, stop following path
                pathfindingComponent.isFollowingPath = false
                pathfindingService.clearPathVisualization()
                // print("⚠️ Cat \(entityId) couldn't find path to target")
            }
        }
    }
    
    private func moveAlongEnhancedPath(
        for entityId: UUID,
        aiComponent: inout AIAgentComponent,
        pathfindingComponent: inout PathfindingComponent,
        transformComponent: inout TransformComponent,
        deltaTime: TimeInterval,
        catStatus: CatStatusComponent? // NEW: Terima CatStatusComponent di sini
    ) {
        guard pathfindingComponent.isFollowingPath && !pathfindingComponent.currentPath.isEmpty else {
            return
        }
        
        guard let realityEntity = realityEntities[entityId] else {
            // print("⚠️ No reality entity found for cat \(entityId)")
            return
        }
        
        let currentPosition = transformComponent.position
        let currentWaypointIndex = pathfindingComponent.currentPathIndex
        
        // Check if we've reached the end of the path
        if currentWaypointIndex >= pathfindingComponent.currentPath.count {
            pathfindingComponent.isFollowingPath = false
            pathfindingService.clearPathVisualization()
            // print("🎯 Cat \(entityId) completed path")
            return
        }
        
        let targetWaypoint = pathfindingComponent.currentPath[currentWaypointIndex]
        let distanceToWaypoint = simd_distance(currentPosition, targetWaypoint)
        
        // print("🚶 Cat \(entityId) moving to waypoint \(currentWaypointIndex): \(targetWaypoint)")
        // print("   Current pos: \(currentPosition)")
        // print("   Distance to waypoint: \(distanceToWaypoint)")
        
        // Check if we've reached the current waypoint
        if distanceToWaypoint < 0.4 { // Waypoint reached threshold
            pathfindingComponent.currentPathIndex += 1
            // print("✅ Cat \(entityId) reached waypoint \(currentWaypointIndex)")
            
            // Check if we've reached the final waypoint
            if pathfindingComponent.currentPathIndex >= pathfindingComponent.currentPath.count {
                pathfindingComponent.isFollowingPath = false
                pathfindingService.clearPathVisualization()
                // print("🎯 Cat \(entityId) reached final destination")
                return
            }
        }
        
        // Hitung kecepatan efektif kucing
        var effectiveSpeed = aiComponent.maxSpeed
        if let currentCatStatus = catStatus, currentCatStatus.isSpeedBoosted {
            effectiveSpeed *= currentCatStatus.speedMultiplier
            // print("🐱 Cat \(entityId) speed boosted! Effective speed: \(effectiveSpeed)")
        }
        
        // Move towards current waypoint with enhanced movement
        let nextWaypoint = pathfindingComponent.currentPath[pathfindingComponent.currentPathIndex]
        moveTowardsWaypointEnhanced(
            entity: realityEntity,
            from: currentPosition,
            to: nextWaypoint,
            speed: effectiveSpeed, // NEW: Gunakan effectiveSpeed di sini
            deltaTime: Float(deltaTime)
        )
        
        // Update transform component
        transformComponent.position = realityEntity.position
    }
    
    private func moveTowardsWaypointEnhanced(
        entity: Entity,
        from currentPosition: SIMD3<Float>,
        to targetPosition: SIMD3<Float>,
        speed: Float,
        deltaTime: Float
    ) {
        // Calculate direction to target
        let direction = targetPosition - currentPosition
        let distance = length(direction)
        
        guard distance > 0.01 else {
            // print("🎯 Cat too close to waypoint, not moving")
            return
        }
        
        // Normalize direction
        let normalizedDirection = direction / distance
        
        // Calculate movement with speed limiting
        let maxMoveDistance = speed * deltaTime
        let moveDistance = min(maxMoveDistance, distance) // Don't overshoot
        let movement = normalizedDirection * moveDistance
        
        // Apply movement
        let newPosition = currentPosition + movement
        entity.position = newPosition
        
        // print("🚶 Cat enhanced movement:")
        // print("   From: (\(String(format: "%.2f", currentPosition.x)), \(String(format: "%.2f", currentPosition.z)))")
        // print("   To: (\(String(format: "%.2f", newPosition.x)), \(String(format: "%.2f", newPosition.z)))")
        // print("   Target: (\(String(format: "%.2f", targetPosition.x)), \(String(format: "%.2f", targetPosition.z)))")
        // print("   Move distance: \(String(format: "%.3f", moveDistance))")
    }
    
    private func hasTargetMovedSignificantly(currentPath: [SIMD3<Float>], targetPosition: SIMD3<Float>) -> Bool {
        guard !currentPath.isEmpty else { return true }
        
        // Check if target has moved significantly from the path's destination
        let pathDestination = currentPath.last!
        let distanceToPathDestination = simd_distance(targetPosition, pathDestination)
        
        let significantMoveThreshold: Float = 0.8
        let hasMoved = distanceToPathDestination > significantMoveThreshold
        
        if hasMoved {
            // print("🎯 Target moved significantly: \(distanceToPathDestination) > \(significantMoveThreshold)")
        }
        
        return hasMoved
    }
    
    private func hasReachedEndOfPath(pathfindingComponent: PathfindingComponent) -> Bool {
        return pathfindingComponent.currentPathIndex >= pathfindingComponent.currentPath.count
    }
    
    /// Check if cat has caught the player
    func checkCatPlayerCollision(catEntityId: UUID, playerEntityId: UUID) -> Bool {
        guard let catTransform = componentManager.getComponent(TransformComponent.self, for: catEntityId),
              let playerTransform = componentManager.getComponent(TransformComponent.self, for: playerEntityId) else { return false }
        
        let distance = simd_distance(catTransform.position, playerTransform.position)
        let collisionDistance: Float = 0.6 // Collision radius
        
        if distance < collisionDistance {
            // print("💥 Cat caught player! Distance: \(String(format: "%.2f", distance))")
            pathfindingService.clearPathVisualization() // Clear path when game ends
            return true
        }
        
        return false
    }
    
    // MARK: - Debug Methods
    
    func getAIDebugInfo() -> String {
        let timeSinceStart = Date().timeIntervalSince(gameStartTime ?? Date())
        let shouldCatBeActive = timeSinceStart >= catSpawnDelay
        
        var info = "=== AI Debug Info ===\n"
        info += "Time Since Start: \(String(format: "%.1f", timeSinceStart))s\n"
        info += "Cat Spawn Delay: \(catSpawnDelay)s\n"
        info += "Cat Should Be Active: \(shouldCatBeActive)\n"
        
        let aiEntities = componentManager.getAllEntitiesWithComponent(AIAgentComponent.self)
        info += "AI Entities: \(aiEntities.count)\n"
        
        for entityId in aiEntities {
            if let aiComponent = componentManager.getComponent(AIAgentComponent.self, for: entityId),
               let pathComponent = componentManager.getComponent(PathfindingComponent.self, for: entityId) {
                info += "\nCat \(entityId):\n"
                info += "  Sleeping: \(aiComponent.isSleeping)\n"
                info += "  Following Path: \(pathComponent.isFollowingPath)\n"
                info += "  Path Length: \(pathComponent.currentPath.count)\n"
                info += "  Current Waypoint: \(pathComponent.currentPathIndex)\n"

                // NEW: Tambahkan info status kucing untuk debugging
                if let catStatus = componentManager.getComponent(CatStatusComponent.self, for: entityId) {
                    info += "  Is Speed Boosted: \(catStatus.isSpeedBoosted)\n"
                    info += "  Speed Multiplier: \(catStatus.speedMultiplier)\n"
                    if let endTime = catStatus.speedBoostEndTime {
                        let remainingTime = endTime.timeIntervalSinceNow
                        info += "  Boost Remaining: \(String(format: "%.1f", max(0, remainingTime)))s\n"
                    }
                    if let endTime = catStatus.stunEndTime {
                        let remainingTime = endTime.timeIntervalSinceNow
                        info += "  Stun Remaining: \(String(format: "%.1f", max(0, remainingTime)))s\n"
                    }
                }
            }
        }
        
        return info
    }
    
    func setCatSpawnDelay(_ delay: TimeInterval) {
        catSpawnDelay = delay
        // print("⏰ Cat spawn delay set to \(delay)s")
    }
}
// CameraSystem removed - using simplified fixed camera approach

// MARK: - ECS World

/// Main ECS world that manages all systems and components
/// Main ECS world that manages all systems and components with pathfinding support
class ECSWorld: ObservableObject {
    let componentManager = ComponentManager()
    private var systems: [GameSystem] = []
    private var isRunning = false
    private let pathfindingService: PathfindingService
    private let soundPlayer: SoundPlayer
    private let gameService: GameService // NEW: Tambahkan properti gameService
    private let mazeService: MazeService // NEW: Tambahkan properti mazeService
    
    init(pathfindingService: PathfindingService, gameService: GameService, mazeService: MazeService) {
            self.pathfindingService = pathfindingService
            self.soundPlayer = SoundPlayer()
            self.gameService = gameService // NEW: Inisialisasi gameService
            self.mazeService = mazeService // NEW: Inisialisasi mazeService
            setupSystems()
        }
    
    func clearAllComponents() {
//        componentManager.clearAll()
        // print("🧹 ECS World: All components cleared")
    }

    
    private func setupSystems() {
        systems = [
            PhysicsSystem(componentManager: componentManager),
            InputSystem(componentManager: componentManager),
            RenderSystem(componentManager: componentManager),
            GameLogicSystem(componentManager: componentManager),
            AISystem(componentManager: componentManager, pathfindingService: pathfindingService),
            CollectibleSystem(componentManager: componentManager, soundPlayer: soundPlayer, gameService: self.gameService, mazeService: self.mazeService)
            
        ]
    }
    
    /// Initialize all systems
    func initialize() {
        // NEW: Muat semua efek suara di sini saat ECSWorld diinisialisasi
        // PASTIKAN NAMA FILE DAN EKSTENSI SESUAI DENGAN YANG ANDA TAMBAHKAN KE PROYEK ANDA!
        soundPlayer.loadSound(named: "sfx_kuaci_collect", fileExtension: "wav")
        soundPlayer.loadSound(named: "sfx_fish_collect", fileExtension: "wav")
        soundPlayer.loadSound(named: "sfx_shield_collect", fileExtension: "wav")
        soundPlayer.loadSound(named: "sfx_bubblegum_collect", fileExtension: "wav")
        soundPlayer.loadSound(named: "sfx_pillow_collect", fileExtension: "mp3")
        // Tambahkan semua SFX lain yang Anda miliki di sini
        
        for system in systems {
            system.initialize()
        }
        isRunning = true
        // print("🌍 ECS World with pathfinding initialized")
    }
    
    /// Update all systems
    func update(deltaTime: TimeInterval) {
        guard isRunning else { return }
        
        for system in systems {
            system.update(deltaTime: deltaTime)
        }
    }
    
    /// Shutdown all systems
    func shutdown() {
        // NEW: Hentikan semua suara saat ECSWorld dimatikan
        soundPlayer.stopAllSounds()
        for system in systems {
            system.shutdown()
        }
        isRunning = false
        // print("🌍 ECS World shut down")
    }
    
    /// Get a specific system
    func getSystem<T: GameSystem>(_ type: T.Type) -> T? {
        return systems.first { $0 is T } as? T
    }
}
