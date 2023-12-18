import SwiftUI
import AVFoundation
import CoreData
import UserNotifications

// Extension to define custom notification names for app-specific events.
extension Notification.Name {
    static let newVoiceNoteAdded = Notification.Name("newVoiceNoteAdded")
}

// Model for a voice note.
struct VoiceNote: Identifiable {
    var id = UUID()
    var audioURL: URL
    var isPlaying = false
}

// View for adding and managing voice notes.
struct View_AddVoiceNotes: View {
    @State private var audioRecorder: AVAudioRecorder!
    @State private var isRecording = false
    @State private var voiceNotes: [VoiceNote] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            voiceNotesList
            recordButton
        }
        .onAppear(perform: setupView)
        .alert(isPresented: $showAlert) {
            Alert(title: Text(NSLocalizedString("Error", comment: "")),
                  message: Text(alertMessage),
                  dismissButton: .default(Text(NSLocalizedString("Ok", comment: ""))))
        }
    }

    // List view for displaying voice notes.
    private var voiceNotesList: some View {
        List {
            ForEach(voiceNotes.indices, id: \.self) { index in
                HStack {
                    Text(String(format: NSLocalizedString("VoiceNoteText", comment: ""), index + 1))
                    Spacer()
                    Button(action: { togglePlayAudio(index) }) {
                        Image(systemName: voiceNotes[index].isPlaying ? "pause.circle" : "play.circle")
                    }
                }
            }
            .onDelete(perform: deleteVoiceNotes)
        }
    }

    // Record button to start or stop recording.
    private var recordButton: some View {
        Button(action: { isRecording ? stopRecording() : startRecording() }) {
            Text(isRecording ? NSLocalizedString("StopRecording", comment: "") : NSLocalizedString("StartRecording", comment: ""))
        }
        .padding()
        .background(isRecording ? Color.red : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        .animation(.easeInOut)
    }

    // Sets up the view components.
    private func setupView() {
        requestNotificationPermission()
        setupAudioRecorder()
        fetchVoiceNotesFromCoreData()
    }

    // Requests permission to send notifications.
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print(NSLocalizedString("PermissionGranted", comment: ""))
            } else {
                print(NSLocalizedString("PermissionDenied", comment: "") + " \(error?.localizedDescription ?? "")")
            }
        }
    }

    // Schedules a local notification for the newly recorded voice note.
    private func scheduleNotification(for voiceNote: VoiceNote) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("RecordingSaved", comment: "")
        content.body = NSLocalizedString("NewVoiceNoteReady", comment: "")
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: voiceNote.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // Starts recording a new voice note.
    func startRecording() {
        isRecording = true
        let audioFileName = getDocumentsDirectory().appendingPathComponent(UUID().uuidString + ".m4a")

        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: getAudioSettings())
            audioRecorder.record()
        } catch {
            alertMessage = NSLocalizedString("RecordingError", comment: "") + " \(error.localizedDescription)"
            showAlert = true
        }
    }

    // Stops the current recording and processes the recorded voice note.
    func stopRecording() {
        isRecording = false
        audioRecorder.stop()
        let newVoiceNote = VoiceNote(audioURL: audioRecorder.url)
        voiceNotes.append(newVoiceNote)
        saveToCoreData(audioURL: newVoiceNote.audioURL)
        scheduleNotification(for: newVoiceNote)
        NotificationCenter.default.post(name: .newVoiceNoteAdded, object: nil)
    }

    // Sets up the audio recorder with necessary settings.
    func setupAudioRecorder() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print(NSLocalizedString("AudioSessionError", comment: "") + " \(error.localizedDescription)")
        }
    }

    // Returns audio settings for the recorder.
    func getAudioSettings() -> [String: Any] {
        [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    // Gets the documents directory URL.
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // Saves the voice note URL to Core Data.
    func saveToCoreData(audioURL: URL) {
        let managedContext = CoreDataStack.shared.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "VoiceNoteEntity", in: managedContext)!
        let voiceNote = NSManagedObject(entity: entity, insertInto: managedContext) as! VoiceNoteEntity

        voiceNote.audioURL = audioURL.absoluteString

        do {
            try managedContext.save()
        } catch {
            print(NSLocalizedString("CoreDataSaveError", comment: "") + " \(error.localizedDescription)")
        }
    }

    // Fetches voice notes from Core Data.
    func fetchVoiceNotesFromCoreData() {
        let managedContext = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<VoiceNoteEntity>(entityName: "VoiceNoteEntity")

        do {
            let fetchedVoiceNotes = try managedContext.fetch(fetchRequest)
            voiceNotes = fetchedVoiceNotes.compactMap { voiceNoteEntity in
                if let urlString = voiceNoteEntity.audioURL, let url = URL(string: urlString) {
                    return VoiceNote(audioURL: url)
                } else {
                    return nil
                }
            }
        } catch {
            print(NSLocalizedString("CoreDataFetchError", comment: "") + " \(error.localizedDescription)")
        }
    }

    // Deletes a specific voice note.
    func deleteVoiceNote(_ note: VoiceNote) {
        if let index = voiceNotes.firstIndex(where: { $0.id == note.id }) {
            voiceNotes.remove(at: index)
            deleteVoiceNoteFromCoreData(note)
        }
    }

    // Deletes voice notes based on the provided index set.
    func deleteVoiceNotes(at indices: IndexSet) {
        indices.forEach { index in
            guard index < voiceNotes.count else { return }
            deleteVoiceNote(voiceNotes[index])
        }
    }

    // Deletes a voice note from Core Data.
    func deleteVoiceNoteFromCoreData(_ note: VoiceNote) {
        let managedContext = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<VoiceNoteEntity>(entityName: "VoiceNoteEntity")
        fetchRequest.predicate = NSPredicate(format: "audioURL == %@", note.audioURL.absoluteString)

        do {
            if let result = try managedContext.fetch(fetchRequest).first {
                managedContext.delete(result)
                try managedContext.save()
            }
        } catch {
            print(NSLocalizedString("CoreDataDeleteError", comment: "") + " \(error.localizedDescription)")
        }
    }

    // Plays the audio from the given URL.
    func playAudio(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print(NSLocalizedString("AudioPlayError", comment: "") + " \(error.localizedDescription)")
        }
    }

    // Toggles the playback state of the selected voice note.
    func togglePlayAudio(_ index: Int) {
        if voiceNotes[index].isPlaying {
            audioPlayer?.pause()
        } else {
            playAudio(url: voiceNotes[index].audioURL)
        }
        voiceNotes.indices.forEach { voiceNotes[$0].isPlaying = ($0 == index) && !voiceNotes[index].isPlaying }
    }
}

// Preview provider for SwiftUI previews.
struct View_AddVoiceNotes_Previews: PreviewProvider {
    static var previews: some View {
        View_AddVoiceNotes()
    }
}
