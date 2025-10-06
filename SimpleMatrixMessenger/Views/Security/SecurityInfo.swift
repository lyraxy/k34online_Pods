import SwiftUI
import Foundation
import MatrixSDK
// MARK: - Security Info View
struct SecurityInfoView: View {
    @Binding var isPresented: Bool
    @ObservedObject var matrixService: MatrixService
    let room: MXRoom
    @State private var securityState: SecurityState?
    
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
                            
                            Text("Информация о безопасности")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(K34Colors.textPrimary)
                            
                            Text("Детали шифрования для этого чата")
                                .font(.body)
                                .foregroundColor(K34Colors.textSecondary)
                        }
                        .padding(.top, 20)
                        
                        // Security Status Card
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(K34Colors.encryptedGreen)
                                Text("Статус шифрования")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                Spacer()
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("End-to-end шифрование")
                                        .font(.subheadline)
                                        .foregroundColor(K34Colors.textPrimary)
                                    
                                    Text("Активно")
                                        .font(.caption)
                                        .foregroundColor(K34Colors.encryptedGreen)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(K34Colors.encryptedGreen.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(K34Colors.encryptedGreen)
                            }
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
                                Text("Устройства участников")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                Spacer()
                            }
                            
                            if let state = securityState {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Ваше устройство:")
                                            .font(.subheadline)
                                            .foregroundColor(K34Colors.textSecondary)
                                        Spacer()
                                        Text(state.isVerified ? "Проверено" : "Не проверено")
                                            .font(.subheadline)
                                            .foregroundColor(state.isVerified ? K34Colors.encryptedGreen : K34Colors.warningYellow)
                                    }
                                    
                                    HStack {
                                        Text("Cross-signing:")
                                            .font(.subheadline)
                                            .foregroundColor(K34Colors.textSecondary)
                                        Spacer()
                                        Text(state.isCrossSigned ? "Активно" : "Не активно")
                                            .font(.subheadline)
                                            .foregroundColor(state.isCrossSigned ? K34Colors.encryptedGreen : K34Colors.warningYellow)
                                    }
                                }
                            } else {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: K34Colors.primaryRed))
                            }
                        }
                        .padding()
                        .background(K34Colors.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Security Tips
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Рекомендации по безопасности")
                                    .font(.headline)
                                    .foregroundColor(K34Colors.textPrimary)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                SecurityTipRow(
                                    icon: "checkmark.shield",
                                    title: "Проверяйте устройства",
                                    description: "Убедитесь, что все устройства участников проверены."
                                )
                                
                                SecurityTipRow(
                                    icon: "key.fill",
                                    title: "Храните ключи безопасно",
                                    description: "Не передавайте ключи восстановления третьим лицам."
                                )
                                
                                SecurityTipRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Регулярно обновляйте",
                                    description: "Поддерживайте приложение в актуальном состоянии."
                                )
                            }
                        }
                        .padding()
                        .background(K34Colors.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Button("Проверить безопасность") {
                            matrixService.verifyRoom(roomId: room.roomId)
                            isPresented = false
                        }
                        .buttonStyle(K34ButtonStyle())
                        .padding(.horizontal)
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
            .onAppear {
                loadSecurityState()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func loadSecurityState() {
        securityState = matrixService.getSecurityState(for: room.roomId)
    }
}

