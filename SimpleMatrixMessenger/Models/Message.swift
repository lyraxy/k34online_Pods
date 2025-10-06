import Foundation
import MatrixSDK


struct Message: Identifiable, Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let text: String
    let sender: String
    let timestamp: Date
    let roomId: String
    let isOutgoing: Bool
    var reactions: [MessageReaction]
    let messageType: MessageType
    let mediaURL: String?
    let fileName: String?
    let fileSize: Int?
    let duration: TimeInterval?
    var isVoicePlaying: Bool = false
    let isEncrypted: Bool
    let encryptionStatus: EncryptionStatus
    let originalEvent: MXEvent?
}
