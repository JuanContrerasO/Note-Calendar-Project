import SwiftUI

struct ContentView: View {
    
    @AppStorage("isWelcomeSheetShowing") var isWelcomeSheetShowing = true
    
    
    
    var body: some View {
        
        
        TabView {
            
            
                         
                 
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .sheet(isPresented: $isWelcomeSheetShowing) {
                    Color(.blue)
                        .interactiveDismissDisabled()
                }
           
            
        }
    }
}

#Preview {
    ContentView()
}
