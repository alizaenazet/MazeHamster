//
//  PathfindingService.swift
//  MazeHamster
//
//  Created by Darmawan on 16/07/25.
//


import Foundation
import RealityKit
import simd

/// Enhanced service for handling pathfinding and navigation through the maze
class PathfindingService: BaseService {
    
    // MARK: - Private Properties
    
    private var mazeService: MazeService?
    private var pathCache: [String: [SIMD2<Int>]] = [:]
    private var navigationGrid: [[NavigationNode]] = []
    private var pathVisualizationEntities: [Entity] = []
    
    // MARK: - Navigation Node
    
    private struct NavigationNode {
        var position: SIMD2<Int>
        var isWalkable: Bool
        var gScore: Float = Float.infinity
        var fScore: Float = Float.infinity
        var parent: SIMD2<Int>?
        
        init(position: SIMD2<Int>, isWalkable: Bool) {
            self.position = position
            self.isWalkable = isWalkable
        }
    }
    
    // MARK: - Service Setup
    
    override func setupService() {
        super.setupService()
        print("✅ Enhanced PathfindingService configured successfully")
    }
    
    // MARK: - Public Methods
    
    /// Set the maze service for pathfinding
    func setMazeService(_ service: MazeService) {
        mazeService = service
        buildNavigationGrid()
        clearPathCache()
    }
    
    func getGridGraphDatas() {
        guard let mazeGridGraph = mazeService?.gridGraph, let convertedGrid = mazeService?.convertMazeToGridData() else {
            print("Failed convert into GKGrid")
            return
        }
            
        print("mazeGridGraph: 🗺️")
        print(mazeGridGraph)
        
        mazeService?.printMazeASCII()
    }
    
    /// Find path from start position to target position using A* algorithm
    func findPath(from startWorld: SIMD3<Float>, to targetWorld: SIMD3<Float>) -> [SIMD3<Float>] {
        guard let mazeService = mazeService else {
            print("⚠️ PathfindingService: No maze service available")
            return []
        }
        
        // Convert world positions to maze coordinates
        let startCell = worldToGridPosition(startWorld)
        let targetCell = worldToGridPosition(targetWorld)
        
        print("🗺️ Pathfinding from \(startCell) to \(targetCell)")
        
        // Validate positions are within maze bounds
        guard isValidGridPosition(startCell) && isValidGridPosition(targetCell) else {
            print("⚠️ Invalid grid positions: start=\(startCell), target=\(targetCell)")
            return []
        }
        
        // Check cache first
        let cacheKey = "\(startCell.x),\(startCell.y)-\(targetCell.x),\(targetCell.y)"
        if let cachedPath = pathCache[cacheKey] {
            print("📋 Using cached path with \(cachedPath.count) waypoints")
            return convertCellPathToWorldPath(cachedPath)
        }
        
        // Find path using A*
        let cellPath = findPathAStar(from: startCell, to: targetCell)
        
        // Cache the result
        if !cellPath.isEmpty {
            pathCache[cacheKey] = cellPath
            print("💾 Cached new path with \(cellPath.count) waypoints")
        }
        
        // Convert to world coordinates
        let worldPath = convertCellPathToWorldPath(cellPath)
        
        print("🎯 Found path: \(cellPath.count) cells -> \(worldPath.count) world points")
        return worldPath
    }
    
    /// Create visual representation of the path
    func visualizePath(_ path: [SIMD3<Float>], in scene: Entity) {
        clearPathVisualization()
        
        guard path.count > 1 else { return }
        
        for i in 0..<(path.count - 1) {
            let start = path[i]
            let end = path[i + 1]
            
            // Create line segment between waypoints
            let lineEntity = createPathLineSegment(from: start, to: end)
            scene.addChild(lineEntity)
            pathVisualizationEntities.append(lineEntity)
            
            // Create waypoint marker
            let waypointEntity = createWaypointMarker(at: path[i], index: i)
            scene.addChild(waypointEntity)
            pathVisualizationEntities.append(waypointEntity)
        }
        
        // Add final waypoint
        if let lastPoint = path.last {
            let finalWaypoint = createWaypointMarker(at: lastPoint, index: path.count - 1)
            scene.addChild(finalWaypoint)
            pathVisualizationEntities.append(finalWaypoint)
        }
        
        print("👁️ Path visualization created with \(pathVisualizationEntities.count) entities")
    }
    
    /// Clear path visualization
    func clearPathVisualization() {
        for entity in pathVisualizationEntities {
            entity.removeFromParent()
        }
        pathVisualizationEntities.removeAll()
    }
    
    /// Clear the path cache (call when maze changes)
    func clearPathCache() {
        pathCache.removeAll()
        print("🗑️ PathfindingService: Path cache cleared")
    }
    
    // MARK: - Navigation Grid Building
    
    private func buildNavigationGrid() {
        guard let mazeService = mazeService else { 
            print("⚠️ PathfindingService: No maze service in buildNavigationGrid")
            return 
        }
        
        let maze = mazeService.maze
        let width = maze.configuration.width
        let height = maze.configuration.height
        
        // Ensure we don't have empty dimensions
        guard width > 0 && height > 0 else {
            print("⚠️ PathfindingService: Invalid maze dimensions \(width)x\(height)")
            return
        }
        
        // Initialize navigation grid with proper bounds checking
        navigationGrid = Array(repeating: Array(repeating: NavigationNode(position: SIMD2<Int>(0, 0), isWalkable: false), count: height), count: width)
        
        // Mark all cells as walkable initially
        for x in 0..<width {
            for y in 0..<height {
                navigationGrid[x][y] = NavigationNode(position: SIMD2<Int>(x, y), isWalkable: true)
            }
        }
        
        print("🗺️ Navigation grid built successfully: \(width)x\(height)")
        print("🔍 Navigation grid actual size: \(navigationGrid.count)x\(navigationGrid.first?.count ?? 0)")
    }
    
    // MARK: - A* Pathfinding Implementation
    
    private func findPathAStar(from start: SIMD2<Int>, to target: SIMD2<Int>) -> [SIMD2<Int>] {
        guard let mazeService = mazeService else { 
            print("⚠️ PathfindingService: No maze service in findPathAStar")
            return [] 
        }
        
        // Validate start and target positions
        guard isValidGridPosition(start) && isValidGridPosition(target) else {
            print("⚠️ PathfindingService: Invalid start (\(start)) or target (\(target)) positions")
            return []
        }
        
        // Ensure navigation grid is properly sized
        guard !navigationGrid.isEmpty && !navigationGrid[0].isEmpty else {
            print("⚠️ PathfindingService: Navigation grid is empty or malformed")
            buildNavigationGrid() // Try to rebuild
            if navigationGrid.isEmpty || navigationGrid[0].isEmpty {
                print("❌ PathfindingService: Failed to rebuild navigation grid")
                return []
            }
            return findPathAStar(from: start, to: target) // Retry after rebuilding
        }
        
        // Double-check that start and target are within navigation grid bounds
        guard start.x < navigationGrid.count && start.y < navigationGrid[0].count &&
              target.x < navigationGrid.count && target.y < navigationGrid[0].count else {
            print("⚠️ PathfindingService: Start (\(start)) or target (\(target)) outside navigation grid bounds \(navigationGrid.count)x\(navigationGrid[0].count)")
            return []
        }
        
        // Reset navigation grid
        resetNavigationGrid()
        
        var openSet: Set<SIMD2<Int>> = [start]
        var closedSet: Set<SIMD2<Int>> = []
        
        navigationGrid[start.x][start.y].gScore = 0
        navigationGrid[start.x][start.y].fScore = heuristic(from: start, to: target)
        
        var searchCount = 0
        let maxSearchNodes = 1000
        
        while !openSet.isEmpty && searchCount < maxSearchNodes {
            searchCount += 1
            
            // Find node with lowest fScore
            let current = openSet.min { node1, node2 in
                // Add bounds checking here too
                guard node1.x < navigationGrid.count && node1.y < navigationGrid[0].count &&
                      node2.x < navigationGrid.count && node2.y < navigationGrid[0].count else {
                    print("⚠️ PathfindingService: Node out of bounds in openSet comparison")
                    return false
                }
                return navigationGrid[node1.x][node1.y].fScore < navigationGrid[node2.x][node2.y].fScore
            }!
            
            // Check if we reached the target
            if current == target {
                let path = reconstructPath(from: start, to: target)
                print("🎯 A* found path with \(path.count) waypoints after \(searchCount) searches")
                return path
            }
            
            openSet.remove(current)
            closedSet.insert(current)
            
            // Check all navigable neighbors with improved error handling
            let neighbors = getNavigableNeighbors(of: current)
            for neighbor in neighbors {
                if closedSet.contains(neighbor) {
                    continue
                }
                
                // Additional safety check before accessing navigation grid
                guard neighbor.x < navigationGrid.count && neighbor.y < navigationGrid[0].count else {
                    print("⚠️ PathfindingService: Neighbor \(neighbor) out of navigation grid bounds, skipping")
                    continue
                }
                
                let tentativeGScore = navigationGrid[current.x][current.y].gScore + 1.0
                
                if !openSet.contains(neighbor) {
                    openSet.insert(neighbor)
                } else if tentativeGScore >= navigationGrid[neighbor.x][neighbor.y].gScore {
                    continue
                }
                
                navigationGrid[neighbor.x][neighbor.y].parent = current
                navigationGrid[neighbor.x][neighbor.y].gScore = tentativeGScore
                navigationGrid[neighbor.x][neighbor.y].fScore = tentativeGScore + heuristic(from: neighbor, to: target)
            }
        }
        
        print("⚠️ A* failed to find path after \(searchCount) searches")
        return []
    }
    
    /// Get navigable neighbors (cells that can be reached without going through walls)
    private func getNavigableNeighbors(of cell: SIMD2<Int>) -> [SIMD2<Int>] {
        guard let mazeService = mazeService else { 
            print("⚠️ PathfindingService: No maze service available in getNavigableNeighbors")
            return [] 
        }
        
        var neighbors: [SIMD2<Int>] = []
        let maze = mazeService.maze
        
        // Check bounds for current cell
        guard isValidGridPosition(cell) else { 
            print("⚠️ PathfindingService: Invalid current cell position \(cell)")
            return [] 
        }
        
        let directions: [(SIMD2<Int>, Wall)] = [
            (SIMD2<Int>(0, -1), .top),    // North
            (SIMD2<Int>(1, 0), .right),   // East
            (SIMD2<Int>(0, 1), .bottom),  // South
            (SIMD2<Int>(-1, 0), .left)    // West
        ]
        
        for (direction, wall) in directions {
            let neighborCell = cell + direction
            
            // Check if neighbor is within maze bounds FIRST
            guard isValidGridPosition(neighborCell) else { 
                print("🚫 Neighbor \(neighborCell) is out of bounds for maze \(maze.configuration.width)x\(maze.configuration.height)")
                continue 
            }
            
            // Additional safety check for navigation grid bounds
            guard neighborCell.x >= 0 && neighborCell.x < navigationGrid.count &&
                  neighborCell.y >= 0 && neighborCell.y < navigationGrid[0].count else {
                print("🚫 Neighbor \(neighborCell) is out of navigation grid bounds \(navigationGrid.count)x\(navigationGrid[0].count)")
                continue
            }
            
            // Check if there's no wall blocking the path
            if !mazeService.hasWall(at: cell, direction: wall) {
                neighbors.append(neighborCell)
                print("✅ Valid neighbor: \(cell) -> \(neighborCell) (no \(wall) wall)")
            } else {
                print("❌ Blocked neighbor: \(cell) -> \(neighborCell) (has \(wall) wall)")
            }
        }
        
        print("🧭 Cell \(cell) has \(neighbors.count) navigable neighbors: \(neighbors)")
        return neighbors
    }
    
    private func isValidGridPosition(_ position: SIMD2<Int>) -> Bool {
        guard let mazeService = mazeService else { 
            print("⚠️ PathfindingService: No maze service in isValidGridPosition")
            return false 
        }
        let maze = mazeService.maze
        let isValid = position.x >= 0 && position.x < maze.configuration.width &&
                     position.y >= 0 && position.y < maze.configuration.height
        
        if !isValid {
            print("🚫 Position \(position) is invalid for maze bounds \(maze.configuration.width)x\(maze.configuration.height)")
        }
        
        return isValid
    }
    
    private func resetNavigationGrid() {
        guard !navigationGrid.isEmpty && !navigationGrid[0].isEmpty else {
            print("⚠️ PathfindingService: Cannot reset empty navigation grid")
            return
        }
        
        for x in 0..<navigationGrid.count {
            for y in 0..<navigationGrid[x].count {
                navigationGrid[x][y].gScore = Float.infinity
                navigationGrid[x][y].fScore = Float.infinity
                navigationGrid[x][y].parent = nil
            }
        }
    }
    
    /// Reconstruct the path from A* algorithm result
    private func reconstructPath(from start: SIMD2<Int>, to target: SIMD2<Int>) -> [SIMD2<Int>] {
        var path: [SIMD2<Int>] = []
        var current = target
        var safetyCounter = 0
        let maxPathLength = navigationGrid.count * navigationGrid[0].count // Prevent infinite loops
        
        while current != start && safetyCounter < maxPathLength {
            path.insert(current, at: 0)
            
            // Bounds check before accessing navigation grid
            guard current.x < navigationGrid.count && current.y < navigationGrid[0].count else {
                print("⚠️ Path reconstruction failed - current position \(current) out of bounds")
                return []
            }
            
            guard let parent = navigationGrid[current.x][current.y].parent else {
                print("⚠️ Path reconstruction failed - no parent for \(current)")
                return []
            }
            current = parent
            safetyCounter += 1
        }
        
        if safetyCounter >= maxPathLength {
            print("⚠️ Path reconstruction stopped - possible infinite loop detected")
            return []
        }
        
        path.insert(start, at: 0)
        print("🔄 Reconstructed path successfully with \(path.count) waypoints")
        return path
    }
    
    /// Calculate heuristic distance (Manhattan distance)
    private func heuristic(from start: SIMD2<Int>, to target: SIMD2<Int>) -> Float {
        let dx = abs(start.x - target.x)
        let dy = abs(start.y - target.y)
        return Float(dx + dy)
    }
    
    // MARK: - Coordinate Conversion
    
    private func worldToGridPosition(_ worldPos: SIMD3<Float>) -> SIMD2<Int> {
        guard let mazeService = mazeService else { return SIMD2<Int>(0, 0) }
        return mazeService.getCellCoordinate(for: worldPos)
    }
    
    /// Convert cell coordinate path to world coordinate path
    private func convertCellPathToWorldPath(_ cellPath: [SIMD2<Int>]) -> [SIMD3<Float>] {
        guard let mazeService = mazeService else { return [] }
        
        return cellPath.map { cell in
            let worldPos = mazeService.getWorldPosition(for: cell)
            return worldPos.offsetY(0.2) // Slightly above ground for cat movement
        }
    }
    
    // MARK: - Path Visualization
    
    private func createPathLineSegment(from start: SIMD3<Float>, to end: SIMD3<Float>) -> Entity {
        let lineEntity = Entity()
        lineEntity.name = "PathLine"
        
        // Calculate line properties
        let direction = end - start
        let distance = length(direction)
        let center = (start + end) * 0.5
        
        // Create cylinder for line
        let lineGeometry = MeshResource.generateBox(size: SIMD3<Float>(0.05, 0.05, distance))
        let lineMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
        lineEntity.components.set(ModelComponent(mesh: lineGeometry, materials: [lineMaterial]))
        
        // Position and orient the line
        lineEntity.position = center
        
        // Calculate rotation to align with direction
        if distance > 0.001 {
            let normalizedDirection = direction / distance
            let defaultDirection = SIMD3<Float>(0, 0, 1)
            let rotationAxis = cross(defaultDirection, normalizedDirection)
            let rotationAngle = acos(dot(defaultDirection, normalizedDirection))
            
            if length(rotationAxis) > 0.001 {
                let normalizedAxis = normalize(rotationAxis)
                lineEntity.transform.rotation = simd_quatf(angle: rotationAngle, axis: normalizedAxis)
            }
        }
        
        return lineEntity
    }
    
    private func createWaypointMarker(at position: SIMD3<Float>, index: Int) -> Entity {
        let markerEntity = Entity()
        markerEntity.name = "Waypoint_\(index)"
        
        // Create small sphere for waypoint
        let markerGeometry = MeshResource.generateSphere(radius: 0.1)
        let markerMaterial = SimpleMaterial(color: .green, isMetallic: false)
        markerEntity.components.set(ModelComponent(mesh: markerGeometry, materials: [markerMaterial]))
        
        markerEntity.position = position + SIMD3<Float>(0, 0.1, 0) // Slightly higher
        
        return markerEntity
    }
    
    // MARK: - Debug Methods
    
    func getNavigationDebugInfo() -> String {
        guard let mazeService = mazeService else { return "No maze service available" }
        
        let maze = mazeService.maze
        var info = "=== Navigation Debug ===\n"
        info += "Grid Size: \(navigationGrid.count)x\(navigationGrid.first?.count ?? 0)\n"
        info += "Maze Size: \(maze.configuration.width)x\(maze.configuration.height)\n"
        info += "Grid vs Maze Match: \(navigationGrid.count == maze.configuration.width && (navigationGrid.first?.count ?? 0) == maze.configuration.height)\n"
        info += "Cached Paths: \(pathCache.count)\n"
        info += "Visualization Entities: \(pathVisualizationEntities.count)\n"
        
        // Add bounds validation info
        if !navigationGrid.isEmpty && !navigationGrid[0].isEmpty {
            info += "Grid State: Valid\n"
        } else {
            info += "Grid State: Invalid/Empty\n"
        }
        
        return info
    }
}

// MARK: - SIMD2 Extensions

extension SIMD2 where Scalar == Int {
    static func +(lhs: SIMD2<Int>, rhs: SIMD2<Int>) -> SIMD2<Int> {
        return SIMD2<Int>(lhs.x + rhs.x, lhs.y + rhs.y)
    }
    
    static func -(lhs: SIMD2<Int>, rhs: SIMD2<Int>) -> SIMD2<Int> {
        return SIMD2<Int>(lhs.x - rhs.x, lhs.y - rhs.y)
    }
    
    static func ==(lhs: SIMD2<Int>, rhs: SIMD2<Int>) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension SIMD2: Hashable where Scalar == Int {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
