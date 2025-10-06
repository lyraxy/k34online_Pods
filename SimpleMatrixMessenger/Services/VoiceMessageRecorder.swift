import Foundation
import MatrixSDK

@MainActor
class VoiceMessageRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var currentPlaybackTime: TimeInterval = 0
    @Published var recordingURL: URL?
    @Published var showPermissionAlert = false
    @Published var permissionError: String?
    
    private var timer: Timer?
    
    override init() {
        super.init()
        setupRecordingSession()
    }
    
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        guard let recordingSession = recordingSession else {
            completion(false)
            return
        }
        
        recordingSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupAudioSession()
                    completion(true)
                } else {
                    self?.showPermissionAlert = true
                    self?.permissionError = "Для записи голосовых сообщений требуется доступ к микрофону. Пожалуйста, разрешите доступ в настройках устройства."
                    completion(false)
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
            DispatchQueue.main.async {
                self.permissionError = "Ошибка настройки аудиосессии: \(error.localizedDescription)"
                self.showPermissionAlert = true
            }
        }
    }
    
    func startRecording() {
        requestMicrophonePermission { [weak self] granted in
            guard let self = self, granted else { return }
            
            DispatchQueue.main.async {
                self.startRecordingInternal()
            }
        }
    }
    
    private func startRecordingInternal() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording-\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            recordingURL = audioFilename
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingTime += 0.1
            }
        } catch {
            print("Could not start recording: \(error)")
            DispatchQueue.main.async {
                self.permissionError = "Ошибка начала записи: \(error.localizedDescription)"
                self.showPermissionAlert = true
            }
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        // Деактивируем аудиосессию после записи
        do {
            try recordingSession?.setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
    
    func playRecording() {
        guard let url = recordingURL else { return }
        
        do {
            // Активируем аудиосессию для воспроизведения
            try recordingSession?.setCategory(.playback, mode: .default)
            try recordingSession?.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentPlaybackTime = player.currentTime
            }
        } catch {
            print("Could not play recording: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        currentPlaybackTime = 0
        timer?.invalidate()
        timer = nil
        
        // Деактивируем аудиосессию после воспроизведения
        do {
            try recordingSession?.setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
    
    func deleteRecording() {
        stopRecording()
        stopPlayback()
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
        recordingTime = 0
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }
}

extension VoiceMessageRecorder: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentPlaybackTime = 0
        timer?.invalidate()
        timer = nil
    }
}
