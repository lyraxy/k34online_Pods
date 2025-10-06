import Foundation
import MatrixSDK
import SwiftUI

// MARK: - Reactions View
struct ReactionsView: View {
    let reactions: [MessageReaction]
    var onReactionTap: ((MessageReaction) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(reactions) { reaction in
                HStack(spacing: 4) {
                    Text(reaction.emoji)
                    Text("\(reaction.count)")
                        .font(.system(size: 10))
                        .foregroundColor(K34Colors.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(reaction.didReact ? K34Colors.primaryRed.opacity(0.3) : K34Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(reaction.didReact ? K34Colors.primaryRed : K34Colors.lightGray, lineWidth: 1)
                )
                .cornerRadius(12)
                .onTapGesture {
                    onReactionTap?(reaction)
                }
                .contextMenu {
                    if reaction.didReact {
                        Button(role: .destructive) {
                            onReactionTap?(reaction)
                        } label: {
                            Label("Убрать реакцию", systemImage: "trash")
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
