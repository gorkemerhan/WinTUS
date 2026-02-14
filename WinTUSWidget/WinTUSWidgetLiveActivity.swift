import ActivityKit
import WidgetKit
import SwiftUI

struct WinTUSWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WinTUSWidgetAttributes.self) { context in
            // Lock Screen / Banner UI
            VStack {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(Color(hex: context.attributes.subjectColorHex))
                    
                    Text("\(context.attributes.subjectName)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(context.state.timerValue)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding()
            }
            .activityBackgroundTint(Color(hex: "#1A1A1A")) // Dark background
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(Color(hex: context.attributes.subjectColorHex))
                        Text(context.attributes.subjectName)
                            .font(.caption)
                            .foregroundColor(Color(hex: context.attributes.subjectColorHex))
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timerValue)
                        .font(.monospacedDigit(.title2))
                        .foregroundStyle(.white)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(Color(hex: context.attributes.subjectColorHex))
                        .padding([.leading, .trailing])
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .tint(Color(hex: context.attributes.subjectColorHex))
            } compactTrailing: {
                Text(context.state.timerValue)
                    .font(.monospacedDigit(.caption))
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "timer")
                    .tint(Color(hex: context.attributes.subjectColorHex))
            }
        }
    }
}

// Helper for Color inside Widget Target
// Bu extension sadece Widget target içinde geçerlidir (Main app ile çakışmaz)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
