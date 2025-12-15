import SwiftUI
import MatrixSDK
import AVFoundation
import CryptoKit
import Security
import WebRTC
import AVFoundation

class CallCoordinator: ObservableObject {
    static let shared = CallCoordinator()
    
    @Published var activeCall: CallManager.ActiveCall?
    @Published var incomingCall: CallManager.IncomingCall?
    @Published var showingCallView = false
    @Published var showingIncomingCall = false
    
    private var matrixService: MatrixService?
    private var callManager: CallManager?
    
    private init() {}
    
    func setup(matrixService: MatrixService, callManager: CallManager) {
        self.matrixService = matrixService
        self.callManager = callManager
        
        setupCallListeners()
    }
    
    private func setupCallListeners() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("IncomingCall"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleIncomingCall(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CallAnswer"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleCallAnswer(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CallCandidate"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleCallCandidate(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CallHangup"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleCallHangup(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CallStarted"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.showingCallView = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CallEnded"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.showingCallView = false
                self?.showingIncomingCall = false
            }
        }
    }
    
    private func handleIncomingCall(_ notification: Notification) {
        guard let callId = notification.userInfo?["callId"] as? String,
              let roomId = notification.userInfo?["roomId"] as? String,
              let userId = notification.userInfo?["userId"] as? String,
              let offerSDP = notification.userInfo?["offerSDP"] as? String,
              let isVideo = notification.userInfo?["isVideo"] as? Bool else {
            return
        }
        
        DispatchQueue.main.async {
            self.showingIncomingCall = true
        }
        
        callManager?.receiveCallInvite(
            callId: callId,
            roomId: roomId,
            userId: userId,
            offerSDP: offerSDP,
            isVideo: isVideo
        )
    }
    
    private func handleCallAnswer(_ notification: Notification) {
        guard let callId = notification.userInfo?["callId"] as? String,
              let answerSDP = notification.userInfo?["answerSDP"] as? String else {
            return
        }
        
        callManager?.handleRemoteAnswer(callId: callId, answerSDP: answerSDP)
    }
    
    private func handleCallCandidate(_ notification: Notification) {
        guard let callId = notification.userInfo?["callId"] as? String,
              let candidate = notification.userInfo?["candidate"] as? [String: Any] else {
            return
        }
        
        callManager?.handleRemoteCandidate(callId: callId, candidate: candidate)
    }
    
    private func handleCallHangup(_ notification: Notification) {
        guard let callId = notification.userInfo?["callId"] as? String else {
            return
        }
        
        let duration = notification.userInfo?["duration"] as? TimeInterval
        callManager?.handleRemoteHangup(callId: callId, duration: duration)
    }
    
    func acceptIncomingCall() {
        callManager?.acceptIncomingCall()
        showingIncomingCall = false
        showingCallView = true
    }
    
    func rejectIncomingCall() {
        callManager?.rejectIncomingCall()
        showingIncomingCall = false
    }
    
    func endCall() {
        callManager?.endCall()
        showingCallView = false
    }
}
