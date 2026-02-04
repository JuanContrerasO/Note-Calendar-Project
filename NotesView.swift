import SwiftUI

struct NotesView: View {
    @State private var notes: [Note] = []
    @State private var showingAddNote = false
    
    var body: some View {
        
        NavigationView {
            
                
            List {
                ForEach(notes) { note in
                    NavigationLink(destination: NoteDetailView(note: note, notes: $notes)) {
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
            .scrollContentBackground(.hidden)  // Hide default list background
                    .background(                        // Add image as background
                        Image("Image")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.2)              // Reduced opacity
                            .ignoresSafeArea()
                    )
            .navigationTitle("Upcoming Events")
            .toolbar {
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(notes: $notes)
            }
            
            
        }
    }
    
    
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
}

struct AddNoteView: View {
    @Binding var notes: [Note]
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $content)
                    .frame(height: 200)
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let note = Note(title: title, content: content, createdAt: Date())
                        notes.append(note)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct NoteDetailView: View {
    let note: Note
    @Binding var notes: [Note]
    
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
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
