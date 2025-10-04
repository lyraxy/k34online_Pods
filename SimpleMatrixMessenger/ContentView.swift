import SwiftUI
import MatrixSDK

struct ContentView: View {
    @StateObject private var matrixService = MatrixService()
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            if isLoggedIn {
                mainView
            } else {
                loginView
            }
        }
        .onChange(of: matrixService.isLoggedIn) { newValue in
            isLoggedIn = newValue
        }
    }
    
    var mainView: some View {
        TabView(selection: $selectedTab) {
            ChatListView(matrixService: matrixService)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Чаты")
                }
                .tag(0)
            
            NewChatView(matrixService: matrixService)
                .tabItem {
                    Image(systemName: "plus.message.fill")
                    Text("Новый чат")
                }
                .tag(1)
            
            ProfileView(matrixService: matrixService)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
                .tag(2)
        }
    }
    
    var loginView: some View {
        VStack(spacing: 20) {
            Text("K-34 Online")
                .font(.title)
                .padding(.bottom, 30)
            
            TextField("Имя пользователя", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
            
            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Войти") {
                matrixService.login(username: username, password: password)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if matrixService.isLoading {
                ProgressView()
            }
            
            if let error = matrixService.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

// MARK: - Chat List View
struct ChatListView: View {
    @ObservedObject var matrixService: MatrixService
    @State private var selectedRoomId: String?
    
    var body: some View {
        NavigationView {
            List {
                if matrixService.rooms.isEmpty {
                    Text("Пока нет чатов. Начать новый чат!")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(matrixService.rooms, id: \.roomId) { room in
                        NavigationLink(destination: ChatRoomView(matrixService: matrixService, room: room), tag: room.roomId, selection: $selectedRoomId) {
                            ChatRow(room: room, matrixService: matrixService)
                        }
                    }
                }
            }
            .navigationTitle("Чаты")
            .refreshable {
                matrixService.loadRooms()
            }
            .onAppear {
                matrixService.loadRooms()
            }
        }
    }
}

struct ChatRow: View {
    let room: MXRoom
    @ObservedObject var matrixService: MatrixService
    @State private var displayName: String = ""
    @State private var lastMessageText: String = "Пока нет сообщений"
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(displayName)
                    .font(.headline)
                Text(lastMessageText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
            
            if room.summary?.localUnreadEventCount ?? 0 > 0 {
                Text("\(room.summary?.localUnreadEventCount ?? 0)")
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            updateDisplayInfo()
        }
        .onReceive(matrixService.$messages) { _ in
            updateLastMessagePreview()
        }
        .onReceive(matrixService.objectWillChange) { _ in
            updateDisplayInfo()
        }
    }
    
    private func updateDisplayInfo() {
        updateDisplayName()
        updateLastMessagePreview()
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
        lastMessageText = matrixService.getLastMessagePreview(for: room)
    }
}

// MARK: - New Chat View
struct NewChatView: View {
    @ObservedObject var matrixService: MatrixService
    @State private var userId = ""
    @State private var isCreatingRoom = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Начать новый чат")
                    .font(.title2)
                    .padding()
                
                TextField("Введите имя пользователя (например, ivanov)", text: $userId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()
                
                Button(action: createDirectChat) {
                    if isCreatingRoom {
                        ProgressView()
                    } else {
                        Text("Начать чат")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                .disabled(userId.isEmpty || isCreatingRoom)
                
                if let error = matrixService.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Новый чат")
        }
    }
    
    private func createDirectChat() {
        isCreatingRoom = true
        let trimmedUserId = userId.trimmingCharacters(in: .whitespaces)
        let normalizedUserId = "\(trimmedUserId):k34.online"
        matrixService.createDirectChat(with: normalizedUserId) { success in
            isCreatingRoom = false
            if success {
                userId = ""
            }
        }
    }
}

// MARK: - Chat Room View
struct ChatRoomView: View {
    @ObservedObject var matrixService: MatrixService
    let room: MXRoom
    @State private var messageText = ""
    
    var roomMessages: [Message] {
        matrixService.messages
            .filter { $0.roomId == room.roomId }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    var isLoading: Bool {
        matrixService.isLoadingHistory[room.roomId] ?? false
    }
    
    var body: some View {
        VStack {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Загрузка сообщений...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        if !isLoading && roomMessages.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "message")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Пока нет сообщений")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Начните общение!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(40)
                        } else {
                            ForEach(roomMessages) { message in
                                MessageBubble(message: message)
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
            
            HStack {
                TextField("Напишите сообщение...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMessage()
                    }
                
                Button("Отправить") {
                    sendMessage()
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(matrixService.getDisplayName(for: room))
        .onAppear {
            matrixService.joinRoom(roomId: room.roomId)
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        matrixService.sendMessage(trimmedText, in: room.roomId)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isOutgoing {
                Spacer()
            }
            
            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                Text(message.sender.replacingOccurrences(of: ":k34.online", with: "", options: .literal, range: nil))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isOutgoing ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isOutgoing ? .white : .primary)
                    .cornerRadius(12)
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !message.isOutgoing {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @ObservedObject var matrixService: MatrixService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding()
                
                Text(matrixService.currentUserId ?? "Неизвестный пользователь")
                    .font(.title2)
                
                Button("Выйти") {
                    matrixService.logout()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
            }
            .navigationTitle("Профиль")
        }
    }
}

// MARK: - Models and Services
struct Message: Identifiable {
    let id: String
    let text: String
    let sender: String
    let timestamp: Date
    let roomId: String
    let isOutgoing: Bool
}

class MatrixService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var rooms: [MXRoom] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isLoggedIn = false
    @Published var currentUserId: String?
    @Published var isLoadingHistory: [String: Bool] = [:]
    
    private var mxRestClient: MXRestClient?
    private var mxSession: MXSession?
    private var roomListeners: [String: Any] = [:]
    private var userDisplayNames: [String: String] = [:]
    private var processedEventIds: Set<String> = []
    private var hasSetupRoomListeners = false

    // MARK: - Login and Session Setup
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
        mxSession = MXSession(matrixRestClient: mxRestClient!)
        
        mxSession?.start { [weak self] response in
            guard let self = self else { return }
            
            if case .success = response {
                self.loadRooms()
                self.setupAllRoomListeners()
            } else if case .failure(let error) = response {
                self.error = error.localizedDescription
            }
        }
    }
    
    func loadRooms() {
        guard let session = mxSession else { return }
        rooms = session.rooms ?? []
    }
    
    private func setupAllRoomListeners() {
        guard let session = mxSession, !hasSetupRoomListeners else { return }
        
        for room in session.rooms ?? [] {
            setupRoomListener(for: room)
        }
        hasSetupRoomListeners = true
    }
    
    private func setupRoomListener(for room: MXRoom) {
        let roomId = room.roomId
        
        if let existingListener = roomListeners[roomId!] {
            room.removeListener(existingListener)
        }
        
        let listener = room.liveTimeline { [weak self] timeline in
            guard let self = self, let timeline = timeline else { return }
            
            timeline.listenToEvents { [weak self] event, direction, roomState in
                guard let self = self else { return }
                
                self.handleTimelineEvent(event, direction: direction, roomId: roomId!)
            }
        }
        
        roomListeners[roomId!] = listener
    }
    
    // MARK: - Room Management
    func joinRoom(roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else { return }
        
        isLoadingHistory[roomId] = true
        
        // Загружаем историю сообщений для этой комнаты
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
            
            // Сбрасываем пагинацию и загружаем историю
            timeline.resetPagination()
            
            // Загружаем исторические сообщения
            self.paginateRoomHistory(timeline: timeline, room: room)
        }
    }
    
    private func paginateRoomHistory(timeline: MXEventTimeline, room: MXRoom) {
        let roomId = room.roomId
        
        timeline.paginate(100, direction: .backwards, onlyFromStore: false) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                // Проверяем, есть ли еще сообщения для загрузки
                if timeline.canPaginate(.backwards) {
                    // Продолжаем загрузку
                    self.paginateRoomHistory(timeline: timeline, room: room)
                } else {
                    // Завершили загрузку истории
                    DispatchQueue.main.async {
                        self.isLoadingHistory[roomId!] = false
                        print("Завершена загрузка истории для комнаты: \(roomId)")
                    }
                }
            case .failure(let error):
                print("Ошибка загрузки истории: \(error)")
                DispatchQueue.main.async {
                    self.isLoadingHistory[roomId!] = false
                }
            }
        }
    }
    
    private func handleTimelineEvent(_ event: MXEvent, direction: MXTimelineDirection, roomId: String) {
        // Обрабатываем ВСЕ события
        if let message = createMessage(from: event, roomId: roomId) {
            DispatchQueue.main.async {
                if !self.processedEventIds.contains(message.id) {
                    self.processedEventIds.insert(message.id)
                    self.messages.append(message)
                    
                    // Сортируем сообщения по времени
                    self.messages.sort { $0.timestamp < $1.timestamp }
                    
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    private func createMessage(from event: MXEvent, roomId: String) -> Message? {
        guard event.eventType == .roomMessage else {
            return nil
        }
        
        var messageText = ""
        
        if let text = event.content["body"] as? String {
            messageText = text
        } else if event.content["msgtype"] as? String == "m.image" {
            messageText = "📷 Изображение"
        } else if event.content["msgtype"] as? String == "m.file" {
            messageText = "📎 Файл"
        } else {
            return nil
        }
        
        let timestamp: Date
        if event.originServerTs != 0 {
            timestamp = Date(timeIntervalSince1970: TimeInterval(event.originServerTs / 1000))
        } else {
            timestamp = Date()
        }
        
        return Message(
            id: event.eventId ?? UUID().uuidString,
            text: messageText,
            sender: event.sender ?? "Unknown",
            timestamp: timestamp,
            roomId: roomId,
            isOutgoing: event.sender == self.currentUserId
        )
    }
    
    // MARK: - Room Creation
    func createDirectChat(with userId: String, completion: @escaping (Bool) -> Void) {
        guard let session = mxSession else {
            error = "Нет подключения"
            completion(false)
            return
        }
        
        let parameters = MXRoomCreationParameters()
        parameters.inviteArray = [userId]
        parameters.isDirect = true
        parameters.visibility = kMXRoomDirectoryVisibilityPrivate
        
        session.createRoom(parameters: parameters) { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success(let room):
                    self?.rooms.append(room)
                    self?.error = nil
                    self?.setupRoomListener(for: room)
                    completion(true)
                case .failure(let error):
                    self?.error = "Ошибка при создании чата: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Message Sending
    func sendMessage(_ text: String, in roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else {
            error = "Комната не найдена"
            return
        }
        
        var localEcho: MXEvent?
        room.sendTextMessage(text, localEcho: &localEcho) { [weak self] response in
            DispatchQueue.main.async {
                if case .failure(let error) = response {
                    self?.error = "Ошибка отправки: \(error.localizedDescription)"
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
    
    // MARK: - Last Message Preview
    func getLastMessagePreview(for room: MXRoom) -> String {
        // Сначала проверяем загруженные сообщения
        let roomMessages = messages
            .filter { $0.roomId == room.roomId }
            .sorted { $0.timestamp > $1.timestamp }
        
        if let lastMessage = roomMessages.first {
            return lastMessage.text
        }
        
        // Затем проверяем summary комнаты
        if let lastMessage = room.summary?.lastMessage,
           let text = lastMessage.text, !text.isEmpty {
            return text
        }
        
        return "Пока нет сообщений"
    }
    
    func loadUserDisplayName(userId: String, completion: @escaping (String?) -> Void) {
        mxSession?.matrixRestClient.displayName(forUser: userId) { response in
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
    }
}

// MARK: - Extensions
extension MXRoom: Identifiable {
    public var id: String { roomId }
}
