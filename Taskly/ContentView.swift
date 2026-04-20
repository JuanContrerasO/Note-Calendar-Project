import SwiftUI
import SwiftData
 
struct ContentView: View {
    @AppStorage("isWelcomeSheetShowing") private var isWelcomeSheetShowing = true
 
    var body: some View {
        TabView {
            
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
 
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
 
            DrawingNotesView()
                .tabItem {
                    Label("Draw", systemImage: "pencil.tip.crop.circle")
                }
 
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "book")
                }
        }
        .onAppear {
            _ = NotificationManager.shared
        }
        .fullScreenCover(isPresented: $isWelcomeSheetShowing) {
            WelcomeSheetView(isPresented: $isWelcomeSheetShowing)
                // For iPad (and other devices): the sheet displays in medium or large sizes depending on the device being used
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct WelcomeSheetView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var nameInput = ""
    @FocusState private var nameFocused: Bool
 
    var body: some View {
        ZStack {
            Color(hex: "0F1629").ignoresSafeArea()
 
            if step == 0 {
                introPage
            } else {
                namePage
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }
 
    var introPage: some View {
        VStack(spacing: 0) {
            Spacer()
 
            VStack(spacing: 8) {
                Text("Welcome to Taskly")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color(hex: "e8edf5"))
                Text("Manage your notes, schedule,\nand tasks all in one place.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "5a6a8a"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
 
            Spacer()
 
            VStack(spacing: 12) {
                featureRow(icon: "house.fill",               color: "7C6FF7", text: "See everything at a glance")
                featureRow(icon: "note.text",                color: "2DD4BF", text: "Take and organize your notes")
                featureRow(icon: "calendar",                 color: "fbbf24", text: "Track your schedule and classes")
                featureRow(icon: "pencil.tip.crop.circle",   color: "E24B4A", text: "Draw and sketch with Apple Pencil")
            }
            .padding(.horizontal, 8)
 
            Spacer()
 
            Button {
                step = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    nameFocused = true
                }
            } label: {
                Text("Get Started")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "7C6FF7"))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 4)
        }
        .padding(28)
    }
 
    var namePage: some View {
        VStack(spacing: 0) {
            Spacer()
 
            VStack(spacing: 8) {
                Text("What's your name?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color(hex: "e8edf5"))
                Text("We'll use it to personalise\nyour home screen.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "5a6a8a"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
 
            Spacer()
 
            TextField("Your name", text: $nameInput)
                .font(.system(size: 17))
                .foregroundColor(Color(hex: "e8edf5"))
                .tint(Color(hex: "7C6FF7"))
                .focused($nameFocused)
                .padding(14)
                .background(Color(hex: "161f35"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: nameFocused ? "7C6FF7" : "1e2c45"), lineWidth: nameFocused ? 1.5 : 0.5)
                )
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { saveAndDismiss() }
                .padding(.horizontal, 4)
 
            Spacer()
 
            Button {
                saveAndDismiss()
            } label: {
                Text(nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? "Skip" : "Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "7C6FF7"))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 4)
        }
        .padding(28)
    }
 
    private func saveAndDismiss() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let home = Home(userName: trimmed)
            modelContext.insert(home)
            try? modelContext.save()
        }
        isPresented = false
    }
}
 
func featureRow(icon: String, color: String, text: String) -> some View {
    HStack(spacing: 14) {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: color).opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: color))
        }
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "c8d3e8"))
        Spacer()
    }
    .padding(12)
    .background(Color(hex: "161f35"))
    .cornerRadius(12)
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1e2c45"), lineWidth: 0.5))
}
 
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
 
#Preview {
    ContentView()
        .modelContainer(for: [TaskItem.self, Course.self, Home.self, DrawingNote.self])
}
