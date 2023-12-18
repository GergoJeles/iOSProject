import SwiftUI
import CoreData
import UserNotifications

// View for adding and managing reminders
struct View_AddReminder: View {
    @State private var reminderTitle = ""
    @State private var reminderDescription = ""
    @State private var reminderDate = Date()
    @State private var reminders: [Reminder] = []
    @State private var showAlert = false // State for showing the alert

    // Core Data context for persistence
    let context = CoreDataStack.shared.persistentContainer.viewContext

    var body: some View {
        NavigationView {
            VStack {
                reminderForm
                remindersList
            }
            .navigationBarTitle(NSLocalizedString("AddReminder", comment: ""), displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(NSLocalizedString("ReminderAdded", comment: "")),
                    message: Text(NSLocalizedString("ReminderAddedMessage", comment: "")),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // Form for entering reminder details
    private var reminderForm: some View {
        Form {
            Section(header: Text(NSLocalizedString("ReminderDetails", comment: ""))) {
                TextField(NSLocalizedString("Title", comment: ""), text: $reminderTitle)
                TextField(NSLocalizedString("Description", comment: ""), text: $reminderDescription)
                DatePicker(NSLocalizedString("DateAndTime", comment: ""), selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
            }

            Section {
                Button(action: addReminder) {
                    Text(NSLocalizedString("AddReminder", comment: ""))
                }
            }
        }
        .padding()
    }

    // List view displaying existing reminders
    private var remindersList: some View {
        List {
            Section(header: Text(NSLocalizedString("ReminderList", comment: ""))) {
                ForEach(fetchReminders(), id: \.self) { reminder in
                    NavigationLink(destination: ReminderDetailModal(reminder: reminder)) {
                        HStack {
                            Text(reminder.title ?? "")
                            Spacer()
                            if let date = reminder.date {
                                Text(formatDate(date))
                            }
                        }
                    }
                }
                .onDelete(perform: deleteReminders)
            }
        }
        .listStyle(GroupedListStyle())
        .padding()
    }

    // Adds a new reminder to Core Data and schedules a notification
    private func addReminder() {
        let newReminder = Reminder(context: context)
        newReminder.title = reminderTitle
        newReminder.reminderDescription = reminderDescription
        newReminder.date = reminderDate

        do {
            try context.save()
            scheduleLocalNotification(for: newReminder)
            clearFormFields()
            reminders.append(newReminder)
            showAlert = true
        } catch {
            print("Error saving reminder: \(error.localizedDescription)")
        }
    }

    // Fetches reminders from Core Data
    private func fetchReminders() -> [Reminder] {
        do {
            return try context.fetch(Reminder.fetchRequest())
        } catch {
            print("Error fetching reminders: \(error.localizedDescription)")
            return []
        }
    }

    // Deletes reminders from Core Data
    private func deleteReminders(at indices: IndexSet) {
        indices.forEach { index in
            guard index < reminders.count else { return }
            let reminder = reminders[index]
            context.delete(reminder)
        }

        do {
            try context.save()
            reminders.remove(atOffsets: indices)
        } catch {
            print("Error deleting reminders: \(error.localizedDescription)")
        }
    }

    // Formats the date to a readable string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    // Schedules a local notification for the reminder
    private func scheduleLocalNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title ?? ""
        content.body = reminder.reminderDescription ?? ""
        content.sound = UNNotificationSound.default

        if let reminderDate = reminder.date {
            let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: reminderDate)
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate ?? Date())
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }

    // Clears the input fields after adding a reminder
    private func clearFormFields() {
        reminderTitle = ""
        reminderDescription = ""
        reminderDate = Date()
    }
}

// View for displaying the details of a reminder
struct ReminderDetailModal: View {
    var reminder: Reminder

    var body: some View {
        VStack {
            Text(reminder.title ?? "")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Text(reminder.reminderDescription ?? "")
                .padding()

            if let date = reminder.date {
                Text(formatDate(date))
                    .foregroundColor(.gray)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .navigationBarTitle(Text(NSLocalizedString("addReminder", comment: "")), displayMode: .inline)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct View_AddReminder_Previews: PreviewProvider {
    static var previews: some View {
        View_AddReminder()
    }
}
