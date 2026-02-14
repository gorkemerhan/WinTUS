import SwiftUI
import SwiftData

struct AddManualSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var subjects: [Subject]
    
    var targetDate: Date
    
    @State private var selectedSubject: Subject?
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    
    var body: some View {
        NavigationStack {
            Form {
                // Ders Seçimi
                Section("Ders Seçimi") {
                    if subjects.isEmpty {
                        Text("Önce ders eklemeniz gerekiyor")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Ders", selection: $selectedSubject) {
                            Text("Seçiniz").tag(nil as Subject?)
                            ForEach(subjects.sorted(by: { $0.name < $1.name })) { subject in
                                HStack {
                                    Circle()
                                        .fill(Color(hex: subject.colorHex))
                                        .frame(width: 10, height: 10)
                                    Text(subject.name)
                                }
                                .tag(subject as Subject?)
                            }
                        }
                    }
                }
                
                // Süre Seçimi
                Section("Çalışma Süresi") {
                    HStack {
                        Picker("Saat", selection: $hours) {
                            ForEach(0..<13) { h in
                                Text("\(h) saat").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 120)
                        
                        Picker("Dakika", selection: $minutes) {
                            ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in
                                Text("\(m) dk").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 120)
                    }
                    .frame(height: 150)
                }
                
                // Özet
                Section {
                    HStack {
                        Text("Tarih")
                        Spacer()
                        Text(targetDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Toplam Süre")
                        Spacer()
                        Text(totalDurationString)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Manuel Çalışma Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveSession()
                    }
                    .disabled(selectedSubject == nil || totalDuration == 0)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    var totalDuration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60)
    }
    
    var totalDurationString: String {
        if hours > 0 {
            return "\(hours)sa \(minutes)dk"
        } else {
            return "\(minutes)dk"
        }
    }
    
    func saveSession() {
        guard let subject = selectedSubject, totalDuration > 0 else { return }
        
        // Session başlangıç zamanını hedef tarihin öğleden sonrasına ayarla
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        components.hour = 14 // 14:00 olarak varsayılan
        components.minute = 0
        let startTime = calendar.date(from: components) ?? targetDate
        
        let session = StudySession(startTime: startTime, subject: subject)
        session.duration = totalDuration
        
        modelContext.insert(session)
        dismiss()
    }
}

#Preview {
    AddManualSessionView(targetDate: Date())
}
