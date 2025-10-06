import Foundation
import MatrixSDK

// MARK: - Extensions
extension MXRoom: Identifiable {
    public var id: String { roomId }
}

extension String: Identifiable {
    public var id: String { self }
}

extension MXEvent {
    func isRedactedEvent() -> Bool {
        return self.eventType == .roomRedaction || self.isState()
    }
}
