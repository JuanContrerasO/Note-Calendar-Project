//
//  Created by Juan Contreras on 4/6/26.
//

import SwiftUI

// MARK: - String Extensions
extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var untitledIfEmpty: String {
        trimmed.isEmpty ? "Untitled" : self
    }
}

// MARK: - View Modifier for Keyboard Done Button
extension View {
    func doneButtonOnKeyboard(focused: FocusState<some Hashable?>.Binding) -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused.wrappedValue = nil }
            }
        }
    }
}