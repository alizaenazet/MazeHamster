import Foundation
import CoreMotion
import Combine

/// Concrete implementation of InputService for handling device motion input
class InputService: BaseService, InputServiceProtocol {
    
    // MARK: - Published Properties
    
    @Published private var _tiltData = TiltData(roll: 0, pitch: 0)
    
    // MARK: - Protocol Properties
    
    var tiltData: AnyPublisher<TiltData, Never> {
        return $_tiltData.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 60.0 // 60 FPS
    
    // MARK: - Service Setup
    
    override func setupService() {
        super.setupService()
        configureMotionManager()
    }
    
    private func configureMotionManager() {
        guard motionManager.isDeviceMotionAvailable else {
            // print("⚠️ Device motion is not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        // print("✅ InputService configured successfully")
    }
    
    // MARK: - Protocol Methods
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            // print("⚠️ Cannot start monitoring: Device motion unavailable")
            return
        }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else {
                if let error = error {
                    // print("❌ Motion update error: \(error)")
                }
                return
            }
            
            self.processMotionData(motion)
        }
        
        // print("🎯 Input monitoring started")
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        // print("🔄 Input monitoring stopped")
    }
    
    // MARK: - Private Methods
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        let gravity = motion.gravity
        
        // Calculate tilt angles based on gravity vector
        let roll = Float(atan2(gravity.x, sqrt(gravity.y * gravity.y + gravity.z * gravity.z)))
        let pitch = Float(atan2(gravity.y, sqrt(gravity.x * gravity.x + gravity.z * gravity.z)))
        
        // Create new tilt data (TiltData constructor handles clamping)
        let newTiltData = TiltData(roll: roll, pitch: pitch)
        
        // Update published property
        _tiltData = newTiltData
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopMonitoring()
    }
} 
