import Foundation
import MatrixSDK
import SwiftUI


// MARK: - Voice Message View
struct VoiceMessageView: View {
    let message: Message
    @ObservedObject var matrixService: MatrixService
    @ObservedObject var voicePlayer: VoiceMessagePlayer
    @State private var audioData: Data?
    @State private var isLoading = false
    @State private var actualDuration: TimeInterval = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Кнопка воспроизведения/паузы
            Button(action: {
                togglePlayback()
            }) {
                Image(systemName: getPlayButtonIcon())
                    .font(.title2)
                    .foregroundColor(K34Colors.primaryRed)
                    .frame(width: 30, height: 30)
            }
            .disabled(isLoading)
            
            // Прогресс-бар и время
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("🎤 Голосовое сообщение")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(K34Colors.textPrimary)
                    
                    Spacer()
                    
                    if message.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(K34Colors.encryptedGreen)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(formatTime(getCurrentTime()))
                        .font(.caption)
                        .foregroundColor(K34Colors.textSecondary)
                        .monospacedDigit()
                        .frame(width: 40, alignment: .leading)
                    
                    // Прогресс-бар
                    ProgressView(value: getCurrentTime(), total: getDuration())
                        .progressViewStyle(LinearProgressViewStyle(tint: K34Colors.primaryRed))
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                    
                    Text(formatTime(getDuration()))
                        .font(.caption)
                        .foregroundColor(K34Colors.textSecondary)
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
            
            Spacer()
            
            // Индикатор загрузки
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: K34Colors.primaryRed))
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(K34Colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(K34Colors.lightGray, lineWidth: 1)
        )
        .onAppear {
            // Предзагружаем аудио, если оно еще не загружено
            if audioData == nil && !isLoading {
                loadAudioData()
            }
        }
    }
    
    private func togglePlayback() {
        if voicePlayer.isPlaying && voicePlayer.currentMessageId == message.id {
            voicePlayer.stopPlayback()
        } else {
            if let data = audioData {
                voicePlayer.playAudio(from: data, messageId: message.id)
            } else {
                loadAndPlayAudio()
            }
        }
    }
    
    private func getPlayButtonIcon() -> String {
        if isLoading {
            return "hourglass"
        } else if voicePlayer.isPlaying && voicePlayer.currentMessageId == message.id {
            return "stop.circle.fill"
        } else {
            return "play.circle.fill"
        }
    }
    
    private func getCurrentTime() -> TimeInterval {
        if voicePlayer.isPlaying && voicePlayer.currentMessageId == message.id {
            return voicePlayer.currentPlaybackTime
        } else {
            return 0
        }
    }
    
    private func getDuration() -> TimeInterval {
        // Приоритеты для определения длительности:
        // 1. Длительность из плеера (во время воспроизведения)
        // 2. Фактическая длительность из загруженных данных
        // 3. Длительность из сообщения
        // 4. Fallback значение
        
        if voicePlayer.isPlaying && voicePlayer.currentMessageId == message.id && voicePlayer.duration > 0 {
            return voicePlayer.duration
        } else if actualDuration > 0 {
            return actualDuration
        } else if let messageDuration = message.duration, messageDuration > 0 {
            return messageDuration
        } else {
            return 10 // fallback 10 секунд
        }
    }
    
    private func loadAndPlayAudio() {
        isLoading = true
        matrixService.downloadMedia(for: message) { data in
            isLoading = false
            if let data = data {
                audioData = data
                // Получаем фактическую длительность из данных
                if let player = try? AVAudioPlayer(data: data) {
                    self.actualDuration = player.duration
                    print("DEBUG: Actual audio duration: \(self.actualDuration) seconds")
                }
                voicePlayer.playAudio(from: data, messageId: message.id)
            }
        }
    }
    
    private func loadAudioData() {
        isLoading = true
        matrixService.downloadMedia(for: message) { data in
            isLoading = false
            if let data = data {
                audioData = data
                // Получаем фактическую длительность из данных
                if let player = try? AVAudioPlayer(data: data) {
                    self.actualDuration = player.duration
                    print("DEBUG: Actual audio duration: \(self.actualDuration) seconds")
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
