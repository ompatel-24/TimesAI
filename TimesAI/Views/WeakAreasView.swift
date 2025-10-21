//
//  WeakAreasView.swift
//  TimesAI
//
//  Created on 2025-10-21.
//

import SwiftUI
import SwiftData

// MARK: - Practice Set Model
struct PracticeSet: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let type: SetType
    
    enum SetType {
        case daily
        case hard
        case table(Int)
    }
}

// MARK: - Seeded Random Generator (for daily sets)
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Main Drawer View
struct WeakAreasView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var gameManager: GameManager?
    
    private var practiceSets: [PracticeSet] {
        var sets: [PracticeSet] = [
            PracticeSet(
                title: "Daily Set",
                subtitle: "Fresh challenges every day",
                icon: "calendar.badge.clock",
                color: .blue,
                type: .daily
            ),
            PracticeSet(
                title: "Hard Set",
                subtitle: "Your struggling questions",
                icon: "flame.fill",
                color: .orange,
                type: .hard
            )
        ]
        
        // Add individual table sets (1-12)
        for i in 1...12 {
            sets.append(PracticeSet(
                title: "\(i)× Times Table",
                subtitle: "Practice multiplication by \(i)",
                icon: "number.square.fill",
                color: tableColor(for: i),
                type: .table(i)
            ))
        }
        
        return sets
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Header
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Practice Sets")
                                .font(AppTheme.Typography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("Choose a set to start practicing")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.md)
                        
                        // Practice sets grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                            GridItem(.flexible(), spacing: AppTheme.Spacing.md)
                        ], spacing: AppTheme.Spacing.md) {
                            ForEach(practiceSets) { set in
                                NavigationLink(destination: destinationView(for: set)) {
                                    SetCard(set: set)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if gameManager == nil {
                gameManager = GameManager(modelContext: modelContext)
            }
        }
    }
    
    private func tableColor(for number: Int) -> Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .mint, .teal,
            .cyan, .blue, .indigo, .purple, .pink, .brown
        ]
        return colors[(number - 1) % colors.count]
    }
    
    @ViewBuilder
    private func destinationView(for set: PracticeSet) -> some View {
        if let manager = gameManager {
            SetPracticeView(set: set, gameManager: manager)
        } else {
            Text("Loading...")
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Set Card
struct SetCard: View {
    let set: PracticeSet
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            // Simple title
            Text(displayTitle)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(set.color)
            
            // Subtitle (only for special sets)
            if case .daily = set.type {
                Text("Daily")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            } else if case .hard = set.type {
                Text("Hard")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(set.color.opacity(0.1))
        )
    }
    
    private var displayTitle: String {
        switch set.type {
        case .daily:
            return "📅"
        case .hard:
            return "🔥"
        case .table(let number):
            return "×\(number)"
        }
    }
}

// MARK: - Set Practice View
struct SetPracticeView: View {
    let set: PracticeSet
    @ObservedObject var gameManager: GameManager
    
    @State private var currentQuestion: MultiplicationQuestion?
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var correctCount = 0
    @State private var questionCount = 0
    @State private var answerOptions: [Int] = []
    @State private var answerStartTime: Date?
    @State private var questionScale: CGFloat = 0.8
    @State private var questionOpacity: Double = 0
    @State private var showCompletion = false
    @State private var askedQuestions: Set<String> = []
    @State private var autoAdvanceTask: DispatchWorkItem?
    @State private var showParticles = false
    @Environment(\.dismiss) private var dismiss
    
    private let maxQuestions = 10
    
    private var questions: [MultiplicationQuestion] {
        switch set.type {
        case .daily:
            // Random 10 questions seeded by today's date
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            var generator = SeededRandomNumberGenerator(seed: UInt64(today.timeIntervalSince1970))
            let allQuestions = Array(gameManager.allQuestions)
            return allQuestions.shuffled(using: &generator)
            
        case .hard:
            return Array(gameManager.allQuestions).filter { $0.isStruggling }
            
        case .table(let number):
            return Array(gameManager.allQuestions).filter { $0.firstNumber == number || $0.secondNumber == number }
        }
    }
    
    private var progress: Double {
        guard maxQuestions > 0 else { return 0 }
        return Double(questionCount) / Double(maxQuestions)
    }
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    set.color.opacity(0.05),
                    AppTheme.Colors.appBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if questions.isEmpty {
                emptyStateView
            } else if showCompletion {
                completionView
                    .transition(.scale.combined(with: .opacity))
            } else if let question = currentQuestion {
                questionView(question)
            }
            
            // Particle effects overlay
            if showParticles {
                ParticleEffectView()
                    .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Text(setEmoji)
                        .font(.title3)
                    Text(setTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(set.color)
                }
            }
        }
        .onAppear {
            if currentQuestion == nil {
                loadNextQuestion()
            }
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: set.icon)
                .font(.system(size: 64))
                .foregroundColor(set.color.opacity(0.5))
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("No Questions Available")
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(emptyMessage)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppTheme.Spacing.xl)
    }
    
    private var emptyMessage: String {
        switch set.type {
        case .hard:
            return "Keep practicing! This set unlocks\nwhen you get questions wrong."
        default:
            return "No questions found for this set."
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // Animated trophy
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [set.color.opacity(0.3), set.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Text("🏆")
                    .font(.system(size: 70))
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Amazing!")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("\(correctCount) out of \(maxQuestions) correct")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                // Accuracy percentage with color
                let percentage = Int(Double(correctCount) * 100 / Double(maxQuestions))
                HStack(spacing: 8) {
                    Text("\(percentage)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(percentage >= 80 ? .green : percentage >= 60 ? .orange : .red)
                    
                    Text("Accuracy")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                Button(action: restart) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Practice Again")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [set.color, set.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                }
                
                Button(action: { dismiss() }) {
                    Text("Back to Sets")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(set.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(set.color.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }
    
    // MARK: - Question View
    @ViewBuilder
    private func questionView(_ question: MultiplicationQuestion) -> some View {
        VStack(spacing: 0) {
            // Animated progress bar
            progressBar
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
            
            Spacer()
            
            // Question with slide-in animation
            VStack(spacing: AppTheme.Spacing.lg) {
                HStack(spacing: 12) {
                    Text("\(question.firstNumber)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(set.color)
                    
                    Text("×")
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("\(question.secondNumber)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(set.color)
                }
                .scaleEffect(questionScale)
                .opacity(questionOpacity)
            }
            
            Spacer()
            
            // Answer options grid with stagger animation
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md)
            ], spacing: AppTheme.Spacing.md) {
                ForEach(Array(answerOptions.enumerated()), id: \.element) { index, option in
                    answerButton(option, correctAnswer: question.answer, index: index)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
            .disabled(showFeedback)
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(questionCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(set.color)
                + Text(" / \(maxQuestions)")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                    Text("\(correctCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            }
            
            // Progress bar with animation
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(set.color.opacity(0.15))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [set.color, set.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 10)
        }
    }
    
    // MARK: - Answer Button
    private func answerButton(_ answer: Int, correctAnswer: Int, index: Int) -> some View {
        let isSelected = selectedAnswer == answer
        let isCorrect = answer == correctAnswer
        let isWrong = isSelected && !isCorrect
        
        return Button(action: {
            guard selectedAnswer == nil else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                handleAnswer(answer, correctAnswer: correctAnswer)
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(buttonBackground(isCorrect: isCorrect, isWrong: isWrong))
                    .shadow(
                        color: buttonShadow(isCorrect: isCorrect, isWrong: isWrong),
                        radius: showFeedback && (isCorrect || isWrong) ? 16 : 4,
                        y: showFeedback && (isCorrect || isWrong) ? 8 : 2
                    )
                
                Text("\(answer)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .frame(height: 130)
            .scaleEffect(isSelected && showFeedback ? 1.02 : 1.0)
            .opacity(showFeedback && !isCorrect && !isSelected ? 0.5 : 1.0)
        }
        .buttonStyle(BounceButtonStyle())
    }
    
    private func buttonBackground(isCorrect: Bool, isWrong: Bool) -> Color {
        if showFeedback && isCorrect {
            return Color.green
        } else if showFeedback && isWrong {
            return Color.red
        } else {
            return AppTheme.Colors.surface
        }
    }
    
    private func buttonShadow(isCorrect: Bool, isWrong: Bool) -> Color {
        if showFeedback && isCorrect {
            return Color.green.opacity(0.4)
        } else if showFeedback && isWrong {
            return Color.red.opacity(0.4)
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    private var setEmoji: String {
        switch set.type {
        case .daily: return "📅"
        case .hard: return "🔥"
        case .table: return "×"
        }
    }
    
    private var setTitle: String {
        switch set.type {
        case .daily: return "Daily Set"
        case .hard: return "Hard Set"
        case .table(let number): return "×\(number) Table"
        }
    }
    
    // MARK: - Actions
    private func loadNextQuestion() {
        guard questionCount < maxQuestions else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCompletion = true
            }
            return
        }
        guard !questions.isEmpty else { return }
        
        // Reset animations
        questionScale = 0.8
        questionOpacity = 0
        
        // Get next question that hasn't been asked
        let availableQuestions = questions.filter { question in
            let key = "\(question.firstNumber)×\(question.secondNumber)"
            return !askedQuestions.contains(key)
        }
        
        // If all questions asked, clear history and continue
        if availableQuestions.isEmpty {
            askedQuestions.removeAll()
        }
        
        guard let nextQuestion = (availableQuestions.isEmpty ? questions : availableQuestions).randomElement() else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCompletion = true
            }
            return
        }
        
        let questionKey = "\(nextQuestion.firstNumber)×\(nextQuestion.secondNumber)"
        askedQuestions.insert(questionKey)
        
        gameManager.currentQuestion = nextQuestion
        currentQuestion = nextQuestion
        
        // Generate answer options
        answerOptions = generateAnswerOptions(correctAnswer: nextQuestion.answer)
        
        // Reset state
        selectedAnswer = nil
        showFeedback = false
        showParticles = false
        answerStartTime = Date()
        
        // Animate question entrance
        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            questionScale = 1.0
            questionOpacity = 1.0
        }
    }
    
    private func generateAnswerOptions(correctAnswer: Int) -> [Int] {
        var options = Set<Int>([correctAnswer])
        
        let range = max(2, correctAnswer / 3)...min(144, correctAnswer * 2)
        
        while options.count < 4 {
            let wrongAnswer = Int.random(in: range)
            if wrongAnswer != correctAnswer {
                options.insert(wrongAnswer)
            }
        }
        
        return Array(options).shuffled()
    }
    
    private func handleAnswer(_ answer: Int, correctAnswer: Int) {
        selectedAnswer = answer
        
        let responseTime = answerStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // Submit answer using gameManager's method
        gameManager.submitAnswer(answer, responseTime: responseTime)
        
        // Update stats
        questionCount += 1
        let isCorrect = answer == correctAnswer
        if isCorrect {
            correctCount += 1
        }
        
        // Haptic feedback and particles
        if isCorrect {
            HapticManager.shared.success()
            showParticles = true
        } else {
            HapticManager.shared.error()
        }
        
        handleFeedback()
    }
    
    private func handleFeedback() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showFeedback = true
        }
        
        // Cancel any existing auto-advance task
        autoAdvanceTask?.cancel()
        
        // Auto-advance after delay
        let task = DispatchWorkItem { [weak gameManager] in
            guard gameManager != nil else { return }
            loadNextQuestion()
        }
        autoAdvanceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
    }
    
    private func restart() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showCompletion = false
            currentQuestion = nil
            selectedAnswer = nil
            showFeedback = false
            correctCount = 0
            questionCount = 0
            answerOptions = []
            questionScale = 0.8
            questionOpacity = 0
            askedQuestions.removeAll()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadNextQuestion()
        }
    }
}

// MARK: - Bounce Button Style
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    WeakAreasView()
}
