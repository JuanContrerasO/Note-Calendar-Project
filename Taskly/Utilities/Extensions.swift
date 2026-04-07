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

struct MyView: View {
    @FocusState private var isTitleFocused: Bool  // Bool is Hashable

    var body: some View {
        TextField("Title", text: $title)
            .focused($isTitleFocused)
            .doneButtonOnKeyboard(focused: $isTitleFocused)  // ✅ Works
    }
}