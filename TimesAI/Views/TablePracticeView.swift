//
//  TablePracticeView.swift
//  TimesAI
//
//  Created on 2025-10-21.
//

import SwiftUI
import SwiftData

struct TablePracticeView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    @State private var questionStartTime: Date?
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var isCorrectAnswer = false
    @State private var showParticles = false
    @State private var shakeOffset: CGFloat = 0
    @State private var questionsAnswered = 0
    @State private var correctAnswers = 0
    
    let tableNumber: Int
    
    var tableQuestions: [MultiplicationQuestion] {
        gameManager.allQuestions.filter { question in
            question.firstNumber == tableNumber || question.secondNumber == tableNumber
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.Colors.appBackground, AppTheme.Colors.secondary.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if gameManager.currentQuestion == nil {
                VStack(spacing: AppTheme.Spacing.xl) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.Colors.success)
                    
                    Text("Practice Complete!")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack {
                            Text("Correct:")
                                .font(AppTheme.Typography.headline)
                            Spacer()
                            Text("\(correctAnswers)/\(questionsAnswered)")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                        
                        HStack {
                            Text("Accuracy:")
                                .font(AppTheme.Typography.headline)
                            Spacer()
                            Text(String(format: "%.0f%%", questionsAnswered > 0 ? Double(correctAnswers) / Double(questionsAnswered) * 100 : 0))
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .fill(AppTheme.Colors.surface)
                    )
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Back to Weak Areas")
                            .font(AppTheme.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.Spacing.md)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                    .fill(AppTheme.Colors.primary)
                            )
                    }
                    .padding(.top, AppTheme.Spacing.lg)
                }
                .padding(AppTheme.Spacing.lg)
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(correctAnswers)/\(questionsAnswered)")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("\(tableNumber)× Table")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    
                    Spacer()
                    
                    // Question
                    if let question = gameManager.currentQuestion {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            Text(question.questionText)
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .offset(x: shakeOffset)
                            
                            Text("= ?")
                                .font(.system(size: 48, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(AppTheme.Spacing.xl)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                                .fill(AppTheme.Colors.surface)
                                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                        )
                        .padding(AppTheme.Spacing.lg)
                    }
                    
                    Spacer()
                    
                    // Answer buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(gameManager.questionOptions, id: \.self) { option in
                            answerButton(for: option)
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            
            if showParticles {
                ParticleEffectView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            startNewQuestion()
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
    
    private func startNewQuestion() {
        // Select from table-specific questions
        let tableQuestions = gameManager.allQuestions.filter { question in
            question.firstNumber == tableNumber || question.secondNumber == tableNumber
        }
        
        if !tableQuestions.isEmpty {
            gameManager.currentQuestion = tableQuestions.randomElement()
            if let question = gameManager.currentQuestion {
                gameManager.generateOptions(for: question)
            }
        }
        
        questionStartTime = Date()
        selectedAnswer = nil
        showFeedback = false
        isCorrectAnswer = false
        showParticles = false
    }
    
    private func handleAnswerSelection(_ answer: Int) {
        guard let startTime = questionStartTime,
              let question = gameManager.currentQuestion else { return }
        
        let responseTime = Date().timeIntervalSince(startTime)
        selectedAnswer = answer
        isCorrectAnswer = answer == question.answer
        showFeedback = true
        
        questionsAnswered += 1
        if isCorrectAnswer {
            correctAnswers += 1
            HapticManager.shared.success()
            showParticles = true
        } else {
            HapticManager.shared.error()
            shakeAnimation()
        }
        
        gameManager.submitAnswer(answer, responseTime: responseTime)
        
        // Continue or finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if questionsAnswered < 10 {
                withAnimation(AppTheme.Animations.smooth) {
                    startNewQuestion()
                }
            } else {
                withAnimation(AppTheme.Animations.smooth) {
                    gameManager.currentQuestion = nil
                }
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
    TablePracticeView(tableNumber: 7)
        .environmentObject(GameManager(modelContext: ModelContext(try! ModelContainer(for: UserProgress.self, MultiplicationQuestion.self))))
}
