import SwiftUI
import Combine

protocol QuestionManaging: ObservableObject {
    var askedQuestions: [Question] { get }
    var unaskedQuestions: [Question] { get }
}

class StruggleQuestionDataManager: ObservableObject {
    @Published var struggleQuestions: [Question] = []
    private var allQuestions: [Question]
    
    var askedQuestions: [Question] { struggleQuestions }
    var unaskedQuestions: [Question] { [] }
    
    init(questions: [Question]) {
        self.allQuestions = questions
        filterStruggleQuestions()
    }
    
    func filterStruggleQuestions() {
        struggleQuestions = allQuestions.filter { $0.isStruggleQuestion }
    }

    func refreshData(with questions: [Question]) {
        self.allQuestions = questions
        filterStruggleQuestions()
    }
}

struct StruggleView: View {
    @EnvironmentObject var dataManager: QuestionDataManager
    @EnvironmentObject var starsDataManager: StarsDataManager
    @StateObject private var struggleDataManager: StruggleQuestionDataManager
    @State private var showingBalloon = false
    @State private var balloonOffset = CGSize.zero
    @State private var showingCross = false
    @State private var crossOffset = CGSize.zero
    @State private var currentQuestion: Question? = nil
    @State private var options = [String]()
    @State private var selectedOption = ""
    @State private var points = 0
    @State private var pointsColor = Color(UIColor.label)
    @State private var defaultPointsColor = Color(UIColor.label)
    @State private var questionStartTime: Date?
    @State private var showFlash = false
    @State private var popIncorrect = false
    @State private var isPaused = false
    @State private var sessionInPlay = false
    @State private var sessionStats = false
    @State private var sessionWrongAnswers = 0
    @State private var sessionQuestionCount = 0
    @State private var secondChance = false
    @State private var showAlert = false

    init(questions: [Question]) {
        _struggleDataManager = StateObject(wrappedValue: StruggleQuestionDataManager(questions: questions))
    }

    var body: some View {
        ZStack {
            Color(UIColor.background)
                .ignoresSafeArea()

            VStack {
                HStack {
                    StarsView(sessionCorrectAnswers: starsDataManager.sessionCorrectAnswers)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Button("Pause") {
                        isPaused.toggle()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .fontDesign(.serif)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(10)
                }

                Spacer()
                if let currentQuestion = currentQuestion {
                    QuestionView(question: currentQuestion.question)
                    Spacer()
                    OptionsGrid(options: options, correctAnswer: currentQuestion.correctAnswer, handleAnswer: handleAnswer, showFlash: $showFlash, popIncorrect: $popIncorrect)
                    StatisticsView(correctCount: currentQuestion.correctCount, wrongCount: currentQuestion.wrongCount, answerTimes: currentQuestion.answerTimes)
                    Spacer()
                }
            }
            .disabled(isPaused || !sessionInPlay)
            .blur(radius: isPaused || !sessionInPlay ? 5 : 0)

            if isPaused {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Text("PAUSED")
                        .font(Font.custom("BigillaBold", size: 50))
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .foregroundColor(.white)
                        .padding()

                    Button(action: {
                        isPaused.toggle()
                        reset()
                    }) {
                        Text("Resume")
                            .font(.title)
                            .padding()
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        isPaused.toggle()
                        sessionStats.toggle()
                    }) {
                        Text("End Session")
                            .font(.title)
                            .padding()
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(10)
                    }
                }
                .font(Font.custom("BigillaBold", size: 50))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding()
                .background(AppTheme.Colors.primary)
                .cornerRadius(10)
            }

            if !sessionInPlay {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Button(action: {
                        if struggleDataManager.struggleQuestions.isEmpty {
                            showAlert.toggle()
                        } else {
                            sessionInPlay.toggle()
                            reset()
                        }
                    }) {
                        Text("start session")
                            .font(Font.custom("BigillaBold", size: 50))
                            .padding()
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(10)
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("No Struggle Questions"), message: Text("Please answer some questions in the main view to generate struggle questions."), dismissButton: .default(Text("OK")))
                }
            }

            if sessionStats {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    SessionStatisticsView(sessionQuestionCount: sessionQuestionCount, sessionCorrectAnswers: starsDataManager.sessionCorrectAnswers, sessionWrongAnswers: sessionWrongAnswers)
                    
                    Button(action: {
                        sessionStats.toggle()
                        sessionInPlay.toggle()
                        dataManager.loadQuestions()
                        points = 0
                        starsDataManager.sessionCorrectAnswers = 0
                        sessionWrongAnswers = 0
                        sessionQuestionCount = 0
                    }) {
                        Text("continue")
                            .font(Font.custom("BigillaBold", size: 50))
                            .padding()
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(10)
                    }
                }
                .font(Font.custom("BigillaBold", size: 50))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding()
                .background(AppTheme.Colors.primary)
                .cornerRadius(10)
            }

            if showingBalloon {
                BalloonView()
                    .offset(balloonOffset)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut(duration: 1), value: showingBalloon)
                    .onAppear {
                        animateBalloon()
                    }
            }

            if showingCross {
                CrossView()
                    .offset(crossOffset)
                    .transition(.move(edge: .top))
                    .animation(.easeInOut(duration: 1), value: showingCross)
                    .onAppear {
                        animateCross()
                    }
            }
        }
        .onAppear {
            reset()
        }
        .onAppear {
            struggleDataManager.refreshData(with: dataManager.askedQuestions)
        }
    }

    func reset() {
        guard !struggleDataManager.struggleQuestions.isEmpty else { return }

        let randomIndex = Int.random(in: 0..<struggleDataManager.struggleQuestions.count)
        currentQuestion = struggleDataManager.struggleQuestions.remove(at: randomIndex)
        struggleDataManager.filterStruggleQuestions()

        if let currentQuestion = currentQuestion {
            var optionSet = Set<String>()
            optionSet.insert("\(currentQuestion.correctAnswer)")

            while optionSet.count < 3 {
                optionSet.insert("\(Int.random(in: max(currentQuestion.correctAnswer - 6, 1)...min(currentQuestion.correctAnswer + 6, 100)))")
            }

            options = Array(optionSet).shuffled()
        }

        questionStartTime = Date()
        secondChance = false
    }

    func handleAnswer(_ selectedOption: String) {
        guard var currentQuestion = currentQuestion else { return }
        self.selectedOption = selectedOption
        currentQuestion.attempts += 1

        if let startTime = questionStartTime {
            let answerTime = Date().timeIntervalSince(startTime)
            currentQuestion.answerTimes.append(answerTime)
        }

        if "\(currentQuestion.correctAnswer)" == selectedOption {
            updateResult(isCorrect: true, question: &currentQuestion)
            popIncorrectOptions()
        } else if !secondChance {
            secondChance = true
            showFlash = true
            removeOneIncorrectOption()
        } else {
            updateResult(isCorrect: false, question: &currentQuestion)
            flashCorrectAnswer()
        }
        self.currentQuestion = currentQuestion
    }

    func updateResult(isCorrect: Bool, question: inout Question) {
        print("Updating result: \(isCorrect ? "Correct" : "Wrong") for question: \(question.question)")
        if isCorrect {
            question.correct += 1
            question.correctCount += 1
            points += 1
            starsDataManager.sessionCorrectAnswers += 1
            showingBalloon = true
            balloonOffset = CGSize.zero
            withAnimation {
                pointsColor = .green
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    pointsColor = defaultPointsColor
                }
            }
        } else {
            question.wrongCount += 1
            sessionWrongAnswers += 1
            showingCross = true
            crossOffset = CGSize.zero
            withAnimation {
                pointsColor = .red
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    pointsColor = defaultPointsColor
                }
                reset()
            }
        }
        sessionQuestionCount += 1
        print("Session stats: \(sessionQuestionCount), Points: \(points), Correct: \(starsDataManager.sessionCorrectAnswers), Wrong: \(sessionWrongAnswers)")
    }

    func flashCorrectAnswer() {
        let flashCount = 3
        let flashDuration = 0.2

        for i in 0..<flashCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + (flashDuration * 2 * Double(i))) {
                withAnimation {
                    showFlash = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (flashDuration * 2 * Double(i) + flashDuration)) {
                withAnimation {
                    showFlash = false
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (flashDuration * 2 * Double(flashCount))) {
            reset()
        }
    }

    func popIncorrectOptions() {
        withAnimation {
            popIncorrect = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            popIncorrect = false
            reset()
        }
    }

    func removeOneIncorrectOption() {
        guard let currentQuestion = currentQuestion else { return }
        if let incorrectOptionIndex = options.firstIndex(where: { $0 != "\(currentQuestion.correctAnswer)" }) {
            options.remove(at: incorrectOptionIndex)
        }
    }

    func animateBalloon() {
        withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
            balloonOffset = CGSize(width: 0, height: -UIScreen.main.bounds.height)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingBalloon = false
        }
    }

    func animateCross() {
        withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
            crossOffset = CGSize(width: 0, height: UIScreen.main.bounds.height)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCross = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(QuestionDataManager())
        .environmentObject(StarsDataManager())
}
