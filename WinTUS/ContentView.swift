import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .timer
    
    enum Tab: Int, CaseIterable {
        case calendar = 0
        case timer = 1
        case tools = 2
        case analytics = 3
        
        var title: String {
            switch self {
            case .calendar: return "Takvim"
            case .timer: return "Sayaç"
            case .tools: return "Araçlar"
            case .analytics: return "Analiz"
            }
        }
        
        var icon: String {
            switch self {
            case .calendar: return "calendar"
            case .timer: return "timer"
            case .tools: return "square.grid.2x2"
            case .analytics: return "chart.bar"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Ana İçerik - TabView yerine doğrudan switch ile gösteriyoruz (crash fix)
            Group {
                switch selectedTab {
                case .calendar:
                    CalendarView()
                case .timer:
                    TimerView()
                case .tools:
                    ToolsView()
                case .analytics:
                    AnalyticsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                Divider() // Üst çizgi
                HStack {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 24))
                                    .symbolVariant(selectedTab == tab ? .fill : .none)
                                Text(tab.title)
                                    .font(.caption2)
                            }
                            .foregroundStyle(selectedTab == tab ? .blue : .gray)
                        }
                        Spacer()
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 20) // Home bar için boşluk
                .background(Color(uiColor: .systemBackground).opacity(0.95)) // Arka plan
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
            }
        }
        .ignoresSafeArea(.keyboard) // Klavye açılınca tab bar yukarı çıkmasın
    }
}

#Preview {
    ContentView()
}
