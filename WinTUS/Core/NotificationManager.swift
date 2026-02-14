import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Bildirim izni verildi.")
            } else if let error = error {
                print("Bildirim izni hatası: \(error.localizedDescription)")
            }
        }
    }
    
    func sendGoalAchievedNotification(subjectName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Tebrikler! 🎉"
        content.body = "\(subjectName) dersi için günlük hedefine ulaştın!"
        content.sound = .default
        
        // Hemen gönder (1 saniye sonra)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
