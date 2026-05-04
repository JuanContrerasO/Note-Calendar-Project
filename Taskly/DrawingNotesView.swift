import SwiftUI
import SwiftData
import PencilKit

// MARK: - DrawingNotesView
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
                                .foregroundColor(Color(hex: "e8edf5"))
                            Text(note.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(Color(hex: "5a6a8a"))
                        }
                    }
                }
                .onDelete(perform: deleteDrawingNote)
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0F1629"))
            .navigationTitle("Drawings")
            .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
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
        for index in offsets { modelContext.delete(drawingNotes[index]) }
    }
}

// MARK: - AddDrawingView
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
                ToolbarItem(placement: .navigationBarLeading) {
                    CancelButton(didPressCancel: $didPressCancel)
                }
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

// MARK: - DrawingCanvasView
struct DrawingCanvasView: View {
    let drawingNote: DrawingNote
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var canvasView = PKCanvasView()
    @State private var toolPickerIsActive = true
    @State private var didPressCancel = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var showingExportError = false

    var body: some View {
        CanvasView(canvasView: $canvasView, toolPickerIsActive: $toolPickerIsActive)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(drawingNote.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0F1629"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CancelButton(didPressCancel: $didPressCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exportAsPDF()
                    } label: {
                        Label("Export PDF", systemImage: "arrow.up.doc.fill")
                    }
                    .tint(Color(hex: "7C6FF7"))
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
                Text("Could not export the drawing as PDF. Please try again.")
            }
            .onAppear { loadDrawing() }
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

    // MARK: - Export

    private func exportAsPDF() {
        let drawing = canvasView.drawing

        // Use the drawing's natural bounds, with a minimum canvas size
        let canvasBounds = drawing.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter fallback
            : drawing.bounds.insetBy(dx: -40, dy: -40)    // add padding

        // Render the drawing to a UIImage at screen scale
        let image = drawing.image(from: canvasBounds, scale: UIScreen.main.scale)

        // Build PDF data
        let pdfData = NSMutableData()
        let pageRect = CGRect(origin: .zero, size: canvasBounds.size)
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        UIGraphicsBeginPDFPage()
        if let ctx = UIGraphicsGetCurrentContext() {
            // White background
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(pageRect)
            // Draw image
            image.draw(in: pageRect)
        }
        UIGraphicsEndPDFContext()

        // Write to a temp file
        let fileName = "\(drawingNote.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Drawing" : drawingNote.title).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tempURL, options: .atomic)
            exportURL = tempURL
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingShareSheet = true
            }
        } catch {
            showingExportError = true
        }
    }

    private func cleanupExport() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            exportURL = nil
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

// MARK: - ShareSheet (UIActivityViewController wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
