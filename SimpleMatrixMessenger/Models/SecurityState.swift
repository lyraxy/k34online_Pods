import Foundation
import MatrixSDK

// MARK: - E2EE Security State
struct SecurityState {
    let deviceId: String?
    let deviceTrust: MXDeviceTrustLevel?
    let isVerified: Bool
    let isCrossSigned: Bool
}

