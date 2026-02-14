import SwiftData
import Foundation

@Model
class TrialExam {
    var id: UUID
    var date: Date
    var name: String
    
    // Genel Sonuçlar
    var totalBasicCorrect: Int
    var totalBasicIncorrect: Int
    var totalBasicNet: Double
    
    var totalClinicalCorrect: Int
    var totalClinicalIncorrect: Int
    var totalClinicalNet: Double
    
    var calculatedScore: Double
    
    // İlişkili Ders Sonuçları
    @Relationship(deleteRule: .cascade) var results: [TrialExamResult] = []
    
    init(date: Date = Date(), name: String, results: [TrialExamResult] = []) {
        self.id = UUID()
        self.date = date
        self.name = name
        self.results = results
        
        // Başlangıçta 0 hesapla, sonra update edilecek
        self.totalBasicCorrect = 0
        self.totalBasicIncorrect = 0
        self.totalBasicNet = 0.0
        self.totalClinicalCorrect = 0
        self.totalClinicalIncorrect = 0
        self.totalClinicalNet = 0.0
        self.calculatedScore = 0.0
    }
    
    func calculateTotals() {
        // Temel Bilimler (Anatomi, Fizyoloji, Biyokimya, Mikrobiyoloji, Patoloji, Farmakoloji)
        let basics = results.filter { $0.isBasicScience }
        totalBasicCorrect = basics.reduce(0) { $0 + $1.correctCount }
        totalBasicIncorrect = basics.reduce(0) { $0 + $1.incorrectCount }
        totalBasicNet = Double(totalBasicCorrect) - (Double(totalBasicIncorrect) / 4.0)
        
        // Klinik Bilimler (Dahiliye, Pediatri, Cerrahi, Kadın Doğum, Küçük Stajlar)
        let clinicals = results.filter { !$0.isBasicScience }
        totalClinicalCorrect = clinicals.reduce(0) { $0 + $1.correctCount }
        totalClinicalIncorrect = clinicals.reduce(0) { $0 + $1.incorrectCount }
        totalClinicalNet = Double(totalClinicalCorrect) - (Double(totalClinicalIncorrect) / 4.0)
        
        // Puan Hesapla
        self.calculatedScore = TUSScoreCalculator.calculate(basicNet: totalBasicNet, clinicalNet: totalClinicalNet)
    }
}

@Model
class TrialExamResult {
    var id: UUID
    var lessonName: String
    var isBasicScience: Bool // True: Temel, False: Klinik
    var correctCount: Int
    var incorrectCount: Int
    
    var net: Double {
        return Double(correctCount) - (Double(incorrectCount) / 4.0)
    }
    
    init(lessonName: String, isBasicScience: Bool, correctCount: Int = 0, incorrectCount: Int = 0) {
        self.id = UUID()
        self.lessonName = lessonName
        self.isBasicScience = isBasicScience
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
    }
}

// MARK: - Score Calculator Helper
class TUSScoreCalculator {
    static func calculate(basicNet: Double, clinicalNet: Double) -> Double {
        // 2024-2025 Yaklaşık Katsayılar
        let baseScore = 45.0
        let basicCoeff = 0.5 // Temel Katsayısı
        let clinicalCoeff = 0.5 // Klinik Katsayısı
        
        let score = baseScore + (basicNet * basicCoeff) + (clinicalNet * clinicalCoeff)
        return min(max(score, 0), 85)
    }
}
