//
//  Created by Juan Contreras on 4/6/26.
//

import SwiftData

struct NoteSaver {
    static func saveOrDelete(note: Note, title: String, content: String, context: ModelContext) {
        let trimmedTitle = title.trimmed
        let trimmedContent = content.trimmed
        
        if trimmedTitle.isEmpty && trimmedContent.isEmpty {
            context.delete(note)
        } else {
            note.title = trimmedTitle.isEmpty ? "Untitled" : title
            note.content = content
        }
        try? context.save()
    }
}