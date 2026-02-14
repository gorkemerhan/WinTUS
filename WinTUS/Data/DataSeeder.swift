import SwiftData
import SwiftUI

class DataSeeder {
    static let shared = DataSeeder()
    
    // TUS Ders Listesi (Temel ve Klinik)
    private let defaultSubjects: [(name: String, color: String)] = [
        // Temel Bilimler
        ("Anatomi", "#E74C3C"), // Kırmızı
        ("Fizyoloji", "#E67E22"), // Turuncu
        ("Biyokimya", "#F1C40F"), // Sarı
        ("Mikrobiyoloji", "#2ECC71"), // Yeşil
        ("Patoloji", "#9B59B6"), // Mor
        ("Farmakoloji", "#3498DB"), // Mavi
        
        // Klinik Bilimler
        ("Dahiliye", "#34495E"), // Lacivert
        ("Pediatri", "#1ABC9C"), // Turkuaz
        ("Genel Cerrahi", "#E91E63"), // Pembe
        ("Kadın Doğum", "#D35400"), // Koyu Turuncu
        ("Küçük Stajlar", "#7F8C8D"), // Gri
        
        // Ekstra Seçenekler
        ("Deneme Çözümü", "#000000"), // Siyah (veya çok koyu gri)
        ("Genel Tekrar", "#FFFFFF")   // Beyaz (Dark mode için özel ayar gerekebilir, kodda handle edeceğiz)
    ]
    
    @MainActor
    func seedData(modelContext: ModelContext) {
        // Kontrol et: Veri var mı?
        let descriptor = FetchDescriptor<Subject>()
        do {
            let existingSubjects = try modelContext.fetch(descriptor)
            if existingSubjects.isEmpty {
                print("Veritabanı boş, varsayılan dersler yükleniyor...")
                
                for subjectData in defaultSubjects {
                    let subject = Subject(name: subjectData.name, colorHex: subjectData.color)
                    modelContext.insert(subject)
                }
                
                try modelContext.save()
                print("Dersler yüklendi!")
            }
        } catch {
            print("Veri kontrolü yapılamadı: \(error)")
        }
    }
}
