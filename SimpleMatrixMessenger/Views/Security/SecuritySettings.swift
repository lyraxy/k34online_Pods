import SwiftUI


// MARK: - Security Settings View
struct SecuritySettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var matrixService: MatrixService
    @State private var enableEncryptionByDefault = true
    @State private var verifyAllDevices = false
    
    var body: some View {
        NavigationView {
            ZStack {
                K34Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 50))
                                .foregroundColor(K34Colors.encryptedGreen)
                            
                            Text("Настройки безопасности")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(K34Colors.textPrimary)
                        }
                        .padding(.top, 20)
                        
                        // Encryption Settings
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(K34Colors.encryptedGreen)
                                Text("Шифрование по умолчанию")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                Spacer()
                            }
                            
                            Toggle(isOn: $enableEncryptionByDefault) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Создавать зашифрованные чаты")
                                        .font(.subheadline)
                                        .foregroundColor(K34Colors.textPrimary)
                                    Text("Все новые чаты будут использовать end-to-end шифрование")
                                        .font(.caption)
                                        .foregroundColor(K34Colors.textSecondary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: K34Colors.encryptedGreen))
                        }
                        .padding()
                        .background(K34Colors.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Device Verification
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "iphone.gen2")
                                    .foregroundColor(K34Colors.primaryRed)
                                Text("Проверка устройств")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                Spacer()
                            }
                            
                            Toggle(isOn: $verifyAllDevices) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Требовать проверку устройств")
                                        .font(.subheadline)
                                        .foregroundColor(K34Colors.textPrimary)
                                    Text("Предупреждать о непроверенных устройствах")
                                        .font(.caption)
                                        .foregroundColor(K34Colors.textSecondary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: K34Colors.primaryRed))
                            
                            Button("Проверить все устройства") {
                                matrixService.verifyAllDevices()
                            }
                            .buttonStyle(K34ButtonStyle())
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(K34Colors.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Security Info
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("О шифровании")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                Spacer()
                            }
                            
                            Text("End-to-end шифрование гарантирует, что только вы и получатель можете читать сообщения. Даже сервер не имеет доступа к содержимому ваших сообщений.")
                                .font(.caption)
                                .foregroundColor(K34Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(K34Colors.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Безопасность")
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
}

