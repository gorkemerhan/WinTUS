import Foundation
import SwiftData

@Model
final class Flashcard {
    var id: UUID
    var question: String
    var answer: String
    var createdAt: Date
    var isMastered: Bool // Öğrenildi mi?
    
    // İlişki
    var subject: Subject?
    
    init(question: String, answer: String, subject: Subject) {
        self.question = question
        self.answer = answer
        self.subject = subject
        self.createdAt = Date()
        self.isMastered = false
        self.id = UUID()
    }
}

@Model
final class StudyNote {
    var id: UUID
    var title: String
    var imageData: Data? // Fotoğraf verisi
    var createdAt: Date
    
    var subject: Subject?
    
    init(title: String, imageData: Data?, subject: Subject) {
        self.title = title
        self.imageData = imageData
        self.subject = subject
        self.createdAt = Date()
        self.id = UUID()
    }
}
