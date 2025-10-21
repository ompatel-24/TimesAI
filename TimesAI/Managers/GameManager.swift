//
//  GameManager.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import Foundation
import SwiftData
import SwiftUI

/// Core manager for game logic, question selection, and progress tracking
@MainActor
class GameManager: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var userProgress: UserProgress
    @Published var allQuestions: [MultiplicationQuestion] = []
    @Published var currentQuestion: MultiplicationQuestion?
    @Published var questionOptions: [Int] = []
    
    // Session tracking
    @Published var sessionCorrectCount: Int = 0
    @Published var sessionTotalCount: Int = 0
    @Published var currentCombo: Int = 0
    @Published var sessionXP: Int = 0
    @Published var sessionStartTime: Date?
    
    // UI State
    @Published var showCelebration: Bool = false
    @Published var showLevelUp: Bool = false
    @Published var recentlyUnlockedAchievements: [Achievement] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Load or create user progress
        let descriptor = FetchDescriptor<UserProgress>()
        if let existingProgress = try? modelContext.fetch(descriptor).first {
            self.userProgress = existingProgress
        } else {
            self.userProgress = UserProgress(username: "Player")
            modelContext.insert(userProgress)
        }
        
        // Load or create questions
        loadQuestions()
    }
    
    private func loadQuestions() {
        let descriptor = FetchDescriptor<MultiplicationQuestion>()
        
        if let existingQuestions = try? modelContext.fetch(descriptor), !existingQuestions.isEmpty {
            self.allQuestions = existingQuestions
        } else {
            // Initialize all multiplication questions (1-12 tables)
            for i in 1...12 {
                for j in 1...12 {
                    let question = MultiplicationQuestion(firstNumber: i, secondNumber: j)
                    modelContext.insert(question)
                    allQuestions.append(question)
                }
            }
            
            try? modelContext.save()
        }
    }
    
    // MARK: - Question Selection
    
    func selectNextQuestion(mode: GameMode) {
        switch mode {
        case .practice:
            selectPracticeQuestion()
        case .learning:
            selectLearningQuestion()
        case .challenge:
            selectChallengeQuestion()
        }
        
        if let question = currentQuestion {
            generateOptions(for: question)
        }
    }
    
    private func selectPracticeQuestion() {
        // Random selection with slight bias toward less practiced questions
        let sortedByAttempts = allQuestions.sorted { $0.totalAttempts < $1.totalAttempts }
        let pool = Array(sortedByAttempts.prefix(30)) // Top 30 least practiced
        currentQuestion = pool.randomElement()
    }
    
    private func selectLearningQuestion() {
        // Smart selection: struggling questions + spaced repetition
        let strugglingQuestions = allQuestions.filter { $0.isStruggling }
        
        if !strugglingQuestions.isEmpty {
            // Prioritize questions that need review or have low mastery
            let sortedByNeed = strugglingQuestions.sorted { q1, q2 in
                if q1.needsReview != q2.needsReview {
                    return q1.needsReview
                }
                return q1.masteryScore < q2.masteryScore
            }
            currentQuestion = sortedByNeed.first
        } else {
            // If no struggling questions, review least recent
            let sortedByRecency = allQuestions.sorted { q1, q2 in
                guard let date1 = q1.lastAttemptDate, let date2 = q2.lastAttemptDate else {
                    return q1.lastAttemptDate == nil
                }
                return date1 < date2
            }
            currentQuestion = sortedByRecency.first
        }
    }
    
    private func selectChallengeQuestion() {
        // Daily challenge: 10 questions of increasing difficulty
        let sortedByDifficulty = allQuestions.sorted { $0.difficultyWeight < $1.difficultyWeight }
        let challengeIndex = min(sessionTotalCount, sortedByDifficulty.count - 1)
        currentQuestion = sortedByDifficulty[challengeIndex]
    }
    
    func generateOptions(for question: MultiplicationQuestion) {
        var options = Set<Int>()
        options.insert(question.answer)
        
        let range = max(10, Int(question.answer / 2))
        
        while options.count < 4 {
            let offset = Int.random(in: 1...range)
            let wrongAnswer = Bool.random() ? question.answer + offset : max(1, question.answer - offset)
            if wrongAnswer != question.answer {
                options.insert(wrongAnswer)
            }
        }
        
        questionOptions = Array(options).shuffled()
    }
    
    // MARK: - Answer Processing
    
    func submitAnswer(_ selectedAnswer: Int, responseTime: TimeInterval) {
        guard let question = currentQuestion else { return }
        
        let isCorrect = selectedAnswer == question.answer
        
        // Record attempt
        question.recordAttempt(correct: isCorrect, responseTime: responseTime)
        
        // Calculate XP
        let xpEarned = calculateXP(for: question, correct: isCorrect, responseTime: responseTime)
        
        // Update session
        sessionTotalCount += 1
        if isCorrect {
            sessionCorrectCount += 1
            currentCombo += 1
            sessionXP += xpEarned
        } else {
            currentCombo = 0
        }
        
        // Update user progress
        let previousLevel = userProgress.level
        userProgress.recordQuestionAnswered(correct: isCorrect, xpEarned: xpEarned)
        
        // Check for level up
        if userProgress.level > previousLevel {
            showLevelUp = true
        }
        
        // Check achievements
        checkAchievements()
        
        // Save
        try? modelContext.save()
        
        // Show celebration for correct answers
        if isCorrect {
            showCelebration = true
        }
    }
    
    private func calculateXP(for question: MultiplicationQuestion, correct: Bool, responseTime: TimeInterval) -> Int {
        guard correct else { return 5 } // Participation XP
        
        // Base XP based on difficulty
        let baseXP = Int(10 + question.difficultyWeight * 2)
        
        // Speed bonus
        let targetTime = 3.0 + (question.difficultyWeight * 0.3)
        let speedMultiplier: Double
        if responseTime < targetTime * 0.5 {
            speedMultiplier = 2.0 // Lightning fast
        } else if responseTime < targetTime {
            speedMultiplier = 1.5 // Fast
        } else if responseTime < targetTime * 1.5 {
            speedMultiplier = 1.0 // Normal
        } else {
            speedMultiplier = 0.8 // Slow
        }
        
        // Combo bonus
        let comboBonus = min(currentCombo * 2, 50)
        
        return Int(Double(baseXP) * speedMultiplier) + comboBonus
    }
    
    // MARK: - Achievements
    
    private func checkAchievements() {
        for achievement in Achievement.allAchievements {
            if !userProgress.unlockedAchievements.contains(achievement.id) {
                if checkAchievementRequirement(achievement.requirement) {
                    userProgress.unlockAchievement(achievement.id)
                    recentlyUnlockedAchievements.append(achievement)
                    userProgress.addXP(achievement.xpReward)
                }
            }
        }
    }
    
    private func checkAchievementRequirement(_ requirement: Achievement.AchievementRequirement) -> Bool {
        switch requirement {
        case .answeredQuestions(let count):
            return userProgress.totalQuestionsAnswered >= count
            
        case .accuracyAbove(let threshold):
            return userProgress.totalQuestionsAnswered >= 50 && userProgress.accuracyRate >= threshold
            
        case .streakDays(let days):
            return userProgress.currentStreak >= days
            
        case .speedDemon(let targetTime):
            let allTimes = allQuestions.flatMap { $0.responseTimes }
            guard allTimes.count >= 20 else { return false }
            let avgTime = allTimes.reduce(0, +) / Double(allTimes.count)
            return avgTime <= targetTime
            
        case .perfectStreak(let count):
            return currentCombo >= count
            
        case .masterAllTables:
            return allQuestions.allSatisfy { $0.masteryScore >= 80.0 }
            
        case .reachLevel(let level):
            return userProgress.level >= level
        }
    }
    
    // MARK: - Session Management
    
    func startSession() {
        sessionStartTime = Date()
        sessionCorrectCount = 0
        sessionTotalCount = 0
        currentCombo = 0
        sessionXP = 0
        userProgress.updateStreak()
        try? modelContext.save()
    }
    
    func endSession() {
        if let startTime = sessionStartTime {
            let duration = Date().timeIntervalSince(startTime)
            userProgress.totalPlayTime += duration
        }
        try? modelContext.save()
    }
    
    // MARK: - Statistics
    
    func getMasteryByTable() -> [Int: Double] {
        var masteryByTable: [Int: [Double]] = [:]
        
        for question in allQuestions {
            masteryByTable[question.firstNumber, default: []].append(question.masteryScore)
        }
        
        return masteryByTable.mapValues { scores in
            scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        }
    }
    
    func getStrugglingQuestions() -> [MultiplicationQuestion] {
        allQuestions.filter { $0.isStruggling }.sorted { $0.masteryScore < $1.masteryScore }
    }
}

enum GameMode {
    case practice   // General practice with all questions
    case learning   // Adaptive focus on struggling questions
    case challenge  // Daily challenge mode
}
