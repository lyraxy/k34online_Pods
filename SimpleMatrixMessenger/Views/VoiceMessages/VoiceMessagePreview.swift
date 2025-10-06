import Foundation
import MatrixSDK
import SwiftUI

// MARK: - Voice Message Preview
struct VoiceMessagePreview: View {
    @ObservedObject var voiceRecorder: VoiceMessageRecorder
    let recordingURL: URL
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                Button(action: {
                    if voiceRecorder.isPlaying {
                        voiceRecorder.stopPlayback()
                    } else {
                        voiceRecorder.playRecording()
                    }
                }) {
                    Image(systemName: voiceRecorder.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(K34Colors.primaryRed)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Прослушать запись")
                        .font(.headline)
                        .foregroundColor(K34Colors.textPrimary)
                    
                    Text(formatTime(voiceRecorder.isPlaying ? voiceRecorder.currentPlaybackTime : voiceRecorder.recordingTime))
                        .font(.caption)
                        .foregroundColor(K34Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding()
            .background(K34Colors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
