//
//  Extensions.swift
//  Taskly
//

import SwiftUI

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var untitledIfEmpty: String {
        trimmed.isEmpty ? "Untitled" : self
    }
}