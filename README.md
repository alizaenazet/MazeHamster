# MazeHamster Developer Onboarding Guide

Welcome to the MazeHamster project! This guide will help you understand the codebase architecture and get you up to speed quickly.

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Project Structure](#project-structure)
4. [Core Components](#core-components)
5. [Data Flow](#data-flow)
6. [Development Patterns](#development-patterns)
7. [Getting Started](#getting-started)
8. [Common Tasks](#common-tasks)
9. [Best Practices](#best-practices)

## 🎯 Project Overview

MazeHamster is a iOS game built with **SwiftUI** and **RealityKit** that uses device gyroscope input to guide a ball through a 3D maze. The project was completely refactored from a monolithic 440-line file into a clean, modular architecture.

### Key Technologies
- **SwiftUI**: User interface framework
- **RealityKit**: 3D rendering and physics
- **Core Motion**: Device orientation and motion sensing
- **Combine**: Reactive programming for data binding

## 🏗️ Architecture Overview

The project follows a **MVVM + ECS (Model-View-ViewModel + Entity Component System)** architecture pattern:

### MVVM Layer
- **Model**: Data structures and business logic
- **View**: SwiftUI views for UI presentation
- **ViewModel**: Coordinates between services and manages UI state

### ECS Layer
- **Entities**: Game objects (ball, walls, floor)
- **Components**: Data containers (position, physics, rendering)
- **Systems**: Logic processors (physics, input, rendering)

This hybrid approach gives us:
- **Clean separation of concerns**
- **Easy testing and debugging**
- **Scalable game architecture**
- **Reactive UI updates**

### Simplified Game Mechanics
- **Fixed camera**: Camera stays at optimal position to view entire maze
- **Centered maze**: Maze remains stationary at screen center
- **Ball-only physics**: Only the ball responds to gyroscope input
- **Streamlined systems**: Removed complex camera following and maze rotation

## 📁 Project Structure

```
MazeHamster/
├── Core/                          # Core game systems
│   ├── Base/                      # Base classes and protocols
│   ├── Models/                    # Data structures
│   ├── Protocols/                 # Service interfaces
│   ├── ECS/                       # Entity Component System
│   │   ├── Components.swift       # Game components & manager
│   │   └── Systems.swift          # Game systems & ECS world
│   ├── Services/                  # Concrete service implementations
│   │   ├── InputService.swift     # Motion/gyroscope handling
│   │   ├── PhysicsService.swift   # Physics operations
│   │   ├── MazeService.swift      # Maze generation & management
│   │   ├── GameService.swift      # Game state management
│   │   └── CameraService.swift    # Camera behavior
│   ├── Factories/                 # Entity creation
│   │   └── EntityFactory.swift    # Centralized entity creation
│   └── Coordinators/              # High-level coordination
│       └── GameCoordinator.swift  # Game flow management
├── ViewModels/                    # MVVM layer
│   └── GameViewModel.swift        # UI state coordination
├── ContentView.swift              # Main SwiftUI view
├── MazeGenerator.swift            # Legacy maze generation
└── MazeHamsterApp.swift          # App entry point
```

## 🧩 Core Components

### 1. Services Layer (`Core/Services/`)

Services handle specific aspects of the game:

#### InputService
- **Purpose**: Handles device motion and gyroscope input
- **Key Methods**: 
  - `startMotionUpdates()`: Begin motion tracking
  - `stopMotionUpdates()`: Stop motion tracking
- **Publishes**: `@Published var tiltData: TiltData`

#### GameService
- **Purpose**: Manages game state and scoring
- **Key Methods**:
  - `startGame()`, `pauseGame()`, `resetGame()`
  - `addPoints()`, `subtractPoints()`
- **Publishes**: `@Published var gameState: GameState`

#### MazeService
- **Purpose**: Generates and manages maze data
- **Key Methods**:
  - `generateNewMaze()`: Create new maze
  - `getCellPosition()`: Convert coordinates
- **Publishes**: `@Published var maze: MazeData`

#### PhysicsService
- **Purpose**: Handles physics setup and operations
- **Key Methods**:
  - `setupBallPhysics()`: Configure ball physics
  - `setupWallPhysics()`: Configure wall collisions
  - `applyTiltToBall()`: Apply gyroscope forces to ball only

#### CameraService
- **Purpose**: Manages camera setup with fixed positioning
- **Key Methods**:
  - `setupCamera()`: Initialize camera at fixed position
  - `getCameraPosition()`: Get current camera position

### 2. ECS System (`Core/ECS/`)

#### Components (`Components.swift`)
Data containers that hold specific attributes:

```swift
// Example component usage
struct TransformComponent: GameComponent {
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var scale: SIMD3<Float>
}

struct PhysicsComponent: GameComponent {
    var mass: Float
    var velocity: SIMD3<Float>
    var isKinematic: Bool
}
```

#### Systems (`Systems.swift`)
Logic processors that operate on components:

```swift
// Systems process entities with specific components
class PhysicsSystem: GameSystem {
    func update(deltaTime: Float) {
        // Process all entities with physics components
    }
}
```

#### ComponentManager
Centralized component storage and retrieval:

```swift
// Add component to entity
componentManager.addComponent(TransformComponent(...), to: entityId)

// Get component from entity
let transform = componentManager.getComponent(TransformComponent.self, for: entityId)
```

### 3. Factory Pattern (`Core/Factories/`)

#### EntityFactory
Centralized entity creation with proper component setup:

```swift
// Create a ball entity with all required components
let ballEntity = entityFactory.createBall(at: position)

// Create maze walls with physics
let wallEntities = entityFactory.createMazeWalls(from: mazeData)
```

### 4. Coordination Layer (`Core/Coordinators/`)

#### GameCoordinator
High-level game flow management:
- Coordinates between all services
- Manages game lifecycle
- Handles complex interactions

### 5. ViewModel Layer (`ViewModels/`)

#### GameViewModel
MVVM coordination layer:
- Binds service data to UI
- Handles user interactions
- Manages view state

## 🔄 Data Flow

### 1. Game Initialization
```
App Start → GameViewModel → GameCoordinator → Services Setup → ECS World Creation
```

### 2. Game Loop (Simplified)
```
Motion Input → InputService → PhysicsService → Ball Movement → Render System → UI Update
```

### 3. State Changes
```
Game Event → GameService → GameViewModel → SwiftUI View → UI Update
```

### 4. Reactive Updates
```
Service @Published Property → Combine Pipeline → ViewModel → SwiftUI View
```

## 🔧 Development Patterns

### 1. Adding New Components

```swift
// 1. Define the component
struct HealthComponent: GameComponent {
    var currentHealth: Int
    var maxHealth: Int
}

// 2. Register in ComponentManager (if needed)
// 3. Use in EntityFactory
func createPlayer() -> UUID {
    let entityId = UUID()
    componentManager.addComponent(HealthComponent(currentHealth: 100, maxHealth: 100), to: entityId)
    return entityId
}
```

### 2. Creating New Systems

```swift
// 1. Conform to GameSystem protocol
class HealthSystem: GameSystem {
    let componentManager: ComponentManager
    
    func update(deltaTime: Float) {
        // Process entities with health components
        let healthEntities = componentManager.getAllEntitiesWithComponent(HealthComponent.self)
        for entityId in healthEntities {
            // Update health logic
        }
    }
}

// 2. Add to ECSWorld
ecsWorld.addSystem(HealthSystem(componentManager: componentManager))
```

### 3. Service Communication

```swift
// Services communicate through published properties
class NewService: BaseService {
    @Published var serviceData: ServiceData
    
    func setupService() {
        // Subscribe to other services
        otherService.$otherData
            .sink { [weak self] data in
                self?.handleDataChange(data)
            }
            .store(in: &cancellables)
    }
}
```

## 🚀 Getting Started

### 1. Environment Setup
- Ensure you have Xcode 14+ installed
- iOS 16+ deployment target
- Device with gyroscope for testing

### 2. Code Exploration Path
1. Start with `ContentView.swift` - See the UI layer
2. Review `GameViewModel.swift` - Understand MVVM coordination
3. Explore `GameCoordinator.swift` - See high-level game flow
4. Check `Core/Services/` - Understand service responsibilities
5. Look at `Core/ECS/` - Learn the component system

### 3. Running the Project
```bash
# Open in Xcode
open MazeHamster.xcodeproj

# Build and run on device (gyroscope required)
cmd+R
```

## 🛠️ Common Tasks

### Adding a New Game Feature

1. **Identify the layers involved**
   - Does it need new components? → `Core/ECS/Components.swift`
   - Does it need new systems? → `Core/ECS/Systems.swift`
   - Does it need a new service? → `Core/Services/`
   - Does it affect UI? → `ViewModels/GameViewModel.swift`

2. **Follow the data flow**
   - Model the data → Components/Models
   - Process the logic → Systems/Services
   - Coordinate the flow → Coordinators
   - Present to user → ViewModel → View

### Debugging Common Issues

1. **Component not found**
   ```swift
   // Check if component was added
   if componentManager.hasComponent(YourComponent.self, for: entityId) {
       // Component exists
   }
   ```

2. **Service not updating**
   ```swift
   // Ensure @Published properties are used
   @Published var yourData: YourDataType
   
   // Check subscriptions are stored
   .store(in: &cancellables)
   ```

3. **Physics not working**
   ```swift
   // Verify physics setup in PhysicsService
   // Check entity has required components
   // Confirm RealityKit entity is properly created
   ```

## ✅ Best Practices

### 1. Component Design
- **Keep components data-only** - No logic in components
- **Use clear naming** - `TransformComponent`, not `TC`
- **Group related data** - Position, rotation, scale in one component

### 2. System Design
- **Single responsibility** - Each system handles one aspect
- **Stateless when possible** - Use components for state
- **Performance aware** - Cache expensive operations

### 3. Service Design
- **Follow protocols** - Implement defined interfaces
- **Use @Published for reactive data** - Enable UI binding
- **Handle errors gracefully** - Don't crash the game

### 4. Code Organization
- **Use proper access levels** - `private`, `internal`, `public`
- **Document complex logic** - Especially physics and math
- **Follow Swift conventions** - Naming, formatting, structure

### 5. Testing Approach
- **Unit test services** - Easy to mock and test
- **Integration test coordinators** - Test service interactions
- **UI test critical paths** - Game start, pause, completion

## 🎓 Learning Resources

### Architecture Patterns
- [MVVM in SwiftUI](https://developer.apple.com/documentation/swiftui/model-data)
- [Entity Component System](https://github.com/SanderMertens/ecs-faq)
- [Combine Framework](https://developer.apple.com/documentation/combine)

### RealityKit & Game Development
- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
- [Core Motion Guide](https://developer.apple.com/documentation/coremotion)
- [iOS Game Development](https://developer.apple.com/games/)

---

Welcome to the team! 🎉 If you have questions, check the code comments or ask a team member. Happy coding! 