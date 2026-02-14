import Foundation

/// TUS Puan Hesaplayıcı - Farklı sınav dönemleri için tahmini puan hesaplar
class TUSMultiPeriodCalculator {
    static let shared = TUSMultiPeriodCalculator()
    
    private var statistics: TUSStatistics?
    
    private init() {
        loadStatistics()
    }
    
    // MARK: - Data Loading
    
    private func loadStatistics() {
        guard let url = Bundle.main.url(forResource: "tus_statistics", withExtension: "json") else {
            print("TUS istatistik dosyası bulunamadı")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            statistics = try decoder.decode(TUSStatistics.self, from: data)
            print("TUS istatistikleri yüklendi: \(statistics?.examPeriods.count ?? 0) dönem")
        } catch {
            print("TUS istatistik yükleme hatası: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Tüm sınav dönemlerini döndür
    var availablePeriods: [ExamPeriod] {
        return statistics?.examPeriods ?? []
    }
    
    /// Belirli bir dönem için puan hesapla
    func calculateScore(
        temelDogru: Int,
        temelYanlis: Int,
        klinikDogru: Int,
        klinikYanlis: Int,
        periodId: String
    ) -> TUSScoreResult? {
        guard let period = statistics?.examPeriods.first(where: { $0.id == periodId }) else {
            return nil
        }
        
        // Net hesapla
        let temelNet = Double(temelDogru) - (Double(temelYanlis) / 4.0)
        let klinikNet = Double(klinikDogru) - (Double(klinikYanlis) / 4.0)
        
        // Z-score hesapla
        let temelZ = (temelNet - period.temel.ortalama) / period.temel.standartSapma
        let klinikZ = (klinikNet - period.klinik.ortalama) / period.klinik.standartSapma
        
        // Standart puan hesapla (ortalama 50, std 10)
        let temelSP = 50.0 + (10.0 * temelZ)
        let klinikSP = 50.0 + (10.0 * klinikZ)
        
        // T ve K puanı hesapla
        let tPuani = (temelSP * 0.7) + (klinikSP * 0.3)
        let kPuani = (temelSP * 0.3) + (klinikSP * 0.7)
        
        return TUSScoreResult(
            periodId: periodId,
            periodName: period.name,
            temelNet: temelNet,
            klinikNet: klinikNet,
            temelStandartPuan: temelSP,
            klinikStandartPuan: klinikSP,
            tPuani: tPuani,
            kPuani: kPuani
        )
    }
    
    /// Tüm dönemler için puan hesapla
    func calculateScoreForAllPeriods(
        temelDogru: Int,
        temelYanlis: Int,
        klinikDogru: Int,
        klinikYanlis: Int
    ) -> [TUSScoreResult] {
        guard let periods = statistics?.examPeriods else { return [] }
        
        return periods.compactMap { period in
            calculateScore(
                temelDogru: temelDogru,
                temelYanlis: temelYanlis,
                klinikDogru: klinikDogru,
                klinikYanlis: klinikYanlis,
                periodId: period.id
            )
        }
    }
}

// MARK: - Models

struct TUSStatistics: Codable {
    let description: String
    let formula: ScoreFormula
    let examPeriods: [ExamPeriod]
    let lastUpdated: String
    let source: String
}

struct ScoreFormula: Codable {
    let net: String
    let z_score: String
    let standart_puan: String
    let t_puani: String
    let k_puani: String
}

struct ExamPeriod: Codable, Identifiable {
    let id: String
    let name: String
    let year: Int
    let period: Int
    let examDate: String
    let temel: TestStatistics
    let klinik: TestStatistics
}

struct TestStatistics: Codable {
    let ortalama: Double
    let standartSapma: Double
}

struct TUSScoreResult: Identifiable {
    let id = UUID()
    let periodId: String
    let periodName: String
    let temelNet: Double
    let klinikNet: Double
    let temelStandartPuan: Double
    let klinikStandartPuan: Double
    let tPuani: Double
    let kPuani: Double
    
    var formattedTPuani: String {
        String(format: "%.2f", tPuani)
    }
    
    var formattedKPuani: String {
        String(format: "%.2f", kPuani)
    }
    
    var isEligibleForPlacement: Bool {
        tPuani >= 45 && kPuani >= 45
    }
}
