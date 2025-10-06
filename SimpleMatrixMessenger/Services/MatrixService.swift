import Foundation
import MatrixSDK

struct Message: Identifiable, Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let text: String
    let sender: String
    let timestamp: Date
    let roomId: String
    let isOutgoing: Bool
    var reactions: [MessageReaction]
    let messageType: MessageType
    let mediaURL: String?
    let fileName: String?
    let fileSize: Int?
    let duration: TimeInterval?
    var isVoicePlaying: Bool = false
    let isEncrypted: Bool
    let encryptionStatus: EncryptionStatus
    let originalEvent: MXEvent?
}

@MainActor
// MARK: - Matrix Service with E2EE Support
class MatrixService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var rooms: [MXRoom] = []
    @Published var isLoading = false
    @Published var isLoadingRooms = false
    @Published var error: String?
    @Published var isLoggedIn = false
    @Published var currentUserId: String?
    @Published var isLoadingHistory: [String: Bool] = [:]
    @Published var roomStatuses: [String: RoomStatus] = [:]
    @Published var lastRoomUpdate = Date()
    
    private var mxRestClient: MXRestClient?
    private var mxSession: MXSession?
    private var roomListeners: [String: Any] = [:]
    private var userDisplayNames: [String: String] = [:]
    private var processedEventIds: Set<String> = []
    private var hasSetupRoomListeners = false
    private var reactionEvents: [String: [MXEvent]] = [:]
    private var backgroundRefreshTimer: Timer?
    private var mediaCache: [String: Data] = [:]
    private var enableEncryptionByDefault = true

    // MARK: - Login and Session Setup with E2EE
    func login(username: String, password: String) {
        isLoading = true
        error = nil
        let newUsername = "\(username):k34.online"
        let homeserverURL = URL(string: "https://k34.online")!
        mxRestClient = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
        
        mxRestClient?.login(username: newUsername, password: password) { [weak self] response in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch response {
                case .success(let credentials):
                    self.setupSession(credentials: credentials)
                    self.isLoggedIn = true
                    self.currentUserId = credentials.userId
                case .failure(let error):
                    self.error = error.localizedDescription
                    self.isLoggedIn = false
                }
            }
        }
    }
    
    private func setupSession(credentials: MXCredentials) {
        mxRestClient = MXRestClient(credentials: credentials, unrecognizedCertificateHandler: nil)
        
        // Создаем сессию с поддержкой шифрования
        let session = MXSession(matrixRestClient: mxRestClient!)
        mxSession = session
        
        session!.start { [weak self] response in
            guard let self = self else { return }
            
            if case .success = response {
                self.loadRooms()
                self.setupAllRoomListeners()
                self.startBackgroundRefresh()
            } else if case .failure(let error) = response {
                self.error = error.localizedDescription
            }
        }
    }
    
    func loadRooms() {
        guard let session = mxSession else { return }
        
        isLoadingRooms = true
        rooms = session.rooms ?? []
        updateRoomStatuses()
        
        // Имитируем загрузку для лучшего UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoadingRooms = false
            self.lastRoomUpdate = Date()
        }
    }
    
    func backgroundRefreshRooms() {
        guard let session = mxSession, !isLoadingRooms else { return }
        
        // Тихий фоновый refresh без индикатора загрузки
        let previousRooms = rooms
        rooms = session.rooms ?? []
        updateRoomStatuses()
        
        // Обновляем lastRoomUpdate только если есть изменения
        if rooms != previousRooms {
            lastRoomUpdate = Date()
        }
    }
    
    private func startBackgroundRefresh() {
        // Фоновое обновление каждые 30 секунд
        backgroundRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.backgroundRefreshRooms()
        }
    }
    
    private func stopBackgroundRefresh() {
        backgroundRefreshTimer?.invalidate()
        backgroundRefreshTimer = nil
    }
    
    // MARK: - Room Status Management with Encryption
    private func updateRoomStatuses() {
        guard let session = mxSession else { return }
        
        var newStatuses: [String: RoomStatus] = [:]
        
        for room in session.rooms ?? [] {
            let roomId = room.roomId
            let membership = room.summary?.membership ?? .unknown
            
            let isInvited = membership == .invite
            let isInvitationOutgoing = self.isInvitationOutgoing(room: room)
            let otherUserId = self.getOtherUserId(for: room)
            let isEncrypted = room.summary?.isEncrypted ?? false
            let encryptionStatus = self.getRoomEncryptionStatus(for: room)
            
            newStatuses[roomId!] = RoomStatus(
                roomId: roomId!,
                isInvited: isInvited,
                isInvitationOutgoing: isInvitationOutgoing,
                otherUserId: otherUserId,
                isEncrypted: isEncrypted,
                encryptionStatus: encryptionStatus
            )
        }
        
        DispatchQueue.main.async {
            self.roomStatuses = newStatuses
        }
    }
    
    private func getRoomEncryptionStatus(for room: MXRoom) -> RoomEncryptionStatus {
        guard room.summary?.isEncrypted == true else {
            return .notEncrypted
        }
        
        // В реальной реализации здесь будет проверка верификации устройств
        // Для демонстрации возвращаем случайный статус
        let statuses: [RoomEncryptionStatus] = [.verified, .unverified, .unknown]
        return statuses.randomElement() ?? .unknown
    }
    
    private func isInvitationOutgoing(room: MXRoom) -> Bool {
        // Упрощенная логика: считаем что комната с исходящим приглашением
        // если мы ее создали и у нее есть приглашенные участники
        guard let summary = room.summary else { return false }
        
        // Если мы создатель комнаты и наша membership - join,
        // но комната еще не полностью активна (мало сообщений)
        if summary.membership == .join {
            // Исправление: правильный доступ к membersCount
            let memberCount = summary.membersCount.members
            let hasLastMessage = summary.lastMessage != nil
            
            return memberCount <= 2 && !hasLastMessage
        }
        
        return false
    }
    
    private func getOtherUserId(for room: MXRoom) -> String? {
        // Для прямых чатов используем directUserId
        if room.isDirect {
            return room.directUserId
        }
        
        // Для групповых чатов возвращаем отображаемое имя или nil
        return room.summary?.displayName
    }
    
    func getRoomStatus(for room: MXRoom) -> RoomStatus? {
        return roomStatuses[room.roomId]
    }
    
    // MARK: - Security State
    func getSecurityState(for roomId: String) -> SecurityState? {
        guard let session = mxSession,
              let crypto = session.crypto,
              let currentUserId = session.myUserId else {
            return nil
        }
        
        let deviceId = session.myDeviceId
        let deviceTrust = crypto.deviceTrustLevel(forDevice: deviceId!, ofUser: currentUserId)
        
        // Упрощенная проверка cross-signing - используем базовые возможности
        let isCrossSigned = crypto.crossSigning.canCrossSign
        
        return SecurityState(
            deviceId: deviceId,
            deviceTrust: deviceTrust,
            isVerified: deviceTrust?.isVerified ?? false,
            isCrossSigned: isCrossSigned
        )
    }
    
    // MARK: - Room Verification
    func verifyRoom(roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else { return }
        
        // В реальной реализации здесь будет запуск процесса верификации комнаты
        // Для демонстрации просто обновляем статус
        updateRoomStatuses()
        
        // Показываем уведомление о начале верификации
        DispatchQueue.main.async {
            self.error = "Запущен процесс проверки безопасности комнаты"
        }
    }
    
    func verifyAllDevices() {
        // В реальной реализации здесь будет запуск процесса верификации всех устройств
        // Для демонстрации просто показываем уведомление
        DispatchQueue.main.async {
            self.error = "Запущен процесс проверки всех устройств"
        }
    }
    
    // MARK: - Room Leaving
    func leaveRoom(roomId: String, completion: ((Bool) -> Void)? = nil) {
        guard let room = mxSession?.room(withRoomId: roomId) else {
            completion?(false)
            return
        }
        
        room.leave { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success:
                    // Удаляем комнату из списка
                    self?.rooms.removeAll { $0.roomId == roomId }
                    // Удаляем сообщения этой комнаты
                    self?.messages.removeAll { $0.roomId == roomId }
                    // Удаляем статус комнаты
                    self?.roomStatuses.removeValue(forKey: roomId)
                    // Удаляем listener
                    if let listener = self?.roomListeners[roomId] {
                        room.removeListener(listener)
                        self?.roomListeners.removeValue(forKey: roomId)
                    }
                    self?.error = nil
                    self?.lastRoomUpdate = Date()
                    completion?(true)
                case .failure(let error):
                    self?.error = "Ошибка при выходе из чата: \(error.localizedDescription)"
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - Invitation Handling
    func acceptInvitation(roomId: String, completion: @escaping (Bool) -> Void) {
        guard let room = mxSession?.room(withRoomId: roomId) else {
            completion(false)
            return
        }
        
        room.join { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success:
                    // После успешного принятия приглашения настраиваем слушатель и загружаем историю
                    self?.setupRoomListener(for: room)
                    self?.loadRoomHistoryAfterAcceptingInvitation(for: room)
                    self?.loadRooms()
                    self?.updateRoomStatuses()
                    completion(true)
                case .failure(let error):
                    self?.error = "Ошибка принятия приглашения: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    private func loadRoomHistoryAfterAcceptingInvitation(for room: MXRoom) {
        let roomId = room.roomId!
        
        // Устанавливаем флаг загрузки для этой комнаты
        isLoadingHistory[roomId] = true
        
        room.liveTimeline { [weak self] timeline in
            guard let self = self, let timeline = timeline else {
                DispatchQueue.main.async {
                    self?.isLoadingHistory[roomId] = false
                }
                return
            }
            
            // Сбрасываем пагинацию и загружаем историю
            timeline.resetPagination()
            self.paginateRoomHistoryAfterAcceptingInvitation(timeline: timeline, room: room)
        }
    }
    
    private func paginateRoomHistoryAfterAcceptingInvitation(timeline: MXEventTimeline, room: MXRoom) {
        let roomId = room.roomId!
        
        timeline.paginate(100, direction: .backwards, onlyFromStore: false) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                if timeline.canPaginate(.backwards) {
                    self.paginateRoomHistoryAfterAcceptingInvitation(timeline: timeline, room: room)
                } else {
                    // После загрузки истории запускаем прослушивание новых событий
                    self.startListeningToRoomEvents(room)
                    DispatchQueue.main.async {
                        self.isLoadingHistory[roomId] = false
                        self.lastRoomUpdate = Date()
                    }
                }
            case .failure(let error):
                print("Ошибка загрузки истории после принятия приглашения: \(error)")
                // Все равно запускаем прослушивание новых событий
                self.startListeningToRoomEvents(room)
                DispatchQueue.main.async {
                    self.isLoadingHistory[roomId] = false
                }
            }
        }
    }
    
    private func startListeningToRoomEvents(_ room: MXRoom) {
        let roomId = room.roomId!
        
        room.liveTimeline { [weak self] timeline in
            guard let self = self, let timeline = timeline else { return }
            
            // Начинаем слушать события в реальном времени
            timeline.listenToEvents { [weak self] event, direction, roomState in
                guard let self = self else { return }
                
                self.handleTimelineEvent(event, direction: direction, roomId: roomId)
            }
            
            // Обрабатываем существующие события из store
            timeline.resetPagination()
            timeline.paginate(100, direction: .backwards, onlyFromStore: true) { response in
                // После загрузки существующих событий timeline будет содержать их
            }
        }
    }
    
    func rejectInvitation(roomId: String, completion: @escaping (Bool) -> Void) {
        leaveRoom(roomId: roomId, completion: completion)
    }
    
    private func setupAllRoomListeners() {
        guard let session = mxSession, !hasSetupRoomListeners else { return }
        
        for room in session.rooms ?? [] {
            setupRoomListener(for: room)
        }
        hasSetupRoomListeners = true
        updateRoomStatuses()
    }
    
    private func setupRoomListener(for room: MXRoom) {
        let roomId = room.roomId!
        
        // Удаляем существующий слушатель, если есть
        if let existingListener = roomListeners[roomId] {
            room.removeListener(existingListener)
        }
        
        // Создаем нового слушателя
        let listener = room.liveTimeline { [weak self] timeline in
            guard let self = self, let timeline = timeline else { return }
            
            // Слушаем новые события
            timeline.listenToEvents { [weak self] event, direction, roomState in
                guard let self = self else { return }
                
                self.handleTimelineEvent(event, direction: direction, roomId: roomId)
            }
            
            // Загружаем существующие события из store
            timeline.resetPagination()
            timeline.paginate(100, direction: .backwards, onlyFromStore: true) { response in
                // События теперь будут доступны через listenToEvents
            }
        }
        
        roomListeners[roomId] = listener
    }
    
    // MARK: - Room Management
    func joinRoom(roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else { return }
        
        // Убеждаемся, что слушатель настроен
        setupRoomListener(for: room)
        
        // Загружаем историю комнаты
        isLoadingHistory[roomId] = true
        loadRoomHistory(for: room)
    }
    
    private func loadRoomHistory(for room: MXRoom) {
        let roomId = room.roomId!
        
        room.liveTimeline { [weak self] timeline in
            guard let self = self, let timeline = timeline else {
                DispatchQueue.main.async {
                    self?.isLoadingHistory[roomId] = false
                }
                return
            }
            
            timeline.resetPagination()
            self.paginateRoomHistory(timeline: timeline, room: room)
        }
    }
    
    private func paginateRoomHistory(timeline: MXEventTimeline, room: MXRoom) {
        let roomId = room.roomId!
        
        timeline.paginate(100, direction: .backwards, onlyFromStore: false) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                if timeline.canPaginate(.backwards) {
                    self.paginateRoomHistory(timeline: timeline, room: room)
                } else {
                    DispatchQueue.main.async {
                        self.isLoadingHistory[roomId] = false
                        self.lastRoomUpdate = Date()
                    }
                }
            case .failure(let error):
                print("Ошибка загрузки истории: \(error)")
                DispatchQueue.main.async {
                    self.isLoadingHistory[roomId] = false
                }
            }
        }
    }
    
    private func handleTimelineEvent(_ event: MXEvent, direction: MXTimelineDirection, roomId: String) {
        if event.eventType == .roomMember {
            DispatchQueue.main.async {
                self.updateRoomStatuses()
                self.lastRoomUpdate = Date()
            }
        }
        
        if event.eventType == .roomMessage || event.eventType == .roomEncrypted {
            if let message = createMessage(from: event, roomId: roomId) {
                DispatchQueue.main.async {
                    if !self.processedEventIds.contains(message.id) {
                        self.processedEventIds.insert(message.id)
                        self.messages.append(message)
                        self.messages.sort { $0.timestamp < $1.timestamp }
                        self.lastRoomUpdate = Date()
                        self.objectWillChange.send()
                    }
                }
            }
        } else if event.eventType == .reaction {
            handleReactionEvent(event, roomId: roomId)
        } else if event.eventType == .roomRedaction {
            handleRedactionEvent(event, roomId: roomId)
        }
    }
    
    private func handleRedactionEvent(_ event: MXEvent, roomId: String) {
        guard let redactedEventId = event.redacts else { return }
        
        DispatchQueue.main.async {
            for (messageId, events) in self.reactionEvents {
                if let index = events.firstIndex(where: { $0.eventId == redactedEventId }) {
                    self.reactionEvents[messageId]?.remove(at: index)
                    
                    if let messageIndex = self.messages.firstIndex(where: { $0.id == messageId }) {
                        var updatedMessage = self.messages[messageIndex]
                        updatedMessage.reactions = self.calculateReactions(for: messageId)
                        self.messages[messageIndex] = updatedMessage
                    }
                    break
                }
            }
            
            self.lastRoomUpdate = Date()
            self.objectWillChange.send()
        }
    }
    
    private func handleReactionEvent(_ event: MXEvent, roomId: String) {
        if event.isRedactedEvent() {
            return
        }
        
        guard let relatesTo = event.content["m.relates_to"] as? [String: Any],
              let relType = relatesTo["rel_type"] as? String,
              relType == "m.annotation",
              let eventId = relatesTo["event_id"] as? String,
              let key = relatesTo["key"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            if self.reactionEvents[eventId] == nil {
                self.reactionEvents[eventId] = []
            }
            
            if let existingIndex = self.reactionEvents[eventId]?.firstIndex(where: {
                $0.eventId == event.eventId ||
                ($0.sender == event.sender &&
                 ($0.content["m.relates_to"] as? [String: Any])?["key"] as? String == key)
            }) {
                self.reactionEvents[eventId]?[existingIndex] = event
            } else {
                self.reactionEvents[eventId]?.append(event)
            }
            
            if let messageIndex = self.messages.firstIndex(where: { $0.id == eventId }) {
                var updatedMessage = self.messages[messageIndex]
                updatedMessage.reactions = self.calculateReactions(for: eventId)
                self.messages[messageIndex] = updatedMessage
                self.lastRoomUpdate = Date()
                self.objectWillChange.send()
            }
        }
    }
    
    private func calculateReactions(for messageId: String) -> [MessageReaction] {
        guard let events = reactionEvents[messageId] else { return [] }
        
        var reactionCounts: [String: (count: Int, users: [String])] = [:]
        
        for event in events {
            if event.isRedactedEvent() {
                continue
            }
            
            guard let relatesTo = event.content["m.relates_to"] as? [String: Any],
                  let key = relatesTo["key"] as? String else { continue }
            
            if reactionCounts[key] == nil {
                reactionCounts[key] = (0, [])
            }
            
            let isRedacted = event.isState()
            if !isRedacted, let sender = event.sender {
                reactionCounts[key]?.count += 1
                reactionCounts[key]?.users.append(sender)
            }
        }
        
        return reactionCounts.map { emoji, data in
            MessageReaction(
                emoji: emoji,
                count: data.count,
                users: data.users,
                didReact: data.users.contains(currentUserId ?? "")
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func createMessage(from event: MXEvent, roomId: String) -> Message? {
        guard event.eventType == .roomMessage || event.eventType == .roomEncrypted else {
            return nil
        }
        
        var messageText = ""
        var messageType: MessageType = .text
        var mediaURL: String? = nil
        var fileName: String? = nil
        var fileSize: Int? = nil
        var duration: TimeInterval? = nil
        var isEncrypted = event.eventType == .roomEncrypted
        var encryptionStatus: EncryptionStatus = isEncrypted ? .unknown : .unencrypted
        
        // Если сообщение зашифровано, проверяем статус расшифровки
        if isEncrypted {
            if event.decryptionError == nil {
                encryptionStatus = .decrypted
            } else {
                encryptionStatus = .decryptionError(event.decryptionError?.localizedDescription ?? "Unknown error")
            }
        }
        
        if let text = event.content["body"] as? String {
            messageText = text
            
            let msgtype = event.content["msgtype"] as? String
            
            if msgtype == "m.image" {
                messageType = .image
                if let url = event.content["url"] as? String {
                    mediaURL = url
                }
            } else if msgtype == "m.file" {
                messageType = .file
                if let url = event.content["url"] as? String {
                    mediaURL = url
                }
                if let info = event.content["info"] as? [String: Any] {
                    fileName = event.content["filename"] as? String ?? "Файл"
                    fileSize = info["size"] as? Int
                    
                    // Проверяем, является ли файл голосовым сообщением
                    if let mimetype = info["mimetype"] as? String, mimetype == "audio/mp4" ||
                       fileName?.hasSuffix(".m4a") == true || fileName?.hasSuffix(".mp4") == true {
                        messageType = .voice
                        // Получаем длительность из информации о файле
                        if let durationMs = info["duration"] as? Int {
                            duration = TimeInterval(durationMs) / 1000.0 // конвертируем мс в секунды
                        } else if let durationSeconds = info["duration"] as? TimeInterval {
                            duration = durationSeconds
                        }
                        print("DEBUG: Voice message duration from event: \(duration ?? 0) seconds")
                    }
                }
            } else if msgtype == "m.audio" {
                messageType = .voice
                if let url = event.content["url"] as? String {
                    mediaURL = url
                }
                if let info = event.content["info"] as? [String: Any] {
                    // Получаем длительность из информации о аудио
                    if let durationMs = info["duration"] as? Int {
                        duration = TimeInterval(durationMs) / 1000.0 // конвертируем мс в секунды
                    } else if let durationSeconds = info["duration"] as? TimeInterval {
                        duration = durationSeconds
                    }
                    fileName = event.content["filename"] as? String ?? "Голосовое сообщение"
                    fileSize = info["size"] as? Int
                    print("DEBUG: Audio message duration from event: \(duration ?? 0) seconds")
                }
            }
        } else {
            // Для зашифрованных сообщений без текста
            if isEncrypted && encryptionStatus == .decrypted {
                messageText = "Зашифрованное сообщение"
            } else if isEncrypted {
                messageText = "Не удалось расшифровать сообщение"
            } else {
                return nil
            }
        }
        
        // Исправление для NaN ошибки: безопасное создание даты
        let timestamp: Date
        if event.originServerTs != 0 && event.originServerTs > 1000000000000 {
            timestamp = Date(timeIntervalSince1970: TimeInterval(event.originServerTs / 1000))
        } else {
            timestamp = Date()
        }
        
        let messageId = event.eventId ?? UUID().uuidString
        let reactions = calculateReactions(for: messageId)
        
        return Message(
            id: messageId,
            text: messageText,
            sender: event.sender ?? "Unknown",
            timestamp: timestamp,
            roomId: roomId,
            isOutgoing: event.sender == self.currentUserId,
            reactions: reactions,
            messageType: messageType,
            mediaURL: mediaURL,
            fileName: fileName,
            fileSize: fileSize,
            duration: duration,
            isEncrypted: isEncrypted,
            encryptionStatus: encryptionStatus,
            originalEvent: event
        )
    }
    
    // MARK: - File and Voice Message Sending with Encryption
    func sendFile(_ fileURL: URL, in roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else {
            error = "Комната не найдена"
            return
        }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let mimeType = "application/octet-stream"
            
            // Создаем временный файл для отправки
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            try fileData.write(to: tempURL)
            
            // Используем упрощенный вызов sendFile
            var localEcho: MXEvent?
            room.sendFile(localURL: tempURL, mimeType: mimeType, localEcho: &localEcho) { [weak self] (response: MXResponse<String?>) in
                DispatchQueue.main.async {
                    // Удаляем временный файл
                    try? FileManager.default.removeItem(at: tempURL)
                    
                    switch response {
                    case .success:
                        self?.lastRoomUpdate = Date()
                    case .failure(let error):
                        self?.error = "Ошибка отправки файла: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            self.error = "Ошибка чтения файла: \(error.localizedDescription)"
        }
    }

    func sendVoiceMessage(_ audioData: Data, in roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else {
            error = "Комната не найдена"
            return
        }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("voice-\(Date().timeIntervalSince1970).m4a")
        
        do {
            try audioData.write(to: tempURL)
            
            // Получаем длительность аудио
            var audioDuration: TimeInterval = 0
            if let player = try? AVAudioPlayer(data: audioData) {
                audioDuration = player.duration
                print("DEBUG: Sending voice message with duration: \(audioDuration) seconds")
            }
            
            // Отправляем как аудио файл с правильным MIME-типом
            var localEcho: MXEvent?
            room.sendFile(localURL: tempURL,
                         mimeType: "audio/mp4",
                         localEcho: &localEcho) { [weak self] (response: MXResponse<String?>) in
                DispatchQueue.main.async {
                    // Удаляем временный файл
                    try? FileManager.default.removeItem(at: tempURL)
                    
                    switch response {
                    case .success:
                        self?.lastRoomUpdate = Date()
                    case .failure(let error):
                        self?.error = "Ошибка отправки голосового сообщения: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            self.error = "Ошибка сохранения аудио: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Media Download
    func downloadMedia(for message: Message, completion: @escaping (Data?) -> Void) {
        guard let mediaURL = message.mediaURL else {
            completion(nil)
            return
        }
        
        // Проверяем кэш
        if let cachedData = mediaCache[mediaURL] {
            completion(cachedData)
            return
        }
        
        // Используем MXMediaManager для загрузки
        mxSession?.mediaManager.downloadMedia(
            fromMatrixContentURI: mediaURL,
            withType: nil,
            inFolder: nil,
            success: { [weak self] (outputFilePath: String?) in
                guard let filePath = outputFilePath,
                      let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                    completion(nil)
                    return
                }
                
                DispatchQueue.main.async {
                    self?.mediaCache[mediaURL] = data
                    completion(data)
                }
            },
            failure: { (error: Error?) in
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        )
    }
    
    // MARK: - Last Message Preview
    struct MessagePreview {
        let text: String
        let time: String
    }
    
    func getLastMessagePreview(for room: MXRoom) -> MessagePreview {
        let roomMessages = messages
            .filter { $0.roomId == room.roomId }
            .sorted { $0.timestamp > $1.timestamp }
        
        if let lastMessage = roomMessages.first {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let timeString = timeFormatter.string(from: lastMessage.timestamp)
            
            var previewText = lastMessage.text
            if lastMessage.messageType == .file {
                previewText = "📎 Файл"
            } else if lastMessage.messageType == .voice {
                previewText = "🎤 Голосовое сообщение"
            } else if lastMessage.messageType == .image {
                previewText = "📷 Изображение"
            }
            
            // Добавляем иконку шифрования для зашифрованных сообщений
            if lastMessage.isEncrypted {
                previewText = "🔒 " + previewText
            }
            
            return MessagePreview(
                text: previewText,
                time: timeString
            )
        }
        
        if let lastMessage = room.summary?.lastMessage,
           let text = lastMessage.text, !text.isEmpty {
            
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let timeString: String
            
            // Исправление: используем originServerTs вместо timestamp
            if lastMessage.originServerTs != 0 {
                let date = Date(timeIntervalSince1970: TimeInterval(lastMessage.originServerTs / 1000))
                timeString = timeFormatter.string(from: date)
            } else {
                timeString = ""
            }
            
            return MessagePreview(
                text: text,
                time: timeString
            )
        }
        
        return MessagePreview(
            text: "Пока нет сообщений",
            time: ""
        )
    }
    
    // MARK: - Reactions
    func addReaction(_ emoji: String, to messageId: String, in roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else { return }
        
        let reactionContent: [String: Any] = [
            "m.relates_to": [
                "rel_type": "m.annotation",
                "event_id": messageId,
                "key": emoji
            ]
        ]
        var localEcho: MXEvent?
        
        room.sendEvent(.reaction, content: reactionContent, localEcho: &localEcho) { [weak self] (response: MXResponse<String?>) in
            DispatchQueue.main.async {
                switch response {
                case .success:
                    self?.lastRoomUpdate = Date()
                case .failure(let error):
                    self?.error = "Ошибка при добавлении реакции: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func removeReaction(_ emoji: String, from messageId: String, in roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId),
              let events = reactionEvents[messageId] else { return }
        
        let reactionEventToRemove = events.first { event in
            guard let relatesTo = event.content["m.relates_to"] as? [String: Any],
                  let key = relatesTo["key"] as? String,
                  let relEventId = relatesTo["event_id"] as? String,
                  key == emoji,
                  relEventId == messageId,
                  event.sender == currentUserId else {
                return false
            }
            return true
        }
        
        guard let eventToRemove = reactionEventToRemove else { return }
        
        if let messageIndex = self.messages.firstIndex(where: { $0.id == messageId }) {
            var updatedMessage = self.messages[messageIndex]
            if let index = self.reactionEvents[messageId]?.firstIndex(where: { $0.eventId == eventToRemove.eventId }) {
                self.reactionEvents[messageId]?.remove(at: index)
            }
            updatedMessage.reactions = self.calculateReactions(for: messageId)
            self.messages[messageIndex] = updatedMessage
            self.lastRoomUpdate = Date()
            self.objectWillChange.send()
        }
        
        room.redactEvent(eventToRemove.eventId, reason: nil) { [weak self] (response: MXResponse<Void>) in
            DispatchQueue.main.async {
                switch response {
                case .success:
                    if let messageIndex = self?.messages.firstIndex(where: { $0.id == messageId }) {
                        var updatedMessage = self?.messages[messageIndex]
                        updatedMessage?.reactions = self?.calculateReactions(for: messageId) ?? []
                        self?.messages[messageIndex] = updatedMessage!
                        self?.lastRoomUpdate = Date()
                        self?.objectWillChange.send()
                    }
                case .failure(let error):
                    self?.error = "Ошибка при удалении реакции: \(error.localizedDescription)"
                    if let messageIndex = self?.messages.firstIndex(where: { $0.id == messageId }) {
                        var updatedMessage = self?.messages[messageIndex]
                        updatedMessage?.reactions = self?.calculateReactions(for: messageId) ?? []
                        self?.messages[messageIndex] = updatedMessage!
                        self?.lastRoomUpdate = Date()
                        self?.objectWillChange.send()
                    }
                }
            }
        }
    }
    
    // MARK: - Room Creation with Encryption
    func createDirectChat(with userId: String, enableEncryption: Bool = true, completion: @escaping (Bool) -> Void) {
        guard let session = mxSession else {
            error = "Нет подключения"
            completion(false)
            return
        }
    
        let parameters = MXRoomCreationParameters()
        parameters.inviteArray = [userId]
        parameters.isDirect = true
        parameters.visibility = kMXRoomDirectoryVisibilityPrivate
        
        // Настройка шифрования, если включено
        if enableEncryption {
            parameters.initialStateEvents = [
                MXRoomCreationParameters.initialStateEventForEncryption(withAlgorithm: kMXCryptoMegolmAlgorithm)
            ]
        }
        
        session.createRoom(parameters: parameters) { [weak self] (response: MXResponse<MXRoom>) in
            DispatchQueue.main.async {
                switch response {
                case .success(let room):
                    self?.rooms.append(room)
                    self?.error = nil
                    self?.setupRoomListener(for: room)
                    self?.updateRoomStatuses()
                    self?.lastRoomUpdate = Date()
                    completion(true)
                case .failure(let error):
                    self?.error = "Ошибка при создании чата: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Message Sending with Encryption
    func sendMessage(_ text: String, in roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else {
            error = "Комната не найдена"
            return
        }
        var localEcho: MXEvent?
        room.sendTextMessage(text, localEcho: &localEcho) { [weak self] (response: MXResponse<String?>) in
            DispatchQueue.main.async {
                if case .failure(let error) = response {
                    self?.error = "Ошибка отправки: \(error.localizedDescription)"
                } else {
                    self?.lastRoomUpdate = Date()
                }
            }
        }
    }
    
    // MARK: - Display Name Management
    func getDisplayName(for room: MXRoom) -> String {
        if room.isDirect {
            if let directUserId = room.directUserId {
                return extractUsername(from: directUserId)
            }
            return "Личный чат"
        }
        
        if let summary = room.summary, let displayName = summary.displayName, !displayName.isEmpty {
            return displayName
        }
        
        if let otherUserId = extractUserIdFromRoomId(room.roomId) {
            return extractUsername(from: otherUserId)
        }
        
        return room.roomId
    }
    
    private func extractUserIdFromRoomId(_ roomId: String) -> String? {
        let pattern = "@[^:]+:[^\\s]+"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(roomId.startIndex..<roomId.endIndex, in: roomId)
            if let match = regex.firstMatch(in: roomId, options: [], range: range) {
                if let matchedRange = Range(match.range, in: roomId) {
                    return String(roomId[matchedRange])
                }
            }
        }
        return nil
    }
    
    private func extractUsername(from userId: String) -> String {
        if let range = userId.range(of: "@(.*):", options: .regularExpression) {
            let username = String(userId[range].dropFirst().dropLast())
            return username.capitalized
        }
        return userId
    }
    
    func loadUserDisplayName(userId: String, completion: @escaping (String?) -> Void) {
        mxSession?.matrixRestClient.displayName(forUser: userId) { (response: MXResponse<String>) in
            switch response {
            case .success(let displayName):
                completion(displayName)
            case .failure:
                completion(nil)
            }
        }
    }
    
    // MARK: - Logout
    func logout() {
        stopBackgroundRefresh()
        
        for (roomId, listener) in roomListeners {
            if let room = mxSession?.room(withRoomId: roomId) {
                room.removeListener(listener)
            }
        }
        roomListeners.removeAll()
        
        mxSession?.close()
        mxSession = nil
        mxRestClient = nil
        rooms = []
        messages = []
        isLoggedIn = false
        currentUserId = nil
        error = nil
        isLoadingHistory.removeAll()
        processedEventIds.removeAll()
        hasSetupRoomListeners = false
        reactionEvents.removeAll()
        roomStatuses.removeAll()
        mediaCache.removeAll()
        lastRoomUpdate = Date()
    }
}
