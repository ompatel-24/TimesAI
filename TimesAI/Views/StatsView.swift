//
//  StatsView.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Overall stats cards
                    overallStatsSection
                    
                    // Mastery heatmap
                    masteryHeatmapSection
                    
                    // Achievements
                    achievementsSection
                    
                    // Streak calendar
                    streakSection
                    
                    // Struggling questions
                    strugglingQuestionsSection
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Your Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Overall Stats
    
    private var overallStatsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                statCard(
                    title: "Level",
                    value: "\(gameManager.userProgress.level)",
                    icon: "star.fill",
                    color: AppTheme.Colors.warning
                )
                
                statCard(
                    title: "Total XP",
                    value: "\(gameManager.userProgress.totalXP)",
                    icon: "bolt.fill",
                    color: AppTheme.Colors.accent
                )
            }
            
            HStack(spacing: AppTheme.Spacing.md) {
                statCard(
                    title: "Accuracy",
                    value: "\(Int(gameManager.userProgress.accuracyRate * 100))%",
                    icon: "target",
                    color: AppTheme.Colors.success
                )
                
                statCard(
                    title: "Questions",
                    value: "\(gameManager.userProgress.totalQuestionsAnswered)",
                    icon: "number",
                    color: AppTheme.Colors.info
                )
            }
            
            // XP Progress bar
            xpProgressCard
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(AppTheme.Colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
    }
    
    private var xpProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Level \(gameManager.userProgress.level)")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(gameManager.userProgress.totalXP) / \(gameManager.userProgress.xpToNextLevel) XP")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                        .fill(AppTheme.Colors.background)
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.warning, AppTheme.Colors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(gameManager.userProgress.totalXP) / CGFloat(gameManager.userProgress.xpToNextLevel),
                            height: 12
                        )
                }
            }
            .frame(height: 12)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(AppTheme.Colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
    }
    
    // MARK: - Mastery Heatmap
    
    private var masteryHeatmapSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Times Tables Mastery")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            let masteryByTable = gameManager.getMasteryByTable()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(1...12, id: \.self) { table in
                    let mastery = masteryByTable[table] ?? 0
                    
                    VStack(spacing: 4) {
                        Text("\(table)×")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Circle()
                            .fill(masteryColor(for: mastery))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("\(Int(mastery))")
                                    .font(AppTheme.Typography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            
            // Legend
            HStack(spacing: AppTheme.Spacing.md) {
                legendItem(color: AppTheme.Colors.error, label: "0-20")
                legendItem(color: AppTheme.Colors.warning, label: "20-60")
                legendItem(color: AppTheme.Colors.info, label: "60-80")
                legendItem(color: AppTheme.Colors.success, label: "80-100")
            }
            .padding(.top, 8)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(AppTheme.Colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
    }
    
    private func masteryColor(for score: Double) -> Color {
        switch score {
        case 0..<20: return AppTheme.Colors.error
        case 20..<60: return AppTheme.Colors.warning
        case 60..<80: return AppTheme.Colors.info
        default: return AppTheme.Colors.success
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Achievements
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Achievements")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(gameManager.userProgress.unlockedAchievements.count)/\(Achievement.allAchievements.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Achievement.allAchievements) { achievement in
                    achievementBadge(achievement, isUnlocked: gameManager.userProgress.unlockedAchievements.contains(achievement.id))
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(AppTheme.Colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
    }
    
    private func achievementBadge(_ achievement: Achievement, isUnlocked: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? AppTheme.Colors.warning.opacity(0.2) : AppTheme.Colors.background)
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? AppTheme.Colors.warning : AppTheme.Colors.textTertiary)
            }
            
            Text(achievement.title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(isUnlocked ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
    
    // MARK: - Streak
    
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Current Streak")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            HStack(spacing: AppTheme.Spacing.xl) {
                streakCard(
                    value: "\(gameManager.userProgress.currentStreak)",
                    label: "Days",
                    icon: "flame.fill",
                    color: AppTheme.Colors.secondary
                )
                
                Divider()
                    .frame(height: 60)
                
                streakCard(
                    value: "\(gameManager.userProgress.longestStreak)",
                    label: "Best",
                    icon: "trophy.fill",
                    color: AppTheme.Colors.warning
                )
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(AppTheme.Colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
    }
    
    private func streakCard(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Struggling Questions
    
    private var strugglingQuestionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Questions to Review")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            let strugglingQuestions = gameManager.getStrugglingQuestions().prefix(5)
            
            if strugglingQuestions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.Colors.success)
                        
                        Text("All caught up!")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(AppTheme.Spacing.xl)
                    Spacer()
                }
            } else {
                ForEach(Array(strugglingQuestions)) { question in
                    strugglingQuestionRow(question)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(AppTheme.Colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
    }
    
    private func strugglingQuestionRow(_ question: MultiplicationQuestion) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Question
            Text(question.questionText)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .frame(width: 80, alignment: .leading)
            
            // Mastery bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.background)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(masteryColor(for: question.masteryScore))
                        .frame(
                            width: geometry.size.width * CGFloat(question.masteryScore / 100),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
            
            // Mastery score
            Text("\(Int(question.masteryScore))%")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                .fill(AppTheme.Colors.background)
        )
    }
}

#Preview {
    StatsView()
        .environmentObject(GameManager(modelContext: ModelContext(try! ModelContainer(for: UserProgress.self, MultiplicationQuestion.self))))
}
