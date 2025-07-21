import Foundation
import RealityKit
import simd

/// Concrete implementation of MazeService for handling maze generation and management
class MazeService: BaseService, MazeServiceProtocol {
    
    // MARK: - Published Properties
    
    @Published var maze: MazeData
    
    // MARK: - Private Properties
    
    private let visualMaterials = VisualMaterials.default
    private let configuration = MazeConfiguration.default
    
    // MARK: - Initialization
    
    override init() {
        // Initialize with default maze
        self.maze = MazeData(
            configuration: MazeConfiguration.default,
            cells: []
        )
        super.init()
    }
    
    // MARK: - Service Setup
    
//    override func setupService() {
//        super.setupService()
//        // Generate initial maze
//        maze = generateMaze(width: configuration.width, height: configuration.height)
//        print("✅ MazeService configured successfully")
//    }
    
    func setupWithConfiguration(_ config: MazeConfiguration) {
        self.maze = generateMaze(width: config.width, height: config.height)
    }

    
    // MARK: - Protocol Methods
    
    func generateMaze(width: Int, height: Int) -> MazeData {
        let config = MazeConfiguration(
            width: width,
            height: height,
            cellSize: configuration.cellSize,
            wallHeight: configuration.wallHeight,
            wallThickness: configuration.wallThickness
        )
        
        let loopCount = max(1, (width * height) / 20)
        print("LOOP COUNT IS: \(loopCount)")
        
        // Use the existing MazeGenerator
        let generator = MazeGenerator(width: width, height: height, extra: loopCount)
        
        // Convert MazeGenerator grid to MazeData format
        let mazeData = MazeData(
            configuration: config,
            cells: generator.grid,
            seed: UInt32.random(in: 0...UInt32.max)
        )
        
        // Update published property
        maze = mazeData
        
        print("🌀 Generated new maze: \(width)x\(height)")
//        generator.addExtraPaths(count: loopCount)
        return mazeData
    }
    
    func createMazeEntities() -> [Entity] {
        var entities: [Entity] = []
        
        // Create floor entity
        let floorEntity = createFloorEntity()
        entities.append(floorEntity)
        
        // Create wall entities
        let wallEntities = createWallEntities()
        entities.append(contentsOf: wallEntities)
        
        // Create exit entity
        let exitEntity = createExitEntity()
        entities.append(exitEntity)
        
        print("🏗️ Created \(entities.count) maze entities")
        return entities
    }
    
    // MARK: - Private Entity Creation Methods
    
    private func createFloorEntity() -> Entity {
        let floorEntity = Entity()
        floorEntity.name = "MazeFloor"
        
        let floorSize = SIMD3<Float>(
            Float(maze.configuration.width) * maze.configuration.cellSize,
            0.1,
            Float(maze.configuration.height) * maze.configuration.cellSize
        )
        
        // Create floor mesh and material
        let floorMesh = MeshResource.generateBox(size: floorSize)
        let floorMaterial = visualMaterials.floor
        
        floorEntity.components.set(ModelComponent(mesh: floorMesh, materials: [floorMaterial]))
        floorEntity.position = maze.centerPosition.offsetY(-0.05)
        
        return floorEntity
    }
    
    private func createWallEntities() -> [Entity] {
        var wallEntities: [Entity] = []
        
        for x in 0..<maze.configuration.width {
            for y in 0..<maze.configuration.height {
                let cell = maze.cells[x][y]
                let cellPosition = maze.worldPosition(for: SIMD2<Int>(x, y))
                
                // Create walls for each side that exists
                if cell.walls.contains(.top) {
                    let wallPosition = cellPosition + SIMD3<Float>(0, 0, -maze.configuration.cellSize * 0.5)
                    let wallSize = SIMD3<Float>(maze.configuration.cellSize, maze.configuration.wallHeight, maze.configuration.wallThickness)
                    let wall = createWallEntity(at: wallPosition, size: wallSize, name: "Wall_\(x)_\(y)_top")
                    wallEntities.append(wall)
                }
                
                if cell.walls.contains(.right) {
                    let wallPosition = cellPosition + SIMD3<Float>(maze.configuration.cellSize * 0.5, 0, 0)
                    let wallSize = SIMD3<Float>(maze.configuration.wallThickness, maze.configuration.wallHeight, maze.configuration.cellSize)
                    let wall = createWallEntity(at: wallPosition, size: wallSize, name: "Wall_\(x)_\(y)_right")
                    wallEntities.append(wall)
                }
                
                if cell.walls.contains(.bottom) {
                    let wallPosition = cellPosition + SIMD3<Float>(0, 0, maze.configuration.cellSize * 0.5)
                    let wallSize = SIMD3<Float>(maze.configuration.cellSize, maze.configuration.wallHeight, maze.configuration.wallThickness)
                    let wall = createWallEntity(at: wallPosition, size: wallSize, name: "Wall_\(x)_\(y)_bottom")
                    wallEntities.append(wall)
                }
                
                if cell.walls.contains(.left) {
                    let wallPosition = cellPosition + SIMD3<Float>(-maze.configuration.cellSize * 0.5, 0, 0)
                    let wallSize = SIMD3<Float>(maze.configuration.wallThickness, maze.configuration.wallHeight, maze.configuration.cellSize)
                    let wall = createWallEntity(at: wallPosition, size: wallSize, name: "Wall_\(x)_\(y)_left")
                    wallEntities.append(wall)
                }
            }
        }
        
        return wallEntities
    }
    
    private func createWallEntity(at position: SIMD3<Float>, size: SIMD3<Float>, name: String) -> Entity {
        let wallEntity = Entity()
        wallEntity.name = name
        
        // Create wall mesh and material
        let wallMesh = MeshResource.generateBox(size: size)
        let wallMaterial = visualMaterials.wall
        
        wallEntity.components.set(ModelComponent(mesh: wallMesh, materials: [wallMaterial]))
        wallEntity.position = position + SIMD3<Float>(0, size.y * 0.5, 0) // Raise wall to sit on floor
        
        return wallEntity
    }
    
    private func createExitEntity() -> Entity {
        let exitEntity = Entity()
        exitEntity.name = "MazeExit"
        
        let exitRadius: Float = 0.3
        let exitMesh = MeshResource.generateSphere(radius: exitRadius)
        let exitMaterial = visualMaterials.exit
        
        exitEntity.components.set(ModelComponent(mesh: exitMesh, materials: [exitMaterial]))
        exitEntity.position = maze.worldPosition(for: maze.exitPosition).offsetY(maze.configuration.wallHeight + 0.5)
        
        return exitEntity
    }
    
    // MARK: - Helper Methods
    
    /// Get world position for a maze cell coordinate
    func getWorldPosition(for cellCoordinate: SIMD2<Int>) -> SIMD3<Float> {
        return maze.worldPosition(for: cellCoordinate)
    }
    
    /// Get cell coordinate for a world position
    func getCellCoordinate(for worldPosition: SIMD3<Float>) -> SIMD2<Int> {
        let x = Int(worldPosition.x / maze.configuration.cellSize)
        let y = Int(worldPosition.z / maze.configuration.cellSize)
        return SIMD2<Int>(
            max(0, min(maze.configuration.width - 1, x)),
            max(0, min(maze.configuration.height - 1, y))
        )
    }
    
    /// Check if a cell has a wall in the specified direction
    func hasWall(at cellCoordinate: SIMD2<Int>, direction: Wall) -> Bool {
        guard cellCoordinate.x >= 0 && cellCoordinate.x < maze.configuration.width &&
              cellCoordinate.y >= 0 && cellCoordinate.y < maze.configuration.height else {
            return true // Out of bounds = wall
        }
        
        let cell = maze.cells[cellCoordinate.x][cellCoordinate.y]
        return cell.walls.contains(direction)
    }
    
    /// Get the start position of the maze
    func getStartPosition() -> SIMD3<Float> {
        return maze.worldPosition(for: maze.startPosition).offsetY(maze.configuration.wallHeight + 0.5)
    }
    
    /// Get the exit position of the maze
    func getExitPosition() -> SIMD3<Float> {
        return maze.worldPosition(for: maze.exitPosition).offsetY(maze.configuration.wallHeight + 0.5)
    }
    
    /// Check if position is near the exit
    func isNearExit(_ position: SIMD3<Float>, threshold: Float = 0.5) -> Bool {
        let exitPos = getExitPosition()
        let distance = simd_distance(position, exitPos)
        return distance < threshold
    }
} 
