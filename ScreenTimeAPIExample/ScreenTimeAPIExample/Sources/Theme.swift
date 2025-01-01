import SwiftUI

struct AppTheme {
    static let mainPurple = Color(red: 125/255, green: 74/255, blue: 255/255)
    static let mainBlue = Color(red: 64/255, green: 93/255, blue: 230/255)
    
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 125/255, green: 74/255, blue: 255/255),
            Color(red: 64/255, green: 93/255, blue: 230/255)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Dark mode colors
    static let darkBackground = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let darkSecondaryBackground = Color(red: 44/255, green: 44/255, blue: 46/255)
} 