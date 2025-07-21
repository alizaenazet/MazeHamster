//
//  MazeGenerator.swift
//  DraftBallMazeGame
//
//  Created by Rafi Abhista  on 10/07/25.
//

import Foundation

enum Wall {
    case top, right, bottom, left
}

struct MazeCell {
    var x: Int
    var y: Int
    var walls: Set<Wall> = [.top, .right, .bottom, .left]
    var visited = false
}

class MazeGenerator {
    var width: Int
    var height: Int
    var grid: [[MazeCell]]

    init(width: Int, height: Int, extra: Int) {
        self.width = width
        self.height = height
        self.grid = (0..<width).map { x in
            (0..<height).map { y in
                MazeCell(x: x, y: y)
            }
        }
        generateMaze(extra: extra)
    }

    func generateMaze(extra: Int) {
        dfs(x: 0, y: 0)
        addExtraPaths(count: extra) // Add 2 extra paths to introduce loops

    }

    func dfs(x: Int, y: Int) {
        grid[x][y].visited = true

        let directions: [(Int, Int, Wall, Wall)] = [
            (0, -1, .top, .bottom),
            (1, 0, .right, .left),
            (0, 1, .bottom, .top),
            (-1, 0, .left, .right)
        ].shuffled()

        for (dx, dy, wall, oppWall) in directions {
            let nx = x + dx, ny = y + dy
            if nx >= 0, ny >= 0, nx < width, ny < height, !grid[nx][ny].visited {
                grid[x][y].walls.remove(wall)
                grid[nx][ny].walls.remove(oppWall)
                dfs(x: nx, y: ny)
            }
        }
    }
    
    func addExtraPaths(count: Int = 2) {
        var added = 0
        let directions: [(Int, Int, Wall, Wall)] = [
            (0, -1, .top, .bottom),
            (1, 0, .right, .left),
            (0, 1, .bottom, .top),
            (-1, 0, .left, .right)
        ]

        while added < count {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)

            // Shuffle directions for randomness
            for (dx, dy, wall, oppWall) in directions.shuffled() {
                let nx = x + dx
                let ny = y + dy

                // Valid neighbor?
                if nx >= 0, ny >= 0, nx < width, ny < height {
                    let current = grid[x][y]
                    let neighbor = grid[nx][ny]

                    // Only remove wall if there is still a wall between them (i.e., wasn't already opened by DFS)
                    if current.walls.contains(wall) && neighbor.walls.contains(oppWall) {
                        grid[x][y].walls.remove(wall)
                        grid[nx][ny].walls.remove(oppWall)
                        added += 1
                        break
                    }
                }
            }
        }
    }

}
