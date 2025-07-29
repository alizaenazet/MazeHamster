//
//  SoundPlayer.swift
//  MazeHamster
//
//  Created by Rigel Sundun Tandilolo on 23/07/25.
//

// Core/Services/SoundPlayer.swift

import Foundation
import AVFoundation

class SoundPlayer {
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var activePlayers: [AVAudioPlayer] = []

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // print("Failed to set audio session category: \(error.localizedDescription)")
        }
    }

    /// Loads a sound file into memory. Call this during initialization or before first use.
    func loadSound(named fileName: String, fileExtension: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            // print("Sound file not found: \(fileName).\(fileExtension)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay() // Pre-load audio data
            audioPlayers[fileName] = player
            // print("🎶 Sound loaded: \(fileName)")
        } catch {
            // print("Could not load sound file \(fileName).\(fileExtension): \(error.localizedDescription)")
        }
    }

    /// Plays a sound effect.
    func playSound(named fileName: String) {
        if let player = audioPlayers[fileName] {
            do {
                let newPlayer = try AVAudioPlayer(contentsOf: player.url!)
                newPlayer.volume = 0.7 // Adjust volume as needed
                newPlayer.play()
                
                activePlayers.append(newPlayer)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + newPlayer.duration) { [weak self] in
                    self?.activePlayers.removeAll(where: { $0 == newPlayer })
                }
                // print("🔊 Playing sound: \(fileName)")
            } catch {
                // print("Failed to create new player instance for \(fileName): \(error.localizedDescription)")
            }
        } else {
            // print("Sound not loaded: \(fileName)")
        }
    }
    
    func stopAllSounds() {
        for player in activePlayers {
            player.stop()
        }
        activePlayers.removeAll()
    }
}
