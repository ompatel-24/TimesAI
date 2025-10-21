//
//  StatsView.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import SwiftUI
import Charts
import SwiftData

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
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.appBackground.ignoresSafeArea())
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
                        .fill(AppTheme.Colors.appBackground)
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Times Tables Mastery")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Mastery combines accuracy, speed, and consistency")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
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
                
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.warning)
                    
                    Text("\(gameManager.userProgress.unlockedAchievements.count)/\(Achievement.allAchievements.count)")
                        .font(AppTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.warning.opacity(0.15))
                )
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
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
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked 
                        ? LinearGradient(
                            colors: [AppTheme.Colors.warning.opacity(0.3), AppTheme.Colors.accent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [AppTheme.Colors.appBackground, AppTheme.Colors.appBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(
                                isUnlocked ? AppTheme.Colors.warning.opacity(0.3) : AppTheme.Colors.textTertiary.opacity(0.2),
                                lineWidth: 2
                            )
                    )
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(isUnlocked ? AppTheme.Colors.warning : AppTheme.Colors.textTertiary)
                
                // Shine effect for unlocked achievements
                if isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.3), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                }
            }
            
            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(isUnlocked ? .semibold : .regular)
                    .foregroundColor(isUnlocked ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !isUnlocked {
                    Text("Locked")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
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
}

#Preview {
    StatsView()
        .environmentObject(GameManager(modelContext: ModelContext(try! ModelContainer(for: UserProgress.self, MultiplicationQuestion.self))))
}
