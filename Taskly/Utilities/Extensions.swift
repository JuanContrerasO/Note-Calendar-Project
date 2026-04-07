//
//  Extensions.swift
//  Taskly
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

// MARK: - View Extension for Keyboard Done Button
extension View {
    func doneButtonOnKeyboard<F: Hashable>(focused: FocusState<F?>.Binding) -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focused.wrappedValue = nil
                }
            }
        }
    }
}