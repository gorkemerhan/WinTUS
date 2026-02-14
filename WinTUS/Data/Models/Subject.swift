import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var repetitionCount: Int = 1
    
    // İlişkiler
    @Relationship(deleteRule: .cascade) 
    var sessions: [StudySession]? = []
    
    @Relationship(deleteRule: .cascade) 
    var plans: [StudyPlan]? = []
    
    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.repetitionCount = 1
        self.id = UUID()
    }
}
