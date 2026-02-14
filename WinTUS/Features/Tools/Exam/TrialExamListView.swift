import SwiftUI
import SwiftData
import Charts

struct TrialExamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrialExam.date, order: .reverse) private var exams: [TrialExam]
    
    @State private var showingAddExam = false
    
    var body: some View {
        List {
            if !exams.isEmpty {
                Section {
                    // Grafik Alanı
                    VStack(alignment: .leading) {
                        Text("Net Gelişimi")
                            .font(.headline)
                        
                        Chart {
                            ForEach(exams.sorted(by: { $0.date < $1.date })) { exam in
                                LineMark(
                                    x: .value("Tarih", exam.date, unit: .day),
                                    y: .value("Net", exam.totalBasicNet + exam.totalClinicalNet)
                                )
                                .foregroundStyle(Color.green)
                                .symbol(by: .value("Net", "Net"))
                                
                                PointMark(
                                    x: .value("Tarih", exam.date, unit: .day),
                                    y: .value("Net", exam.totalBasicNet + exam.totalClinicalNet)
                                )
                                .annotation(position: .top) {
                                    Text(String(format: "%.1f", exam.totalBasicNet + exam.totalClinicalNet))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel(format: .dateTime.day().month())
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                } header: {
                    Text("Performans (Toplam Net)")
                }
            }
            
            Section {
                if exams.isEmpty {
                    ContentUnavailableView("Deneme Yok", systemImage: "list.clipboard", description: Text("İlk deneme sonucunuzu ekleyerek başlayın."))
                } else {
                    ForEach(exams) { exam in
                        NavigationLink(destination: TrialExamDetailView(exam: exam)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exam.name)
                                        .font(.headline)
                                    Text(exam.date.formatted(date: .numeric, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(String(format: "%.2f Net", exam.totalBasicNet + exam.totalClinicalNet))
                                        .font(.system(.body, design: .rounded))
                                        .bold()
                                        .foregroundStyle(.green)
                                    
                                    Text("Puan: \(String(format: "%.2f", exam.calculatedScore))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .contextMenu {
                            Button("Sil", systemImage: "trash", role: .destructive) {
                                modelContext.delete(exam)
                            }
                        }
                    }
                    .onDelete(perform: deleteExam)
                }
            } header: {
                Text("Geçmiş Denemeler")
            }
        }
        .navigationTitle("Deneme Takibi")
        .toolbar {
            Button("Ekle", systemImage: "plus") {
                showingAddExam = true
            }
        }
        .sheet(isPresented: $showingAddExam) {
            AddTrialExamView()
        }
    }
    
    func deleteExam(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(exams[index])
        }
    }
}

// Basit Detay Görünümü
struct TrialExamDetailView: View {
    let exam: TrialExam
    
    var body: some View {
        List {
            Section("Özet") {
                HStack {
                    Text("TUS Puanı")
                    Spacer()
                    Text(String(format: "%.2f", exam.calculatedScore))
                        .bold()
                        .foregroundStyle(.blue)
                }
                HStack {
                    Text("Temel Net")
                    Spacer()
                    Text(String(format: "%.2f", exam.totalBasicNet))
                }
                HStack {
                    Text("Klinik Net")
                    Spacer()
                    Text(String(format: "%.2f", exam.totalClinicalNet))
                }
            }
            
            Section("Temel Bilimler") {
                ForEach(exam.results.filter { $0.isBasicScience }) { res in
                    HStack {
                        Text(res.lessonName)
                        Spacer()
                        Text("\(res.correctCount)D / \(res.incorrectCount)Y")
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f Net", res.net))
                            .bold()
                    }
                }
            }
            
            Section("Klinik Bilimler") {
                ForEach(exam.results.filter { !$0.isBasicScience }) { res in
                    HStack {
                        Text(res.lessonName)
                        Spacer()
                        Text("\(res.correctCount)D / \(res.incorrectCount)Y")
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f Net", res.net))
                            .bold()
                    }
                }
            }
        }
        .navigationTitle(exam.name)
    }
}
