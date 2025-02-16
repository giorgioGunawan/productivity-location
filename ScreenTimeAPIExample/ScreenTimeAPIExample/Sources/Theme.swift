import SwiftUI

public struct Theme {
    // Colors
    public static let mainPurple = Color(red: 125/255, green: 74/255, blue: 255/255)
    public static let mainBlue = Color(red: 64/255, green: 93/255, blue: 230/255)
    public static let background = Color(.systemBackground)
    
    // Gradients
    public static let mainGradient = LinearGradient(
        gradient: Gradient(colors: [mainPurple, mainBlue]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Text Styles
    public static let titleStyle = Font.system(size: 28, weight: .bold)
    public static let subtitleStyle = Font.system(size: 18, weight: .medium)
    public static let bodyStyle = Font.system(size: 16)
    
    // Dimensions
    public static let minimumTapTarget: CGFloat = 44
    public static let standardPadding: CGFloat = 16
    public static let largeCornerRadius: CGFloat = 16
    public static let standardCornerRadius: CGFloat = 12
    
    // Shadows
    public static let standardShadow = Shadow(
        color: Color.black.opacity(0.1),
        radius: 10,
        x: 0,
        y: 5
    )
}

public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
} 