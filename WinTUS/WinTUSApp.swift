import SwiftUI
import SwiftData

@main
struct WinTUSApp: App {
    // SwiftData container kurulumu
    // İleride buraya Subject, StudySession, StudyPlan modellerini ekleyeceğiz
    @StateObject private var timerManager = TimerManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subject.self,
            StudySession.self,
            StudyPlan.self,
            Flashcard.self,
            StudyNote.self,
            TrialExam.self,
            TrialExamResult.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .onAppear {
                    DataSeeder.shared.seedData(modelContext: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
