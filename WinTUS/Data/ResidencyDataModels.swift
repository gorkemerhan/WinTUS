import Foundation
import SwiftData

// Not: Bu model SwiftData değil, standart Struct yapısında olacak. 
// Çünkü bu veriler statik referans verisidir, kullanıcı değiştirmez.
struct ResidencyProgram: Identifiable, Codable, Hashable {
    var id = UUID()
    let university: String // Örn: İstanbul Cerrahpaşa Üniversitesi
    let hospital: String   // Örn: Cerrahpaşa Tıp Fakültesi
    let department: String // Örn: Deri ve Zührevi Hastalıklar
    let city: String       // Örn: İstanbul
    let type: String       // Örn: Üniversite, EAH, Şehir Hastanesi
    let quota: Int         // Örn: 5
    let minScore: Double   // Örn: 72.4
    let scoreType: String  // Örn: K, T (Klinik/Temel)
    let period: String     // Örn: 2024/2, 2024/1
    
    // UI uyumluluğu için
    var institution: String { university }
    
    // UI için yardımcı computed property
    var displayName: String {
        "\(department) - \(hospital)"
    }
}

class ResidencyDataManager {
    static let shared = ResidencyDataManager()
    
    // Mock Data Listesi
    var programs: [ResidencyProgram] = []
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        // Otomatik oluşturulan gerçek verileri (CSV'den gelen) yüklüyoruz
        programs = ResidencyDataManager.generatedPrograms
    }
    
    // CSV Yükleme Fonksiyonu (Gelecekte Kullanılacak)
    func loadFromCSV(csvContent: String) {
        // Şimdilik pasif, çünkü verileri build-time'da ürettik.
    }
}
