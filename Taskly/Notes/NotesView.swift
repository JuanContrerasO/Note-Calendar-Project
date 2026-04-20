import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [Note]
    @Query private var folders: [Folder]
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

    var body: some View {
        NavigationStack {
            mainList
                .navigationTitle("Notes")
                .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(isEditing ? "Done" : "Edit") {
                            isEditing.toggle()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAddOptions = true }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "7C6FF7"))
                    }
                }
        }
        .confirmationDialog("Add", isPresented: $showingAddOptions, titleVisibility: .visible) {
            Button("New Note") { showingAddNote = true }
            Button("New Folder") { showingAddFolder = true }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Folder Options", isPresented: $showingFolderActions, titleVisibility: .visible, presenting: selectedFolderForActions) { folder in
            Button("Edit Folder") { folderToEdit = folder }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Note Options", isPresented: $showingNoteActions, titleVisibility: .visible, presenting: selectedNoteForActions) { note in
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
        .navigationDestination(item: $noteToView) { note in
            NoteDetailView(note: note)
        }
    }

    @ViewBuilder
    private var mainList: some View {
        List {
            if !sortedFolders.isEmpty {
                Section("Folders") {
                    ForEach(sortedFolders) { folder in
                        folderSection(folder)
                    }
                }
            }

            Section("Notes") {
                ForEach(unfiledNotes) { note in
                    noteRow(note)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(hex: "0F1629"))
    }

    @ViewBuilder
    private func folderSection(_ folder: Folder) -> some View {
        let folderNotes = sortedNotes(in: folder)
        VStack(spacing: 0) {
            folderRow(folder, notes: folderNotes)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditing {
                        selectedFolderForActions = folder
                        showingFolderActions = true
                    } else {
                        toggleExpanded(folder)
                    }
                }
                .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                    handleDrop(providers, to: folder)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteFolder(folder)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

            if expandedFolderIDs.contains(folder.persistentModelID) {
                ForEach(folderNotes) { note in
                    noteRow(note)
                        .padding(.leading, 24)
                }
            }
        }
    }

    private func folderRow(_ folder: Folder, notes: [Note]) -> some View {
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
        .onDrag {
            NSItemProvider(object: note.id.uuidString as NSString)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var sortedFolders: [Folder] {
        folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var unfiledNotes: [Note] {
        notes
            .filter { $0.folder == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func sortedNotes(in folder: Folder) -> [Note] {
        folder.notes.sorted { $0.createdAt > $1.createdAt }
    }

    private func toggleExpanded(_ folder: Folder) {
        let id = folder.persistentModelID
        if expandedFolderIDs.contains(id) {
            expandedFolderIDs.remove(id)
        } else {
            expandedFolderIDs.insert(id)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider], to folder: Folder) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let idString = object as? NSString,
                  let noteID = UUID(uuidString: idString as String) else { return }

            DispatchQueue.main.async {
                if let note = notes.first(where: { $0.id == noteID }) {
                    note.folder = folder
                    expandedFolderIDs.insert(folder.persistentModelID)
                }
            }
        }

        return true
    }

    private func deleteFolder(_ folder: Folder) {
        for note in folder.notes {
            note.folder = nil
        }
        modelContext.delete(folder)
    }
}

// MARK: - Add Note View
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
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
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
            let note = Note(title: trimmedTitle.isEmpty ? "Untitled" : title, content: content, createdAt: Date())
            if let selectedFolderID, let folder = folders.first(where: { $0.persistentModelID == selectedFolderID }) {
                note.folder = folder
            }
            modelContext.insert(note)
        }
    }
}

// MARK: - Edit Note View
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
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
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
            NoteSaver.saveOrDelete(note: note, title: editedTitle, content: editedContent, context: modelContext)
        }
    }
}

// MARK: - Add Folder View
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
                            Button {
                                selectedColorName = color.rawValue
                            } label: {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedColorName == color.rawValue ? Color(hex: "e8edf5") : Color.clear,
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

// MARK: - Edit Folder View
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
                            Button {
                                folder.colorName = color.rawValue
                            } label: {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                folder.colorName == color.rawValue ? Color(hex: "e8edf5") : Color.clear,
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

// MARK: - Note Detail View
struct NoteDetailView: View {
    let note: Note
    @Environment(\.modelContext) private var modelContext
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Title", text: $editedTitle)
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "e8edf5"))
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .content }

                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(Color(hex: "5a6a8a"))

                Divider()
                    .overlay(Color(hex: "1e2c45"))

                TextEditor(text: $editedContent)
                    .frame(minHeight: 200)
                    .foregroundColor(Color(hex: "e8edf5"))
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .content)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
            }
            .padding()
        }
        .background(Color(hex: "0F1629"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .foregroundColor(Color(hex: "7C6FF7"))
            }
        }
        .onDisappear {
            NoteSaver.saveOrDelete(note: note, title: editedTitle, content: editedContent, context: modelContext)
        }
    }
}

// MARK: - FolderColor Enum
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
