import SwiftUI
import SwiftData
import Charts

struct StudyDetailsView: View {
    @Query private var sessions: [StudySession]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Arka Plan
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.isDarkMode ? Color(hex: "#1A1A1A") : Color(hex: "#F0F4F8"),
                    themeManager.isDarkMode ? Color.black : Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Toplam Özet
                    VStack(spacing: 8) {
                        Text(totalDurationString)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("Toplam Çalışma Süresi")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Pasta Grafik
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ders Dağılımı")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        if sessions.isEmpty {
                            ContentUnavailableView("Veri Yok", systemImage: "chart.pie", description: Text("Henüz çalışma kaydı bulunmuyor."))
                                .frame(height: 300)
                        } else {
                            Chart(subjectDurations, id: \.name) { item in
                                SectorMark(
                                    angle: .value("Süre", item.duration),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .cornerRadius(5)
                                .foregroundStyle(Color(hex: item.colorHex))
                            }
                            .frame(height: 280)
                            .padding()
                            
                            // Detaylı Liste
                            VStack(spacing: 12) {
                                ForEach(subjectDurations, id: \.name) { item in
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: item.colorHex))
                                            .frame(width: 12, height: 12)
                                        
                                        Text(item.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(formatDurationShort(item.duration))
                                                .font(.subheadline)
                                                .bold()
                                            Text("\(Int((item.duration / totalDuration) * 100))%")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Material.thin)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Material.regular)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    

                    
                    // Alt Boşluk
                    Color.clear.frame(height: 80)
                }
            }
        }
        .navigationTitle("Çalışma Detayları")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helpers
    
    var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    var totalDurationString: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return "\(hours)s \(minutes)dk"
    }
    
    struct SubjectDuration {
        let name: String
        let duration: TimeInterval
        let colorHex: String
    }
    
    var subjectDurations: [SubjectDuration] {
        let grouped = Dictionary(grouping: sessions, by: { $0.subject?.name ?? "Bilinmeyen" })
        return grouped.map { (key, value) in
            let total = value.reduce(0) { $0 + $1.duration }
            let color = value.first?.subject?.colorHex ?? "#888888"
            return SubjectDuration(name: key, duration: total, colorHex: color)
        }.sorted { $0.duration > $1.duration }
    }
    
    func formatDurationShort(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%dsa %02ddk", hours, minutes)
    }
    

}

#Preview {
    NavigationStack {
        StudyDetailsView()
            .environmentObject(ThemeManager())
    }
}
