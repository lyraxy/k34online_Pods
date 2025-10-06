import SwiftUI

// MARK: - Recovery Key View
struct RecoveryKeyView: View {
    @Binding var isPresented: Bool
    @ObservedObject var matrixService: MatrixService
    @State private var recoveryKey: String?
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                K34Colors.background.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 50))
                            .foregroundColor(K34Colors.primaryRed)
                        
                        Text("Ключ восстановления")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(K34Colors.textPrimary)
                        
                        Text("Сохраните этот ключ в безопасном месте. Он понадобится для восстановления доступа к зашифрованным сообщениям.")
                            .font(.body)
                            .foregroundColor(K34Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    if let key = recoveryKey {
                        // Recovery Key Display
                        VStack(spacing: 15) {
                            Text("Ваш ключ восстановления:")
                                .font(.headline)
                                .foregroundColor(K34Colors.textPrimary)
                            
                            Text(key)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(K34Colors.textPrimary)
                                .padding()
                                .background(K34Colors.cardBackground)
                                .cornerRadius(12)
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = key
                                    } label: {
                                        Label("Копировать", systemImage: "doc.on.doc")
                                    }
                                }
                            
                            Text("⚠️ Не делитесь этим ключом с другими")
                                .font(.caption)
                                .foregroundColor(K34Colors.warningYellow)
                        }
                        .padding(.horizontal)
                    } else if isGenerating {
                        ProgressView("Генерация ключа...")
                            .progressViewStyle(CircularProgressViewStyle(tint: K34Colors.primaryRed))
                    } else {
                        Button("Сгенерировать ключ") {
                            generateRecoveryKey()
                        }
                        .buttonStyle(K34ButtonStyle())
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Security Warning
                    VStack(spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(K34Colors.warningYellow)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Важно!")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                Text("Без этого ключа вы не сможете прочитать старые зашифрованные сообщения при смене устройства.")
                                    .font(.caption)
                                    .foregroundColor(K34Colors.textSecondary)
                            }
                        }
                        .padding()
                        .background(K34Colors.cardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Ключ восстановления")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        isPresented = false
                    }
                    .foregroundColor(K34Colors.primaryRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func generateRecoveryKey() {
        isGenerating = true
        // В реальной реализации здесь будет вызов метода Matrix SDK
        // Для демонстрации генерируем случайный ключ
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
            let key = String((0..<32).map { _ in characters.randomElement()! })
            recoveryKey = key
            isGenerating = false
        }
    }
}

