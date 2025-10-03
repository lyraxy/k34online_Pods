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
            Text("k34 online")
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
        }
    }
}

struct ChatRow: View {
    let room: MXRoom
    @ObservedObject var matrixService: MatrixService
    @State private var displayName: String = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(displayName)
                    .font(.headline)
                    .onAppear {
                        updateDisplayName()
                    }
                Text(getLastMessagePreview(room))
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
    }
    
    private func updateDisplayName() {
        // Get initial display name
        let initialName = matrixService.getDisplayName(for: room)
        displayName = initialName
        
        // Try to load better display name if it's a user ID
        if initialName.contains("@") && initialName.contains(":") {
            matrixService.loadUserDisplayName(userId: initialName) { betterName in
                if let betterName = betterName, !betterName.isEmpty {
                    displayName = betterName
                }
            }
        }
    }
    
    private func getLastMessagePreview(_ room: MXRoom) -> String {
        guard let lastMessage = room.summary?.lastMessage else {
            return "Пока нет сообщений"
        }
        
        if let content = lastMessage.text as? String {
            return content
        }
        
        return "Новое сообщение"
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
        let normalizedUserId = "@\(trimmedUserId):k34.online"
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
            // Индикатор загрузки
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
                        }
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Напишите сообщение...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Отправить") {
                    matrixService.sendMessage(messageText, in: room.roomId)
                    messageText = ""
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(matrixService.getDisplayName(for: room))
        .onAppear {
            matrixService.joinRoom(roomId: room.roomId)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isOutgoing {
                Spacer()
            }
            
            VStack(alignment: message.isOutgoing ? .trailing : .leading) {
                Text(message.sender)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(message.text)
                    .padding()
                    .background(message.isOutgoing ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isOutgoing ? .white : .primary)
                    .cornerRadius(16)
            }
            
            if !message.isOutgoing {
                Spacer()
            }
        }
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
    private var processedEventIds: Set<String> = [] // Для отслеживания уже обработанных сообщений
    
    func login(username: String, password: String) {
        isLoading = true
        error = nil
        let newUsername = "@\(username):k34.online"
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
            } else if case .failure(let error) = response {
                self.error = error.localizedDescription
            }
        }
    }
    
    func loadRooms() {
        guard let session = mxSession else { return }
        rooms = session.rooms ?? []
    }
    
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
                    completion(true)
                case .failure(let error):
                    self?.error = "Ошибка при создании чата: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    func joinRoom(roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else { return }
        
        // Устанавливаем флаг загрузки
        isLoadingHistory[roomId] = true
        
        // Удаляем старый слушатель
        if let existingListener = roomListeners[roomId] {
            room.removeListener(existingListener)
        }
        
        // Добавляем новый слушатель для ВСЕХ событий (исторических и новых)
        let listener = room.liveTimeline { [weak self] timeline in
            guard let self = self, let timeline = timeline else { return }
            
            timeline.listenToEvents { [weak self] event, direction, roomState in
                guard let self = self else { return }
                
                // Убираем conditional binding, так как event не optional
                self.handleTimelineEvent(event, direction: direction, roomId: roomId)
            }
            
            // Загружаем историю сообщений
            self.loadRoomHistory(timeline: timeline, room: room)
        }
        
        roomListeners[roomId] = listener
    }
    
    private func loadRoomHistory(timeline: MXEventTimeline, room: MXRoom) {
        // Сбрасываем пагинацию и загружаем исторические сообщения
        timeline.resetPagination()
        
        timeline.paginate(100, direction: .backwards, onlyFromStore: false) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                // Проверяем, можно ли загрузить еще сообщения
                if timeline.canPaginate(.backwards) {
                    // Продолжаем загрузку истории
                    self.loadRoomHistory(timeline: timeline, room: room)
                } else {
                    // Завершили загрузку истории
                    DispatchQueue.main.async {
                        self.isLoadingHistory[room.roomId] = false
                        print("Завершена загрузка истории для комнаты: \(room.roomId)")
                    }
                }
                
            case .failure(let error):
                print("Ошибка загрузки истории: \(error)")
                DispatchQueue.main.async {
                    self.isLoadingHistory[room.roomId] = false
                    self.error = "Ошибка загрузки истории сообщений"
                }
            }
        }
    }
    
    private func handleTimelineEvent(_ event: MXEvent, direction: MXTimelineDirection, roomId: String) {
        // Обрабатываем ВСЕ события (и исторические .backwards и новые .forwards)
        if let message = createMessage(from: event, roomId: roomId) {
            DispatchQueue.main.async {
                // Проверяем, не обработали ли мы уже это сообщение
                if !self.processedEventIds.contains(message.id) {
                    self.processedEventIds.insert(message.id)
                    self.messages.append(message)
                    
                    // Сортируем сообщения по времени
                    self.messages.sort { $0.timestamp < $1.timestamp }
                }
            }
        }
    }
    
    private func createMessage(from event: MXEvent, roomId: String) -> Message? {
        guard event.eventType == .roomMessage else {
            return nil
        }
        
        // Извлекаем текст сообщения
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
        
        // Создаем timestamp
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
    
    func sendMessage(_ text: String, in roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else {
            error = "Комната не найдена"
            return
        }
        
        // Исправленная версия - создаем переменную для localEcho
        var localEcho: MXEvent?
        room.sendTextMessage(text, localEcho: &localEcho) { [weak self] response in
            DispatchQueue.main.async {
                if case .failure(let error) = response {
                    self?.error = "Ошибка отправки: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func logout() {
        // Удаляем все слушатели
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
    }
    
    func getDisplayName(for room: MXRoom) -> String {
        // Для личных чатов пытаемся получить отображаемое имя другого пользователя
        if room.isDirect {
            if let directUserId = room.directUserId {
                return extractUsername(from: directUserId)
            }
            return "Личный чат"
        }
        
        // Для групповых чатов используем displayName из summary
        if let summary = room.summary, let displayName = summary.displayName, !displayName.isEmpty {
            return displayName
        }
        
        // Fallback: извлекаем user ID из room ID
        if let otherUserId = extractUserIdFromRoomId(room.roomId) {
            return extractUsername(from: otherUserId)
        }
        
        return room.roomId // Финальный fallback
    }
    
    private func extractUserIdFromRoomId(_ roomId: String) -> String? {
        // Matrix room IDs часто содержат user IDs, особенно в личных сообщениях
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
        // Извлекаем username из user ID (например: "@ivanov:k34.online" -> "ivanov")
        if let range = userId.range(of: "@(.*):", options: .regularExpression) {
            let username = String(userId[range].dropFirst().dropLast())
            return username.capitalized
        }
        return userId
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
}

// MARK: - Extensions
extension MXRoom: Identifiable {
    public var id: String { roomId }
}
