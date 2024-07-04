import SwiftUI

struct AllTimeStatisticsView: View {
    @EnvironmentObject var dataManager: QuestionDataManager
    
    let backC = UIColor(named: "Color") ?? UIColor.systemBackground

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                List {
                    Section(header: Text("Questions Statistics").font(.headline)) {
                        StatisticRow(label: "Total Questions Attempted", value: "\(totalQuestionsAttempted())")
                        StatisticRow(label: "Total Correct Answers", value: "\(totalCorrectAnswers())")
                        StatisticRow(label: "Total Wrong Answers", value: "\(totalWrongAnswers())")
                        StatisticRow(label: "Average Answer Time", value: "\(String(format: "%.2f", averageAnswerTime())) seconds")
                    }
                    
                    Section(header: Text("Top 5 Most Difficult Questions").font(.headline)) {
                        ForEach(topDifficultQuestions(), id: \.id) { question in
                            DifficultQuestionRow(question: question)
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
            .navigationTitle("Statistics")
        }
    }

    private func totalQuestionsAttempted() -> Int {
        return dataManager.askedQuestions.reduce(0) { $0 + $1.attempts }
    }

    private func totalCorrectAnswers() -> Int {
        return dataManager.askedQuestions.reduce(0) { $0 + $1.correct }
    }

    private func totalWrongAnswers() -> Int {
        return dataManager.askedQuestions.reduce(0) { $0 + $1.wrongCount }
    }

    private func averageAnswerTime() -> Double {
        let allTimes = dataManager.askedQuestions.flatMap { $0.answerTimes }
        guard !allTimes.isEmpty else { return 0.0 }
        let totalTime = allTimes.reduce(0, +)
        return totalTime / Double(allTimes.count)
    }

    private func topDifficultQuestions() -> [Question] {
        return Array(dataManager.askedQuestions
            .sorted { $0.wrongCount > $1.wrongCount }
            .prefix(5))
    }
}

struct StatisticRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 5)
    }
}

struct DifficultQuestionRow: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(question.question)
                .font(.body)
                .fontWeight(.bold)
            HStack {
                Text("Correct: \(question.correctCount)")
                Text("Wrong: \(question.wrongCount)")
                Spacer()
                Text("Avg Time: \(String(format: "%.2f", averageTime())) s")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
    
    private func averageTime() -> Double {
        guard !question.answerTimes.isEmpty else { return 0.0 }
        let totalTime = question.answerTimes.reduce(0, +)
        return totalTime / Double(question.answerTimes.count)
    }
}

#Preview {
    ContentView()
        .environmentObject(QuestionDataManager())
        .environmentObject(StarsDataManager())
}
