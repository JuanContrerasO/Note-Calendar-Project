import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [Note]
    @State private var showingAddNote = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(notes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.headline)
                            Text(note.content)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                }
                .onDelete(perform: deleteNote)
            }
            .scrollContentBackground(.hidden)
            .background(
                Image("Image")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.2)
                    .ignoresSafeArea()
            )
            .navigationTitle("Upcoming Events")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddNote = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView()

                    //Allows the resizing of the sheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    func deleteNote(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(notes[index])
        }
    }
}

struct AddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""

    //Add focus state for the two fields
    @FocusState private var focusedField: Field?

    enum Field {
        case title, content
    }

    var body: some View {
        NavigationStack {
            Form {
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
            .scrollDismissesKeyboard(.interactively) //Allow tapping outside to dismiss keyboard
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let note = Note(title: title, content: content, createdAt: Date())
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
