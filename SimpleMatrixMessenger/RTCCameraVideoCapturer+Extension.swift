import WebRTC

extension RTCCameraVideoCapturer {
    // Добавляем свойство для проверки работы камеры
    var isCapturing: Bool {
        return captureSession?.isRunning ?? false
    }
}
