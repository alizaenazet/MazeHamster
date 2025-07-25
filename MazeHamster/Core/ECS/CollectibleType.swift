//
//  CollectibleType.swift
//  MazeBall
//
//  Maze Feature: Collectible Items System
//

import Foundation
import RealityKit
import simd
import SwiftUI // Diperlukan untuk UIColor, atau ganti dengan import lain jika menggunakan warna kustom

// MARK: - Collectible Types

enum CollectibleType: CaseIterable {
    case coin           // Basic points
    case shield         // Temporary cat protection
    case fish           // Make cat faster (debuff for player)
    case pillow         // Stun the cat
    case bubbleGum      // Slow down the hamster
    
    var points: Int {
        switch self {
        case .coin: return 10
        case .shield, .fish, .pillow, .bubbleGum: return 0 // Item efek tidak memberi poin langsung
        }
    }
    
    var color: UIColor {
        switch self {
        case .coin: return .systemYellow
        case .shield: return .systemGreen
        case .fish: return .systemRed
        case .pillow: return .systemBlue
        case .bubbleGum: return .systemPink // Menggunakan pink untuk bubble gum
        }
    }
    
    var effectDuration: TimeInterval {
        switch self {
        case .coin: return 0 // Koin tidak punya durasi efek
        case .shield: return 5.0
        case .fish: return 4.5
        case .pillow: return 2.8 // Durasi stun 4 detik (menggunakan durasi pillow dari diskusi sebelumnya)
        case .bubbleGum: return 3.5 // Durasi lambat 3.5 detik
        }
    }
    
    var rarity: Float {
        switch self {
        case .coin: return 0.7      // Common (disesuaikan agar item efek lebih sering muncul)
        case .shield: return 0.2   // Uncommon
        case .fish: return 0.1    // Rare (debuff)
        case .pillow: return 0.1   // Uncommon (menggunakan rarity pillow dari diskusi sebelumnya)
        case .bubbleGum: return 0.4 // Uncommon (menggunakan rarity bubble gum dari diskusi sebelumnya)
        }
    }
}

// MARK: - Collectible Component

struct CollectibleComponent: GameComponent {
    let entityId: UUID
    let collectibleType: CollectibleType
    var isCollected: Bool = false
    var pulseAnimation: Float = 0.0
    var rotationSpeed: Float = 2.0
    
    init(entityId: UUID, type: CollectibleType) {
        self.entityId = entityId
        self.collectibleType = type
    }
}

// MARK: - Player Status Component (Hamster)

struct PlayerStatusComponent: GameComponent {
    let entityId: UUID
    var hasSpeedBoost: Bool = false
    var hasShield: Bool = false
    var isSlowMotion: Bool = false
    var collectedKeys: Int = 0 // Tetap ada, bisa untuk skor/statistik, tapi bukan untuk keluar maze
    var totalCollectibles: Int = 0 // Total item yang sudah terkumpul
    
    // Effect timers
    var speedBoostEndTime: Date?
    var shieldEndTime: Date?
    var slowMotionEndTime: Date?
    
    init(entityId: UUID) {
        self.entityId = entityId
    }
    
    mutating func updateEffects() {
        let now = Date()
        
        if let endTime = speedBoostEndTime, now > endTime {
            hasSpeedBoost = false
            speedBoostEndTime = nil
        }
        
        if let endTime = shieldEndTime, now > endTime {
            hasShield = false
            shieldEndTime = nil
        }
        
        if let endTime = slowMotionEndTime, now > endTime {
            isSlowMotion = false
            slowMotionEndTime = nil
        }
    }
    
    var activeEffectsDescription: String {
        var effects: [String] = []
        if hasSpeedBoost { effects.append("🚀 Speed Boost") }
        if hasShield { effects.append("🛡️ Shield") }
        if isSlowMotion { effects.append("🐌 Slow Motion") }
        
        return effects.isEmpty ? "None" : effects.joined(separator: ", ")
    }
}

// MARK: - Cat Status Component

struct CatStatusComponent: GameComponent {
    let entityId: UUID
    var isStunned: Bool = false
    var isSpeedBoosted: Bool = false
    var speedMultiplier: Float = 1.0
    
    var stunEndTime: Date?
    var speedBoostEndTime: Date?
    
    init(entityId: UUID) {
        self.entityId = entityId
    }
    
    mutating func updateEffects() {
        let now = Date()
        
        if let endTime = stunEndTime, now > endTime {
            isStunned = false
            stunEndTime = nil
        }
        
        if let endTime = speedBoostEndTime, now > endTime {
            isSpeedBoosted = false
            speedBoostEndTime = nil
            speedMultiplier = 1.0 // Reset multiplier saat efek berakhir
        }
    }
}

// MARK: - Collectible System

class CollectibleSystem: GameSystem {
    let componentManager: ComponentManager
    private var realityEntities: [UUID: Entity] = [:]
    private weak var gameService: GameService?
    private weak var mazeService: MazeService?
    
    private var requiredKeysForExit: Int = 0
    private let soundPlayer: SoundPlayer // NEW: Properti soundPlayer
    
    // PERBAIKI: Inisialisasi harus menerima soundPlayer
    init(componentManager: ComponentManager, soundPlayer: SoundPlayer, gameService: GameService, mazeService: MazeService) {
           self.componentManager = componentManager
           self.soundPlayer = soundPlayer
           self.gameService = gameService // Inisialisasi gameService
           self.mazeService = mazeService // Inisialisasi mazeService
       }
    
    func initialize() {
        print("✨ CollectibleSystem initialized")
    }
    
    func update(deltaTime: TimeInterval) {
        updateCollectibleAnimations(deltaTime: deltaTime)
        updatePlayerEffects()
        updateCatEffects()
        checkCollisions()
    }
    
    func shutdown() {
        realityEntities.removeAll()
        print("✨ CollectibleSystem shut down")
    }
    
    // MARK: - Animation Updates
    
    private func updateCollectibleAnimations(deltaTime: TimeInterval) {
        let collectibleEntities = componentManager.getAllEntitiesWithComponent(CollectibleComponent.self)
        
        for entityId in collectibleEntities {
            guard var collectible = componentManager.getComponent(CollectibleComponent.self, for: entityId),
                  !collectible.isCollected,
                  let realityEntity = realityEntities[entityId] else { continue }
            
            // Update pulse animation
            collectible.pulseAnimation += Float(deltaTime) * 3.0
            let pulseScale = 1.0 + sin(collectible.pulseAnimation) * 0.2
            
            // Update rotation
            let rotationAmount = Float(deltaTime) * collectible.rotationSpeed
            let currentRotation = realityEntity.transform.rotation
            let additionalRotation = simd_quatf(angle: rotationAmount, axis: [0, 1, 0])
            realityEntity.transform.rotation = currentRotation * additionalRotation
            
            // Apply pulse scaling
            realityEntity.transform.scale = SIMD3<Float>(pulseScale, pulseScale, pulseScale)
            
            // Update component
            componentManager.addComponent(collectible, to: entityId)
        }
    }
    
    private func updatePlayerEffects() {
        // Cari ID entitas pemain menggunakan GameEntityComponent
        guard let playerId = (componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
            .first { componentManager.getComponent(GameEntityComponent.self, for: $0)?.entityType == .ball }),
            var playerStatus = componentManager.getComponent(PlayerStatusComponent.self, for: playerId) else { return }
        
        playerStatus.updateEffects()
        componentManager.addComponent(playerStatus, to: playerId)
    }
    
    private func updateCatEffects() {
        // Cari ID entitas kucing menggunakan GameEntityComponent
        guard let catId = (componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
            .first { componentManager.getComponent(GameEntityComponent.self, for: $0)?.entityType == .cat }),
            var catStatus = componentManager.getComponent(CatStatusComponent.self, for: catId) else { return }
        
        catStatus.updateEffects()
        componentManager.addComponent(catStatus, to: catId)
    }
    
    // MARK: - Collision Detection
    
    private func checkCollisions() {
        let ballEntities = componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
            .filter { entityId in
                guard let gameEntity = componentManager.getComponent(GameEntityComponent.self, for: entityId) else { return false }
                return gameEntity.entityType == .ball
            }
        
        let catEntities = componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
            .filter { entityId in
                guard let gameEntity = componentManager.getComponent(GameEntityComponent.self, for: entityId) else { return false }
                return gameEntity.entityType == .cat
            }

        let collectibleEntities = componentManager.getAllEntitiesWithComponent(CollectibleComponent.self)
            .filter { entityId in
                guard let collectible = componentManager.getComponent(CollectibleComponent.self, for: entityId) else { return false }
                return !collectible.isCollected
            }
        
        
        
        for ballId in ballEntities {
            for collectibleId in collectibleEntities {
                if checkCollision(ballId: ballId, collectibleId: collectibleId) {
                    collectItem(ballId: ballId, collectibleId: collectibleId)
                }
            }
        }
    }
    
    private func checkCollision(ballId: UUID, collectibleId: UUID) -> Bool {
        guard let ballTransform = componentManager.getComponent(TransformComponent.self, for: ballId),
              let collectibleTransform = componentManager.getComponent(TransformComponent.self, for: collectibleId) else { return false }
        
        let distance = simd_distance(ballTransform.position, collectibleTransform.position)
        return distance < 0.5 // Collision threshold
    }
    
    // MARK: - Item Collection
    
    private func collectItem(ballId: UUID, collectibleId: UUID) {
        guard var collectible = componentManager.getComponent(CollectibleComponent.self, for: collectibleId),
              let realityEntity = realityEntities[collectibleId] else { return }
        
        // Get or create player status component
        var playerStatus: PlayerStatusComponent
        if let existingStatus = componentManager.getComponent(PlayerStatusComponent.self, for: ballId) {
            playerStatus = existingStatus
        } else {
            playerStatus = PlayerStatusComponent(entityId: ballId)
        }
        
        // Mark as collected
        collectible.isCollected = true
        componentManager.addComponent(collectible, to: collectibleId)
        
        print("collecting coy", collectible.collectibleType)
        
        let now = Date()
        switch collectible.collectibleType {
        case .coin:
            playerStatus.totalCollectibles += 1
            gameService?.addPoints(collectible.collectibleType.points)
            soundPlayer.playSound(named: "sfx_kuaci_collect") // Memainkan SFX
            print("✨ Collected \(collectible.collectibleType): +\(collectible.collectibleType.points) points")
        case .shield:
            playerStatus.hasShield = true
            playerStatus.shieldEndTime = now.addingTimeInterval(collectible.collectibleType.effectDuration)
            soundPlayer.playSound(named: "sfx_shield_collect") // Memainkan SFX
            print("🛡️ Shield collected! Player has shield for \(collectible.collectibleType.effectDuration) seconds!")
        case .fish:
            // Temukan entitas kucing dan terapkan efek kepadanya
            if let catId = (componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
                .first { componentManager.getComponent(GameEntityComponent.self, for: $0)?.entityType == .cat }),
               var catStatus = componentManager.getComponent(CatStatusComponent.self, for: catId) {
                
                catStatus.isSpeedBoosted = true
                catStatus.speedMultiplier = 1.5 // Contoh: Kucing 1.5x lebih cepat
                catStatus.speedBoostEndTime = now.addingTimeInterval(collectible.collectibleType.effectDuration)
                
                componentManager.addComponent(catStatus, to: catId)
                soundPlayer.playSound(named: "sfx_fish_collect") // Memainkan SFX
                print("🐟 Fish collected! Cat is now faster for \(collectible.collectibleType.effectDuration) seconds!")
            } else {
                print("⚠️ Fish collected, but cat entity or CatStatusComponent not found for effect.")
            }
        case .pillow:
            if let catId = (componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
                .first { componentManager.getComponent(GameEntityComponent.self, for: $0)?.entityType == .cat }),
               var catStatus = componentManager.getComponent(CatStatusComponent.self, for: catId) {
                
                catStatus.isStunned = true
                catStatus.stunEndTime = now.addingTimeInterval(collectible.collectibleType.effectDuration)
                
                componentManager.addComponent(catStatus, to: catId)
                soundPlayer.playSound(named: "sfx_pillow_collect") // Memainkan SFX
                print("😴 Pillow collected! Cat is stunned for \(collectible.collectibleType.effectDuration) seconds!")
            } else {
                print("⚠️ Pillow collected, but cat entity or CatStatusComponent not found for effect.")
            }
        case .bubbleGum:
            playerStatus.isSlowMotion = true
            playerStatus.slowMotionEndTime = now.addingTimeInterval(collectible.collectibleType.effectDuration)
            soundPlayer.playSound(named: "sfx_bubblegum_collect") // Memainkan SFX
            print("🐌 Bubble Gum collected! Player is slowed for \(collectible.collectibleType.effectDuration) seconds!")
        }
        
        // Simpan kembali PlayerStatusComponent setelah dimodifikasi
        componentManager.addComponent(playerStatus, to: ballId)
        
        playCollectionEffect(for: collectible.collectibleType, at: realityEntity.position)
        
        // Hide the collectible
        realityEntity.isEnabled = false
    }
    
    private func playCollectionEffect(for type: CollectibleType, at position: SIMD3<Float>) {
        // Ini adalah placeholder untuk efek partikel atau visual lainnya
        print("✨ Collection effect for \(type) at \(position)")
    }
    
    // MARK: - Public Methods
    
    func registerEntity(_ entity: Entity, with entityId: UUID) {
        realityEntities[entityId] = entity
    }
    
    func setGameService(_ service: GameService) {
        gameService = service
    }
    
    // setCatEntityId dan setPlayerEntityId dihapus dari CollectibleSystem
    // karena ID entitas sekarang dicari langsung dari componentManager di metode update/collect.
    // Ini membuat CollectibleSystem lebih mandiri.
    
    func setRequiredKeys(_ count: Int) {
        // Karena kunci dihilangkan, requiredKeysForExit tidak lagi digunakan untuk keluar maze.
        // Properti ini bisa dipertahankan jika Anda ingin melacaknya untuk tujuan lain (misal, skor).
        requiredKeysForExit = count
    }
    
    func getPlayerStatus(for playerId: UUID) -> PlayerStatusComponent? {
        return componentManager.getComponent(PlayerStatusComponent.self, for: playerId)
    }
    
    func getCatStatus(for catId: UUID) -> CatStatusComponent? {
        return componentManager.getComponent(CatStatusComponent.self, for: catId)
    }
    
    // Metode ini tidak lagi relevan jika kunci tidak digunakan untuk keluar maze
    func canPlayerExit(playerId: UUID) -> Bool {
        // Karena kunci dihilangkan, kondisi keluar maze tidak lagi tergantung pada ini.
        // Logika "apakah pemain bisa keluar" sekarang harus di GameCoordinator atau GameLogicSystem
        // berdasarkan apakah pemain sudah mencapai pintu keluar.
        return true // Default: pemain selalu bisa keluar jika mencapai pintu keluar.
    }
    
    func getCollectionProgress(for playerId: UUID) -> CollectionProgress {
        guard let playerStatus = getPlayerStatus(for: playerId) else {
            return CollectionProgress(totalItems: 0, collectedItems: 0, keys: 0, requiredKeys: 0) // requiredKeys jadi 0
        }
        
        let totalCollectibles = componentManager.getAllEntitiesWithComponent(CollectibleComponent.self).count
        let collectedCount = componentManager.getAllEntitiesWithComponent(CollectibleComponent.self)
            .compactMap { componentManager.getComponent(CollectibleComponent.self, for: $0) }
            .filter { $0.isCollected }
            .count
        
        return CollectionProgress(
            totalItems: totalCollectibles,
            collectedItems: collectedCount,
            keys: playerStatus.collectedKeys, // collectedKeys masih dihitung
            requiredKeys: 0 // Karena kunci dihilangkan, requiredKeys menjadi 0
        )
    }
    
    // MARK: - Debug Methods
    
    func getCollectibleDebugInfo() -> String {
        let collectibleEntities = componentManager.getAllEntitiesWithComponent(CollectibleComponent.self)
        let collected = collectibleEntities.compactMap { componentManager.getComponent(CollectibleComponent.self, for: $0) }
            .filter { $0.isCollected }.count
        
        var info = "=== Collectible System Debug ===\n"
        info += "Total Collectibles: \(collectibleEntities.count)\n"
        info += "Collected: \(collected)\n"
        info += "Required Keys (N/A): 0\n" // Menandai tidak relevan karena kunci dihilangkan
        
        // Debug info untuk player status (menggunakan lookup langsung)
        if let playerId = (componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
            .first { componentManager.getComponent(GameEntityComponent.self, for: $0)?.entityType == .ball }),
           let playerStatus = getPlayerStatus(for: playerId) {
            info += "Player Effects: \(playerStatus.activeEffectsDescription)\n"
        }
        
        // Debug info untuk cat status (menggunakan lookup langsung)
        if let catId = (componentManager.getAllEntitiesWithComponent(GameEntityComponent.self)
            .first { componentManager.getComponent(GameEntityComponent.self, for: $0)?.entityType == .cat }),
           let catStatus = getCatStatus(for: catId) {
            info += "Cat Speed Boosted: \(catStatus.isSpeedBoosted) (Multiplier: \(catStatus.speedMultiplier))\n"
            info += "Cat Is Stunned: \(catStatus.isStunned)\n"
        }
        
        return info
    }
}

// MARK: - Collection Progress (Disesuaikan karena kunci dihilangkan)

struct CollectionProgress {
    let totalItems: Int
    let collectedItems: Int
    let keys: Int // Masih bisa dipertahankan untuk skor/statistik
    let requiredKeys: Int // Sekarang akan selalu 0
    
    var completionPercentage: Float {
        guard totalItems > 0 else { return 0 }
        return Float(collectedItems) / Float(totalItems)
    }
    
    var canExit: Bool {
        // Kondisi keluar tidak lagi bergantung pada kunci
        // Logika ini harus ditangani di GameCoordinator atau GameLogicSystem (misal: hanya mencapai pintu keluar)
        return true
    }
    
    var description: String {
        // Hapus referensi kunci dari deskripsi jika tidak lagi relevan
        return "Collected: \(collectedItems)/\(totalItems)"
    }
}

// MARK: - Entity Factory Extension

extension EntityFactory {
    
    /// Create a collectible item entity with ECS components
    func createCollectible(
            type: CollectibleType,
            at position: SIMD3<Float>,
            componentManager: ComponentManager
        ) -> (Entity, UUID) {
            let collectible = Entity()
            let entityId = UUID()
            collectible.name = "Collectible_\(type)_\(entityId)"
            
            // OLD: Create visual representation based on type using MeshResource.generate...
            // NEW: Load visual representation from 3D asset
            
            let loadedModel: Entity // Ini akan menjadi entitas model yang dimuat
            let collisionShapeSize: Float // Ukuran untuk komponen collision, mungkin beda dengan visual model
            
            switch type {
            case .coin:
                // Mengganti MeshResource.generateSphere dengan memuat model 3D "Sunflower_SeedDemo1"
                do {
                    loadedModel = try Entity.load(named: "Sunflower_SeedDemo1") // PASTIKAN NAMA INI SAMA PERSIS DENGAN NAMA ASET DI XCODE ANDA
                    // Sesuaikan skala model jika diperlukan agar ukurannya pas di game
                    loadedModel.scale = SIMD3<Float>(0.4, 0.4, 0.4) // Contoh skala, sesuaikan
                    loadedModel.transform.rotation = simd_quatf(angle: .pi / 1, axis: [0.4, 0, 0])
                    collisionShapeSize = 0.2 // Ukuran collision yang lebih kecil untuk "kuaci"
                } catch {
                    fatalError("Failed to load Sunflower_SeedDemo1.usdz: \(error.localizedDescription)")
                }
            case .shield:
                // Untuk shield, jika belum ada model 3D, pertahankan geometri generik atau tambahkan model baru
                // Jika ada model 3D shield, ganti baris ini:
                let size: Float = 0.3
                let geometry = MeshResource.generateSphere(radius: size * 0.6)
                let material = SimpleMaterial(color: type.color, isMetallic: false)
                loadedModel = Entity()
                loadedModel.components.set(ModelComponent(mesh: geometry, materials: [material]))
                collisionShapeSize = size * 0.6
                // Jika Anda punya model 3D shield, akan jadi seperti case .coin di atas.

            case .fish:
                // Mengganti MeshResource.generateSphere dengan memuat model 3D "FishDemo"
                do {
                    loadedModel = try Entity.load(named: "FishDemo") // PASTIKAN NAMA INI SAMA PERSIS
                    loadedModel.scale = SIMD3<Float>(0.2, 0.2, 0.2) // Contoh skala, sesuaikan
                    loadedModel.transform.rotation = simd_quatf(angle: .pi / 1, axis: [0.4, 0, 0])
                    collisionShapeSize = 0.2 // Sesuaikan ukuran collision untuk "ikan"
                } catch {
                    fatalError("Failed to load FishDemo.usdz: \(error.localizedDescription)")
                }
            case .pillow:
                // Mengganti MeshResource.generateBox dengan memuat model 3D "PillowDemo"
                do {
                    loadedModel = try Entity.load(named: "PillowDemo") // PASTIKAN NAMA INI SAMA PERSIS
                    loadedModel.scale = SIMD3<Float>(0.15, 0.15, 0.15) // Contoh skala, sesuaikan
                    collisionShapeSize = 0.3 // Sesuaikan ukuran collision untuk "bantal"
                } catch {
                    fatalError("Failed to load PillowDemo.usdz: \(error.localizedDescription)")
                }
            case .bubbleGum:
                // Untuk bubble gum, jika belum ada model 3D, pertahankan geometri generik atau tambahkan model baru
                // Jika ada model 3D bubble gum, ganti baris ini:
                let size: Float = 0.3
                let geometry = MeshResource.generateSphere(radius: size * 0.4)
                let material = SimpleMaterial(color: type.color, isMetallic: false)
                loadedModel = Entity()
                loadedModel.components.set(ModelComponent(mesh: geometry, materials: [material]))
                collisionShapeSize = size * 0.4
                // Jika Anda punya model 3D bubble gum, akan jadi seperti case .coin di atas.
            }
            
            // NEW: Tambahkan loadedModel sebagai child dari collectible entity utama
            collectible.addChild(loadedModel)
            
            // OLD: Kode ini dihapus karena ModelComponent dan Material sudah diatur di loadedModel
            // collectible.components.set(ModelComponent(mesh: geometry, materials: [material]))
            
            // Set position
            collectible.position = position
            
            // Add ECS components
            let transformComponent = TransformComponent(
                entityId: entityId,
                position: position,
                rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                scale: SIMD3<Float>(1, 1, 1) // Skala utama collectible entity tetap 1, skala model disesuaikan di atas
            )
            componentManager.addComponent(transformComponent, to: entityId)
            
            let collectibleComponent = CollectibleComponent(entityId: entityId, type: type)
            componentManager.addComponent(collectibleComponent, to: entityId)
            
            let gameEntityComponent = GameEntityComponent(
                entityId: entityId,
                entityType: .collectible,
                isActive: true,
                isCollectable: true
            )
            componentManager.addComponent(gameEntityComponent, to: entityId)
            
            // Add collision detection (gunakan ukuran dari collisionShapeSize)
            let collision = CollisionComponent(shapes: [.generateSphere(radius: collisionShapeSize)])
            collectible.components.set(collision)
            
            print("✨ Created \(type) collectible at \(position)")
            return (collectible, entityId)
        }
    
    /// Create multiple collectibles distributed throughout the maze
    func createMazeCollectibles(
        mazeService: MazeService,
        componentManager: ComponentManager
    ) -> [(Entity, UUID)] {
        var collectibles: [(Entity, UUID)] = []
        let maze = mazeService.maze
        
        // Calculate number of collectibles based on maze size
        let mazeArea = maze.configuration.width * maze.configuration.height
        let baseCollectibles = max(3, mazeArea / 8) // At least 3, or 1 per 8 cells
        
        var collectibleCounts: [CollectibleType: Int] = [:]
        
        // Distribute collectibles by rarity
        for type in CollectibleType.allCases {
            // Menggunakan max(0, count) agar item yang sangat langka bisa tidak muncul jika area maze kecil
            // Jika Anda ingin setiap tipe item selalu muncul minimal satu, gunakan max(1, count)
            collectibleCounts[type] = max(0, Int(Float(baseCollectibles) * type.rarity))
        }
        
        // Place collectibles in random empty cells
        var usedPositions: Set<SIMD2<Int>> = []
        usedPositions.insert(maze.startPosition) // Don't place at start
        usedPositions.insert(maze.exitPosition)  // Don't place at exit
        
        for (type, count) in collectibleCounts {
            for _ in 0..<count {
                if let position = findRandomEmptyPosition(in: maze, excluding: usedPositions) {
                    usedPositions.insert(position)
                    // Offset Y ke atas agar item tidak tenggelam di lantai
                    let worldPosition = mazeService.getWorldPosition(for: position).offsetY(0.5)
                    let (entity, id) = createCollectible(type: type, at: worldPosition, componentManager: componentManager)
                    collectibles.append((entity, id))
                }
            }
        }
        
        print("✨ Created \(collectibles.count) collectibles in maze")
        return collectibles
    }
    
    private func findRandomEmptyPosition(in maze: MazeData, excluding used: Set<SIMD2<Int>>) -> SIMD2<Int>? {
        var attempts = 0
        let maxAttempts = 100
        
        while attempts < maxAttempts {
            let x = Int.random(in: 0..<maze.configuration.width)
            let y = Int.random(in: 0..<maze.configuration.height)
            let position = SIMD2<Int>(x, y)
            
            if !used.contains(position) {
                return position
            }
            
            attempts += 1
        }
        
        return nil // Couldn't find empty position
    }
}
