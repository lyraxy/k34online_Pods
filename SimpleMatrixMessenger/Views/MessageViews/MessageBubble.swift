import Foundation
import MatrixSDK
import SwiftUI



// MARK: - Message Bubble with Reactions
struct MessageBubble: View {
    let message: Message
    @ObservedObject var matrixService: MatrixService
    let room: MXRoom
    @Binding var showReactionPickerForMessage: String?
    @StateObject private var voicePlayer = VoiceMessagePlayer() // Теперь каждый пузырек имеет свой плеер
    
    var body: some View {
        VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.isOutgoing {
                    Spacer()
                }
                
                VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                    Text(message.sender.replacingOccurrences(of: ":k34.online", with: "", options: .literal, range: nil))
                        .font(.caption)
                        .foregroundColor(K34Colors.textSecondary)
                    
                    if message.messageType == .text {
                        VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 2) {
                            Text(message.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(message.isOutgoing ? K34Colors.primaryRed : K34Colors.cardBackground)
                                .foregroundColor(message.isOutgoing ? .white : K34Colors.textPrimary)
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(message.isOutgoing ? K34Colors.primaryRed : K34Colors.lightGray, lineWidth: 1)
                                )
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Encryption status for text messages
                            if message.isEncrypted {
                                encryptionStatusView
                            }
                        }
                    } else if message.messageType == .file {
                        FileMessageView(message: message)
                    } else if message.messageType == .voice {
                        VoiceMessageView(
                            message: message,
                            matrixService: matrixService,
                            voicePlayer: voicePlayer
                        )
                    } else if message.messageType == .image {
                        ImageMessageView(message: message)
                    }
                    
                    // Отображение реакций
                    if !message.reactions.isEmpty {
                        ReactionsView(reactions: message.reactions) { reaction in
                            handleReactionTap(reaction)
                        }
                        .padding(.top, 2)
                    }
                    
                    HStack(spacing: 6) {
                        Text(formatTimestamp(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(K34Colors.lightGray)
                        
                        if message.isEncrypted {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundColor(K34Colors.encryptedGreen)
                        }
                    }
                }
                .contextMenu {
                    Button {
                        showReactionPickerForMessage = message.id
                    } label: {
                        Label("Добавить реакцию", systemImage: "face.smiling")
                    }
                    
                    if message.messageType == .text {
                        Button {
                            UIPasteboard.general.string = message.text
                        } label: {
                            Label("Копировать", systemImage: "doc.on.doc")
                        }
                    }
                    
                    if message.messageType == .voice {
                        Button {
                            // Действие для голосового сообщения
                        } label: {
                            Label("Действия с аудио", systemImage: "speaker.wave.2")
                        }
                    }
                    
                    if message.isEncrypted {
                        Button {
                            // Показать информацию о шифровании
                            showEncryptionInfo()
                        } label: {
                            Label("Информация о шифровании", systemImage: "lock.shield")
                        }
                    }
                }
                
                if !message.isOutgoing {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .onTapGesture(count: 2) {
            handleQuickReaction()
        }
        .onLongPressGesture {
            showReactionPickerForMessage = message.id
        }
        .onDisappear {
            // Останавливаем воспроизведение при исчезновении пузырька
            voicePlayer.stopPlayback()
        }
    }
    
    private var encryptionStatusView: some View {
        HStack(spacing: 4) {
            switch message.encryptionStatus {
            case .decrypted:
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 10))
                    .foregroundColor(K34Colors.encryptedGreen)
                Text("Зашифровано")
                    .font(.system(size: 10))
                    .foregroundColor(K34Colors.encryptedGreen)
            case .decryptionError(let error):
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 10))
                    .foregroundColor(K34Colors.warningYellow)
                Text("Ошибка расшифровки")
                    .font(.system(size: 10))
                    .foregroundColor(K34Colors.warningYellow)
            case .unencrypted:
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 10))
                    .foregroundColor(K34Colors.lightGray)
                Text("Не зашифровано")
                    .font(.system(size: 10))
                    .foregroundColor(K34Colors.lightGray)
            default:
                EmptyView()
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        // Проверка на валидность даты
        guard date.timeIntervalSince1970 > 0 else {
            return "--:--"
        }
        
        return formatter.string(from: date)
    }
    
    private func handleReactionTap(_ reaction: MessageReaction) {
        if reaction.didReact {
            matrixService.removeReaction(reaction.emoji, from: message.id, in: room.roomId)
        } else {
            matrixService.addReaction(reaction.emoji, to: message.id, in: room.roomId)
        }
    }
    
    private func handleQuickReaction() {
        if let existingReaction = message.reactions.first(where: { $0.emoji == "👍" && $0.didReact }) {
            matrixService.removeReaction("👍", from: message.id, in: room.roomId)
        } else {
            matrixService.addReaction("👍", to: message.id, in: room.roomId)
        }
    }
    
    private func showEncryptionInfo() {
        // Показываем информацию о шифровании сообщения
        let alert = UIAlertController(
            title: "Информация о шифровании",
            message: encryptionInfoMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private var encryptionInfoMessage: String {
        switch message.encryptionStatus {
        case .decrypted:
            return "Сообщение успешно расшифровано. End-to-end шифрование гарантирует, что только вы и отправитель можете читать это сообщение."
        case .decryptionError(let error):
            return "Не удалось расшифровать сообщение: \(error). Возможно, у вас нет нужного ключа шифрования."
        case .unencrypted:
            return "Это сообщение не зашифровано. Для полной безопасности рекомендуется использовать end-to-end шифрование."
        default:
            return "Статус шифрования неизвестен."
        }
    }
}
