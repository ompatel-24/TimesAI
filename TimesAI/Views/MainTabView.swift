//
//  MainTabView.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedTab = 0
    @State private var showLevelUpCelebration = false
    @State private var showAchievementPopup = false
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .transition(.move(edge: .trailing))
            } else {
                mainContent
            }
        }
        .onAppear {
            // Show onboarding if user has never played
            if gameManager.userProgress.totalQuestionsAnswered == 0 {
                showOnboarding = true
            }
            gameManager.startSession()
        }
    }
    
    private var mainContent: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                PracticeView()
                    .tabItem {
                        Label("Practice", systemImage: "pencil")
                    }
                    .tag(0)
                
                LearningView()
                    .tabItem {
                        Label("Learn", systemImage: "brain.head.profile")
                    }
                    .tag(1)
                
                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            .tint(AppTheme.Colors.primary)
            
            // Overlays for celebrations
            if gameManager.showLevelUp {
                LevelUpCelebrationView(level: gameManager.userProgress.level)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                gameManager.showLevelUp = false
                            }
                        }
                    }
            }
            
            if !gameManager.recentlyUnlockedAchievements.isEmpty {
                AchievementPopupView(achievements: gameManager.recentlyUnlockedAchievements)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(99)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation {
                                gameManager.recentlyUnlockedAchievements.removeAll()
                            }
                        }
                    }
            }
        }
        .onAppear {
            // Show onboarding if user has never played
            if gameManager.userProgress.totalQuestionsAnswered == 0 {
                showOnboarding = true
            }
            gameManager.startSession()
        }
    }
    
    private var mainContent: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                PracticeView()
                    .tabItem {
                        Label("Practice", systemImage: "pencil")
                    }
                    .tag(0)
                
                LearningView()
                    .tabItem {
                        Label("Learn", systemImage: "brain.head.profile")
                    }
                    .tag(1)
                
                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            .tint(AppTheme.Colors.primary)
            
            // Overlays for celebrations
            if gameManager.showLevelUp {
                LevelUpCelebrationView(level: gameManager.userProgress.level)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                gameManager.showLevelUp = false
                            }
                        }
                    }
            }
            
            if !gameManager.recentlyUnlockedAchievements.isEmpty {
                AchievementPopupView(achievements: gameManager.recentlyUnlockedAchievements)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(99)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation {
                                gameManager.recentlyUnlockedAchievements.removeAll()
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Level Up Celebration

struct LevelUpCelebrationView: View {
    let level: Int
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -180
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xl) {
                Image(systemName: "star.fill")
                    .font(.system(size: 100))
                    .foregroundColor(AppTheme.Colors.warning)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("LEVEL UP!")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("You're now level \(level)")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.2
                rotation = 0
            }
            
            withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                opacity = 1.0
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4)) {
                scale = 1.0
            }
            
            // Haptic feedback
            HapticManager.shared.impact(.heavy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                HapticManager.shared.impact(.heavy)
            }
        }
    }
}

// MARK: - Achievement Popup

struct AchievementPopupView: View {
    let achievements: [Achievement]
    @State private var offset: CGFloat = -200
    
    var body: some View {
        VStack {
            ForEach(achievements.prefix(3)) { achievement in
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.warning)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(AppTheme.Colors.warning.opacity(0.2))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Achievement Unlocked!")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text(achievement.title)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("+\(achievement.xpReward) XP")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .fill(AppTheme.Colors.surface)
                        .shadow(color: .black.opacity(0.2), radius: 10)
                )
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            
            Spacer()
        }
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = 60
            }
            HapticManager.shared.success()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(GameManager(modelContext: ModelContext(try! ModelContainer(for: UserProgress.self, MultiplicationQuestion.self))))
}
