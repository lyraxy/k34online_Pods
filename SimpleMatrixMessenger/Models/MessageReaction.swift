import Foundation
import MatrixSDK

// MARK: - Models
struct MessageReaction: Identifiable {
    let id = UUID()
    let emoji: String
    let count: Int
    let users: [String]
    var didReact: Bool = false
}
