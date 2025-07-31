//
//  ScreenAdaptiveService.swift
//  MazeHamster
//
//  Created by Darmawan on 16/07/25.
//


//
//  ScreenAdaptiveService.swift
//  MazeHamster
//
//  Created by Darmawan on 16/07/25.
//


import Foundation
import UIKit
import RealityKit
import simd

/// Service for detecting screen properties and adapting maze/camera accordingly
class ScreenAdaptiveService: BaseService {
    
    // MARK: - Screen Properties
    
    struct ScreenInfo {
        let size: CGSize
        let scale: CGFloat
        let deviceType: DeviceType
        let orientation: UIInterfaceOrientation
        let safeAreaInsets: UIEdgeInsets
        let aspectRatio: Float
        
        var isLandscape: Bool {
            return orientation.isLandscape
        }
        
        var isPortrait: Bool {
            return orientation.isPortrait
        }
        
        var screenDiagonal: Float {
            let width = Float(size.width)
            let height = Float(size.height)
            return sqrt(width * width + height * height)
        }
    }
    
    enum DeviceType {
        case phone
        case phonePlus // iPhone Plus/Pro Max
        case pad
        case padPro
        case unknown
        
        var defaultMazeSize: SIMD2<Int> {
            switch self {
            case .phone:
                return SIMD2<Int>(6, 8)      // Small maze for phones
            case .phonePlus:
                return SIMD2<Int>(7, 9)      // Medium maze for larger phones
            case .pad:
                return SIMD2<Int>(8, 10)     // Larger maze for iPads
            case .padPro:
                return SIMD2<Int>(10, 12)    // Biggest maze for iPad Pro
            case .unknown:
                return SIMD2<Int>(6, 8)      // Default to small
            }
        }
        
        var cellSize: Float {
            switch self {
            case .phone:
                return 0.8          // Smaller cells for phones
            case .phonePlus:
                return 0.9          // Medium cells
            case .pad:
                return 1.0          // Standard cells for iPads
            case .padPro:
                return 1.1          // Larger cells for iPad Pro
            case .unknown:
                return 0.8          // Default
            }
        }
        
        var cameraHeight: Float {
            switch self {
            case .phone:
                return 12.0         // Much higher camera for better overview on phones
            case .phonePlus:
                return 13.0         // Much higher camera for larger phones
            case .pad:
                return 8.0          // Higher camera for larger mazes
            case .padPro:
                return 10.0         // Highest camera for biggest mazes
            case .unknown:
                return 12.0         // Default to much higher camera
            }
        }
    }
    
    // MARK: - Private Properties
    
    @Published var currentScreenInfo: ScreenInfo?
    private var orientationObserver: NSObjectProtocol?
    
    // MARK: - Service Setup
    
    override func setupService() {
        super.setupService()
        detectScreenProperties()
        setupOrientationObserver()
       // print("✅ ScreenAdaptiveService configured successfully")
    }
    
    // MARK: - Public Methods
    
    /// Update screen dimensions from GeometryReader
    func updateScreenDimensions(_ dimensions: SIMD2<Float>, aspectRatio: Float? = nil) {
        // Only proceed if we already have screen info
        guard var updatedInfo = currentScreenInfo else {
            return
        }
        
        // Calculate aspect ratio if not provided
        let calculatedAspectRatio = aspectRatio ?? (dimensions.x / dimensions.y)
        
        // Update the size with GeometryReader values
        updatedInfo = ScreenInfo(
            size: CGSize(width: CGFloat(dimensions.x), height: CGFloat(dimensions.y)),
            scale: updatedInfo.scale,
            deviceType: updatedInfo.deviceType,
            orientation: updatedInfo.orientation,
            safeAreaInsets: updatedInfo.safeAreaInsets,
            aspectRatio: calculatedAspectRatio
        )
        
        currentScreenInfo = updatedInfo
        // print("📏 Screen dimensions updated from GeometryReader: \(dimensions.x) × \(dimensions.y), AR: \(calculatedAspectRatio)")
    }
    
    /// Get current screen information
    func getScreenInfo() -> ScreenInfo? {
        return currentScreenInfo
    }
    
    /// Get optimal maze configuration for current screen
    func getOptimalMazeConfiguration() -> MazeConfiguration {
        guard let screenInfo = currentScreenInfo else {
            return MazeConfiguration.default
        }
        
        let deviceType = screenInfo.deviceType
        let mazeSize = deviceType.defaultMazeSize
        
        // Adjust for orientation
        let adjustedSize = screenInfo.isLandscape ? 
            SIMD2<Int>(max(mazeSize.x, mazeSize.y), min(mazeSize.x, mazeSize.y)) :
            SIMD2<Int>(min(mazeSize.x, mazeSize.y), max(mazeSize.x, mazeSize.y))
        
        return MazeConfiguration(
            width: adjustedSize.x,
            height: adjustedSize.y,
            cellSize: deviceType.cellSize,
            wallHeight: 1.0,
            wallThickness: 0.1
        )
    }
    
    /// Get optimal camera height for current screen
    func getOptimalCameraHeight() -> Float {
        guard let screenInfo = currentScreenInfo else {
            return 12.0 // Default to higher camera height to avoid cropping
        }
        
        // Increase camera height slightly to avoid cropping
        let baseHeight = screenInfo.deviceType.cameraHeight
        
        // Adjust based on aspect ratio to prevent side cropping
        let aspectRatioAdjustment = screenInfo.aspectRatio < 1.0 ? 1.3 : 1.0
        
        return baseHeight * Float(aspectRatioAdjustment)
    }
    
    /// Get UI scaling factor for current screen
    func getUIScalingFactor() -> Float {
        guard let screenInfo = currentScreenInfo else {
            return 1.0
        }
        
        switch screenInfo.deviceType {
        case .phone:
            return 0.8          // Smaller UI elements
        case .phonePlus:
            return 0.9          // Medium UI elements
        case .pad:
            return 1.0          // Standard UI elements
        case .padPro:
            return 1.2          // Larger UI elements
        case .unknown:
            return 1.0          // Default
        }
    }
    
    /// Force refresh screen detection (call when orientation changes)
    func refreshScreenDetection() {
        detectScreenProperties()
    }
    
    // MARK: - Screen Detection
    
    private func detectScreenProperties() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
           // print("⚠️ Could not get window for screen detection")
            return
        }
        
        let screen = window.screen
        let size = screen.bounds.size
        let scale = screen.scale
        let orientation = windowScene.interfaceOrientation
        let safeAreaInsets = window.safeAreaInsets
        
        let deviceType = detectDeviceType(screenSize: size, scale: scale)
        let aspectRatio = Float(size.width / size.height)
        
        let screenInfo = ScreenInfo(
            size: size,
            scale: scale,
            deviceType: deviceType,
            orientation: orientation,
            safeAreaInsets: safeAreaInsets,
            aspectRatio: aspectRatio
        )
        
        currentScreenInfo = screenInfo
        
       // print("📱 Screen detected:")
       // print("   Size: \(size)")
       // print("   Scale: \(scale)")
       // print("   Device: \(deviceType)")
       // print("   Orientation: \(orientation)")
       // print("   Aspect Ratio: \(aspectRatio)")
       // print("   Diagonal: \(screenInfo.screenDiagonal)")
    }
    
    private func detectDeviceType(screenSize: CGSize, scale: CGFloat) -> DeviceType {
        let width = screenSize.width * scale
        let height = screenSize.height * scale
        let diagonal = sqrt(width * width + height * height)
        
        // iPhone detection based on pixel dimensions
        if diagonal < 1500 {
            return .phone           // iPhone mini, SE
        } else if diagonal < 1800 {
            return .phone           // iPhone standard
        } else if diagonal < 2200 {
            return .phonePlus       // iPhone Plus/Pro Max
        } else if diagonal < 2800 {
            return .pad             // iPad mini, standard iPad
        } else {
            return .padPro          // iPad Pro, iPad Air
        }
    }
    
    // MARK: - Orientation Observer
    
    private func setupOrientationObserver() {
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.refreshScreenDetection()
            }
        }
    }
    
    // MARK: - Adaptive Configuration Methods
    
    /// Get game configuration optimized for current screen
    func getAdaptiveGameConfiguration() -> GameConfiguration {
        let mazeConfig = getOptimalMazeConfiguration()
        let cameraHeight = getOptimalCameraHeight()
        
        return GameConfiguration(
            maze: mazeConfig,
            physicsMaterials: .default,
            visualMaterials: .default,
            ballRadius: 0.15,  // Slightly smaller ball
            exitRadius: 0.25,  // Slightly smaller exit
            cameraHeight: cameraHeight,
            cameraHeightMultiplier: 0.7, // Adjusted: 1.0=normal, 2.0=zoom out, 0.5=zoom in
            catSleepDuration: 2.0
        )
    }
    
    /// Get adaptive visual materials based on screen size
    func getAdaptiveVisualMaterials() -> VisualMaterials {
        guard let screenInfo = currentScreenInfo else {
            return .default
        }
        
        // Adjust colors/materials based on screen size for better visibility
        let ballColor: UIColor = screenInfo.deviceType == .phone ? .red : .systemRed
        let wallColor: UIColor = screenInfo.deviceType == .phone ? .blue : .systemBlue
        
        return VisualMaterials(
            ball: SimpleMaterial(color: ballColor, isMetallic: true),
            wall: SimpleMaterial(color: wallColor, isMetallic: false),
            floor: SimpleMaterial(color: .systemGray, isMetallic: false),
            exit: SimpleMaterial(color: .systemGreen, isMetallic: false)
        )
    }
    
    // MARK: - Debug Information
    
    func getScreenDebugInfo() -> String {
        guard let screenInfo = currentScreenInfo else {
            return "No screen info available"
        }
        
        let mazeConfig = getOptimalMazeConfiguration()
        
        var info = "=== Screen Adaptive Debug ===\n"
        info += "Device Type: \(screenInfo.deviceType)\n"
        info += "Screen Size: \(screenInfo.size)\n"
        info += "Scale Factor: \(screenInfo.scale)\n"
        info += "Orientation: \(screenInfo.orientation)\n"
        info += "Aspect Ratio: \(String(format: "%.2f", screenInfo.aspectRatio))\n"
        info += "Screen Diagonal: \(String(format: "%.1f", screenInfo.screenDiagonal))\n"
        info += "\n--- Adaptive Configuration ---\n"
        info += "Maze Size: \(mazeConfig.width)x\(mazeConfig.height)\n"
        info += "Cell Size: \(mazeConfig.cellSize)\n"
        info += "Camera Height: \(getOptimalCameraHeight())\n"
        info += "UI Scale: \(getUIScalingFactor())\n"
        
        return info
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
       // print("🧹 ScreenAdaptiveService deallocated")
    }
}

// MARK: - Extensions

extension UIInterfaceOrientation {
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
    
    var isPortrait: Bool {
        return self == .portrait || self == .portraitUpsideDown
    }
}

// MARK: - Adaptive Maze Configuration Extension

extension MazeConfiguration {
    /// Create configuration adapted for specific device type
    static func adaptive(for deviceType: ScreenAdaptiveService.DeviceType, orientation: UIInterfaceOrientation) -> MazeConfiguration {
        let baseSize = deviceType.defaultMazeSize
        
        // Adjust for orientation
        let adjustedSize = orientation.isLandscape ? 
            SIMD2<Int>(max(baseSize.x, baseSize.y), min(baseSize.x, baseSize.y)) :
            SIMD2<Int>(min(baseSize.x, baseSize.y), max(baseSize.x, baseSize.y))
        
        return MazeConfiguration(
            width: adjustedSize.x,
            height: adjustedSize.y,
            cellSize: deviceType.cellSize,
            wallHeight: 1.0,
            wallThickness: 0.1
        )
    }
}
