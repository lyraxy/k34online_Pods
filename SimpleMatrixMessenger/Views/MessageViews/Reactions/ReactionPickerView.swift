import Foundation
import MatrixSDK
import SwiftUI

// MARK: - Reaction Picker View
struct ReactionPickerView: View {
    let messageId: String
    @ObservedObject var matrixService: MatrixService
    let room: MXRoom
    @Environment(\.presentationMode) var presentationMode
    
    let commonReactions = ["👍", "👎", "❤️", "😂", "😮", "😢", "😡", "🎉"]
    
    private var message: Message? {
        matrixService.messages.first { $0.id == messageId }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                K34Colors.background.ignoresSafeArea()
                
                VStack {
                    if let message = message, !message.reactions.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Текущие реакции:")
                                .font(.headline)
                                .foregroundColor(K34Colors.textPrimary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(message.reactions) { reaction in
                                        VStack {
                                            HStack(spacing: 4) {
                                                Text(reaction.emoji)
                                                    .font(.title2)
                                                Text("\(reaction.count)")
                                                    .font(.caption)
                                                    .foregroundColor(K34Colors.textSecondary)
                                            }
                                            .padding(8)
                                            .background(reaction.didReact ? K34Colors.primaryRed.opacity(0.3) : K34Colors.cardBackground)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(reaction.didReact ? K34Colors.primaryRed : K34Colors.lightGray, lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                if reaction.didReact {
                                                    matrixService.removeReaction(reaction.emoji, from: messageId, in: room.roomId)
                                                } else {
                                                    matrixService.addReaction(reaction.emoji, to: messageId, in: room.roomId)
                                                }
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                            
                                            if reaction.didReact {
                                                Text("Убрать")
                                                    .font(.caption2)
                                                    .foregroundColor(K34Colors.lightRed)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    Text("Добавить реакцию:")
                        .font(.headline)
                        .foregroundColor(K34Colors.textPrimary)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                            ForEach(commonReactions, id: \.self) { emoji in
                                Button(action: {
                                    matrixService.addReaction(emoji, to: messageId, in: room.roomId)
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text(emoji)
                                        .font(.system(size: 30))
                                        .frame(width: 50, height: 50)
                                        .background(K34Colors.cardBackground)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(K34Colors.lightGray, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Реакции")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(K34Colors.primaryRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
