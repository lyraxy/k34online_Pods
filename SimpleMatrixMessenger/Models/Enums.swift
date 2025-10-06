import Foundation
import MatrixSDK

enum MessageType {
    case text
    case image
    case file
    case voice
}

enum EncryptionStatus: Equatable {
    case encrypted
    case decrypted
    case decryptionError(String)
    case unencrypted
    case unknown
}

enum RoomEncryptionStatus {
    case verified
    case unverified
    case unknown
    case notEncrypted
}
