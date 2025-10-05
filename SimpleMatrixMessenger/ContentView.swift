import SwiftUI
import MatrixSDK

// MARK: - Color Theme
struct K34Colors {
    static let primaryRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    static let darkRed = Color(red: 0.6, green: 0.05, blue: 0.05)
    static let lightRed = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let darkGray = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let mediumGray = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let lightGray = Color(red: 0.3, green: 0.3, blue: 0.3)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.8, green: 0.8, blue: 0.8)
    static let background = Color.black
    static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
}

// MARK: - Custom Styles
struct K34ButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(K34Colors.primaryRed)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct K34DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.red)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct K34TextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(K34Colors.cardBackground)
            .cornerRadius(12)
            .foregroundColor(K34Colors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(K34Colors.lightGray, lineWidth: 1)
            )
    }
}

// MARK: - Models
struct MessageReaction: Identifiable {
    let id = UUID()
    let emoji: String
    let count: Int
    let users: [String]
    var didReact: Bool = false
}

struct Message: Identifiable {
    let id: String
    let text: String
    let sender: String
    let timestamp: Date
    let roomId: String
    let isOutgoing: Bool
    var reactions: [MessageReaction]
}

struct RoomStatus {
    let roomId: String
    let isInvited: Bool
    let isInvitationOutgoing: Bool
    let otherUserId: String?
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var matrixService = MatrixService()
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                K34Colors.background.ignoresSafeArea()
                
                if isLoggedIn {
                    mainView
                } else {
                    loginView
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .onChange(of: matrixService.isLoggedIn) { newValue in
            isLoggedIn = newValue
        }
    }
    
    var mainView: some View {
        ZStack {
            K34Colors.background.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                ChatListView(matrixService: matrixService)
                    .tabItem {
                        Image(systemName: "message.fill")
                            .foregroundColor(K34Colors.primaryRed)
                        Text("Чаты")
                            .foregroundColor(K34Colors.textPrimary)
                    }
                    .tag(0)
                
                NewChatView(matrixService: matrixService)
                    .tabItem {
                        Image(systemName: "plus.message.fill")
                            .foregroundColor(K34Colors.primaryRed)
                        Text("Новый чат")
                            .foregroundColor(K34Colors.textPrimary)
                    }
                    .tag(1)
                
                ProfileView(matrixService: matrixService)
                    .tabItem {
                        Image(systemName: "person.fill")
                            .foregroundColor(K34Colors.primaryRed)
                        Text("Профиль")
                            .foregroundColor(K34Colors.textPrimary)
                    }
                    .tag(2)
            }
            .accentColor(K34Colors.primaryRed)
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(K34Colors.darkGray)
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor(K34Colors.primaryRed)
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(K34Colors.primaryRed)]
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor(K34Colors.lightGray)
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(K34Colors.lightGray)]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
    
    var loginView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo and Title
            VStack(spacing: 20) {
                Image("login")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .shadow(color: K34Colors.primaryRed.opacity(0.5), radius: 10)
                
                Text("K-34 Online")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(K34Colors.textPrimary)
                
                Text("Общайся безопасно")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(K34Colors.textSecondary)
            }
            
            Spacer()
            
            // Login Form
            VStack(spacing: 20) {
                TextField("Имя пользователя", text: $username)
                    .textFieldStyle(K34TextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)
                
                SecureField("Пароль", text: $password)
                    .textFieldStyle(K34TextFieldStyle())
                    .padding(.horizontal)
                
                Button("Войти") {
                    matrixService.login(username: username, password: password)
                }
                .buttonStyle(K34ButtonStyle())
                .padding(.top, 10)
                
                if matrixService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: K34Colors.primaryRed))
                        .scaleEffect(1.2)
                }
                
                if let error = matrixService.error {
                    Text(error)
                        .foregroundColor(K34Colors.lightRed)
                        .padding()
                        .background(K34Colors.darkRed.opacity(0.3))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Footer
            Text("v0.9 alpha-build • Безопасные коммуникации")
                .font(.caption)
                .foregroundColor(K34Colors.lightGray)
                .padding(.bottom, 20)
        }
        .background(K34Colors.background.ignoresSafeArea())
    }
}

// MARK: - Chat List View
struct ChatListView: View {
    @ObservedObject var matrixService: MatrixService
    @State private var selectedRoomId: String?
    @State private var showingLeaveAlert = false
    @State private var roomToLeave: MXRoom?
    
    var activeRooms: [MXRoom] {
        matrixService.rooms.filter { room in
            guard let status = matrixService.getRoomStatus(for: room) else { return true }
            return !status.isInvited && !status.isInvitationOutgoing
        }
    }
    
    var invitationRooms: [MXRoom] {
        matrixService.rooms.filter { room in
            guard let status = matrixService.getRoomStatus(for: room) else { return false }
            return status.isInvited
        }
    }
    
    var outgoingInvitationRooms: [MXRoom] {
        matrixService.rooms.filter { room in
            guard let status = matrixService.getRoomStatus(for: room) else { return false }
            return status.isInvitationOutgoing
        }
    }
    
    var body: some View {
        ZStack {
            K34Colors.background.ignoresSafeArea()
            
            NavigationView {
                ZStack {
                    K34Colors.background.ignoresSafeArea()
                    
                    List {
                        // Входящие приглашения
                        if !invitationRooms.isEmpty {
                            Section {
                                ForEach(invitationRooms, id: \.roomId) { room in
                                    chatRow(for: room)
                                }
                            } header: {
                                Text("Входящие приглашения")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                    .padding(.bottom, 5)
                            }
                        }
                        
                        // Исходящие приглашения
                        if !outgoingInvitationRooms.isEmpty {
                            Section {
                                ForEach(outgoingInvitationRooms, id: \.roomId) { room in
                                    chatRow(for: room)
                                }
                            } header: {
                                Text("Ожидают ответа")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textSecondary)
                                    .padding(.bottom, 5)
                            }
                        }
                        
                        // Активные чаты
                        Section {
                            if activeRooms.isEmpty && invitationRooms.isEmpty && outgoingInvitationRooms.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(activeRooms, id: \.roomId) { room in
                                    chatRow(for: room)
                                }
                            }
                        } header: {
                            if !activeRooms.isEmpty {
                                Text("Активные чаты")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(K34Colors.background)
                    .scrollContentBackground(.hidden)
                    .animation(.default, value: matrixService.rooms.count)
                }
                .navigationTitle("Чаты")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            matrixService.loadRooms()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(K34Colors.primaryRed)
                        }
                    }
                }
            }
        }
        .alert("Покинуть чат", isPresented: $showingLeaveAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Покинуть", role: .destructive) {
                if let room = roomToLeave {
                    leaveRoom(room)
                }
            }
        } message: {
            if let room = roomToLeave {
                Text("Вы уверены, что хотите покинуть чат \"\(matrixService.getDisplayName(for: room))\"?")
            }
        }
    }
    
    private func chatRow(for room: MXRoom) -> some View {
        ZStack {
            NavigationLink(destination: ChatRoomView(matrixService: matrixService, room: room), tag: room.roomId, selection: $selectedRoomId) {
                EmptyView()
            }
            .opacity(0)
            
            ChatRow(room: room, matrixService: matrixService, onLeaveRoom: {
                roomToLeave = room
                showingLeaveAlert = true
            })
            .padding(.vertical, 8)
        }
        .listRowBackground(K34Colors.cardBackground)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 25) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(K34Colors.lightGray)
                .padding(.bottom, 5)
            
            VStack(spacing: 12) {
                Text("Пока нет чатов")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(K34Colors.textPrimary)
                
                Text("Начните новый чат, чтобы начать общение!")
                    .font(.body)
                    .foregroundColor(K34Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private func leaveRoom(_ room: MXRoom) {
        matrixService.leaveRoom(roomId: room.roomId) { success in
            if success {
                // Комната автоматически удалится из списка благодаря обновлению rooms
                matrixService.loadRooms()
            }
        }
    }
}

// MARK: - Chat Row
struct ChatRow: View {
    let room: MXRoom
    @ObservedObject var matrixService: MatrixService
    var onLeaveRoom: (() -> Void)? = nil
    @State private var displayName: String = ""
    @State private var lastMessageText: String = "Пока нет сообщений"
    @State private var roomStatus: RoomStatus?
    @State private var showingContextMenu = false
    
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
                
                Text(lastMessageText)
                    .font(.system(size: 14))
                    .foregroundColor(K34Colors.textSecondary)
                    .lineLimit(1)
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
        }
        .onReceive(matrixService.$messages) { _ in
            updateLastMessagePreview()
        }
        .onReceive(matrixService.objectWillChange) { _ in
            updateDisplayInfo()
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
        lastMessageText = matrixService.getLastMessagePreview(for: room)
    }
}

// MARK: - New Chat View
struct NewChatView: View {
    @ObservedObject var matrixService: MatrixService
    @State private var userId = ""
    @State private var isCreatingRoom = false
    
    var body: some View {
        ZStack {
            K34Colors.background.ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "plus.bubble.fill")
                            .font(.system(size: 50))
                            .foregroundColor(K34Colors.primaryRed)
                        
                        Text("Начать новый чат")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(K34Colors.textPrimary)
                        
                        Text("Введите имя пользователя для начала общения")
                            .font(.body)
                            .foregroundColor(K34Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Input Field
                    VStack(spacing: 20) {
                        TextField("Введите имя пользователя (например, ivanov)", text: $userId)
                            .textFieldStyle(K34TextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .padding(.horizontal)
                        
                        Button(action: createDirectChat) {
                            if isCreatingRoom {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Начать чат")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(K34ButtonStyle())
                        .padding(.horizontal)
                        .disabled(userId.isEmpty || isCreatingRoom)
                    }
                    
                    if let error = matrixService.error {
                        Text(error)
                            .foregroundColor(K34Colors.lightRed)
                            .padding()
                            .background(K34Colors.darkRed.opacity(0.3))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .navigationTitle("Новый чат")
                .navigationBarTitleDisplayMode(.large)
                .background(K34Colors.background.ignoresSafeArea())
            }
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
    @State private var showReactionPickerForMessage: String? = nil
    @State private var roomStatus: RoomStatus?
    @State private var showingLeaveAlert = false
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
                        matrixService.loadRooms()
                    } label: {
                        Label("Обновить", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(K34Colors.primaryRed)
                }
            }
        }
        .onAppear {
            matrixService.joinRoom(roomId: room.roomId)
            updateRoomStatus()
        }
        .onReceive(matrixService.objectWillChange) { _ in
            updateRoomStatus()
        }
        .sheet(item: $showReactionPickerForMessage) { messageId in
            ReactionPickerView(
                messageId: messageId,
                matrixService: matrixService,
                room: room
            )
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
            HStack(spacing: 12) {
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
                // Автоматически перейдет в обычный режим чата
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
}

// MARK: - Message Bubble with Reactions
struct MessageBubble: View {
    let message: Message
    @ObservedObject var matrixService: MatrixService
    let room: MXRoom
    @Binding var showReactionPickerForMessage: String?
    
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
                        .contextMenu {
                            Button {
                                showReactionPickerForMessage = message.id
                            } label: {
                                Label("Добавить реакцию", systemImage: "face.smiling")
                            }
                            
                            Button {
                                UIPasteboard.general.string = message.text
                            } label: {
                                Label("Копировать", systemImage: "doc.on.doc")
                            }
                        }
                    
                    // Отображение реакций
                    if !message.reactions.isEmpty {
                        ReactionsView(reactions: message.reactions) { reaction in
                            handleReactionTap(reaction)
                        }
                        .padding(.top, 2)
                    }
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(K34Colors.lightGray)
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
}

// MARK: - Reactions View
struct ReactionsView: View {
    let reactions: [MessageReaction]
    var onReactionTap: ((MessageReaction) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(reactions) { reaction in
                HStack(spacing: 4) {
                    Text(reaction.emoji)
                    Text("\(reaction.count)")
                        .font(.system(size: 10))
                        .foregroundColor(K34Colors.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(reaction.didReact ? K34Colors.primaryRed.opacity(0.3) : K34Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(reaction.didReact ? K34Colors.primaryRed : K34Colors.lightGray, lineWidth: 1)
                )
                .cornerRadius(12)
                .onTapGesture {
                    onReactionTap?(reaction)
                }
                .contextMenu {
                    if reaction.didReact {
                        Button(role: .destructive) {
                            onReactionTap?(reaction)
                        } label: {
                            Label("Убрать реакцию", systemImage: "trash")
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Reaction Picker View
struct ReactionPickerView: View {
    let messageId: String
    @ObservedObject var matrixService: MatrixService
    let room: MXRoom
    @Environment(\.presentationMode) var presentationMode
    
    let commonReactions = ["👍", "👎", "❤️", "😂", "😮", "😢", "😡", "🎉"]
    
    private var message: Message? {
        matrixService.messages.first { $0.id == messageId }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                K34Colors.background.ignoresSafeArea()
                
                VStack {
                    if let message = message, !message.reactions.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Текущие реакции:")
                                .font(.headline)
                                .foregroundColor(K34Colors.textPrimary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(message.reactions) { reaction in
                                        VStack {
                                            HStack(spacing: 4) {
                                                Text(reaction.emoji)
                                                    .font(.title2)
                                                Text("\(reaction.count)")
                                                    .font(.caption)
                                                    .foregroundColor(K34Colors.textSecondary)
                                            }
                                            .padding(8)
                                            .background(reaction.didReact ? K34Colors.primaryRed.opacity(0.3) : K34Colors.cardBackground)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(reaction.didReact ? K34Colors.primaryRed : K34Colors.lightGray, lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                if reaction.didReact {
                                                    matrixService.removeReaction(reaction.emoji, from: messageId, in: room.roomId)
                                                } else {
                                                    matrixService.addReaction(reaction.emoji, to: messageId, in: room.roomId)
                                                }
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                            
                                            if reaction.didReact {
                                                Text("Убрать")
                                                    .font(.caption2)
                                                    .foregroundColor(K34Colors.lightRed)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    Text("Добавить реакцию:")
                        .font(.headline)
                        .foregroundColor(K34Colors.textPrimary)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                            ForEach(commonReactions, id: \.self) { emoji in
                                Button(action: {
                                    matrixService.addReaction(emoji, to: messageId, in: room.roomId)
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text(emoji)
                                        .font(.system(size: 30))
                                        .frame(width: 50, height: 50)
                                        .background(K34Colors.cardBackground)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(K34Colors.lightGray, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Реакции")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(K34Colors.primaryRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @ObservedObject var matrixService: MatrixService
    
    var body: some View {
        ZStack {
            K34Colors.background.ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(K34Colors.primaryRed)
                                .frame(width: 120, height: 120)
                                .shadow(color: K34Colors.primaryRed.opacity(0.5), radius: 10)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(matrixService.currentUserId ?? "Неизвестный пользователь")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(K34Colors.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text("K-34 Online User")
                                .font(.body)
                                .foregroundColor(K34Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Выйти") {
                        matrixService.logout()
                    }
                    .buttonStyle(K34ButtonStyle())
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Text("K-34 Online Messenger")
                            .font(.caption)
                            .foregroundColor(K34Colors.textSecondary)
                        
                        Text("Secure • Private • Reliable")
                            .font(.caption2)
                            .foregroundColor(K34Colors.lightGray)
                    }
                    .padding(.bottom, 20)
                }
                .navigationTitle("Профиль")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}

// MARK: - Matrix Service
class MatrixService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var rooms: [MXRoom] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isLoggedIn = false
    @Published var currentUserId: String?
    @Published var isLoadingHistory: [String: Bool] = [:]
    @Published var roomStatuses: [String: RoomStatus] = [:]
    
    private var mxRestClient: MXRestClient?
    private var mxSession: MXSession?
    private var roomListeners: [String: Any] = [:]
    private var userDisplayNames: [String: String] = [:]
    private var processedEventIds: Set<String> = []
    private var hasSetupRoomListeners = false
    private var reactionEvents: [String: [MXEvent]] = [:]

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
        updateRoomStatuses()
    }
    
    // MARK: - Room Status Management
    private func updateRoomStatuses() {
        guard let session = mxSession else { return }
        
        var newStatuses: [String: RoomStatus] = [:]
        
        for room in session.rooms ?? [] {
            let roomId = room.roomId
            let membership = room.summary?.membership ?? .unknown
            
            let isInvited = membership == .invite
            let isInvitationOutgoing = self.isInvitationOutgoing(room: room)
            let otherUserId = self.getOtherUserId(for: room)
            
            newStatuses[roomId!] = RoomStatus(
                roomId: roomId!,
                isInvited: isInvited,
                isInvitationOutgoing: isInvitationOutgoing,
                otherUserId: otherUserId
            )
        }
        
        DispatchQueue.main.async {
            self.roomStatuses = newStatuses
        }
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
        
        if let existingListener = roomListeners[roomId] {
            room.removeListener(existingListener)
        }
        
        let listener = room.liveTimeline { [weak self] timeline in
            guard let self = self, let timeline = timeline else { return }
            
            timeline.listenToEvents { [weak self] event, direction, roomState in
                guard let self = self else { return }
                
                self.handleTimelineEvent(event, direction: direction, roomId: roomId)
            }
        }
        
        roomListeners[roomId] = listener
    }
    
    // MARK: - Room Management
    func joinRoom(roomId: String) {
        guard let room = mxSession?.room(withRoomId: roomId) else { return }
        
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
            }
        }
        
        if event.eventType == .roomMessage {
            if let message = createMessage(from: event, roomId: roomId) {
                DispatchQueue.main.async {
                    if !self.processedEventIds.contains(message.id) {
                        self.processedEventIds.insert(message.id)
                        self.messages.append(message)
                        self.messages.sort { $0.timestamp < $1.timestamp }
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
            reactions: reactions
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
                    break
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
                        self?.objectWillChange.send()
                    }
                case .failure(let error):
                    self?.error = "Ошибка при удалении реакции: \(error.localizedDescription)"
                    if let messageIndex = self?.messages.firstIndex(where: { $0.id == messageId }) {
                        var updatedMessage = self?.messages[messageIndex]
                        updatedMessage?.reactions = self?.calculateReactions(for: messageId) ?? []
                        self?.messages[messageIndex] = updatedMessage!
                        self?.objectWillChange.send()
                    }
                }
            }
        }
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
        
        session.createRoom(parameters: parameters) { [weak self] (response: MXResponse<MXRoom>) in
            DispatchQueue.main.async {
                switch response {
                case .success(let room):
                    self?.rooms.append(room)
                    self?.error = nil
                    self?.setupRoomListener(for: room)
                    self?.updateRoomStatuses()
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
        room.sendTextMessage(text, localEcho: &localEcho) { [weak self] (response: MXResponse<String?>) in
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
        let roomMessages = messages
            .filter { $0.roomId == room.roomId }
            .sorted { $0.timestamp > $1.timestamp }
        
        if let lastMessage = roomMessages.first {
            return lastMessage.text
        }
        
        if let lastMessage = room.summary?.lastMessage,
           let text = lastMessage.text, !text.isEmpty {
            return text
        }
        
        return "Пока нет сообщений"
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
    }
}

// MARK: - Extensions
extension MXRoom: Identifiable {
    public var id: String { roomId }
}

extension String: Identifiable {
    public var id: String { self }
}

extension MXEvent {
    func isRedactedEvent() -> Bool {
        return self.eventType == .roomRedaction || self.isState()
    }
}
