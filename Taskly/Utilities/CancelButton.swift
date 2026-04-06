//
//  Created by Juan Contreras on 4/6/26.
//

import SwiftUI

struct CancelButton: View {
    @Environment(\.dismiss) var dismiss
    @Binding var didPressCancel: Bool
    
    var body: some View {
        Button("Cancel") {
            didPressCancel = true
            dismiss()
        }
    }
}