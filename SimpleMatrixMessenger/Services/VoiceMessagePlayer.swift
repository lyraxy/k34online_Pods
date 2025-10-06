import Foundation
import MatrixSDK

@MainActor
class VoiceMessagePlayer: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isPlaying = false
    @Published var currentPlaybackTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentMessageId: String?
    
    private var timer: Timer?
    
    func playAudio(from data: Data, messageId: String) {
        // Останавливаем предыдущее воспроизведение
        stopPlayback()
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            currentMessageId = messageId
            duration = audioPlayer?.duration ?? 0
            
            print("DEBUG: Playing audio - Duration: \(duration)s, Message ID: \(messageId)")
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentPlaybackTime = player.currentTime
            }
        } catch {
            print("Could not play audio: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        currentPlaybackTime = 0
        currentMessageId = nil
        duration = 0
        timer?.invalidate()
        timer = nil
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentPlaybackTime = time
    }
    
    func togglePlayback(for data: Data, messageId: String) {
        if isPlaying && currentMessageId == messageId {
            stopPlayback()
        } else {
            playAudio(from: data, messageId: messageId)
        }
    }
}

extension VoiceMessagePlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentPlaybackTime = 0
        currentMessageId = nil
        duration = 0
        timer?.invalidate()
        timer = nil
    }
}
