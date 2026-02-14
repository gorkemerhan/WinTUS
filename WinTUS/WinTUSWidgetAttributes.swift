import ActivityKit
import SwiftUI

struct WinTUSWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dinamik değişen değerler
        var timerValue: String // "10:00"
        var progress: Double // 0.0 - 1.0 arası
        var isActive: Bool
    }
    
    // Sabit değerler
    var subjectName: String
    var subjectColorHex: String
}
