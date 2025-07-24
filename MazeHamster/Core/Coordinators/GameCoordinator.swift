import Foundation
import RealityKit
import Combine

/// Enhanced Game coordinator with collectible system integration and screen detection
class GameCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isInitialized: Bool = false
    @Published var systemStatus: SystemStatus = .idle
    @Published var currentMazeSize: SIMD2<Int> = SIMD2<Int>(6, 8)
    @Published var adaptiveInfo: String = ""
    @Published var collectionProgress: CollectionProgress = CollectionProgress(totalItems: 0, collectedItems: 0, keys: 0, requiredKeys: 1)
    @Published var playerEffects: String = "None"
    @Published var canPlayerExitMaze: Bool = true
    
    // MARK: - Services
    
    private let inputService: InputService
    private let physicsService: PhysicsService
    private let mazeService: MazeService
    private let gameService: GameService
    private let cameraService: CameraService
    private let pathfindingService: PathfindingService
    private let screenAdaptiveService: ScreenAdaptiveService
    private let entityFactory: EntityFactory
    
    // MARK: - ECS
    
    private let ecsWorld: ECSWorld
    
    // MARK: - Game State
    
    private var gameConfiguration: GameConfiguration
    private var currentScene: Entity?
    private var isRunning: Bool = false
    private var catEntity: Entity?
    private var catEntityId: UUID?
    private var ballEntityId: UUID?
    
    // MARK: - Collectible System
    
    private var collectibleEntities: [(Entity, UUID)] = []
    private var requiredKeysForExit: Int = 1
    
    // MARK: - Combine
    
    private var cancellables = Set<AnyCancellable>()
    private var mazeWorldEntity: Entity? // Add this to store reference
    
    // MARK: - Initialization
    
    init(configuration: GameConfiguration? = nil) {
        // Initialize services
        self.inputService = InputService()
        self.physicsService = PhysicsService()
        self.mazeService = MazeService()
        self.gameService = GameService()
        self.cameraService = CameraService()
        self.pathfindingService = PathfindingService()
        self.screenAdaptiveService = ScreenAdaptiveService()
        self.entityFactory = EntityFactory()
        
        // Use adaptive configuration if none provided
        self.gameConfiguration = configuration ?? AdaptiveConfigurationFactory.createOptimalConfiguration()
        
        // Initialize ECS with enhanced pathfinding and collectibles
        self.ecsWorld = ECSWorld(pathfindingService: pathfindingService)
        
        setupCoordinator()
    }
    
    // MARK: - Setup
    
    private func setupCoordinator() {
        // Setup service dependencies
        gameService.setMazeService(mazeService)
        pathfindingService.setMazeService(mazeService)
        
        // Setup bindings
        setupBindings()
        
        // Initialize ECS
        ecsWorld.initialize()
        
        // Update configuration based on screen detection
        updateAdaptiveConfiguration()
        
        mazeService.setupWithConfiguration(gameConfiguration.maze)
        
        systemStatus = .ready
        isInitialized = true
        
        print("🎮 Enhanced GameCoordinator with collectibles initialized successfully")
    }
    
    private func setupBindings() {
        // Monitor game state changes
        gameService.$gameState
            .sink { [weak self] gameState in
                self?.handleGameStateChange(gameState)
            }
            .store(in: &cancellables)
        
        // Monitor input changes
        inputService.tiltData
            .sink { [weak self] tiltData in
                self?.handleInputChange(tiltData)
            }
            .store(in: &cancellables)
        
        // Monitor maze changes
        mazeService.$maze
            .sink { [weak self] _ in
                self?.handleMazeChange()
            }
            .store(in: &cancellables)
        
        // Monitor screen changes
        screenAdaptiveService.$currentScreenInfo
            .sink { [weak self] screenInfo in
                if screenInfo != nil {
                    self?.handleScreenChange()
                }
            }
            .store(in: &cancellables)
        
        // Monitor collectible progress
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCollectibleProgress()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Adaptive Configuration
    
    private func updateAdaptiveConfiguration() {
        // Get optimal configuration for current screen
        let adaptiveConfig = screenAdaptiveService.getAdaptiveGameConfiguration()
        gameConfiguration = adaptiveConfig
        
        // Update current maze size for UI binding
        currentMazeSize = SIMD2<Int>(adaptiveConfig.maze.width, adaptiveConfig.maze.height)
        
        // Update adaptive info for debugging
        updateAdaptiveInfo()
        
        print("📱 Updated adaptive configuration:")
        print("   Maze Size: \(adaptiveConfig.maze.width)x\(adaptiveConfig.maze.height)")
        print("   Cell Size: \(adaptiveConfig.maze.cellSize)")
        print("   Camera Height: \(adaptiveConfig.cameraHeight)")
    }
    
    private func updateAdaptiveInfo() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.adaptiveInfo = self.screenAdaptiveService.getScreenDebugInfo()
        }
    }
    
    private func handleScreenChange() {
        // Screen orientation or size changed - update configuration
        updateAdaptiveConfiguration()
        
        // If game is running, might want to recreate scene with new configuration
        // For now, just log the change
        print("📱 Screen changed - adaptive configuration updated")
    }
    
    
    
    func clearMazeWorldGameAudio() {
        guard let mazeWorld = mazeWorldEntity else {
            print("⚠️ No mazeWorld entity reference found")
            return
        }
        
        // Stop all audio on the mazeWorld entity
        mazeWorld.stopAllAudio()
        
        // Remove the audio channel component
        mazeWorld.components.remove(ChannelAudioComponent.self)
        
        print("🔇 Successfully cleared all game audio from MazeWorld")
    }
    
    // MARK: - Enhanced Scene Creation with Collectibles
    
    /// Create a new game scene with adaptive sizing and collectibles
    func createGameSceneWithCollectibles() -> Entity {
        systemStatus = .initializing
        
        // Ensure we have the latest adaptive configuration
        updateAdaptiveConfiguration()
        
        // Create main scene
        let scene = entityFactory.createContainer(name: "AdaptiveGameScene")
        currentScene = scene
        
        // Create maze world
        let mazeWorld = entityFactory.createContainer(name: "MazeWorld")
        mazeWorldEntity = mazeWorld // Store reference
        
        // Generate maze entities with adaptive configuration
        let mazeEntities = mazeService.createMazeEntities()
        
        // Setup maze physics
        setupMazePhysics(entities: mazeEntities)
        
        // Add maze entities to world
        for entity in mazeEntities {
            mazeWorld.addChild(entity)
        }
        
        mazeWorld.channelAudio = ChannelAudioComponent()
        do {
            let resource = try AudioFileResource.load(named: "Maze-Runner-Symphony")
            mazeWorld.playAudio(resource)
        } catch {
            fatalError("Failed to create maze world audio channel: \(error)")
        }
        
        // Create collectibles throughout the maze
        collectibleEntities = entityFactory.createMazeCollectibles(
            mazeService: mazeService,
            componentManager: ecsWorld.componentManager
        )
        
        // Register collectibles with collectible system and add to world
        if let collectibleSystem = ecsWorld.getSystem(CollectibleSystem.self) {
            for (collectibleEntity, collectibleId) in collectibleEntities {
                collectibleSystem.registerEntity(collectibleEntity, with: collectibleId)
                mazeWorld.addChild(collectibleEntity)
            }
            collectibleSystem.setGameService(gameService)
            collectibleSystem.setRequiredKeys(requiredKeysForExit)
        }
        
        // Create and setup ball with adaptive sizing
        let ball = createAdaptiveBall()
        mazeWorld.addChild(ball)
        
        // Create and setup cat with adaptive positioning
        let cat = createAdaptiveCat()
        mazeWorld.addChild(cat)
        
        // Create camera with adaptive height and positioning
        let camera = createAdaptiveCamera()
        
        // Configure game service
        gameService.setBallEntity(ball)
        
        // Add to scene
        scene.addChild(mazeWorld)
        scene.addChild(camera)
        
        systemStatus = .ready
        print("🏗️ Enhanced game scene with collectibles created successfully")
        print("   Maze: \(gameConfiguration.maze.width)x\(gameConfiguration.maze.height)")
        print("   Collectibles: \(collectibleEntities.count)")
        print("   Required Keys: \(requiredKeysForExit)")
        
        return scene
    }
    
    /// Legacy method for backward compatibility
    func createGameScene() -> Entity {
        return createGameSceneWithCollectibles()
    }
    
    func generateNewMaze() {
        systemStatus = .initializing
        
        // Update adaptive configuration before generating
        updateAdaptiveConfiguration()
        
        // Clear path visualization before generating new maze
        pathfindingService.clearPathVisualization()
        
        // Clear existing collectibles
        clearCollectibles()
        
        // --- Step 1: Remove old ball and cat ---
        if let mazeWorld = mazeWorldEntity {
            mazeWorld.children.removeAll(where: { $0.name == "MazeBall" || $0.name == "CatAgent" })
        }
        
        ballEntityId = nil
        catEntityId = nil
        
        mazeService.setupWithConfiguration(gameConfiguration.maze)
        
        // CRITICAL: Recreate the visual maze entities
        recreateVisualMaze()
        
        // Recreate collectibles for the new maze
        recreateCollectiblesForNewMaze()
        
        // Reset entity positions
        resetEntityPositionsForNewMaze()

        // 8. Recreate and register new ball & cat
        let newBall = createAdaptiveBall()
        mazeWorldEntity?.addChild(newBall)
        gameService.setBallEntity(newBall)

        let newCat = createAdaptiveCat()
        mazeWorldEntity?.addChild(newCat)

        // --- Step 2: Clear ECS components for old ball and cat ---
        if let oldBallId = ballEntityId {
            ecsWorld.componentManager.removeAllComponents(for: oldBallId)
        }
        if let oldCatId = catEntityId {
            ecsWorld.componentManager.removeAllComponents(for: oldCatId)
        }

        // Clear the ECS world for good measure (optional but safer)
//        ecsWorld.clearAllEntities()
        
        systemStatus = .ready
        
        print("🌀 New adaptive maze with visual recreation generated: \(gameConfiguration.maze.width)x\(gameConfiguration.maze.height)")
        print("   Collectibles recreated: \(collectibleEntities.count)")
    }

    // MARK: - Helper method to recreate visual maze

    /// Recreate all visual maze entities (walls, floors) for the new maze layout
    private func recreateVisualMaze() {
        guard let mazeWorld = currentScene?.children.first(where: { $0.name == "MazeWorld" }) else {
            print("⚠️ Could not find MazeWorld to recreate maze")
            return
        }
        
        // Remove all existing maze entities (walls and floors)
        let entitiesToRemove = mazeWorld.children.filter { entity in
            entity.name.contains("Wall") || entity.name.contains("Floor")
        }
        
        for entity in entitiesToRemove {
            entity.removeFromParent()
        }
        
        print("🗑️ Removed \(entitiesToRemove.count) old maze entities")
        
        // Create new maze entities with the new layout
        let newMazeEntities = mazeService.createMazeEntities()
        
        // Setup physics for new maze entities
        setupMazePhysics(entities: newMazeEntities)
        
        // Add new maze entities to the world
        for entity in newMazeEntities {
            mazeWorld.addChild(entity)
        }
        
        print("✨ Created \(newMazeEntities.count) new maze entities")
    }

    /// Reset entity positions after maze recreation
    private func resetEntityPositionsForNewMaze() {
        guard let scene = currentScene else { return }
        
        scene.children.forEach { child in
            if child.name == "MazeWorld" {
                child.children.forEach { grandChild in
                    if grandChild.name == "MazeBall" {
                        // Reset ball to new start position
                        grandChild.position = mazeService.getStartPosition()
                        
                        // Reset physics velocity
                        if let physicsBody = grandChild.components[PhysicsBodyComponent.self] {
                            var newPhysicsBody = physicsBody
//                            newPhysicsBody.linearVelocity = SIMD3<Float>(0, 0, 0)
//                            newPhysicsBody.angularVelocity = SIMD3<Float>(0, 0, 0)
                            grandChild.components[PhysicsBodyComponent.self] = newPhysicsBody
                        }
                        
                        // Reset player status
                        if let ballEntityId = ballEntityId {
                            let resetPlayerStatus = PlayerStatusComponent(entityId: ballEntityId)
                            ecsWorld.componentManager.addComponent(resetPlayerStatus, to: ballEntityId)
                        }
                        
                    } else if grandChild.name == "CatAgent" {
                        // Reset cat to new position relative to ball
                        let ballStartPosition = mazeService.getStartPosition()
                        let offsetDistance = gameConfiguration.maze.cellSize * 2.0
                        let catStartPosition = ballStartPosition + SIMD3<Float>(offsetDistance, 0, offsetDistance)
                        grandChild.position = catStartPosition
                        
                        // Reset cat's ECS components
                        if let catEntityId = catEntityId,
                           var catTransform = ecsWorld.componentManager.getComponent(TransformComponent.self, for: catEntityId),
                           var catAI = ecsWorld.componentManager.getComponent(AIAgentComponent.self, for: catEntityId),
                           var catPathfinding = ecsWorld.componentManager.getComponent(PathfindingComponent.self, for: catEntityId) {
                            
                            catTransform.position = catStartPosition
                            catAI.startSleep() // Restart sleep when resetting
                            
                            // Clear current pathfinding state
                            catPathfinding.currentPath = []
                            catPathfinding.currentPathIndex = 0
                            catPathfinding.isFollowingPath = false
                            
                            ecsWorld.componentManager.addComponent(catTransform, to: catEntityId)
                            ecsWorld.componentManager.addComponent(catAI, to: catEntityId)
                            ecsWorld.componentManager.addComponent(catPathfinding, to: catEntityId)
                        }
                    }
                }
            }
        }
        
        print("🔄 Reset entity positions for new maze layout")
    }

    // MARK: - Helper method to recreate collectibles

    /// Recreate collectibles when generating a new maze
    private func recreateCollectiblesForNewMaze() {
        guard let mazeWorld = currentScene?.children.first(where: { $0.name == "MazeWorld" }) else {
            print("⚠️ Could not find MazeWorld to add collectibles")
            return
        }
        
        // Create new collectibles for the new maze layout
        collectibleEntities = entityFactory.createMazeCollectibles(
            mazeService: mazeService,
            componentManager: ecsWorld.componentManager
        )
        
        // Register collectibles with collectible system and add to world
        if let collectibleSystem = ecsWorld.getSystem(CollectibleSystem.self) {
            for (collectibleEntity, collectibleId) in collectibleEntities {
                collectibleSystem.registerEntity(collectibleEntity, with: collectibleId)
                mazeWorld.addChild(collectibleEntity)
            }
            // Ensure required keys setting is maintained
            collectibleSystem.setRequiredKeys(requiredKeysForExit)
        }
        
        print("✨ Recreated \(collectibleEntities.count) collectibles for new maze")
    }

    
    /// Force refresh adaptive configuration (useful when screen rotates)
    func refreshAdaptiveConfiguration() {
        screenAdaptiveService.refreshScreenDetection()
        updateAdaptiveConfiguration()
        print("🔄 Adaptive configuration refreshed")
    }
    
    // MARK: - Collectible System Methods
    
    /// Get collectible system instance
    func getCollectibleSystem() -> CollectibleSystem? {
        return ecsWorld.getSystem(CollectibleSystem.self)
    }
    
    /// Check if player can exit (has required keys)
    func canPlayerExit() -> Bool {
        guard let collectibleSystem = getCollectibleSystem(),
              let ballEntityId = ballEntityId else { return true }
        
        return collectibleSystem.canPlayerExit(playerId: ballEntityId)
    }
    
    /// Get collection progress for UI
    func getCollectionProgress() -> CollectionProgress {
        guard let collectibleSystem = getCollectibleSystem(),
              let ballEntityId = ballEntityId else {
            return CollectionProgress(totalItems: 0, collectedItems: 0, keys: 0, requiredKeys: requiredKeysForExit)
        }
        
        return collectibleSystem.getCollectionProgress(for: ballEntityId)
    }
    
    /// Get player status for effects display
    func getPlayerStatus() -> PlayerStatusComponent? {
        guard let collectibleSystem = getCollectibleSystem(),
              let ballEntityId = ballEntityId else { return nil }
        
        return collectibleSystem.getPlayerStatus(for: ballEntityId)
    }
    
    /// Set number of keys required to exit
    func setRequiredKeys(_ count: Int) {
        requiredKeysForExit = count
        if let collectibleSystem = getCollectibleSystem() {
            collectibleSystem.setRequiredKeys(count)
        }
    }
    
    /// Clear all collectibles from the scene
    private func clearCollectibles() {
        for (entity, _) in collectibleEntities {
            entity.removeFromParent()
        }
        collectibleEntities.removeAll()
    }
    
    /// Update collectible progress for UI binding
    private func updateCollectibleProgress() {
        let progress = getCollectionProgress()
        let playerStatus = getPlayerStatus()
        
        DispatchQueue.main.async { [weak self] in
            self?.collectionProgress = progress
            self?.canPlayerExitMaze = progress.canExit
            self?.playerEffects = playerStatus?.activeEffectsDescription ?? "None"
        }
    }
    
    // MARK: - Adaptive Entity Creation
    
    private func createAdaptiveBall() -> Entity {
        let ball = entityFactory.createBall(
            radius: gameConfiguration.ballRadius,
            material: gameConfiguration.visualMaterials.ball
        )
        ball.position = mazeService.getStartPosition()
        physicsService.setupBallPhysics(for: ball, withMaterial: gameConfiguration.physicsMaterials.ball)
        
        // Create ball entity for ECS tracking
        ballEntityId = UUID()
        let ballTransformComponent = TransformComponent(
            entityId: ballEntityId!,
            position: ball.position,
            rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
            scale: SIMD3<Float>(1, 1, 1)
        )
        ecsWorld.componentManager.addComponent(ballTransformComponent, to: ballEntityId!)
        
        let ballGameEntityComponent = GameEntityComponent(
            entityId: ballEntityId!,
            entityType: .ball,
            isActive: true,
            isCollectable: false
        )
        ecsWorld.componentManager.addComponent(ballGameEntityComponent, to: ballEntityId!)
        
        // Add player status component for collectibles
        let playerStatusComponent = PlayerStatusComponent(entityId: ballEntityId!)
        ecsWorld.componentManager.addComponent(playerStatusComponent, to: ballEntityId!)
        
        print("🎯 Adaptive ball with collectible support created with radius: \(gameConfiguration.ballRadius)")
        return ball
    }
    
    private func createAdaptiveCat() -> Entity {
        let ballStartPosition = mazeService.getStartPosition()
        
        // Position cat further away on larger mazes, closer on smaller mazes
        let offsetDistance = gameConfiguration.maze.cellSize * 2.0
        let catStartPosition = ballStartPosition + SIMD3<Float>(offsetDistance, 0, offsetDistance)
        
        let (cat, catId) = entityFactory.createCatWithECS(
            componentManager: ecsWorld.componentManager,
            startPosition: catStartPosition,
            sleepDuration: gameConfiguration.catSleepDuration
        )
        
        catEntity = cat
        catEntityId = catId
        
        // Register cat with enhanced AI system
        if let aiSystem = ecsWorld.getSystem(AISystem.self) {
            aiSystem.registerEntity(cat, with: catId)
            aiSystem.setSceneEntity(currentScene!) // Set scene for path visualization
            aiSystem.setupChaseForCat(catEntityId: catId, targetEntityId: ballEntityId!)
            aiSystem.setCatSpawnDelay(2.0) // 2 second spawn delay
        }
        
        // Register cat with other systems
        if let renderSystem = ecsWorld.getSystem(RenderSystem.self) {
            renderSystem.registerEntity(cat, with: catId)
        }
        
        if let physicsSystem = ecsWorld.getSystem(PhysicsSystem.self) {
            physicsSystem.registerEntity(cat, with: catId)
        }
        
        print("🐱 Adaptive cat created at offset: \(offsetDistance)")
        return cat
    }
    
    private func createAdaptiveCamera() -> Entity {
        let camera = cameraService.setupCamera(
            mazeSize: SIMD2<Int>(gameConfiguration.maze.width, gameConfiguration.maze.height),
            cellSize: gameConfiguration.maze.cellSize,
            gameConfiguration: gameConfiguration
        )
        
        // Keep the camera position from CameraService but ensure proper centering
        let mazeCenter = mazeService.maze.centerPosition
        let cameraPosition = camera.position // Use position calculated by CameraService
        
        // Ensure camera is centered over the maze but keep the height from CameraService
        let centeredPosition = SIMD3<Float>(mazeCenter.x, cameraPosition.y, mazeCenter.z)
        camera.position = centeredPosition
        camera.look(at: mazeCenter, from: centeredPosition, relativeTo: nil)
        
        print("📷 Adaptive camera created at position: \(centeredPosition)")
        return camera
    }
    
    // MARK: - Game Loop and Updates
    
    /// Update the game coordinator (called from main game loop)
    func updateCoordinator(deltaTime: TimeInterval) {
        guard isRunning else { return }
        
        // Update ball position in ECS
        updateBallPosition()
        
        // Sync game state with ECS systems
        syncGameStateWithECS()
        
        // Check cat-player collision (considering shield effect)
        checkCatPlayerCollision()
        
        // Update ECS world (includes collectible system)
        ecsWorld.update(deltaTime: deltaTime)
        
        // Update services
        gameService.updateGameState()
        
        // Check enhanced win condition with collectibles
        checkEnhancedWinCondition()
        
        // Update performance metrics
        updatePerformanceMetrics()
    }
    
    /// Enhanced win condition check including collectibles
    private func checkEnhancedWinCondition() {
        guard let ballEntity = currentScene?.children.first(where: { $0.name == "MazeWorld" })?.children.first(where: { $0.name == "MazeBall" }) else { return }
        
        // Check if near exit
        let nearExit = mazeService.isNearExit(ballEntity.position, threshold: 1.35)
        
        // Check if player has required keys
        let hasRequiredKeys = canPlayerExit()
        
        if nearExit && hasRequiredKeys && gameService.gameState == .playing {
            gameService.setGameState(.completed)
            print("🎉 Game completed with collectibles! Keys collected: \(collectionProgress.keys)/\(collectionProgress.requiredKeys)")
        } else if nearExit && !hasRequiredKeys {
            print("🔒 Player at exit but missing keys: \(collectionProgress.keys)/\(collectionProgress.requiredKeys)")
        }
    }
    
    /// Reset the game with adaptive positioning and collectibles
    func resetGame() {
        gameService.resetGame()
        
        // Reset AI timing for spawn delay
        if let aiSystem = ecsWorld.getSystem(AISystem.self) {
            aiSystem.resetGameTiming()
        }
        
        // Reset collectible progress
        collectionProgress = CollectionProgress(totalItems: 0, collectedItems: 0, keys: 0, requiredKeys: requiredKeysForExit)
        playerEffects = "None"
        canPlayerExitMaze = true
        
        // Reset positions if scene exists
        if let scene = currentScene {
            resetAdaptiveEntityPositions(in: scene)
        }
        
        // Clear path visualization
        pathfindingService.clearPathVisualization()
        
        print("🔄 Enhanced game reset with collectibles and timing restart")
    }
    
    private func resetAdaptiveEntityPositions(in scene: Entity) {
        // Reset ball and cat positions with adaptive spacing
        scene.children.forEach { child in
            if child.name == "MazeWorld" {
                child.children.forEach { grandChild in
                    if grandChild.name == "MazeBall" {
                        grandChild.position = mazeService.getStartPosition()
                        
                        // Reset player status
                        if let ballEntityId = ballEntityId {
                            let resetPlayerStatus = PlayerStatusComponent(entityId: ballEntityId)
                            ecsWorld.componentManager.addComponent(resetPlayerStatus, to: ballEntityId)
                        }
                        
                    } else if grandChild.name == "CatAgent" {
                        let ballStartPosition = mazeService.getStartPosition()
                        let offsetDistance = gameConfiguration.maze.cellSize * 2.0
                        let catStartPosition = ballStartPosition + SIMD3<Float>(offsetDistance, 0, offsetDistance)
                        grandChild.position = catStartPosition
                        
                        // Update cat's transform component and restart sleep
                        if let catEntityId = catEntityId,
                           var catTransform = ecsWorld.componentManager.getComponent(TransformComponent.self, for: catEntityId),
                           var catAI = ecsWorld.componentManager.getComponent(AIAgentComponent.self, for: catEntityId),
                           var catPathfinding = ecsWorld.componentManager.getComponent(PathfindingComponent.self, for: catEntityId) {
                            
                            catTransform.position = catStartPosition
                            catAI.startSleep() // Restart sleep when resetting
                            
                            // Clear current pathfinding state
                            catPathfinding.currentPath = []
                            catPathfinding.currentPathIndex = 0
                            catPathfinding.isFollowingPath = false
                            
                            ecsWorld.componentManager.addComponent(catTransform, to: catEntityId)
                            ecsWorld.componentManager.addComponent(catAI, to: catEntityId)
                            ecsWorld.componentManager.addComponent(catPathfinding, to: catEntityId)
                        }
                        
                    } else if grandChild.name.contains("Collectible") {
                        // Reset collectibles to uncollected state
                        grandChild.isEnabled = true
                        
                        // Reset collectible component
                        if let collectibleId = collectibleEntities.first(where: { $0.0 == grandChild })?.1,
                           var collectibleComponent = ecsWorld.componentManager.getComponent(CollectibleComponent.self, for: collectibleId) {
                            collectibleComponent.isCollected = false
                            ecsWorld.componentManager.addComponent(collectibleComponent, to: collectibleId)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleGameStateChange(_ gameState: GameState) {
        switch gameState {
        case .playing:
            systemStatus = .running
            // Reset AI timing when game starts
            if let aiSystem = ecsWorld.getSystem(AISystem.self) {
                aiSystem.resetGameTiming()
            }
        case .paused:
            systemStatus = .paused
        case .completed:
            systemStatus = .completed
            handleGameCompleted()
        case .failed:
            systemStatus = .failed
            handleGameFailed()
        case .menu:
            systemStatus = .ready
        }
    }
    
    private func handleInputChange(_ tiltData: TiltData) {
        // Apply input to ball, considering speed boost effect
        guard let ballEntity = currentScene?.children.first(where: { $0.name == "MazeWorld" })?.children.first(where: { $0.name == "MazeBall" }) else { return }
        
        var modifiedTiltData = tiltData
        
        // Check for speed boost effect
        if let playerStatus = getPlayerStatus(), playerStatus.hasSpeedBoost {
            // Increase tilt sensitivity for speed boost
            modifiedTiltData = TiltData(
                roll: tiltData.roll * 1.5,
                pitch: tiltData.pitch * 1.5,
                timestamp: tiltData.timestamp
            )
        }
        
        physicsService.applyTiltToBall(ballEntity, tiltData: modifiedTiltData)
    }
    
    private func handleMazeChange() {
        // Clear pathfinding cache and visualization when maze changes
        pathfindingService.clearPathCache()
        pathfindingService.clearPathVisualization()
        
        // Clear collectibles
        clearCollectibles()
        
        print("🔄 Maze changed - pathfinding cache, visualization, and collectibles cleared")
    }
    
    private func handleGameCompleted() {
        pathfindingService.clearPathVisualization()
        
        let finalProgress = getCollectionProgress()
        print("🎉 Game completed with collectibles - coordinator handling")
        print("   Final Collection: \(finalProgress.collectedItems)/\(finalProgress.totalItems)")
        print("   Keys Found: \(finalProgress.keys)/\(finalProgress.requiredKeys)")
        print("   Completion: \(Int(finalProgress.completionPercentage * 100))%")
    }
    
    private func handleGameFailed() {
        pathfindingService.clearPathVisualization()
        print("💥 Game failed - coordinator handling")
    }
    
    // MARK: - Physics and Collision Setup
    
    private func setupMazePhysics(entities: [Entity]) {
        for entity in entities {
            if entity.name.contains("Wall") {
                if let modelComponent = entity.components[ModelComponent.self] {
                    let boundingBox = modelComponent.mesh.bounds
                    let size = boundingBox.max - boundingBox.min
                    physicsService.setupWallPhysics(for: entity, size: size)
                }
            } else if entity.name.contains("Floor") {
                if let modelComponent = entity.components[ModelComponent.self] {
                    let boundingBox = modelComponent.mesh.bounds
                    let size = boundingBox.max - boundingBox.min
                    physicsService.setupFloorPhysics(for: entity, size: size)
                }
            }
        }
    }
    
    /// Update ball position in ECS for AI tracking
    private func updateBallPosition() {
        guard let ballEntityId = ballEntityId,
              let ballEntity = currentScene?.children.first(where: { $0.name == "MazeWorld" })?.children.first(where: { $0.name == "MazeBall" }) else { return }
        
        // Update ball's transform component with current position
        if var ballTransform = ecsWorld.componentManager.getComponent(TransformComponent.self, for: ballEntityId) {
            ballTransform.position = ballEntity.position
            ballTransform.rotation = ballEntity.transform.rotation
            ecsWorld.componentManager.addComponent(ballTransform, to: ballEntityId)
        }
    }
    
    /// Check if cat has caught the player (considering shield effect)
    private func checkCatPlayerCollision() {
        guard let catEntityId = catEntityId,
              let ballEntityId = ballEntityId,
              let aiSystem = ecsWorld.getSystem(AISystem.self) else { return }
        
        // Check if player has shield protection
        if let playerStatus = getPlayerStatus(), playerStatus.hasShield {
            print("🛡️ Player protected by shield - cat collision ignored")
            return
        }
        
        if aiSystem.checkCatPlayerCollision(catEntityId: catEntityId, playerEntityId: ballEntityId) {
            // Cat caught the player - game over
            gameService.setGameState(.failed)
            print("🐱 Cat caught the unprotected player! Game Over!")
        }
    }
    
    private func syncGameStateWithECS() {
        // Update GameLogicSystem with current game state
        if let gameLogicSystem = ecsWorld.getSystem(GameLogicSystem.self) {
            gameLogicSystem.setGameState(gameService.gameState)
        }
    }
    
    private func updatePerformanceMetrics() {
        // Update performance metrics including adaptive info
        updateAdaptiveInfo()
    }
    
    // MARK: - Service Access
    
    func getInputService() -> InputService { return inputService }
    func getPhysicsService() -> PhysicsService { return physicsService }
    func getMazeService() -> MazeService { return mazeService }
    func getGameService() -> GameService { return gameService }
    func getCameraService() -> CameraService { return cameraService }
    func getPathfindingService() -> PathfindingService { return pathfindingService }
    func getScreenAdaptiveService() -> ScreenAdaptiveService { return screenAdaptiveService }
    func getEntityFactory() -> EntityFactory { return entityFactory }
    func getECSWorld() -> ECSWorld { return ecsWorld }
    
    // MARK: - Configuration
    
    func updateConfiguration(_ newConfiguration: GameConfiguration) {
        gameConfiguration = newConfiguration
        currentMazeSize = SIMD2<Int>(newConfiguration.maze.width, newConfiguration.maze.height)
        print("⚙️ Game configuration updated to: \(newConfiguration.maze.width)x\(newConfiguration.maze.height)")
    }
    
    func getConfiguration() -> GameConfiguration {
        return gameConfiguration
    }
    
    /// Get current adaptive configuration
    func getAdaptiveConfiguration() -> GameConfiguration {
        return screenAdaptiveService.getAdaptiveGameConfiguration()
    }
    
    // MARK: - Debug Methods
    
    func getSystemStatus() -> SystemStatusInfo {
        return SystemStatusInfo(
            coordinatorStatus: systemStatus,
            isInitialized: isInitialized,
            isRunning: isRunning,
            ecsSystemsCount: 6, // Updated for collectible system
            activeEntitiesCount: currentScene?.children.count ?? 0,
            gameState: gameService.gameState
        )
    }
    
    func getAdaptiveDebugInfo() -> String {
        var info = "=== Enhanced Coordinator Debug ===\n"
        info += "Status: \(systemStatus.description)\n"
        info += "Running: \(isRunning)\n"
        info += "Current Maze: \(currentMazeSize.x)x\(currentMazeSize.y)\n"
        info += "Collectibles: \(collectibleEntities.count)\n"
        info += "Collection Progress: \(collectionProgress.description)\n"
        info += "Player Effects: \(playerEffects)\n"
        info += "Can Exit: \(canPlayerExitMaze)\n"
        
        // Screen adaptive debug info
        info += "\n" + screenAdaptiveService.getScreenDebugInfo()
        
        // AI System debug info
        if let aiSystem = ecsWorld.getSystem(AISystem.self) {
            info += "\n" + aiSystem.getAIDebugInfo()
        }
        
        // Pathfinding debug info
        info += "\n" + pathfindingService.getNavigationDebugInfo()
        
        // Collectible system debug info
        if let collectibleSystem = getCollectibleSystem() {
            info += "\n" + collectibleSystem.getCollectibleDebugInfo()
        }
        
        return info
    }
    
    // MARK: - Public Control Methods
    
    func startCoordinator() {
        guard isInitialized else {
            print("⚠️ Cannot start coordinator: Not initialized")
            return
        }
        
        systemStatus = .running
        isRunning = true
        
        // Start services
        inputService.startMonitoring()
        
        // Reset AI timing for new game
        if let aiSystem = ecsWorld.getSystem(AISystem.self) {
            aiSystem.resetGameTiming()
        }
        
        print("🚀 Enhanced GameCoordinator with collectibles started")
    }
    
    func stopCoordinator() {
        systemStatus = .stopping
        isRunning = false
        
        // Stop services
        inputService.stopMonitoring()
        
        // Clear audio when stopping coordinator
        clearMazeWorldGameAudio()
        
        // Clear pathfinding visualization and cache
        pathfindingService.clearPathVisualization()
        pathfindingService.clearPathCache()
        
        // Clear collectibles
        clearCollectibles()
        
        // Shutdown ECS
        ecsWorld.shutdown()
        
        systemStatus = .idle
        print("🛑 Enhanced GameCoordinator with collectibles stopped")
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopCoordinator()
        cancellables.removeAll()
        print("🧹 Enhanced GameCoordinator with collectibles deallocated")
    }
}
