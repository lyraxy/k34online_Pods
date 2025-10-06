import Foundation
import MatrixSDK
import SwiftUI


// MARK: - File Message View
struct FileMessageView: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundColor(K34Colors.primaryRed)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.fileName ?? "Файл")
                    .font(.headline)
                    .foregroundColor(K34Colors.textPrimary)
                    .lineLimit(1)
                
                if let fileSize = message.fileSize {
                    Text(formatFileSize(fileSize))
                        .font(.caption)
                        .foregroundColor(K34Colors.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundColor(K34Colors.primaryRed)
        }
        .padding(12)
        .background(K34Colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(K34Colors.lightGray, lineWidth: 1)
        )
    }
    
    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}
