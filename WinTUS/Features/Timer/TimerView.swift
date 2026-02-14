import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var timerManager: TimerManager
    
    @Query private var subjects: [Subject]
    @Query private var plans: [StudyPlan]
    @Query private var sessions: [StudySession]
    
    @State private var showingAddSubject = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                // Ders Seçim Alanı
                HStack {
                    Menu {
                        ForEach(subjects.sorted(by: { s1, s2 in
                            let specialSubjects = ["Deneme Çözümü", "Genel Tekrar"]
                            let s1IsSpecial = specialSubjects.contains(s1.name)
                            let s2IsSpecial = specialSubjects.contains(s2.name)

                            if s1IsSpecial == s2IsSpecial {
                                return s1.name.localizedStandardCompare(s2.name) == .orderedAscending
                            }
                            return !s1IsSpecial && s2IsSpecial
                        })) { subject in
                            Button {
                                timerManager.selectedSubject = subject
                            } label: {
                                Label(subject.name, systemImage: "book.fill")
                            }
                        }
                    } label: {
                        HStack {
                            if let selected = timerManager.selectedSubject {
                                Text(selected.name)
                                    .font(.headline)
                                    .foregroundStyle(Color(hex: selected.colorHex))
                            } else {
                                Text("Ders Seçiniz")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.top)
                
                // Tekrar/Deneme Sayacı
                if let subject = timerManager.selectedSubject {
                    HStack(spacing: 16) {
                        Button(action: {
                            if subject.repetitionCount > 1 {
                                subject.repetitionCount -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Text("\(subject.repetitionCount). \(subject.name == "Deneme Çözümü" ? "Deneme" : "Tekrar")")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                        
                        Button(action: {
                            subject.repetitionCount += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, -10)
                }
                
                // Sayaç Dairesi
                Circle()
                
                    .stroke(lineWidth: 20)
                    .foregroundStyle(timerManager.selectedSubject != nil ? Color(hex: timerManager.selectedSubject!.colorHex) : .gray.opacity(0.3))
                    .overlay {
                        VStack {
                            Text(timerManager.formattedTime)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                            
                            if timerManager.timerPaused {
                                Text("DURAKLATILDI")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .bold()
                            }
                        }
                    }
                    .frame(height: 250)
                    .padding()
                
                // Kontrol Butonları
                HStack(spacing: 20) {
                    if !timerManager.timerActive {
                        // Başlat Butonu
                        Button {
                            timerManager.startTimer()
                        } label: {
                            Text("Başlat")
                                .font(.title2)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(timerManager.selectedSubject == nil ? .gray : .green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(timerManager.selectedSubject == nil)
                    } else {
                        // Duraklat / Devam Et
                        Button {
                            if timerManager.timerPaused {
                                timerManager.resumeTimer()
                            } else {
                                timerManager.pauseTimer()
                            }
                        } label: {
                            Text(timerManager.timerPaused ? "Devam Et" : "Durdur")
                                .font(.title3)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Bitir (Kaydet)
                        Button {
                            timerManager.finishSession(modelContext: modelContext)
                        } label: {
                            Text("Bitir")
                                .font(.title3)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Kronometre")
            .sheet(isPresented: $showingAddSubject) {
                AddSubjectView()
                    .presentationDetents([.medium])
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
            .onChange(of: timerManager.elapsedSeconds) { _, _ in
                if let subject = timerManager.selectedSubject {
                    checkGoal(subject: subject)
                }
            }
        }
    }
    
    func checkGoal(subject: Subject) {
        // Eğer zaten bildirim gönderildiyse tekrar gönderme
        guard !timerManager.goalAchieved else { return }
        
        let calendar = Calendar.current
        
        // 1. Bu ders için BUGÜN bir plan var mı?
        let todayPlans = plans.filter {
            calendar.isDateInToday($0.targetDate) && $0.subject?.id == subject.id
        }
        
        guard let plan = todayPlans.first else { return }
        let targetDuration = plan.targetDuration
        
        // 2. Bugün bu derse ne kadar çalışılmış? (Önceki oturumlar + şu anki sayaç)
        let todaySessions = sessions.filter {
            calendar.isDateInToday($0.startTime) && $0.subject?.id == subject.id
        }
        let previousDuration = todaySessions.reduce(0) { $0 + $1.duration }
        let totalDuration = previousDuration + Double(timerManager.elapsedSeconds)
        
        // 3. Hedefe ulaşıldı mı?
        if totalDuration >= targetDuration {
            timerManager.goalAchieved = true
            NotificationManager.shared.sendGoalAchievedNotification(subjectName: subject.name)
        }
    }
}
