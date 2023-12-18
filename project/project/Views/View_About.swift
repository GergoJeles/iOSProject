import SwiftUI

// A view that displays information about the application, student, and lecture.
struct View_About: View {
    // Retrieving app version and build number from the bundle
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    private let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"

    var body: some View {
        List {
            applicationSection
            studentSection
            lectureSection
        }
        .listStyle(GroupedListStyle())
        .navigationTitle(NSLocalizedString("About", comment: "Navigation title for the About view"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // Section displaying application details
    private var applicationSection: some View {
        Section(header: Text(NSLocalizedString("Application", comment: "Header for application section in About view"))) {
            HStack {
                Label(NSLocalizedString("Version", comment: "Version label in About view"), systemImage: "info.circle")
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
            }
        }
    }

    // Section displaying student information
    private var studentSection: some View {
        Section(header: Text(NSLocalizedString("Student", comment: "Header for student section in About view"))) {
            HStack {
                Label(NSLocalizedString("Name", comment: "Name label in About view"), systemImage: "person.fill")
                Spacer()
                Text("Gergő Jeles")
            }

            HStack {
                Label(NSLocalizedString("Student ID", comment: "Student ID label in About view"), systemImage: "number")
                Spacer()
                Text("2230016011")
            }

            HStack {
                Label(NSLocalizedString("E-mail", comment: "E-mail label in About view"), systemImage: "envelope.fill")
                Spacer()
                Text("pa22l011@technikum-wien.at")
            }
        }
    }

    // Section displaying lecture information
    private var lectureSection: some View {
        Section(header: Text(NSLocalizedString("Lecture", comment: "Header for lecture section in About view"))) {
            HStack {
                Label(NSLocalizedString("Lecturer Name", comment: "Lecturer name label in About view"), systemImage: "person.text.rectangle.fill")
                Spacer()
                Text("Kai Höher")
            }
            
            HStack {
                Label(NSLocalizedString("Lecture Name", comment: "Lecture name label in About view"), systemImage: "book.closed.fill")
                Spacer()
                Text("iOS Advanced")
            }
        }
    }
}

// SwiftUI preview for View_About
struct View_About_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            View_About()
        }
    }
}
