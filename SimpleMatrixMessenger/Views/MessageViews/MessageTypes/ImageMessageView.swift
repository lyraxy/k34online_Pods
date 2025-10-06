import Foundation
import MatrixSDK
import SwiftUI


// MARK: - Image Message View
struct ImageMessageView: View {
    let message: Message
    @State private var imageData: Data?
    @State private var showingFullScreenImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .onTapGesture {
                        showingFullScreenImage = true
                    }
            } else {
                HStack {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(K34Colors.primaryRed)
                    Text("Изображение")
                        .font(.headline)
                        .foregroundColor(K34Colors.textPrimary)
                }
                .padding(12)
                .background(K34Colors.cardBackground)
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingFullScreenImage) {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                FullScreenImageView(image: uiImage, isPresented: $showingFullScreenImage)
            }
        }
    }
}
