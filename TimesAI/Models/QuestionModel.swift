//
//  QuestionModel.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import Foundation
import SwiftData

/// Represents a single multiplication question with full tracking
@Model
final class MultiplicationQuestion {
    var id: UUID
    var firstNumber: Int
    var secondNumber: Int
    var answer: Int
    var difficultyWeight: Double // 1×1=1, 12×12=144
    
    // Performance tracking
    var totalAttempts: Int
    var correctAttempts: Int
    var wrongAttempts: Int
    var responseTimes: [TimeInterval] // All response times
    var lastAttemptDate: Date?
    var lastAttemptCorrect: Bool
    
    // Mastery tracking
    var masteryScore: Double // 0.0 to 100.0
    var consecutiveCorrect: Int
    var needsReview: Bool
    
    init(firstNumber: Int, secondNumber: Int) {
        self.id = UUID()
        self.firstNumber = firstNumber
        self.secondNumber = secondNumber
        self.answer = firstNumber * secondNumber
        self.difficultyWeight = Double(firstNumber * secondNumber) / 12.0 // Normalized difficulty
        
        self.totalAttempts = 0
        self.correctAttempts = 0
        self.wrongAttempts = 0
        self.responseTimes = []
        self.lastAttemptDate = nil
        self.lastAttemptCorrect = false
        
        self.masteryScore = 0.0
        self.consecutiveCorrect = 0
        self.needsReview = false
    }
    
    var questionText: String {
        "\(firstNumber) × \(secondNumber)"
    }
    
    var accuracyRate: Double {
        guard totalAttempts > 0 else { return 0.0 }
        return Double(correctAttempts) / Double(totalAttempts)
    }
    
    var averageResponseTime: TimeInterval {
        guard !responseTimes.isEmpty else { return 0.0 }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    var isStruggling: Bool {
        // Struggling if: needs review (marked after wrong answer) OR has poor performance metrics
        if needsReview {
            return true
        }
        
        guard totalAttempts >= 3 else { return false }
        
        let slowThreshold = 8.0 + (difficultyWeight * 0.5) // Harder questions get more time
        let isAccuratePoor = accuracyRate < 0.6
        let isResponseSlow = averageResponseTime > slowThreshold
        
        return isAccuratePoor || isResponseSlow
    }
    
    func recordAttempt(correct: Bool, responseTime: TimeInterval) {
        totalAttempts += 1
        responseTimes.append(responseTime)
        lastAttemptDate = Date()
        lastAttemptCorrect = correct
        
        if correct {
            correctAttempts += 1
            consecutiveCorrect += 1
        } else {
            wrongAttempts += 1
            consecutiveCorrect = 0
            needsReview = true
        }
        
        updateMasteryScore()
    }
    
    private func updateMasteryScore() {
        // Mastery = weighted combination of accuracy, speed, consistency
        guard totalAttempts > 0 else {
            masteryScore = 0.0
            return
        }
        
        // 1. Accuracy component (0-40 points)
        let accuracyPoints = accuracyRate * 40.0
        
        // 2. Speed component (0-30 points)
        let targetTime = 3.0 + (difficultyWeight * 0.3)
        let avgTime = averageResponseTime
        let speedRatio = max(0, 1.0 - ((avgTime - targetTime) / targetTime))
        let speedPoints = max(0, speedRatio * 30.0)
        
        // 3. Consistency component (0-30 points)
        let consistencyBonus = min(Double(consecutiveCorrect) * 3.0, 30.0)
        
        masteryScore = min(100.0, accuracyPoints + speedPoints + consistencyBonus)
        
        // Clear needs review if mastery is high
        if masteryScore >= 80.0 && consecutiveCorrect >= 3 {
            needsReview = false
        }
    }
    
    var masteryLevel: MasteryLevel {
        switch masteryScore {
        case 0..<20: return .beginner
        case 20..<40: return .learning
        case 40..<60: return .practicing
        case 60..<80: return .skilled
        case 80..<95: return .proficient
        default: return .mastered
        }
    }
}

enum MasteryLevel: String, Codable {
    case beginner = "Beginner"
    case learning = "Learning"
    case practicing = "Practicing"
    case skilled = "Skilled"
    case proficient = "Proficient"
    case mastered = "Mastered"
    
    var color: String {
        switch self {
        case .beginner: return "gray"
        case .learning: return "orange"
        case .practicing: return "yellow"
        case .skilled: return "blue"
        case .proficient: return "purple"
        case .mastered: return "green"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .learning: return "📚"
        case .practicing: return "💪"
        case .skilled: return "⭐️"
        case .proficient: return "🏆"
        case .mastered: return "👑"
        }
    }
}

import SwiftUI

extension Color {
    init(_ masteryColor: String) {
        switch masteryColor {
        case "gray": self = .gray
        case "orange": self = .orange
        case "yellow": self = .yellow
        case "blue": self = .blue
        case "purple": self = .purple
        case "green": self = .green
        default: self = .gray
        }
    }
}
