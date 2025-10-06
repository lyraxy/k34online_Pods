import Foundation
import MatrixSDK
import SwiftUI


// MARK: - Profile View
struct ProfileView: View {
    @ObservedObject var matrixService: MatrixService
    @State private var showingSecuritySettings = false
    @State private var showingRecoveryKey = false
    
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
                    
                    // Security Section
                    VStack(spacing: 15) {
                        Button("Настройки безопасности") {
                            showingSecuritySettings = true
                        }
                        .buttonStyle(K34ButtonStyle())
                        .padding(.horizontal, 40)
                        
                        Button("Ключ восстановления") {
                            showingRecoveryKey = true
                        }
                        .foregroundColor(K34Colors.primaryRed)
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    Button("Выйти") {
                        matrixService.logout()
                    }
                    .buttonStyle(K34DangerButtonStyle())
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Text("K-34 Online")
                            .font(.caption)
                            .foregroundColor(K34Colors.textSecondary)
                        
                        Text("Безопасно • Быстро • Надежно")
                            .font(.caption2)
                            .foregroundColor(K34Colors.lightGray)
                    }
                    .padding(.bottom, 20)
                }
                .navigationTitle("Профиль")
                .navigationBarTitleDisplayMode(.large)
                .sheet(isPresented: $showingSecuritySettings) {
                    SecuritySettingsView(
                        isPresented: $showingSecuritySettings,
                        matrixService: matrixService
                    )
                }
                .sheet(isPresented: $showingRecoveryKey) {
                    RecoveryKeyView(
                        isPresented: $showingRecoveryKey,
                        matrixService: matrixService
                    )
                }
            }
        }
    }
}
