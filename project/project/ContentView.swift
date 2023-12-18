import SwiftUI

struct ContentView: View {
    @State private var reminders: [Reminder] = []

    var body: some View {
        TabView {
            View_AddVoiceNotes()
                .tabItem {
                    Label(LocalizedStringKey("voiceMemos"), systemImage: "list.bullet")
                
                }

            View_AddReminder()
                .tabItem {
                    Label(LocalizedStringKey("addReminder"), systemImage: "plus.circle.fill")
                }
                

            View_About()
                .tabItem {
                    Label(LocalizedStringKey("about"), systemImage: "questionmark.app.fill")
                }
                
        }
       
    }
}

#Preview {
    ContentView()
}
