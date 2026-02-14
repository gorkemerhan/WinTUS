import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    
    // İlişki (Tersi)
    var subject: Subject?
    
    init(startTime: Date, subject: Subject) {
        self.startTime = startTime
        self.subject = subject
        self.duration = 0
        self.id = UUID()
    }
}
