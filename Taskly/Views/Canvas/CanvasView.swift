import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPickerIsActive: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        return canvasView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if toolPickerIsActive {
            let toolPicker = context.coordinator.toolPicker
            toolPicker.setVisible(true, forFirstResponder: uiView)
            toolPicker.addObserver(uiView)
            uiView.becomeFirstResponder()
        }
    }

    class Coordinator {
        let toolPicker = PKToolPicker()
    }
}
