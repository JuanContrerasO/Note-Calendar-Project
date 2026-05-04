import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Drag Payload
struct DragItem: Codable {
    enum Kind: String, Codable { case note, folder }
    let kind: Kind
    let id: String
}

// Flat list item (folders and unfiled notes interleaved in one list)
private enum ListItem: Identifiable {
    case folder(Folder)
    case note(Note)

    var id: String {
        switch self {
        case .folder(let f): return "folder-\(f.id.uuidString)"
        case .note(let n):   return "note-\(n.id.uuidString)"
        }
    }
}

// NotesView
struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.sortOrder)   private var notes: [Note]
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]

    @State private var isEditing = false
    @State private var showingAddOptions = false
    @State private var showingAddNote = false
    @State private var showingAddFolder = false
    @State private var expandedFolderIDs: Set<PersistentIdentifier> = []
    @State private var folderToEdit: Folder?
    @State private var noteToEdit: Note?
    @State private var noteToView: Note?
    @State private var selectedFolderForActions: Folder?
    @State private var selectedNoteForActions: Note?
    @State private var showingFolderActions = false
    @State private var showingNoteActions = false
    @State private var dropTargetFolderID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            mainList
                .navigationTitle("Notes")
                .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAddOptions = true }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "7C6FF7"))
                    }
                }
                .navigationDestination(item: $noteToView) { note in
                    NoteDetailView(note: note)
                }
        }
        .confirmationDialog("Add", isPresented: $showingAddOptions, titleVisibility: .visible) {
            Button("New Note") { showingAddNote = true }
            Button("New Folder") { showingAddFolder = true }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Folder Options", isPresented: $showingFolderActions,
                            titleVisibility: .visible, presenting: selectedFolderForActions) { folder in
            Button("Edit Folder") { folderToEdit = folder }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Note Options", isPresented: $showingNoteActions,
                            titleVisibility: .visible, presenting: selectedNoteForActions) { note in
            Button("View Note") { noteToView = note }
            Button("Edit Note") { noteToEdit = note }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(folders: sortedFolders)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAddFolder) {
            AddFolderView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $folderToEdit) { folder in
            EditFolderView(folder: folder)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $noteToEdit) { note in
            EditNoteView(note: note)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    //  Main List
    // Single flat list — folders and unfiled notes interleaved so drag-into-folder works

    @ViewBuilder
    private var mainList: some View {
        List {
            ForEach(flatItems) { item in
                switch item {
                case .folder(let folder):
                    folderSection(folder)
                        .listRowBackground(Color(hex: "0F1629"))
                        .listRowSeparatorTint(Color(hex: "1e2c45"))
                case .note(let note):
                    noteRow(note)
                        .listRowBackground(Color(hex: "0F1629"))
                        .listRowSeparatorTint(Color(hex: "1e2c45"))
                        .dropDestination(for: Data.self) { items, _ in
                            handleNoteDrop(items, beforeNote: note, intoFolder: nil)
                        } isTargeted: { _ in }
                }
            }
            .onMove { moveItems(from: $0, to: $1) }

            // Invisible drop zone at the bottom — dropping here un-files a note
            Color.clear
                .frame(height: 1)
                .listRowBackground(Color(hex: "0F1629"))
                .listRowSeparator(.hidden)
                .dropDestination(for: Data.self) { items, _ in
                    handleNoteDrop(items, beforeNote: nil, intoFolder: nil)
                } isTargeted: { _ in }
        }
        .scrollContentBackground(.hidden)
        .background(Color(hex: "0F1629"))
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
    }

    // Folder Section

    @ViewBuilder
    private func folderSection(_ folder: Folder) -> some View {
        let folderNotes = sortedNotes(in: folder)
        let isDropTarget = dropTargetFolderID == folder.persistentModelID

        VStack(spacing: 0) {
            folderHeaderRow(folder, notes: folderNotes)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditing {
                        selectedFolderForActions = folder
                        showingFolderActions = true
                    } else {
                        toggleExpanded(folder)
                    }
                }
                .draggable(encoded(.folder, id: folder.id.uuidString))
                // Drop a note onto a folder header → move it inside
                .dropDestination(for: Data.self) { items, _ in
                    dropTargetFolderID = nil
                    return handleNoteDrop(items, beforeNote: nil, intoFolder: folder)
                } isTargeted: { targeted in
                    dropTargetFolderID = targeted ? folder.persistentModelID : nil
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "7C6FF7"), lineWidth: isDropTarget ? 2 : 0)
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { deleteFolder(folder) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

            if expandedFolderIDs.contains(folder.persistentModelID) {
                ForEach(folderNotes) { note in
                    noteRow(note)
                        .padding(.leading, 24)
                        .dropDestination(for: Data.self) { items, _ in
                            handleNoteDrop(items, beforeNote: note, intoFolder: folder)
                        } isTargeted: { _ in }
                }
                .onMove { moveNotesInFolder(folder, from: $0, to: $1) }
            }
        }
    }

    // Row Views

    private func folderHeaderRow(_ folder: Folder, notes: [Note]) -> some View {
        let latestDate = notes.first?.createdAt ?? folder.createdAt
        return HStack(spacing: 12) {
            Circle()
                .fill(FolderColor.color(for: folder.colorName))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundColor(Color(hex: "e8edf5"))
                Text("\(notes.count) Notes • \(latestDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(Color(hex: "5a6a8a"))
            }
            Spacer()
            Image(systemName: expandedFolderIDs.contains(folder.persistentModelID) ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(Color(hex: "5a6a8a"))
        }
        .padding(.vertical, 4)
    }

    private func noteRow(_ note: Note) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(Color(hex: "e8edf5"))
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "5a6a8a"))
                    .lineLimit(2)
            }
            Spacer()
            Text(note.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(Color(hex: "5a6a8a"))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                selectedNoteForActions = note
                showingNoteActions = true
            } else {
                noteToView = note
            }
        }
        .draggable(encoded(.note, id: note.id.uuidString))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { modelContext.delete(note) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // Flat Item List

    private var flatItems: [ListItem] {
        let folderItems = sortedFolders.map { ListItem.folder($0) }
        let noteItems   = unfiledNotes.map  { ListItem.note($0)   }
        return folderItems + noteItems
    }

    // Drag & Drop

    private func encoded(_ kind: DragItem.Kind, id: String) -> Data {
        (try? JSONEncoder().encode(DragItem(kind: kind, id: id))) ?? Data()
    }

    @discardableResult
    private func handleNoteDrop(_ items: [Data], beforeNote: Note?, intoFolder: Folder?) -> Bool {
        guard
            let data = items.first,
            let drag = try? JSONDecoder().decode(DragItem.self, from: data),
            drag.kind == .note,
            let uuid = UUID(uuidString: drag.id),
            let note = notes.first(where: { $0.id == uuid })
        else { return false }

        note.folder = intoFolder
        if let intoFolder { expandedFolderIDs.insert(intoFolder.persistentModelID) }

        var siblings: [Note]
        if let intoFolder {
            siblings = sortedNotes(in: intoFolder).filter { $0.id != note.id }
        } else {
            siblings = unfiledNotes.filter { $0.id != note.id }
        }

        if let beforeNote, let idx = siblings.firstIndex(where: { $0.id == beforeNote.id }) {
            siblings.insert(note, at: idx)
        } else {
            siblings.append(note)
        }
        for (i, n) in siblings.enumerated() { n.sortOrder = i }
        try? modelContext.save()
        return true
    }

    // Move Handlers

    private func moveItems(from indices: IndexSet, to destination: Int) {
        var list = flatItems
        list.move(fromOffsets: indices, toOffset: destination)
        var folderOrder = 0
        var noteOrder = 0
        for item in list {
            switch item {
            case .folder(let f): f.sortOrder = folderOrder; folderOrder += 1
            case .note(let n):   n.sortOrder = noteOrder;   noteOrder += 1
            }
        }
        try? modelContext.save()
    }

    private func moveNotesInFolder(_ folder: Folder, from indices: IndexSet, to destination: Int) {
        var list = sortedNotes(in: folder)
        list.move(fromOffsets: indices, toOffset: destination)
        for (i, n) in list.enumerated() { n.sortOrder = i }
        try? modelContext.save()
    }

    // Computed Collections

    private var sortedFolders: [Folder] {
        folders.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var unfiledNotes: [Note] {
        notes.filter { $0.folder == nil }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func sortedNotes(in folder: Folder) -> [Note] {
        folder.notes.sorted { $0.sortOrder < $1.sortOrder }
    }

    // Helpers

    private func toggleExpanded(_ folder: Folder) {
        let id = folder.persistentModelID
        if expandedFolderIDs.contains(id) { expandedFolderIDs.remove(id) }
        else { expandedFolderIDs.insert(id) }
    }

    private func deleteFolder(_ folder: Folder) {
        for note in folder.notes { note.folder = nil }
        modelContext.delete(folder)
    }
}

// Add Note View
struct AddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let folders: [Folder]
    @State private var title = ""
    @State private var content = ""
    @State private var selectedFolderID: PersistentIdentifier?
    @State private var didPressCancel = false

    @FocusState private var focusedField: Field?
    enum Field { case title, content }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .content }
                        .foregroundColor(Color(hex: "e8edf5"))
                    TextEditor(text: $content)
                        .focused($focusedField, equals: .content)
                        .frame(minHeight: 200)
                        .foregroundColor(Color(hex: "e8edf5"))
                        .scrollContentBackground(.hidden)
                }
                if !folders.isEmpty {
                    Section("Folder") {
                        Picker("Folder", selection: $selectedFolderID) {
                            Text("None").tag(Optional<PersistentIdentifier>.none)
                            ForEach(folders) { folder in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(FolderColor.color(for: folder.colorName))
                                        .frame(width: 10, height: 10)
                                    Text(folder.name)
                                }
                                .tag(Optional(folder.persistentModelID))
                            }
                        }
                        .tint(Color(hex: "7C6FF7"))
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0F1629"))
            .navigationTitle("New Note")
            .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton(didPressCancel: $didPressCancel)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .foregroundColor(Color(hex: "7C6FF7"))
                }
            }
        }
        .onDisappear {
            guard !didPressCancel else { return }
            let trimmedTitle = title.trimmed
            let trimmedContent = content.trimmed
            guard !trimmedTitle.isEmpty || !trimmedContent.isEmpty else { return }
            let note = Note(
                title: trimmedTitle.isEmpty ? "Untitled" : title,
                content: content,
                createdAt: Date()
            )
            if let selectedFolderID,
               let folder = folders.first(where: { $0.persistentModelID == selectedFolderID }) {
                note.folder = folder
            }
            modelContext.insert(note)
        }
    }
}

// Edit Note View
struct EditNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var note: Note
    @State private var didPressCancel = false
    @State private var editedTitle: String
    @State private var editedContent: String

    @FocusState private var focusedField: Field?
    enum Field { case title, content }

    init(note: Note) {
        self.note = note
        _editedTitle = State(initialValue: note.title)
        _editedContent = State(initialValue: note.content)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $editedTitle)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .content }
                        .foregroundColor(Color(hex: "e8edf5"))
                    TextEditor(text: $editedContent)
                        .focused($focusedField, equals: .content)
                        .frame(minHeight: 200)
                        .foregroundColor(Color(hex: "e8edf5"))
                        .scrollContentBackground(.hidden)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0F1629"))
            .navigationTitle("Edit Note")
            .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton(didPressCancel: $didPressCancel)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .foregroundColor(Color(hex: "7C6FF7"))
                }
            }
        }
        .onDisappear {
            guard !didPressCancel else { return }
            NoteSaver.saveOrDelete(
                note: note, title: editedTitle, content: editedContent, context: modelContext
            )
        }
    }
}

// Add Folder View
struct AddFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedColorName = FolderColor.blue.rawValue
    private let gridColumns = [GridItem(.adaptive(minimum: 36), spacing: 12)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder Name", text: $name)
                        .foregroundColor(Color(hex: "e8edf5"))
                }
                Section("Color") {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(FolderColor.allCases) { color in
                            Button { selectedColorName = color.rawValue } label: {
                                Circle().fill(color.color).frame(width: 24, height: 24)
                                    .overlay(
                                        Circle().stroke(
                                            selectedColorName == color.rawValue
                                                ? Color(hex: "e8edf5") : Color.clear,
                                            lineWidth: 2
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(color.label)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0F1629"))
            .navigationTitle("New Folder")
            .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let folder = Folder(name: name, createdAt: Date(), colorName: selectedColorName)
                        modelContext.insert(folder)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .tint(Color(hex: "7C6FF7"))
                }
            }
        }
    }
}

// Edit Folder View
struct EditFolderView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var folder: Folder
    private let gridColumns = [GridItem(.adaptive(minimum: 36), spacing: 12)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder Name", text: $folder.name)
                        .foregroundColor(Color(hex: "e8edf5"))
                }
                Section("Color") {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(FolderColor.allCases) { color in
                            Button { folder.colorName = color.rawValue } label: {
                                Circle().fill(color.color).frame(width: 24, height: 24)
                                    .overlay(
                                        Circle().stroke(
                                            folder.colorName == color.rawValue
                                                ? Color(hex: "e8edf5") : Color.clear,
                                            lineWidth: 2
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(color.label)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0F1629"))
            .navigationTitle("Edit Folder")
            .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .disabled(folder.name.trimmed.isEmpty)
                        .tint(Color(hex: "7C6FF7"))
                }
            }
        }
    }
}

// Note Detail View
struct NoteDetailView: View {
    let note: Note
    @Environment(\.modelContext) private var modelContext
    @Query private var homeData: [Home]                          // ← username source
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var showingExportError = false
    @FocusState private var focusedField: Field?
    enum Field { case title, content }

    private var userName: String {
        homeData.first?.userName ?? "Unknown"
    }

    init(note: Note) {
        self.note = note
        _editedTitle = State(initialValue: note.title)
        _editedContent = State(initialValue: note.content)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Title", text: $editedTitle)
                    .font(.title).bold()
                    .foregroundColor(Color(hex: "e8edf5"))
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .content }

                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(Color(hex: "5a6a8a"))

                Divider().overlay(Color(hex: "1e2c45"))

                TextEditor(text: $editedContent)
                    .frame(minHeight: 200)
                    .foregroundColor(Color(hex: "e8edf5"))
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .content)
            }
            .padding()
        }
        .background(Color(hex: "0F1629"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { exportAsPDF() } label: {
                        Label("Export as PDF", systemImage: "doc.richtext.fill")
                    }
                    Button { exportAsTXT() } label: {
                        Label("Export as .txt", systemImage: "doc.plaintext.fill")
                    }
                } label: {
                    Image(systemName: "arrow.up.doc.fill")
                        .foregroundColor(Color(hex: "7C6FF7"))
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .foregroundColor(Color(hex: "7C6FF7"))
            }
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: cleanupExport) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Failed", isPresented: $showingExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Could not export the note. Please try again.")
        }
        .onDisappear {
            NoteSaver.saveOrDelete(
                note: note, title: editedTitle, content: editedContent, context: modelContext
            )
        }
    }

    // Export as PDF
    private func exportAsPDF() {
        let safeTitle  = editedTitle.trimmed.isEmpty ? "Note" : editedTitle
        let pageWidth:  CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin:     CGFloat = 56

        let pdfData  = NSMutableData()
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        // Title = note title, Author = user's name from Home
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, [
            kCGPDFContextTitle  as String: safeTitle,
            kCGPDFContextAuthor as String: userName
        ])

        let titleFont = UIFont.boldSystemFont(ofSize: 22)
        let bodyFont  = UIFont.systemFont(ofSize: 14)
        let dateFont  = UIFont.systemFont(ofSize: 11)
        let textColor = UIColor(red: 0.910, green: 0.929, blue: 0.961, alpha: 1) // e8edf5
        let bgColor   = UIColor(red: 0.059, green: 0.086, blue: 0.161, alpha: 1) // 0F1629
        let subColor  = UIColor(red: 0.353, green: 0.416, blue: 0.541, alpha: 1) // 5a6a8a
        let contentWidth = pageWidth - margin * 2
        var yOffset: CGFloat = margin

        func beginPage() {
            UIGraphicsBeginPDFPage()
            bgColor.setFill()
            UIRectFill(pageRect)
            yOffset = margin
        }

        func drawText(_ string: String, font: UIFont, color: UIColor) {
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            let nsStr = string as NSString
            let size  = nsStr.boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs, context: nil
            ).size
            if yOffset + size.height > pageHeight - margin { beginPage() }
            nsStr.draw(
                with: CGRect(x: margin, y: yOffset, width: contentWidth, height: size.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs, context: nil
            )
            yOffset += size.height
        }

        beginPage()
        drawText(safeTitle, font: titleFont, color: textColor)
        yOffset += 4
        drawText(note.createdAt.formatted(date: .long, time: .shortened), font: dateFont, color: subColor)
        yOffset += 12
        subColor.setFill()
        UIRectFill(CGRect(x: margin, y: yOffset, width: contentWidth, height: 0.5))
        yOffset += 12
        drawText(editedContent.trimmed.isEmpty ? "(No content)" : editedContent, font: bodyFont, color: textColor)
        UIGraphicsEndPDFContext()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeTitle).pdf")
        do {
            try pdfData.write(to: tempURL, options: .atomic)
            exportURL = tempURL
            showingShareSheet = true
        } catch { showingExportError = true }
    }

    // Export as TXT
    private func exportAsTXT() {
        let safeTitle  = editedTitle.trimmed.isEmpty ? "Note" : editedTitle
        let dateString = note.createdAt.formatted(date: .long, time: .shortened)
        let body       = editedContent.trimmed.isEmpty ? "(No content)" : editedContent

        let fullText   = "\(safeTitle)\nBy \(userName)\n\(dateString)\n\n\(body)"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeTitle).txt")
        do {
            try fullText.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            showingShareSheet = true
        } catch { showingExportError = true }
    }

    private func cleanupExport() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
        }
    }
}

// Share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Folder colors
enum FolderColor: String, CaseIterable, Identifiable {
    case blue, teal, green, yellow, orange, red, pink, purple, gray

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .blue:   return Color(hex: "7C6FF7")
        case .teal:   return Color(hex: "2DD4BF")
        case .green:  return Color(hex: "4ade80")
        case .yellow: return Color(hex: "fbbf24")
        case .orange: return Color(hex: "fb923c")
        case .red:    return Color(hex: "E24B4A")
        case .pink:   return Color(hex: "f472b6")
        case .purple: return Color(hex: "a855f7")
        case .gray:   return Color(hex: "5a6a8a")
        }
    }

    static func color(for name: String) -> Color {
        FolderColor(rawValue: name)?.color ?? Color(hex: "7C6FF7")
    }
}
