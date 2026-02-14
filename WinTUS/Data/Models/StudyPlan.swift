import Foundation
import SwiftData

@Model
final class StudyPlan {
    var id: UUID
    var targetDate: Date
    var targetDuration: TimeInterval // Saniye cinsinden hedef (örn: 3600 = 1 saat)
    var isCompleted: Bool
    
    // İlişki
    var subject: Subject?
    
    init(targetDate: Date, targetDuration: TimeInterval, subject: Subject) {
        self.targetDate = targetDate
        self.targetDuration = targetDuration
        self.subject = subject
        self.isCompleted = false
        self.id = UUID()
    }
}
