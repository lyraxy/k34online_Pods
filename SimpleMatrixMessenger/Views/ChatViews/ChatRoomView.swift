import Foundation
import MatrixSDK
import SwiftUI

// MARK: - Chat Room View
struct ChatRoomView: View {
    @ObservedObject var matrixService: MatrixService
    let room: MXRoom
    @State private var messageText = ""
    @State private var showReactionPickerForMessage: String? = nil
    @State private var roomStatus: RoomStatus?
    @State private var showingLeaveAlert = false
    @State private var showingFilePicker = false
    @State private var showingVoiceRecorder = false
    @StateObject private var voiceRecorder = VoiceMessageRecorder()
    @State private var showingSecurityInfo = false
    @Environment(\.presentationMode) var presentationMode
    
    var roomMessages: [Message] {
        matrixService.messages
            .filter { $0.roomId == room.roomId }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    var isLoading: Bool {
        matrixService.isLoadingHistory[room.roomId] ?? false
    }
    
    var isInvited: Bool {
        roomStatus?.isInvited == true
    }
    
    var body: some View {
        ZStack {
            K34Colors.background.ignoresSafeArea()
            
            if isInvited {
                invitationView
            } else {
                chatView
            }
        }
        .navigationTitle(matrixService.getDisplayName(for: room))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if !isInvited {
                        Button(role: .destructive) {
                            showingLeaveAlert = true
                        } label: {
                            Label("Покинуть чат", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    
                    Button {
                        // Принудительно перезагружаем комнату
                        matrixService.joinRoom(roomId: room.roomId)
                    } label: {
                        Label("Обновить чат", systemImage: "arrow.clockwise")
                    }
                    
                    if roomStatus?.isEncrypted == true {
                        Button {
                            showingSecurityInfo = true
                        } label: {
                            Label("Информация о безопасности", systemImage: "shield.lefthalf.filled")
                        }
                        
                        Button {
                            matrixService.verifyRoom(roomId: room.roomId)
                        } label: {
                            Label("Проверить безопасность", systemImage: "checkmark.shield")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(K34Colors.primaryRed)
                }
            }
        }
        .onAppear {
            // Всегда загружаем историю при входе в комнату, независимо от статуса
            matrixService.joinRoom(roomId: room.roomId)
            updateRoomStatus()
        }
        .onReceive(matrixService.objectWillChange) { _ in
            updateRoomStatus()
        }
        .onReceive(matrixService.$lastRoomUpdate) { _ in
            // Принудительно обновляем представление при обновлении комнат
            updateRoomStatus()
        }
        .sheet(item: $showReactionPickerForMessage) { messageId in
            ReactionPickerView(
                messageId: messageId,
                matrixService: matrixService,
                room: room
            )
        }
        .sheet(isPresented: $showingVoiceRecorder) {
            VoiceMessageRecorderView(
                isPresented: $showingVoiceRecorder,
                voiceRecorder: voiceRecorder,
                onSend: { audioData in
                    matrixService.sendVoiceMessage(audioData, in: room.roomId)
                }
            )
        }
        .sheet(isPresented: $showingSecurityInfo) {
            SecurityInfoView(
                isPresented: $showingSecurityInfo,
                matrixService: matrixService,
                room: room
            )
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Покинуть чат", isPresented: $showingLeaveAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Покинуть", role: .destructive) {
                leaveRoom()
            }
        } message: {
            Text("Вы уверены, что хотите покинуть этот чат?")
        }
    }
    
    private var chatView: some View {
        VStack(spacing: 0) {
            // Security Banner
            if let status = roomStatus, status.isEncrypted {
                HStack(spacing: 8) {
                    Image(systemName: securityStatusIcon)
                        .foregroundColor(securityStatusColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(securityStatusTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(K34Colors.textPrimary)
                        
                        if let subtitle = securityStatusSubtitle {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(K34Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if status.encryptionStatus == .unverified {
                        Button("Проверить") {
                            matrixService.verifyRoom(roomId: room.roomId)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(K34Colors.primaryRed)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(securityStatusBackground)
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
            
            if isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: K34Colors.primaryRed))
                        .scaleEffect(0.8)
                    Text("Загрузка сообщений...")
                        .font(.caption)
                        .foregroundColor(K34Colors.textSecondary)
                }
                .padding()
                .background(K34Colors.cardBackground)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        if !isLoading && roomMessages.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "message")
                                    .font(.system(size: 50))
                                    .foregroundColor(K34Colors.lightGray)
                                Text("Пока нет сообщений")
                                    .font(.title2)
                                    .foregroundColor(K34Colors.textPrimary)
                                Text("Начните общение!")
                                    .font(.body)
                                    .foregroundColor(K34Colors.textSecondary)
                            }
                            .frame(height: 300)
                            .padding(40)
                        } else {
                            ForEach(roomMessages) { message in
                                MessageBubble(
                                    message: message,
                                    matrixService: matrixService,
                                    room: room,
                                    showReactionPickerForMessage: $showReactionPickerForMessage
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: roomMessages.count) { _ in
                    if let lastMessage = roomMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastMessage = roomMessages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            // Message Input
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Attachment Button
                    Menu {
                        Button {
                            showingFilePicker = true
                        } label: {
                            Label("Отправить файл", systemImage: "folder")
                        }
                        
                        Button {
                            showingVoiceRecorder = true
                        } label: {
                            Label("Голосовое сообщение", systemImage: "mic.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(K34Colors.primaryRed)
                    }
                    
                    TextField("Напишите сообщение...", text: $messageText)
                        .textFieldStyle(K34TextFieldStyle())
                        .onSubmit {
                            sendMessage()
                        }
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(K34Colors.primaryRed)
                            .clipShape(Circle())
                            .shadow(color: K34Colors.primaryRed.opacity(0.3), radius: 5)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(K34Colors.cardBackground)
            }
        }
    }
    
    private var securityStatusIcon: String {
        guard let status = roomStatus else { return "lock.open.fill" }
        switch status.encryptionStatus {
        case .verified:
            return "checkmark.shield.fill"
        case .unverified:
            return "exclamationmark.shield"
        case .unknown:
            return "questionmark.shield"
        case .notEncrypted:
            return "lock.open.fill"
        }
    }
    
    private var securityStatusColor: Color {
        guard let status = roomStatus else { return K34Colors.lightGray }
        switch status.encryptionStatus {
        case .verified:
            return K34Colors.encryptedGreen
        case .unverified:
            return K34Colors.warningYellow
        case .unknown:
            return K34Colors.lightGray
        case .notEncrypted:
            return K34Colors.lightGray
        }
    }
    
    private var securityStatusTitle: String {
        guard let status = roomStatus else { return "Чат не зашифрован" }
        
        if !status.isEncrypted {
            return "Чат не зашифрован"
        }
        
        switch status.encryptionStatus {
        case .verified:
            return "Безопасность проверена"
        case .unverified:
            return "Требуется проверка безопасности"
        case .unknown:
            return "Статус безопасности неизвестен"
        case .notEncrypted:
            return "Чат не зашифрован"
        }
    }
    
    private var securityStatusSubtitle: String? {
        guard let status = roomStatus, status.isEncrypted else { return nil }
        
        switch status.encryptionStatus {
        case .verified:
            return "Все участники проверены"
        case .unverified:
            return "Нажмите 'Проверить' для верификации"
        case .unknown:
            return "Не удалось проверить безопасность"
        default:
            return nil
        }
    }
    
    private var securityStatusBackground: Color {
        guard let status = roomStatus else { return K34Colors.cardBackground }
        
        if !status.isEncrypted {
            return K34Colors.cardBackground
        }
        
        switch status.encryptionStatus {
        case .verified:
            return K34Colors.encryptedGreen.opacity(0.1)
        case .unverified:
            return K34Colors.warningYellow.opacity(0.1)
        default:
            return K34Colors.cardBackground
        }
    }
    
    private var invitationView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 60))
                    .foregroundColor(K34Colors.primaryRed)
                
                Text("Приглашение в чат")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(K34Colors.textPrimary)
                
                Text("Вас пригласили в чат с пользователем")
                    .font(.body)
                    .foregroundColor(K34Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text(matrixService.getDisplayName(for: room))
                    .font(.headline)
                    .foregroundColor(K34Colors.primaryRed)
                    .padding()
                    .background(K34Colors.cardBackground)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            VStack(spacing: 15) {
                Button("Принять приглашение") {
                    acceptInvitation()
                }
                .buttonStyle(K34ButtonStyle())
                .frame(maxWidth: .infinity)
                
                Button("Отклонить") {
                    rejectInvitation()
                }
                .foregroundColor(K34Colors.lightRed)
                .padding()
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private func updateRoomStatus() {
        roomStatus = matrixService.getRoomStatus(for: room)
    }
    
    private func acceptInvitation() {
        matrixService.acceptInvitation(roomId: room.roomId) { success in
            if success {
                // После принятия приглашения сразу загружаем историю комнаты
                matrixService.joinRoom(roomId: room.roomId)
                // Обновляем статус комнаты
                updateRoomStatus()
            }
        }
    }
    
    private func rejectInvitation() {
        matrixService.rejectInvitation(roomId: room.roomId) { success in
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func leaveRoom() {
        matrixService.leaveRoom(roomId: room.roomId) { success in
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        matrixService.sendMessage(trimmedText, in: room.roomId)
        messageText = ""
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            matrixService.sendFile(url, in: room.roomId)
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
}
