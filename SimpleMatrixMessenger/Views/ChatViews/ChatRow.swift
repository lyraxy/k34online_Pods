import Foundation
import MatrixSDK
import SwiftUI

// MARK: - Chat Row
struct ChatRow: View {
    let room: MXRoom
    @ObservedObject var matrixService: MatrixService
    var onLeaveRoom: (() -> Void)? = nil
    @State private var displayName: String = ""
    @State private var lastMessageText: String = "Пока нет сообщений"
    @State private var lastMessageTime: String = ""
    @State private var roomStatus: RoomStatus?
    @State private var showingContextMenu = false
    @State private var updateTrigger = 0
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar with status indicator
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 50, height: 50)
                    
                    Text(displayName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Encryption badge
                    if roomStatus?.isEncrypted == true {
                        Circle()
                            .fill(K34Colors.encryptedGreen)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 18, y: 18)
                    }
                }
                
                // Status indicator
                if let status = roomStatus {
                    Circle()
                        .fill(statusColor(for: status))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(K34Colors.background, lineWidth: 2)
                        )
                }
            }
            
            // Chat Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(K34Colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let status = roomStatus {
                        statusBadge(for: status)
                    }
                }
                
                HStack(spacing: 4) {
                    if roomStatus?.isEncrypted == true {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(K34Colors.encryptedGreen)
                    }
                    
                    Text(lastMessageText)
                        .font(.system(size: 14))
                        .foregroundColor(K34Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Text(lastMessageTime)
                    .font(.system(size: 12))
                    .foregroundColor(K34Colors.lightGray)
            }
            
            Spacer()
            
            // Unread Count
            if room.summary?.localUnreadEventCount ?? 0 > 0 {
                Text("\(room.summary?.localUnreadEventCount ?? 0)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(K34Colors.primaryRed)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            updateDisplayInfo()
            startAutoRefresh()
        }
        .onReceive(matrixService.$messages) { _ in
            updateLastMessagePreview()
        }
        .onReceive(matrixService.objectWillChange) { _ in
            updateDisplayInfo()
        }
        .onReceive(matrixService.$lastRoomUpdate) { _ in
            // Обновляем превью при глобальном обновлении комнат
            updateLastMessagePreview()
        }
        .onChange(of: updateTrigger) { _ in
            // Принудительное обновление по таймеру
            updateLastMessagePreview()
        }
        .contextMenu {
            if roomStatus?.isInvited != true && roomStatus?.isInvitationOutgoing != true {
                Button(role: .destructive) {
                    onLeaveRoom?()
                } label: {
                    Label("Покинуть чат", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            
            Button {
                matrixService.loadRooms()
            } label: {
                Label("Обновить", systemImage: "arrow.clockwise")
            }
            
            if roomStatus?.isEncrypted == true {
                Button {
                    matrixService.verifyRoom(roomId: room.roomId)
                } label: {
                    Label("Проверить безопасность", systemImage: "shield.checkerboard")
                }
            }
        }
    }
    
    private var avatarColor: Color {
        if let status = roomStatus {
            if status.isInvited {
                return K34Colors.primaryRed
            } else if status.isInvitationOutgoing {
                return K34Colors.lightGray
            }
        }
        return K34Colors.primaryRed
    }
    
    private func statusColor(for status: RoomStatus) -> Color {
        if status.isInvited {
            return .green
        } else if status.isInvitationOutgoing {
            return .yellow
        }
        return .green
    }
    
    private func statusBadge(for status: RoomStatus) -> some View {
        Group {
            if status.isInvited {
                Text("Приглашение")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(8)
            } else if status.isInvitationOutgoing {
                Text("Ожидание")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(K34Colors.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.yellow)
                    .cornerRadius(8)
            } else if status.isEncrypted {
                if status.encryptionStatus == .verified {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 12))
                        .foregroundColor(K34Colors.encryptedGreen)
                } else if status.encryptionStatus == .unverified {
                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 12))
                        .foregroundColor(K34Colors.warningYellow)
                }
            }
        }
    }
    
    private func updateDisplayInfo() {
        updateDisplayName()
        updateLastMessagePreview()
        updateRoomStatus()
    }
    
    private func updateRoomStatus() {
        roomStatus = matrixService.getRoomStatus(for: room)
    }
    
    private func updateDisplayName() {
        let initialName = matrixService.getDisplayName(for: room)
        displayName = initialName
        
        if initialName.contains("@") && initialName.contains(":") {
            matrixService.loadUserDisplayName(userId: initialName) { betterName in
                if let betterName = betterName, !betterName.isEmpty {
                    displayName = betterName
                }
            }
        }
    }
    
    private func updateLastMessagePreview() {
        let preview = matrixService.getLastMessagePreview(for: room)
        lastMessageText = preview.text
        lastMessageTime = preview.time
    }
    
    private func startAutoRefresh() {
        // Обновляем превью каждые 10 секунд
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            updateTrigger += 1
        }
    }
}
