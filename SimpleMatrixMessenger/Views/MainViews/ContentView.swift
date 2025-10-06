import Foundation
import MatrixSDK
import SwiftUI

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
