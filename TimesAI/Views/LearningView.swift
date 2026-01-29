//
//  LearningView.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import SwiftUI
import SwiftData

struct LearningView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var questionStartTime: Date?
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var isCorrectAnswer = false
    @State private var showParticles = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showExplanation = false
    
    @State private var strugglingQuestions: [MultiplicationQuestion] = []
    @State private var refreshTimer: Timer?
    
    var body: some View {
        ZStack {
            // Background gradient with warmer tone for learning
            LinearGradient(
                colors: [AppTheme.Colors.appBackground, AppTheme.Colors.warning.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if strugglingQuestions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Top bar with safe area consideration
                    VStack(spacing: 0) {
                        topBar
                    }
                    .padding(.top, AppTheme.Spacing.lg)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    Spacer()
                    
                    // Question card
                    if let question = gameManager.currentQuestion {
                        learningQuestionCard(question: question)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                    
                    Spacer()
                    
                    // Answer options
                    answerOptions
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    // Helper explanation
                    if showExplanation, let question = gameManager.currentQuestion {
                        explanationView(for: question)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            
            // Particle effects overlay
            if showParticles {
                ParticleEffectView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            refreshStrugglingQuestions()
            // Start a timer to refresh struggling questions periodically
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                refreshStrugglingQuestions()
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
    
    // MARK: - Components
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.Colors.success)
            
            Text("Amazing Work!")
                .font(AppTheme.Typography.largeTitle)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("You don't have any struggling questions right now. Keep practicing to maintain your mastery!")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .padding(AppTheme.Spacing.xl)
    }
    
    private var topBar: some View {
        HStack {
            // Learning mode indicator
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(AppTheme.Colors.warning)
                
                Text("Learning Mode")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .fill(AppTheme.Colors.warning.opacity(0.15))
            )
            
            Spacer()
            
            // Struggling questions count
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(strugglingQuestions.count)")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("to review")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .fill(AppTheme.Colors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 4)
            )
        }
    }
    
    private func learningQuestionCard(question: MultiplicationQuestion) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Mastery indicator with progress
            VStack(spacing: 8) {
                MasteryBadge(level: question.masteryLevel)
                
                // Mastery progress bar
                ProgressView(value: question.masteryScore, total: 100)
                    .tint(AppTheme.Colors.warning)
                    .scaleEffect(x: 1, y: 2)
            }
            
            // Question
            Text(question.questionText)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .offset(x: shakeOffset)
            
            Text("= ?")
                .font(.system(size: 48, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Stats
            HStack(spacing: AppTheme.Spacing.lg) {
                statPill(icon: "checkmark.circle", value: "\(Int(question.accuracyRate * 100))%", label: "Accuracy")
                statPill(icon: "clock", value: String(format: "%.1fs", question.averageResponseTime), label: "Avg Time")
            }
            
            // Helper button
            Button {
                withAnimation(AppTheme.Animations.smooth) {
                    showExplanation.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showExplanation ? "lightbulb.fill" : "lightbulb")
                    Text(showExplanation ? "Hide Hint" : "Show Hint")
                        .font(AppTheme.Typography.callout)
                }
                .foregroundColor(AppTheme.Colors.warning)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .stroke(AppTheme.Colors.warning, lineWidth: 2)
                )
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                .fill(AppTheme.Colors.surface)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        )
    }
    
    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(value)
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.semibold)
            }
            .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.Colors.appBackground)
        )
    }
    
    private func explanationView(for question: MultiplicationQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppTheme.Colors.warning)
                Text("Helpful Hint")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Text(generateHint(for: question))
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(AppTheme.Colors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func generateHint(for question: MultiplicationQuestion) -> String {
        let a = question.firstNumber
        let b = question.secondNumber
        
        // Special cases
        if a == 1 || b == 1 {
            return "Multiplying by 1 gives you the same number!"
        } else if a == 2 || b == 2 {
            return "Multiplying by 2 is like adding the number to itself. \(max(a,b)) + \(max(a,b)) = \(question.answer)"
        } else if a == 5 || b == 5 {
            return "Count by 5s: 5, 10, 15, 20..."
        } else if a == 10 || b == 10 {
            return "Multiplying by 10? Just add a zero! \(min(a,b)) × 10 = \(min(a,b))0"
        } else if a == b {
            return "This is a square number: \(a) × \(a) = \(question.answer)"
        } else {
            // General skip counting hint
            let smaller = min(a, b)
            let larger = max(a, b)
            var sequence = ""
            for i in 1...smaller {
                sequence += "\(larger * i)"
                if i < smaller {
                    sequence += ", "
                }
            }
            return "Count by \(larger)s: \(sequence)"
        }
    }
    
    private var answerOptions: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(gameManager.questionOptions, id: \.self) { option in
                answerButton(for: option)
            }
        }
    }
    
    private func answerButton(for option: Int) -> some View {
        Button {
            handleAnswerSelection(option)
        } label: {
            Text("\(option)")
        }
        .buttonStyle(AnswerButtonStyle(
            isCorrect: showFeedback && isCorrectAnswer && selectedAnswer == option,
            isWrong: showFeedback && !isCorrectAnswer && selectedAnswer == option
        ))
        .disabled(showFeedback)
    }
    
    // MARK: - Actions
    
    private func refreshStrugglingQuestions() {
        let newList = gameManager.getStrugglingQuestions()
        
        // Only update if the list has changed
        if newList.count != strugglingQuestions.count ||
            newList.map({ $0.id }) != strugglingQuestions.map({ $0.id }) {
            strugglingQuestions = newList
            
            // If we have questions and no current question, start one
            if !strugglingQuestions.isEmpty && gameManager.currentQuestion == nil {
                startNewQuestion()
            }
            // If we had questions but now we don't, clear current question
            else if strugglingQuestions.isEmpty {
                gameManager.currentQuestion = nil
            }
            // If current question is no longer in struggling list, get a new one
            else if !strugglingQuestions.contains(where: { $0.id == gameManager.currentQuestion?.id }) {
                startNewQuestion()
            }
        }
    }
    
    private func startNewQuestion() {
        // Select from struggling questions if available
        if !strugglingQuestions.isEmpty {
            // Prioritize questions that need review or have low mastery
            let sortedByNeed = strugglingQuestions.sorted { q1, q2 in
                if q1.needsReview != q2.needsReview {
                    return q1.needsReview
                }
                return q1.masteryScore < q2.masteryScore
            }
            gameManager.currentQuestion = sortedByNeed.first
        } else {
            // Fallback to learning mode selection
            gameManager.selectNextQuestion(mode: .learning)
        }
        
        if let question = gameManager.currentQuestion {
            gameManager.generateOptions(for: question)
        }
        
        questionStartTime = Date()
        selectedAnswer = nil
        showFeedback = false
        isCorrectAnswer = false
        showParticles = false
        showExplanation = false
    }
    
    private func handleAnswerSelection(_ answer: Int) {
        guard let startTime = questionStartTime,
              let question = gameManager.currentQuestion else { return }
        
        let responseTime = Date().timeIntervalSince(startTime)
        selectedAnswer = answer
        isCorrectAnswer = answer == question.answer
        showFeedback = true
        
        // Haptic feedback
        if isCorrectAnswer {
            HapticManager.shared.success()
            showParticles = true
        } else {
            HapticManager.shared.error()
            shakeAnimation()
        }
        
        // Submit answer
        gameManager.submitAnswer(answer, responseTime: responseTime)
        
        // Refresh struggling questions list
        refreshStrugglingQuestions()
        
        // Move to next question (with longer delay for learning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(AppTheme.Animations.smooth) {
                startNewQuestion()
            }
        }
    }
    
    private func shakeAnimation() {
        withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
            shakeOffset = 10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shakeOffset = 0
        }
    }
}

#Preview {
    LearningView()
        .environmentObject(GameManager(modelContext: ModelContext(try! ModelContainer(for: UserProgress.self, MultiplicationQuestion.self))))
}
