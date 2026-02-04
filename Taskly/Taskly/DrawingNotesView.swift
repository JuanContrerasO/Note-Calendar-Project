import SwiftUI
import SwiftData
import PencilKit

struct DrawingNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var drawingNotes: [DrawingNote]
    @State private var showingAddDrawing = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(drawingNotes) { note in
                    NavigationLink(destination: DrawingCanvasView(drawingNote: note)) {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.headline)
                            Text(note.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteDrawingNote)
            }
            .navigationTitle("Drawings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddDrawing = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDrawing) {
                AddDrawingView()
            }
        }
    }

    func deleteDrawingNote(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(drawingNotes[index])
        }
    }
}

struct AddDrawingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var canvasView = PKCanvasView()
    @State private var toolPickerIsActive = true

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Drawing Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                CanvasView(canvasView: $canvasView, toolPickerIsActive: $toolPickerIsActive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .navigationTitle("New Drawing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let drawingData = canvasView.drawing.dataRepresentation()
                        let note = DrawingNote(
                            title: title,
                            drawingData: drawingData,
                            createdAt: Date()
                        )
                        modelContext.insert(note)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct DrawingCanvasView: View {
    let drawingNote: DrawingNote
    @State private var canvasView = PKCanvasView()
    @State private var toolPickerIsActive = true

    var body: some View {
        CanvasView(canvasView: $canvasView, toolPickerIsActive: $toolPickerIsActive)
            .navigationTitle(drawingNote.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        drawingNote.drawingData = canvasView.drawing.dataRepresentation()
                    }
                }
            }
            .onAppear {
                loadDrawing()
            }
    }

    private func loadDrawing() {
        do {
            let drawing = try PKDrawing(data: drawingNote.drawingData)
            canvasView.drawing = drawing
        } catch {
            canvasView.drawing = PKDrawing()
        }
    }
}
