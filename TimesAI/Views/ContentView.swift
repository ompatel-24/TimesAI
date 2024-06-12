import SwiftUI
import Combine

struct Question: Identifiable, Codable {
    let id: UUID
    let question: String
    var attempts: Int
    var correct: Int
    var correctAnswer: Int
    var correctCount: Int
    var wrongCount: Int
    var answerTimes: [TimeInterval]
    
    init(id: UUID = UUID(), question: String, attempts: Int = 0, correct: Int = 0, correctAnswer: Int, correctCount: Int = 0, wrongCount: Int = 0, answerTimes: [TimeInterval] = []) {
        self.id = id
        self.question = question
        self.attempts = attempts
        self.correct = correct
        self.correctAnswer = correctAnswer
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.answerTimes = answerTimes
    }
    
    enum CodingKeys: String, CodingKey {
        case id, question, attempts, correct, correctAnswer, correctCount, wrongCount, answerTimes
    }
}

class QuestionDataManager: ObservableObject {
    @Published var unaskedQuestions: [Question] = []
    @Published var askedQuestions: [Question] = []

    init() {
        loadQuestions()
    }

    func loadQuestions() {
        if let savedUnaskedQuestions = UserDefaults.standard.data(forKey: "unaskedQuestions"),
           let savedAskedQuestions = UserDefaults.standard.data(forKey: "askedQuestions") {
            if let decodedUnaskedQuestions = try? JSONDecoder().decode([Question].self, from: savedUnaskedQuestions),
               let decodedAskedQuestions = try? JSONDecoder().decode([Question].self, from: savedAskedQuestions) {
                unaskedQuestions = decodedUnaskedQuestions
                askedQuestions = decodedAskedQuestions
                return
            }
        }
        
        for i in 1...10 {
            for j in 1...10 {
                let questionText = "\(i) x \(j)"
                let correctAnswer = i * j
                
                if !questionExists(questionText) {
                    let question = Question(question: questionText, correctAnswer: correctAnswer)
                    unaskedQuestions.append(question)
                }
            }
        }
        saveQuestions()
    }

    func saveQuestions() {
        if let encodedUnasked = try? JSONEncoder().encode(unaskedQuestions),
           let encodedAsked = try? JSONEncoder().encode(askedQuestions) {
            UserDefaults.standard.set(encodedUnasked, forKey: "unaskedQuestions")
            UserDefaults.standard.set(encodedAsked, forKey: "askedQuestions")
        }
    }

    func updateQuestion(_ updatedQuestion: Question) {
        if let index = askedQuestions.firstIndex(where: { $0.id == updatedQuestion.id }) {
            askedQuestions[index] = updatedQuestion
            saveQuestions()
        }
    }

    private func questionExists(_ questionText: String) -> Bool {
        return unaskedQuestions.contains { $0.question == questionText } || askedQuestions.contains { $0.question == questionText }
    }
}

class TimerManager: ObservableObject {
    @Published var secondsElapsed = 0.0
    var timer: Timer?
    private var pauseTime: Date?

    func startTimer() {
        if let pauseTime = pauseTime {
            secondsElapsed += Date().timeIntervalSince(pauseTime)
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.secondsElapsed += 1
        }
        self.pauseTime = nil
    }
    
    func stopTimer() {
        timer?.invalidate()
        pauseTime = Date()
    }
    
    func resetTimer() {
        stopTimer()
        secondsElapsed = 0
    }
}

struct ContentView: View {
    @StateObject private var dataManager = QuestionDataManager()
    @StateObject private var timerManager = TimerManager()
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

    @State private var sessionCorrectAnswers = 0
    @State private var sessionWrongAnswers = 0
    @State private var sessionQuestionCount = 0

    let backC = UIColor(named: "Background") ?? UIColor.systemBackground

    var body: some View {
        TabView {
            mainView
                .tabItem {
                    Label("Main", systemImage: "house")
                }
                .tag(0)

            StruggleView(questions: dataManager.askedQuestions + dataManager.unaskedQuestions)
                .tabItem {
                    Label("Struggle", systemImage: "flame")
                }
                .tag(1)

            AllTimeStatisticsView(dataManager: dataManager)
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
                .tag(2)
        }
    }

    var mainView: some View {
        ZStack {
            Color(backC)
                .foregroundColor(.white)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text(formatTime(timerManager.secondsElapsed))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fontDesign(.serif)

                    ScoreView(points: $points, pointsColor: $pointsColor)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Button("Pause") {
                        isPaused.toggle()
                        timerManager.stopTimer()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer()
                if let currentQuestion = currentQuestion {
                    QuestionView(question: currentQuestion.question)
                    Spacer()
                    OptionsGrid(options: options, correctAnswer: currentQuestion.correctAnswer, handleAnswer: handleAnswer, showFlash: $showFlash, popIncorrect: $popIncorrect)
                    StatisticsView(correctCount: currentQuestion.correctCount, wrongCount: currentQuestion.wrongCount, answerTimes: currentQuestion.answerTimes)
                    Spacer()
                } else {
                    Text("Loading...")
                }
            }
            .disabled(isPaused || !sessionInPlay)
            .blur(radius: isPaused || !sessionInPlay ? 5 : 0)

            if isPaused {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Paused")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()

                    Button(action: {
                        isPaused.toggle()
                        timerManager.startTimer()
                    }) {
                        Text("Resume")
                            .font(.title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isPaused.toggle()
                        sessionStats.toggle()
                        timerManager.stopTimer()
                    }) {
                        Text("End Session")
                            .font(.title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
            }
            
            if !sessionInPlay {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Button(action: {
                        sessionInPlay.toggle()
                        reset()
                        timerManager.startTimer()
                    }) {
                        Text("Start Session")
                            .font(.title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
            }
            
            if sessionStats {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    SessionStatisticsView(dataManager: dataManager, timerManager: timerManager, sessionQuestionCount: sessionQuestionCount, sessionCorrectAnswers: sessionCorrectAnswers, sessionWrongAnswers: sessionWrongAnswers)
                    
                    Button(action: {
                        sessionStats.toggle()
                        sessionInPlay.toggle()
                        timerManager.resetTimer()
                        dataManager.loadQuestions()
                        points = 0
                        sessionCorrectAnswers = 0
                        sessionWrongAnswers = 0
                        sessionQuestionCount = 0
                    }) {
                        Text("Continue")
                            .font(.title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
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

    func reset() {
        if dataManager.unaskedQuestions.isEmpty {
            dataManager.unaskedQuestions = dataManager.askedQuestions
            dataManager.askedQuestions = []
        }

        guard !dataManager.unaskedQuestions.isEmpty else { return }

        let randomIndex = Int.random(in: 0..<dataManager.unaskedQuestions.count)
        currentQuestion = dataManager.unaskedQuestions.remove(at: randomIndex)
        dataManager.askedQuestions.append(currentQuestion!)
        dataManager.saveQuestions()

        if let currentQuestion = currentQuestion {
            var optionSet = Set<String>()
            optionSet.insert("\(currentQuestion.correctAnswer)")

            while optionSet.count < 3 {
                optionSet.insert("\(Int.random(in: max(currentQuestion.correctAnswer - 6, 1)...min(currentQuestion.correctAnswer + 6, 100)))")
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
        dataManager.updateQuestion(currentQuestion)
        self.currentQuestion = currentQuestion
    }

    func updateResult(isCorrect: Bool, question: inout Question) {
        if isCorrect {
            question.correct += 1
            question.correctCount += 1
            points += 1
            sessionCorrectAnswers += 1
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
            }
        }
        sessionQuestionCount += 1
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

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct OptionsGrid: View {
    var options: [String]
    var correctAnswer: Int
    var handleAnswer: (String) -> Void
    @Binding var showFlash: Bool
    @Binding var popIncorrect: Bool
    
    let buttonC = UIColor(named: "Buttons")
    let textC: UIColor? = UIColor(named: "Text")

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 3), alignment: .center, spacing: 20) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    handleAnswer(option)
                }) {
                    Text(option)
                        .padding()
                        .frame(width: 120, height: 120)
                        .background(flashColor(for: option))
                        .foregroundColor(Color(textC ?? .label))
                        .font(.title)
                        .fontWeight(.bold)
                        .cornerRadius(60)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .scaleEffect(popScale(for: option))
                        .opacity(popOpacity(for: option))
                }
                .padding(.vertical, 10)
            }
        }
    }

    private func flashColor(for option: String) -> Color {
        if showFlash && option == "\(correctAnswer)" {
            return Color.green.opacity(showFlash ? 0.5 : 1.0)
        } else {
            if let buttonColor = buttonC {
                return Color(buttonColor)
            } else {
                return Color.clear
            }
        }
    }

    private func popScale(for option: String) -> CGFloat {
        if popIncorrect && option != "\(correctAnswer)" {
            return 0.1
        } else {
            return 1.0
        }
    }

    private func popOpacity(for option: String) -> Double {
        if popIncorrect && option != "\(correctAnswer)" {
            return 0.0
        } else {
            return 1.0
        }
    }
}

struct ScoreView: View {
    @Binding var points: Int
    @Binding var pointsColor: Color
    
    var body: some View {
        Text("\(points)")
            .font(.largeTitle)
            .fontDesign(.serif)
            .fontWeight(.bold)
            .foregroundColor(pointsColor)
            .padding()
    }
}

struct QuestionView: View {
    let question: String
    
    var body: some View {
        Text("What is \(question)?")
            .font(.largeTitle)
            .fontDesign(.serif)
            .fontWeight(.bold)
            .foregroundColor(Color(UIColor.label))
            .padding()
    }
}

struct StatisticsView: View {
    let correctCount: Int
    let wrongCount: Int
    let answerTimes: [TimeInterval]
    
    var body: some View {
        VStack {
            HStack {
                Text("Correct: \(correctCount)")
                Text("Wrong: \(wrongCount)")
            }
            .font(.title3)
            .padding()
            .fontDesign(.serif)
            
            let averageTime = answerTimes.isEmpty ? 0 : answerTimes.reduce(0, +) / Double(answerTimes.count)
            Text("Average Time: \(String(format: "%.2f", averageTime))")
                .font(.title3)
                .padding()
                .fontDesign(.serif)
        }
    }
}

struct SessionStatisticsView: View {
    @ObservedObject var dataManager: QuestionDataManager
    @ObservedObject var timerManager: TimerManager

    let sessionQuestionCount: Int
    let sessionCorrectAnswers: Int
    let sessionWrongAnswers: Int
    
    var body: some View {
        VStack {
            Text("Session Statistics")
                .font(.largeTitle)
                .padding()
            
            let totalTime = timerManager.secondsElapsed
            let averageTime = sessionQuestionCount > 0 ? totalTime / Double(sessionQuestionCount) : 0.0
            
            Text("Questions Answered: \(sessionQuestionCount)")
            Text("Correct Answers: \(sessionCorrectAnswers)")
            Text("Wrong Answers: \(sessionWrongAnswers)")
            Text("Average Time: \(String(format: "%.2f", averageTime)) seconds")
            Text("Total Time: \(String(format: "%.0f", totalTime)) seconds")
        }
        .font(.title2)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

struct BalloonView: View {
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text("Correct!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
    }
}

struct CrossView: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
            
            Text("Incorrect!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.red)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0

        if scanner.scanHexInt64(&rgbValue) {
            let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            let blue = Double(rgbValue & 0x0000FF) / 255.0
            self.init(red: red, green: green, blue: blue)
            return
        }

        self.init(red: 0, green: 0, blue: 0)
    }
}

#Preview {
    ContentView()
}
