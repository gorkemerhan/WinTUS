import SwiftUI
import SwiftData
import UIKit

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [StudySession]
    @Query private var plans: [StudyPlan]
    @Query private var subjects: [Subject]
    
    // Tema yönetimi
    @EnvironmentObject var themeManager: ThemeManager
    
    // Seçili tarih ve Görünüm modu
    @State private var selectedDateComponents: DateComponents? = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    @State private var viewMode: ViewMode = .month
    @State private var showingAddPlan = false
    @State private var showingAddManualSession = false
    
    // Performans için cache (Opsiyonel, SwiftData zaten hızlı ama bu yapı korunabilir)
    @State private var sessionDates: Set<DateComponents> = []
    @State private var planDates: Set<DateComponents> = []
    
    enum ViewMode {
        case month, day
    }
    
    var selectedDate: Date {
        Calendar.current.date(from: selectedDateComponents ?? DateComponents()) ?? Date()
    }
    
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
                        // Header ve Picker
                        headerView
                        
                        // Takvim Görünümü (Aylık veya Günlük)
                        // Transition sorununu çözmek için if-else bloğu
                        if viewMode == .month {
                            MonthCalendarWrapper(
                                plans: plans,
                                selectedDate: $selectedDateComponents
                            )
                            .frame(height: 400)
                            .background(Material.regular)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                            .padding(.horizontal)
                        } else {
                            DayCalendarStripView(
                                plans: plans,
                                selectedDateComponents: $selectedDateComponents
                            )
                            .frame(height: 100)
                        }
                        
                        // Seçili Güne Ait Bilgiler
                        detailsView
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddPlan) {
                AddPlanView(targetDate: selectedDate)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingAddManualSession) {
                AddManualSessionView(targetDate: selectedDate)
                    .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("Takvim 🔵")
                .font(.largeTitle)
                .bold()
            Spacer()
            
            // Custom Segmented Picker
            HStack(spacing: 0) {
                viewModeButton(title: "Aylık", mode: .month)
                viewModeButton(title: "Günlük", mode: .day)
            }
            .padding(2)
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(width: 160)
        }
        .padding(.top, 10)
        .padding(.horizontal, 20)
    }
    
    private func viewModeButton(title: String, mode: ViewMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = mode
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(viewMode == mode ? .semibold : .regular)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(viewMode == mode ? Color.white : Color.clear)
                .foregroundStyle(viewMode == mode ? .black : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Planlananlar
            Text("Planlanan Çalışmalar")
                .font(.headline)
            
            let daysPlans = plans.filter { Calendar.current.isDate($0.targetDate, inSameDayAs: selectedDate) }
            
            if daysPlans.isEmpty {
                Text("Bu gün için plan yok.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(daysPlans) { plan in
                    HStack {
                        Circle()
                            .fill(Color(hex: plan.subject?.colorHex ?? "#888888"))
                            .frame(width: 10, height: 10)
                        Text(plan.subject?.name ?? "Bilinmeyen Ders")
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Text("\(Int(plan.targetDuration / 60)) dk")
                            .foregroundStyle(.secondary)
                        
                        Button {
                            deletePlan(plan: plan)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .padding(.leading, 4)
                    }
                    .padding()
                    .background(Material.ultraThin)
                    .cornerRadius(10)
                }
            }
            
            // Yeni Plan Ekle Butonu
            if selectedDate >= Calendar.current.startOfDay(for: Date()) {
                Button {
                    showingAddPlan = true
                } label: {
                    Label("Yeni Plan Ekle", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            
            Divider().padding(.vertical)
            
            // Tamamlananlar
            Text("Tamamlanan Çalışmalar")
                .font(.headline)
            
            let daysSessions = sessions.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
            
            if daysSessions.isEmpty {
                Text("Çalışma kaydı bulunamadı.").foregroundStyle(.secondary)
            } else {
                // Derslere göre gruplandır ve toplam süreyi hesapla
                let groupedSessions = Dictionary(grouping: daysSessions, by: { $0.subject?.id })
                let sortedGroups = groupedSessions.sorted { group1, group2 in
                    let total1 = group1.value.reduce(0) { $0 + $1.duration }
                    let total2 = group2.value.reduce(0) { $0 + $1.duration }
                    return total1 > total2 // En çok çalışılan ders üstte
                }
                
                ForEach(sortedGroups, id: \.key) { subjectId, sessionsForSubject in
                    let firstSession = sessionsForSubject.first
                    let totalDuration = sessionsForSubject.reduce(0) { $0 + $1.duration }
                    let sessionCount = sessionsForSubject.count
                    
                    HStack {
                        Circle()
                            .fill(Color(hex: firstSession?.subject?.colorHex ?? "#888888"))
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(firstSession?.subject?.name ?? "Bilinmeyen Ders")
                                .lineLimit(1)
                            if sessionCount > 1 {
                                Text("\(sessionCount) oturum")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(formatDuration(totalDuration))
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Material.ultraThin)
                    .cornerRadius(10)
                }
            }
            
            // Manuel Çalışma Ekle Butonu
            Button {
                showingAddManualSession = true
            } label: {
                Label("Manuel Çalışma Ekle", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
    
    // Helper Methods
    func deletePlan(plan: StudyPlan) {
        modelContext.delete(plan)
    }
    
    func deleteSession(session: StudySession) {
        modelContext.delete(session)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return hours > 0 ? "\(hours)sa \(minutes)dk" : "\(minutes)dk"
    }
}

// MARK: - Day Calendar Strip View
struct DayCalendarStripView: View {
    var plans: [StudyPlan]
    @Binding var selectedDateComponents: DateComponents?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                LazyHStack(spacing: 12) {
                    // Geniş bir tarih aralığı
                    ForEach(-180...180, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        let isSelected = isDateSelected(date)
                        let isToday = Calendar.current.isDateInToday(date)
                        
                        dayCell(date: date, isSelected: isSelected, isToday: isToday)
                            .id(offset)
                            .onTapGesture {
                                withAnimation {
                                    selectedDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .onAppear {
                    // Seçili güne veya bugüne odaklan
                    proxy.scrollTo(0, anchor: .center)
                }
                // Seçili tarih değiştiğinde de scroll etmesi için (Opsiyonel)
            }
        }
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let selected = selectedDateComponents?.date else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selected)
    }
    
    private func dayCell(date: Date, isSelected: Bool, isToday: Bool) -> some View {
        let daysPlans = plans.filter { Calendar.current.isDate($0.targetDate, inSameDayAs: date) }
        let uniqueColors = Set(daysPlans.compactMap { $0.subject?.colorHex }).prefix(3)
        
        return VStack(spacing: 6) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.caption2)
                .textCase(.uppercase)
            
            Text(date.formatted(.dateTime.day()))
                .font(.title2)
                .bold()
            
            // Noktalar
            HStack(spacing: 3) {
                if uniqueColors.isEmpty {
                    Circle().fill(Color.clear).frame(width: 4, height: 4)
                } else {
                    ForEach(Array(uniqueColors), id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .frame(height: 6)
        }
        .frame(width: 60)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)))
        .foregroundStyle(isSelected ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Month Calendar Wrapper (UICalendarView)
struct MonthCalendarWrapper: UIViewRepresentable {
    var plans: [StudyPlan]
    @Binding var selectedDate: DateComponents?
    
    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = Calendar.current
        view.locale = Locale(identifier: "tr_TR")
        view.fontDesign = .rounded
        view.delegate = context.coordinator
        view.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.plans = plans
        
        // Seçili tarihi güncelle
        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            selection.selectedDate = selectedDate
        }
        
        // Dekorasyonları yenile
        uiView.reloadDecorations(forDateComponents: [], animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: MonthCalendarWrapper
        var plans: [StudyPlan] = []
        
        init(_ parent: MonthCalendarWrapper) {
            self.parent = parent
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.selectedDate = dateComponents
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = dateComponents.date else { return nil }
            
            let daysPlans = plans.filter { Calendar.current.isDate($0.targetDate, inSameDayAs: date) }
            
            if !daysPlans.isEmpty {
                let uniqueColors = Set(daysPlans.compactMap { $0.subject?.colorHex }).prefix(3)
                let uiColors = uniqueColors.map { UIColor(Color(hex: $0)) }
                
                if let image = createMultiDotImage(colors: uiColors) {
                    return .image(image, size: .large)
                }
            }
            return nil
        }
        
        private func createMultiDotImage(colors: [UIColor]) -> UIImage? {
            guard !colors.isEmpty else { return nil }
            let dotSize: CGFloat = 6
            let spacing: CGFloat = 4
            let totalWidth = CGFloat(colors.count) * dotSize + CGFloat(max(0, colors.count - 1)) * spacing
            let height = dotSize
            
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: height))
            return renderer.image { ctx in
                for (index, color) in colors.enumerated() {
                    let x = CGFloat(index) * (dotSize + spacing)
                    let rect = CGRect(x: x, y: 0, width: dotSize, height: dotSize)
                    color.setFill()
                    ctx.cgContext.fillEllipse(in: rect)
                }
            }
        }
    }
}
