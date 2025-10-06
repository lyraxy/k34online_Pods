import Foundation
import MatrixSDK
import SwiftUI

struct K34TextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(K34Colors.cardBackground)
            .cornerRadius(12)
            .foregroundColor(K34Colors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(K34Colors.lightGray, lineWidth: 1)
            )
    }
}
