import SwiftUI
import SwiftData

struct AddPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Subject.name) private var subjects: [Subject]
    
    var targetDate: Date
    @State private var selectedSubject: Subject?
    @State private var durationMinutes: Double = 60 // Varsayılan 1 saat
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tarih") {
                    Text(targetDate.formatted(date: .long, time: .omitted))
                        .foregroundStyle(.secondary)
                }
                
                Section("Ders Seçimi") {
                    Picker("Ders", selection: $selectedSubject) {
                        Text("Ders Seçiniz").tag(nil as Subject?)
                        ForEach(subjects.sorted(by: { $0.name < $1.name })) { subject in
                            Text(subject.name).tag(subject as Subject?)
                        }
                    }
                }
                
                Section("Hedef Süre") {
                    HStack {
                        Text("\(Int(durationMinutes)) dakika")
                        Slider(value: $durationMinutes, in: 15...300, step: 15)
                    }
                }
            }
            .navigationTitle("Çalışma Planla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Planla") {
                        savePlan()
                    }
                    .disabled(selectedSubject == nil)
                }
            }
        }
    }
    
    private func savePlan() {
        guard let subject = selectedSubject else { return }
        
        // Duration saniye cinsinden
        let durationSeconds = durationMinutes * 60
        
        let newPlan = StudyPlan(targetDate: targetDate, targetDuration: durationSeconds, subject: subject)
        modelContext.insert(newPlan)
        dismiss()
    }
}
