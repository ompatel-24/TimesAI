import SwiftUI
import Combine

extension Question {
    var isStruggleQuestion: Bool {
        guard attempts > 0 else { return false }
        let correctRate = Double(correct) / Double(attempts)
        let averageTime = answerTimes.isEmpty ? 0 : answerTimes.reduce(0, +) / Double(answerTimes.count)
        return correctRate < 0.5 || averageTime > 10 // Customize the thresholds as needed
    }
}

class StruggleQuestionDataManager: ObservableObject {
    @Published var struggleQuestions: [Question] = []
    private var allQuestions: [Question]
    
    init(questions: [Question]) {
        self.allQuestions = questions
        filterStruggleQuestions()
    }
    
    func filterStruggleQuestions() {
        struggleQuestions = allQuestions.filter { $0.isStruggleQuestion }
    }
}

struct StruggleView: View {
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

    init(questions: [Question]) {
        _struggleDataManager = StateObject(wrappedValue: StruggleQuestionDataManager(questions: questions))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    ScoreView(points: $points, pointsColor: $pointsColor)
                    Spacer()
                    if let currentQuestion = currentQuestion {
                        QuestionView(question: currentQuestion.question)
                        Spacer()
                        OptionsGrid(options: options, correctAnswer: currentQuestion.correctAnswer, handleAnswer: handleAnswer, showFlash: $showFlash, popIncorrect: $popIncorrect)
                            .padding(.horizontal)
                            .colorInvert()
//                        Spacer()
                        StatisticsView(correctCount: currentQuestion.correctCount, wrongCount: currentQuestion.wrongCount, answerTimes: currentQuestion.answerTimes)
                        Spacer()
                    } else {
                        Text("Loading...")
                    }
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
                optionSet.insert("\(Int.random(in: max(currentQuestion.correctAnswer - 6, 0)...min(currentQuestion.correctAnswer + 6, 100)))")
            }
            
            options = Array(optionSet).shuffled()
        }
        
        questionStartTime = Date()
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
        } else {
            updateResult(isCorrect: false, question: &currentQuestion)
            showFlash = true
            flashCorrectAnswer()
        }
        self.currentQuestion = currentQuestion
    }

    func updateResult(isCorrect: Bool, question: inout Question) {
        if isCorrect {
            question.correct += 1
            question.correctCount += 1
            points += 1
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
            showingCross = true
            crossOffset = CGSize.zero
            withAnimation {
                pointsColor = .red
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    pointsColor = defaultPointsColor
                }
            }
        }
    }

    func flashCorrectAnswer() {
        let flashCount = 3
        let flashDuration: Double = 0.5
        
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

    func animateBalloon() {
        withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
            balloonOffset = CGSize(width: 0, height: -UIScreen.main.bounds.height)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingBalloon = false
//            reset()
        }
    }
    
    func animateCross() {
        withAnimation(Animation.easeInOut(duration: 1).delay(1)) {
            crossOffset = CGSize(width: 0, height: UIScreen.main.bounds.height)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCross = false
//            reset()
        }
    }
}


#Preview {
    ContentView()
}

