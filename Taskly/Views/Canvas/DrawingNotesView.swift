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
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
    @State private var didPressCancel = false

    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Drawing Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit { isTitleFocused = false }

                CanvasView(canvasView: $canvasView, toolPickerIsActive: $toolPickerIsActive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .navigationTitle("New Drawing")
            .toolbar {
                CancelButton(didPressCancel: $didPressCancel)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isTitleFocused = false }
                }
            }
        }
        .onDisappear {
            guard !didPressCancel else { return }
            let hasDrawing = !canvasView.drawing.bounds.isEmpty
            guard hasDrawing else { return }
            let finalTitle = title.untitledIfEmpty
            let drawingData = canvasView.drawing.dataRepresentation()
            let note = DrawingNote(title: finalTitle, drawingData: drawingData, createdAt: Date())
            modelContext.insert(note)
            try? modelContext.save()
        }
    }
}

struct DrawingCanvasView: View {
    let drawingNote: DrawingNote
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var canvasView = PKCanvasView()
    @State private var toolPickerIsActive = true
    @State private var didPressCancel = false

    var body: some View {
        CanvasView(canvasView: $canvasView, toolPickerIsActive: $toolPickerIsActive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(drawingNote.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CancelButton(didPressCancel: $didPressCancel)
            }
            .onAppear {
                loadDrawing()
            }
            .onDisappear {
                guard !didPressCancel else { return }
                let hasDrawing = !canvasView.drawing.bounds.isEmpty
                if hasDrawing {
                    drawingNote.drawingData = canvasView.drawing.dataRepresentation()
                    try? modelContext.save()
                } else {
                    modelContext.delete(drawingNote)
                    try? modelContext.save()
                }
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
