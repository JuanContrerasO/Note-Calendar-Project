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
            List {
                if !sortedFolders.isEmpty {
                    Section("Folders") {
                        ForEach(sortedFolders) { folder in
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
                    }
                }

                Section("Notes") {
                    ForEach(unfiledNotes) { note in
                        noteRow(note)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                Image("Image")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.2)
                    .ignoresSafeArea()
            )
            .navigationTitle("Notes")
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
                    .buttonStyle(.glass)
                }
            }
            .confirmationDialog("Add", isPresented: $showingAddOptions, titleVisibility: .visible) {
                Button("New Note") { showingAddNote = true }
                Button("New Folder") { showingAddFolder = true }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Folder Options", isPresented: $showingFolderActions, titleVisibility: .visible, presenting: selectedFolderForActions) { folder in
                Button("Edit Folder") {
                    folderToEdit = folder
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Note Options", isPresented: $showingNoteActions, titleVisibility: .visible, presenting: selectedNoteForActions) { note in
                Button("View Note") {
                    noteToView = note
                }
                Button("Edit Note") {
                    noteToEdit = note
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(folders: sortedFolders)
                    //Allows the resizing of the sheet
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
                  let noteID = UUID(uuidString: idString as String) else {
                return
            }

            DispatchQueue.main.async {
                if let note = notes.first(where: { $0.id == noteID }) {
                    note.folder = folder
                    expandedFolderIDs.insert(folder.persistentModelID)
                }
            }
        }

        return true
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
                Text("\(notes.count) Notes • \(latestDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: expandedFolderIDs.contains(folder.persistentModelID) ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func noteRow(_ note: Note) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            Text(note.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
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

    private func deleteFolder(_ folder: Folder) {
        for note in folder.notes {
            note.folder = nil
        }
        modelContext.delete(folder)
    }
}

struct AddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    let folders: [Folder]
    @State private var title = ""
    @State private var content = ""
    @State private var selectedFolderID: PersistentIdentifier?

    //Add focus state for the two fields
    @FocusState private var focusedField: Field?

    enum Field {
        case title, content
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title) //Bind focus
                        .submitLabel(.next) //"Next" on keyboard
                        .onSubmit {
                            focusedField = .content //Move to content when Next is tapped
                        }

                    TextEditor(text: $content)
                        .focused($focusedField, equals: .content)
                        .frame(minHeight: 200)
                        .submitLabel(.done) //"Done" on keyboard
                        .onSubmit {
                            focusedField = nil //Dismiss keyboard when Done tappped
                        }
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
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively) //Allow tapping outside to dismiss keyboard
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let note = Note(title: title, content: content, createdAt: Date())
                        if let selectedFolderID,
                           let folder = folders.first(where: { $0.persistentModelID == selectedFolderID }) {
                            note.folder = folder
                        }
                        modelContext.insert(note)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
                //Add a keyboard toolbar with a "Done" button
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil //Dismiss keyboard
                    }
                }
            }
        }
    }
}

struct EditNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var note: Note

    //Add focus state for the two fields
    @FocusState private var focusedField: Field?

    enum Field {
        case title, content
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $note.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .content
                        }

                    TextEditor(text: $note.content)
                        .focused($focusedField, equals: .content)
                        .frame(minHeight: 200)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .disabled(note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}

struct AddFolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedColorName = FolderColor.blue.rawValue

    private let gridColumns = [
        GridItem(.adaptive(minimum: 36), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder Name", text: $name)
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
                                                selectedColorName == color.rawValue ? Color.primary : Color.clear,
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
            .navigationTitle("New Folder")
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
                }
            }
        }
    }
}

struct EditFolderView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var folder: Folder

    private let gridColumns = [
        GridItem(.adaptive(minimum: 36), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder Name", text: $folder.name)
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
                                                folder.colorName == color.rawValue ? Color.primary : Color.clear,
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
            .navigationTitle("Edit Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .disabled(folder.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct NoteDetailView: View {
    let note: Note

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(note.title)
                    .font(.title)
                    .bold()

                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider()

                Text(note.content)
                    .padding(.top)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum FolderColor: String, CaseIterable, Identifiable {
    case blue
    case teal
    case green
    case yellow
    case orange
    case red
    case pink
    case purple
    case gray

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .blue:
            return Color.blue
        case .teal:
            return Color.teal
        case .green:
            return Color.green
        case .yellow:
            return Color.yellow
        case .orange:
            return Color.orange
        case .red:
            return Color.red
        case .pink:
            return Color.pink
        case .purple:
            return Color.purple
        case .gray:
            return Color.gray
        }
    }

    static func color(for name: String) -> Color {
        FolderColor(rawValue: name)?.color ?? .blue
    }
}
