import WidgetKit
import SwiftUI

@main
struct WinTUSWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Statik widget geçici olarak devre dışı - sadece Live Activity kullanılıyor
        // WinTUSWidget()
        WinTUSWidgetLiveActivity()
    }
}
