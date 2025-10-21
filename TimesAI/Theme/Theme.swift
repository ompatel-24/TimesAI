//
//  Theme.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Primary palette
        static let primary = Color(hex: "6366F1") // Indigo
        static let secondary = Color(hex: "EC4899") // Pink
        static let accent = Color(hex: "F59E0B") // Amber
        
        // Status colors
        static let success = Color(hex: "10B981") // Green
        static let error = Color(hex: "EF4444") // Red
        static let warning = Color(hex: "F59E0B") // Amber
        static let info = Color(hex: "3B82F6") // Blue
        
        // Neutral
        static let background = Color(hex: "F8FAFC")
        static let backgroundDark = Color(hex: "0F172A")
        static let surface = Color.white
        static let surfaceDark = Color(hex: "1E293B")
        
        static let textPrimary = Color(hex: "1E293B")
        static let textSecondary = Color(hex: "64748B")
        static let textTertiary = Color(hex: "94A3B8")
        
        // Mastery colors
        static let mastery = [
            "beginner": Color.gray,
            "learning": Color.orange,
            "practicing": Color.yellow,
            "skilled": Color.blue,
            "proficient": Color.purple,
            "mastered": Color.green
        ]
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadows {
        static func sm() -> some View {
            EmptyView()
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        
        static func md() -> some View {
            EmptyView()
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        
        static func lg() -> some View {
            EmptyView()
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        }
    }
    
    // MARK: - Animations
    struct Animations {
        static let quick = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.6)
        static let celebration = Animation.spring(response: 0.8, dampingFraction: 0.5)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .fill(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppTheme.Animations.quick, value: configuration.isPressed)
    }
}

struct AnswerButtonStyle: ButtonStyle {
    var isCorrect: Bool = false
    var isWrong: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.title)
            .foregroundColor(buttonForegroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .fill(buttonBackgroundColor)
                    .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isCorrect || isWrong ? 1.05 : 1.0))
            .animation(AppTheme.Animations.bouncy, value: configuration.isPressed)
            .animation(AppTheme.Animations.bouncy, value: isCorrect)
            .animation(AppTheme.Animations.bouncy, value: isWrong)
    }
    
    private var buttonBackgroundColor: Color {
        if isCorrect {
            return AppTheme.Colors.success
        } else if isWrong {
            return AppTheme.Colors.error
        } else {
            return AppTheme.Colors.surface
        }
    }
    
    private var buttonForegroundColor: Color {
        if isCorrect || isWrong {
            return .white
        } else {
            return AppTheme.Colors.textPrimary
        }
    }
    
    private var shadowColor: Color {
        if isCorrect {
            return AppTheme.Colors.success.opacity(0.3)
        } else if isWrong {
            return AppTheme.Colors.error.opacity(0.3)
        } else {
            return Color.black.opacity(0.1)
        }
    }
}
