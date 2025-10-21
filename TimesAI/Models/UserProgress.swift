//
//  UserProgress.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import Foundation
import SwiftData

/// Tracks overall user progress and gamification data
@Model
final class UserProgress {
    var id: UUID
    var username: String
    var avatarName: String
    
    // XP & Level System
    var totalXP: Int
    var level: Int
    var xpToNextLevel: Int
    
    // Streak System
    var currentStreak: Int
    var longestStreak: Int
    var lastPlayedDate: Date?
    
    // Session Stats
    var totalQuestionsAnswered: Int
    var totalCorrectAnswers: Int
    var totalWrongAnswers: Int
    var totalPlayTime: TimeInterval // in seconds
    
    // Daily Challenge
    var dailyChallengeCompleted: Bool
    var dailyChallengeDate: Date?
    var dailyChallengeStreak: Int
    
    // Achievements
    var unlockedAchievements: [String] // Achievement IDs
    
    // Preferences
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var selectedTheme: String
    
    init(username: String = "Player") {
        self.id = UUID()
        self.username = username
        self.avatarName = "avatar_default"
        
        self.totalXP = 0
        self.level = 1
        self.xpToNextLevel = 100
        
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastPlayedDate = nil
        
        self.totalQuestionsAnswered = 0
        self.totalCorrectAnswers = 0
        self.totalWrongAnswers = 0
        self.totalPlayTime = 0
        
        self.dailyChallengeCompleted = false
        self.dailyChallengeDate = nil
        self.dailyChallengeStreak = 0
        
        self.unlockedAchievements = []
        
        self.soundEnabled = true
        self.hapticsEnabled = true
        self.selectedTheme = "default"
    }
    
    var accuracyRate: Double {
        guard totalQuestionsAnswered > 0 else { return 0.0 }
        return Double(totalCorrectAnswers) / Double(totalQuestionsAnswered)
    }
    
    func addXP(_ amount: Int) {
        totalXP += amount
        
        // Check for level up
        while totalXP >= xpToNextLevel {
            levelUp()
        }
    }
    
    private func levelUp() {
        level += 1
        totalXP -= xpToNextLevel
        xpToNextLevel = calculateXPForNextLevel()
    }
    
    private func calculateXPForNextLevel() -> Int {
        // Progressive XP requirement: 100, 150, 225, 338, 506...
        return Int(100 * pow(1.5, Double(level - 1)))
    }
    
    func recordQuestionAnswered(correct: Bool, xpEarned: Int) {
        totalQuestionsAnswered += 1
        if correct {
            totalCorrectAnswers += 1
        } else {
            totalWrongAnswers += 1
        }
        addXP(xpEarned)
    }
    
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastPlayed = lastPlayedDate {
            let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
            let daysDifference = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0
            
            if daysDifference == 0 {
                // Same day, streak continues
                return
            } else if daysDifference == 1 {
                // Next day, increment streak
                currentStreak += 1
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            // First time playing
            currentStreak = 1
        }
        
        lastPlayedDate = Date()
        longestStreak = max(longestStreak, currentStreak)
    }
    
    func unlockAchievement(_ achievementId: String) {
        if !unlockedAchievements.contains(achievementId) {
            unlockedAchievements.append(achievementId)
        }
    }
}

/// Achievement definition
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let xpReward: Int
    let requirement: AchievementRequirement
    
    enum AchievementRequirement: Codable {
        case answeredQuestions(Int)
        case accuracyAbove(Double)
        case streakDays(Int)
        case speedDemon(TimeInterval) // Average time under X seconds
        case perfectStreak(Int) // X correct in a row
        case masterAllTables
        case reachLevel(Int)
    }
}

extension Achievement {
    static let allAchievements: [Achievement] = [
        Achievement(id: "first_blood", title: "First Steps", description: "Answer your first question", iconName: "star.fill", xpReward: 50, requirement: .answeredQuestions(1)),
        Achievement(id: "century", title: "Century", description: "Answer 100 questions", iconName: "100.circle.fill", xpReward: 200, requirement: .answeredQuestions(100)),
        Achievement(id: "accuracy_ace", title: "Accuracy Ace", description: "Maintain 90% accuracy over 50 questions", iconName: "target", xpReward: 300, requirement: .accuracyAbove(0.9)),
        Achievement(id: "speed_demon", title: "Speed Demon", description: "Average under 3 seconds per question", iconName: "bolt.fill", xpReward: 250, requirement: .speedDemon(3.0)),
        Achievement(id: "week_warrior", title: "Week Warrior", description: "Maintain a 7-day streak", iconName: "calendar", xpReward: 400, requirement: .streakDays(7)),
        Achievement(id: "perfect_ten", title: "Perfect Ten", description: "Answer 10 questions correctly in a row", iconName: "flame.fill", xpReward: 150, requirement: .perfectStreak(10)),
        Achievement(id: "master", title: "Multiplication Master", description: "Master all times tables", iconName: "crown.fill", xpReward: 1000, requirement: .masterAllTables),
        Achievement(id: "level_10", title: "Level 10", description: "Reach level 10", iconName: "star.circle.fill", xpReward: 500, requirement: .reachLevel(10))
    ]
}
