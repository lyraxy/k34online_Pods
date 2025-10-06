import Foundation
import MatrixSDK
import SwiftUI

// MARK: - Chat List View
struct ChatListView: View {
    @ObservedObject var matrixService: MatrixService
    @State private var selectedRoomId: String?
    @State private var showingLeaveAlert = false
    @State private var roomToLeave: MXRoom?
    @State private var lastUpdateTime = Date()
    @State private var timer: Timer?
    
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
                                HStack {
                                    Text("Активные чаты")
                                        .font(.headline)
                                        .foregroundColor(K34Colors.textPrimary)
                                    
                                    Spacer()
                                }
                                .padding(.bottom, 5)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(K34Colors.background)
                    .scrollContentBackground(.hidden)
                    .animation(.default, value: matrixService.rooms.count)
                    .refreshable {
                        await refreshRooms()
                    }
                }
                .navigationTitle("Чаты")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if matrixService.isLoadingRooms {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: K34Colors.primaryRed))
                                    .scaleEffect(0.8)
                            }
                            
                            Button(action: {
                                manualRefresh()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(K34Colors.primaryRed)
                            }
                            .disabled(matrixService.isLoadingRooms)
                        }
                    }
                }
            }
        }
        .onAppear {
            startBackgroundRefresh()
            // Первоначальная загрузка при появлении
            matrixService.loadRooms()
        }
        .onDisappear {
            stopBackgroundRefresh()
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
    
    private func startBackgroundRefresh() {
        // Запускаем таймер для фонового обновления каждые 30 секунд
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            backgroundRefresh()
        }
    }
    
    private func stopBackgroundRefresh() {
        timer?.invalidate()
        timer = nil
    }
    
    private func backgroundRefresh() {
        matrixService.backgroundRefreshRooms()
        updateLastUpdateTime()
    }
    
    private func manualRefresh() {
        matrixService.loadRooms()
        updateLastUpdateTime()
    }
    
    @MainActor
    private func refreshRooms() async {
        matrixService.loadRooms()
        updateLastUpdateTime()
        // Даем немного времени для анимации pull-to-refresh
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func updateLastUpdateTime() {
        lastUpdateTime = Date()
    }
}
