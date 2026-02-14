import ActivityKit
import Foundation

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var activity: Activity<WinTUSWidgetAttributes>?
    
    private init() {}
    
    func start(subjectName: String, colorHex: String, timerValue: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = WinTUSWidgetAttributes(subjectName: subjectName, subjectColorHex: colorHex)
        let state = WinTUSWidgetAttributes.ContentState(timerValue: timerValue, progress: 0.0, isActive: true)
        
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            print("Live Activity Başlatıldı: \(activity?.id ?? "")")
        } catch {
            print("Live Activity Hatası: \(error)")
        }
    }
    
    func update(timerValue: String, progress: Double) {
        guard let activity = activity else { return }
        
        // iOS 16.2+ için update fonksiyonu
        let newState = WinTUSWidgetAttributes.ContentState(timerValue: timerValue, progress: progress, isActive: true)
        
        Task {
            await activity.update(
                ActivityContent(state: newState, staleDate: nil)
            )
        }
    }
    
    func stop() {
        guard let activity = activity else { return }
        
        let finalState = WinTUSWidgetAttributes.ContentState(timerValue: "Bitti", progress: 1.0, isActive: false)
        
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            self.activity = nil
        }
    }
}
