import Foundation
import MatrixSDK

struct RoomStatus {
    let roomId: String
    let isInvited: Bool
    let isInvitationOutgoing: Bool
    let otherUserId: String?
    let isEncrypted: Bool
    let encryptionStatus: RoomEncryptionStatus
}
