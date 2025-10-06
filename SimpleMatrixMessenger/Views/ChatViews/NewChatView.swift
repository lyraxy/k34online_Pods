import Foundation
import MatrixSDK
import SwiftUI

// MARK: - New Chat View
struct NewChatView: View {
    @ObservedObject var matrixService: MatrixService
    @State private var userId = ""
    @State private var isCreatingRoom = false
    @State private var enableEncryption = true
    
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
                        
                        // Encryption Toggle
                        Toggle(isOn: $enableEncryption) {
                            HStack(spacing: 8) {
                                Image(systemName: enableEncryption ? "lock.fill" : "lock.open.fill")
                                    .foregroundColor(enableEncryption ? K34Colors.encryptedGreen : K34Colors.lightGray)
                                Text("End-to-end шифрование")
                                    .foregroundColor(K34Colors.textPrimary)
                                Spacer()
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: K34Colors.encryptedGreen))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(K34Colors.cardBackground)
                        .cornerRadius(12)
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
                    
                    // Security Info
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(K34Colors.encryptedGreen)
                            Text("Безопасность соединения")
                                .font(.headline)
                                .foregroundColor(K34Colors.textPrimary)
                        }
                        
                        Text("End-to-end шифрование гарантирует, что только вы и получатель можете читать сообщения.")
                            .font(.caption)
                            .foregroundColor(K34Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(K34Colors.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
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
        matrixService.createDirectChat(with: normalizedUserId, enableEncryption: enableEncryption) { success in
            isCreatingRoom = false
            if success {
                userId = ""
            }
        }
    }
}
