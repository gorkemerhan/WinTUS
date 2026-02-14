import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var sessions: [StudySession]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
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
                        
                        // Özet Kartları
                        HStack(spacing: 14) {
                            // Toplam Çalışma (Tıklanabilir)
                            NavigationLink(destination: StudyDetailsView()) {
                                SummaryCard(
                                    title: "Toplam Çalışma",
                                    value: totalDurationString,
                                    icon: "clock.fill",
                                    gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Mevcut Seri (Statik)
                            SummaryCard(
                                title: "Mevcut Seri",
                                value: "\(currentStreak) Gün",
                                icon: "flame.fill",
                                gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Son 7 Gün Çubuk Grafik
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Son 7 Gün")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(last7DaysData, id: \.date) { item in
                                    BarMark(
                                        x: .value("Gün", item.dayName),
                                        y: .value("Süre", item.duration / 3600)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisValueLabel {
                                        if let intValue = value.as(Double.self) {
                                            Text("\(Int(intValue))s")
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .frame(height: 220)
                            .padding()
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
                    .padding(.vertical)
                }
            }
            .navigationTitle("Analiz")
        }
    }
    
    // MARK: - Computed Properties
    
    var totalDurationString: String {
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        return "\(hours)s \(minutes)dk"
    }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        let uniqueDates = Set(sessions.map { calendar.startOfDay(for: $0.startTime) }).sorted(by: >)
        
        guard let lastStudyDate = uniqueDates.first else { return 0 }
        
        if !calendar.isDateInToday(lastStudyDate) && !calendar.isDateInYesterday(lastStudyDate) {
            return 0
        }
        
        var streak = 0
        var checkDate = lastStudyDate
        
        for date in uniqueDates {
            if calendar.isDate(date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }
    
    struct DailyData {
        let date: Date
        let dayName: String
        let duration: TimeInterval
    }
    
    var last7DaysData: [DailyData] {
        let calendar = Calendar.current
        var result: [DailyData] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: Date()) {
                let dayStart = calendar.startOfDay(for: date)
                let daySessions = sessions.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
                let total = daySessions.reduce(0) { $0 + $1.duration }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "E"
                formatter.locale = Locale(identifier: "tr_TR")
                
                result.append(DailyData(date: dayStart, dayName: formatter.string(from: date), duration: total))
            }
        }
        return result
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(gradient)
                    .clipShape(Circle())
                Spacer()
            }
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(ThemeManager())
}
