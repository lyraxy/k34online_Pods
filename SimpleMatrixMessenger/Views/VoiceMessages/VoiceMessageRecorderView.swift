import Foundation
import MatrixSDK
import SwiftUI

// MARK: - Voice Message Recorder View
struct VoiceMessageRecorderView: View {
    @Binding var isPresented: Bool
    @ObservedObject var voiceRecorder: VoiceMessageRecorder
    var onSend: (Data) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                K34Colors.background.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(K34Colors.primaryRed)
                        
                        Text(voiceRecorder.isRecording ? "Запись..." : "Голосовое сообщение")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(K34Colors.textPrimary)
                        
                        Text(formatTime(voiceRecorder.recordingTime))
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundColor(K34Colors.textSecondary)
                        
                        if let url = voiceRecorder.recordingURL, !voiceRecorder.isRecording {
                            VoiceMessagePreview(
                                voiceRecorder: voiceRecorder,
                                recordingURL: url
                            )
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 30) {
                        if voiceRecorder.isRecording {
                            Button("Остановить") {
                                voiceRecorder.stopRecording()
                            }
                            .buttonStyle(K34ButtonStyle())
                        } else {
                            if voiceRecorder.recordingURL == nil {
                                Button("Начать запись") {
                                    voiceRecorder.startRecording()
                                }
                                .buttonStyle(K34ButtonStyle())
                            } else {
                                Button("Перезаписать") {
                                    voiceRecorder.deleteRecording()
                                    voiceRecorder.startRecording()
                                }
                                .foregroundColor(K34Colors.lightRed)
                                
                                Button("Отправить") {
                                    if let audioData = voiceRecorder.getRecordingData() {
                                        onSend(audioData)
                                        isPresented = false
                                        voiceRecorder.deleteRecording()
                                    }
                                }
                                .buttonStyle(K34ButtonStyle())
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Запись голоса")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        voiceRecorder.deleteRecording()
                        isPresented = false
                    }
                    .foregroundColor(K34Colors.primaryRed)
                }
            }
            .alert("Доступ к микрофону", isPresented: $voiceRecorder.showPermissionAlert) {
                Button("OK", role: .cancel) { }
                Button("Настройки") {
                    // Открываем настройки для предоставления разрешения
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            } message: {
                Text(voiceRecorder.permissionError ?? "Для записи голосовых сообщений требуется доступ к микрофону.")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Предварительно запрашиваем разрешение при открытии экрана
            voiceRecorder.requestMicrophonePermission { _ in }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
