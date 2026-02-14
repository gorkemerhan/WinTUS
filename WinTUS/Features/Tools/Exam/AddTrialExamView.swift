import SwiftUI
import SwiftData

// Alt Bileşen: Ders Satırı (Dosya başına taşındı)
struct LessonInputRow: View {
    @Binding var input: LessonInput
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(input.lessonName)
                .font(.headline)
            
            HStack {
                VStack {
                    Text("Doğru")
                        .font(.caption)
                    Stepper("\(input.correct)", value: $input.correct, in: 0...100)
                }
                Divider()
                VStack {
                    Text("Yanlış")
                        .font(.caption)
                    Stepper("\(input.incorrect)", value: $input.incorrect, in: 0...100)
                }
            }
            
            Text("Net: \(String(format: "%.2f", input.net))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }
}

// Form için Geçici Veri Yapısı (Model yerine bunu kullanacağız)
struct LessonInput: Identifiable, Hashable {
    let id = UUID()
    var lessonName: String
    var isBasic: Bool
    var correct: Int = 0
    var incorrect: Int = 0
    
    var net: Double {
        return Double(correct) - (Double(incorrect) / 4.0)
    }
}

struct AddTrialExamView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var examName = ""
    @State private var examDate = Date()
    @State private var showDatePicker = false
    
    @State private var entryMode: EntryMode = .quick
    @State private var selectedTab = 0 
    
    enum EntryMode: String, CaseIterable {
        case quick = "Hızlı Giriş (Toplam)"
        case detailed = "Detaylı (Ders Ders)"
    }
    
    // Hızlı Giriş Değişkenleri
    @State private var basicTotalCorrect = 0
    @State private var basicTotalIncorrect = 0
    @State private var clinicalTotalCorrect = 0
    @State private var clinicalTotalIncorrect = 0
    
    // Detaylı Bilimler (Struct Array)
    @State private var basicInputs: [LessonInput] = [
        LessonInput(lessonName: "Anatomi", isBasic: true),
        LessonInput(lessonName: "Fizyoloji-Histoloji-Embriyoloji", isBasic: true),
        LessonInput(lessonName: "Biyokimya", isBasic: true),
        LessonInput(lessonName: "Mikrobiyoloji", isBasic: true),
        LessonInput(lessonName: "Patoloji", isBasic: true),
        LessonInput(lessonName: "Farmakoloji", isBasic: true)
    ]
    
    @State private var clinicalInputs: [LessonInput] = [
        LessonInput(lessonName: "Dahiliye", isBasic: false),
        LessonInput(lessonName: "Pediatri", isBasic: false),
        LessonInput(lessonName: "Genel Cerrahi", isBasic: false),
        LessonInput(lessonName: "Kadın Doğum", isBasic: false),
        LessonInput(lessonName: "Küçük Stajlar", isBasic: false)
    ]
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Genel Bilgiler") {
                    TextField("Deneme Adı (Örn: TUSEM 1)", text: $examName)
                    
                    HStack {
                        Text("Tarih")
                        Spacer()
                        Button {
                            showDatePicker = true
                        } label: {
                            Text(examDate.formatted(date: .long, time: .omitted))
                                .foregroundStyle(Color.blue)
                        }
                    }
                    
                    Picker("Giriş Yöntemi", selection: $entryMode) {
                        ForEach(EntryMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if entryMode == .quick {
                    // HIZLI GİRİŞ MODU
                    Section("Temel Bilimler (Max 100 Soru)") {
                        Stepper("Doğru: \(basicTotalCorrect)", value: $basicTotalCorrect, in: 0...100)
                        Stepper("Yanlış: \(basicTotalIncorrect)", value: $basicTotalIncorrect, in: 0...100)
                        
                        // Validation Info
                        if (basicTotalCorrect + basicTotalIncorrect) > 100 {
                            Text("Toplam soru sayısı 100'ü geçmemeli!")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        
                        Text("Net: \(String(format: "%.2f", calculateQuickNet(correct: basicTotalCorrect, incorrect: basicTotalIncorrect)))")
                            .foregroundStyle(.secondary)
                    }
                    
                    Section("Klinik Bilimler (Max 100 Soru)") {
                        Stepper("Doğru: \(clinicalTotalCorrect)", value: $clinicalTotalCorrect, in: 0...100)
                        Stepper("Yanlış: \(clinicalTotalIncorrect)", value: $clinicalTotalIncorrect, in: 0...100)
                        
                        if (clinicalTotalCorrect + clinicalTotalIncorrect) > 100 {
                            Text("Toplam soru sayısı 100'ü geçmemeli!")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        
                        Text("Net: \(String(format: "%.2f", calculateQuickNet(correct: clinicalTotalCorrect, incorrect: clinicalTotalIncorrect)))")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // DETAYLI GİRİŞ MODU
                    Section {
                        Picker("Bölüm", selection: $selectedTab) {
                            Text("Temel Bilimler").tag(0)
                            Text("Klinik Bilimler").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    if selectedTab == 0 {
                        ForEach($basicInputs) { $input in
                            LessonInputRow(input: $input)
                        }
                    } else {
                        ForEach($clinicalInputs) { $input in
                            LessonInputRow(input: $input)
                        }
                    }
                }
                
                Section("Özet & Tahmin") {
                    HStack {
                        Text("Toplam Net:")
                        Spacer()
                        Text(String(format: "%.2f", calculateTotalNet()))
                            .bold()
                    }
                    HStack {
                        Text("Tahmini Puan:")
                        Spacer()
                        Text(String(format: "%.2f", calculateScore()))
                            .bold()
                            .foregroundStyle(.blue)
                    }
                    Text("*Puanlar yaklaşık değerlerdir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Deneme Ekle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        if validate() {
                            saveExam()
                        }
                    }
                    .disabled(examName.isEmpty)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    DatePicker("Tarih Seçiniz", selection: $examDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: examDate) { _ in
                             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                 showDatePicker = false
                             }
                        }
                        .padding()
                    
                    Button("Tamam") {
                        showDatePicker = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .presentationDetents([.medium, .height(400)])
            }
            .alert("Hata", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Logic
    
    func validate() -> Bool {
        if entryMode == .quick {
            if (basicTotalCorrect + basicTotalIncorrect) > 100 {
                alertMessage = "Temel Bilimler toplam soru sayısı 100'ü geçemez."
                showAlert = true
                return false
            }
            if (clinicalTotalCorrect + clinicalTotalIncorrect) > 100 {
                alertMessage = "Klinik Bilimler toplam soru sayısı 100'ü geçemez."
                showAlert = true
                return false
            }
        }
        return true
    }
    
    func calculateQuickNet(correct: Int, incorrect: Int) -> Double {
        return Double(correct) - (Double(incorrect) / 4.0)
    }
    
    func calculateTotalNet() -> Double {
        if entryMode == .quick {
            return calculateQuickNet(correct: basicTotalCorrect, incorrect: basicTotalIncorrect) +
                   calculateQuickNet(correct: clinicalTotalCorrect, incorrect: clinicalTotalIncorrect)
        } else {
            let basic = basicInputs.reduce(0.0) { $0 + $1.net }
            let clinical = clinicalInputs.reduce(0.0) { $0 + $1.net }
            return basic + clinical
        }
    }
    
    func calculateScore() -> Double {
        var basicNet = 0.0
        var clinicalNet = 0.0
        
        if entryMode == .quick {
            basicNet = calculateQuickNet(correct: basicTotalCorrect, incorrect: basicTotalIncorrect)
            clinicalNet = calculateQuickNet(correct: clinicalTotalCorrect, incorrect: clinicalTotalIncorrect)
        } else {
            basicNet = basicInputs.reduce(0.0) { $0 + $1.net }
            clinicalNet = clinicalInputs.reduce(0.0) { $0 + $1.net }
        }
        
        return TUSScoreCalculator.calculate(basicNet: basicNet, clinicalNet: clinicalNet)
    }
    
    func saveExam() {
        print("Saving exam...")
        
        // 1. Exam Nesnesini Oluştur ve Ekle
        let exam = TrialExam(date: examDate, name: examName)
        modelContext.insert(exam)
        
        // 2. Result Nesnelerini Oluştur
        var finalResults: [TrialExamResult] = []
        
        if entryMode == .quick {
            finalResults.append(TrialExamResult(lessonName: "Temel (Genel)", isBasicScience: true, correctCount: basicTotalCorrect, incorrectCount: basicTotalIncorrect))
            finalResults.append(TrialExamResult(lessonName: "Klinik (Genel)", isBasicScience: false, correctCount: clinicalTotalCorrect, incorrectCount: clinicalTotalIncorrect))
        } else {
            for input in basicInputs {
                finalResults.append(TrialExamResult(lessonName: input.lessonName, isBasicScience: true, correctCount: input.correct, incorrectCount: input.incorrect))
            }
            for input in clinicalInputs {
                finalResults.append(TrialExamResult(lessonName: input.lessonName, isBasicScience: false, correctCount: input.correct, incorrectCount: input.incorrect))
            }
        }
        
        // 3. İlişkiyi Kur (SwiftData bunu otomatik context'e ekleyecektir)
        exam.results = finalResults
        
        // 4. Hesapla
        exam.calculateTotals()
        
        // 5. Explicit Save (Bazen autosave gecikebilir)
        do {
            try modelContext.save()
            print("Exam saved successfully!")
            dismiss()
        } catch {
            print("Failed to save exam: \(error)")
            alertMessage = "Kaydedilirken hata oluştu: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
