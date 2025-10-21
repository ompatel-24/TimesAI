//
//  PracticeView.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var questionStartTime: Date?
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var isCorrectAnswer = false
    @State private var showParticles = false
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppTheme.Colors.background, AppTheme.Colors.primary.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.lg) {
                // Top bar
                topBar
                
                Spacer()
                
                // Question card
                if let question = gameManager.currentQuestion {
                    questionCard(question: question)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
                
                Spacer()
                
                // Answer options
                answerOptions
                
                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            
            // Particle effects overlay
            if showParticles {
                ParticleEffectView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            startNewQuestion()
        }
    }
    
    // MARK: - Components
    
    private var topBar: some View {
        HStack {
            // Combo counter
            ComboView(combo: gameManager.currentCombo)
            
            Spacer()
            
            // Session stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(gameManager.sessionCorrectCount)/\(gameManager.sessionTotalCount)")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("+\(gameManager.sessionXP) XP")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.accent)
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
    
    private func questionCard(question: MultiplicationQuestion) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Mastery indicator
            MasteryBadge(level: question.masteryLevel)
            
            // Question
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
    
    private func startNewQuestion() {
        gameManager.selectNextQuestion(mode: .practice)
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
        
        // Move to next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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

// MARK: - Supporting Views

struct ComboView: View {
    let combo: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(comboColor)
                .scaleEffect(combo > 0 ? 1.2 : 1.0)
                .animation(AppTheme.Animations.bouncy, value: combo)
            
            Text("\(combo)")
                .font(AppTheme.Typography.title2)
                .foregroundColor(comboColor)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(comboBackgroundColor)
                .shadow(color: comboColor.opacity(0.3), radius: combo > 5 ? 8 : 0)
        )
    }
    
    private var comboColor: Color {
        switch combo {
        case 0: return AppTheme.Colors.textTertiary
        case 1...4: return AppTheme.Colors.warning
        case 5...9: return AppTheme.Colors.secondary
        default: return AppTheme.Colors.error
        }
    }
    
    private var comboBackgroundColor: Color {
        combo > 0 ? comboColor.opacity(0.15) : AppTheme.Colors.surface
    }
}

struct MasteryBadge: View {
    let level: MasteryLevel
    
    var body: some View {
        HStack(spacing: 6) {
            Text(level.emoji)
                .font(.system(size: 16))
            
            Text(level.rawValue)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(level.color))
        )
    }
}

struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(AppTheme.Colors.success)
                    .frame(width: 10, height: 10)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<20 {
            let particle = Particle(
                x: screenWidth / 2 + CGFloat.random(in: -50...50),
                y: screenHeight / 2 + CGFloat.random(in: -50...50),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0
            )
            particles.append(particle)
        }
        
        withAnimation(.easeOut(duration: 1.0)) {
            for i in particles.indices {
                particles[i].y -= CGFloat.random(in: 100...200)
                particles[i].x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
                particles[i].scale *= 1.5
            }
        }
    }
}

// MARK: - Haptic Manager

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    PracticeView()
        .environmentObject(GameManager(modelContext: ModelContext(try! ModelContainer(for: UserProgress.self, MultiplicationQuestion.self))))
}
