//
//  OnboardingView.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var currentPage = 0
    @State private var enteredName = ""
    @Binding var showOnboarding: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppTheme.Colors.primary, AppTheme.Colors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    welcomePage
                        .tag(0)
                    
                    howItWorksPage
                        .tag(1)
                    
                    gamificationPage
                        .tag(2)
                    
                    namePage
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.lg)
                
                // Next/Get Started button
                Button {
                    if currentPage < 3 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage == 3 ? "Get Started!" : "Next")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                .fill(Color.white)
                        )
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xl)
                .disabled(currentPage == 3 && enteredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    // MARK: - Pages
    
    private var welcomePage: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // App icon/logo
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Text("✖️")
                    .font(.system(size: 80))
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Welcome to")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("TimesAI")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Master multiplication through fun, adaptive learning")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            
            Spacer()
        }
    }
    
    private var howItWorksPage: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            Text("How It Works")
                .font(AppTheme.Typography.largeTitle)
                .foregroundColor(.white)
            
            VStack(spacing: AppTheme.Spacing.lg) {
                featureCard(
                    icon: "questionmark.circle.fill",
                    title: "Answer Questions",
                    description: "Solve multiplication problems from 1×1 to 12×12"
                )
                
                featureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    description: "We monitor your speed, accuracy, and improvement"
                )
                
                featureCard(
                    icon: "brain.head.profile",
                    title: "Adaptive Learning",
                    description: "Focus on questions you find challenging"
                )
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            Spacer()
        }
    }
    
    private var gamificationPage: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            Text("Earn Rewards!")
                .font(AppTheme.Typography.largeTitle)
                .foregroundColor(.white)
            
            VStack(spacing: AppTheme.Spacing.lg) {
                rewardCard(
                    icon: "star.fill",
                    title: "Level Up",
                    description: "Gain XP and unlock new levels",
                    color: AppTheme.Colors.warning
                )
                
                rewardCard(
                    icon: "trophy.fill",
                    title: "Achievements",
                    description: "Unlock badges for your accomplishments",
                    color: AppTheme.Colors.accent
                )
                
                rewardCard(
                    icon: "flame.fill",
                    title: "Streaks",
                    description: "Build combos and daily streaks",
                    color: AppTheme.Colors.secondary
                )
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            Spacer()
        }
    }
    
    private var namePage: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("👋")
                    .font(.system(size: 80))
                
                Text("What's your name?")
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(.white)
                
                Text("We'll use this to personalize your experience")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            TextField("Enter your name", text: $enteredName)
                .font(AppTheme.Typography.title3)
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .fill(Color.white)
                )
                .padding(.horizontal, AppTheme.Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Views
    
    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(Color.white.opacity(0.15))
        )
    }
    
    private func rewardCard(icon: String, title: String, description: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundColor(.white)
            
            Text(description)
                .font(AppTheme.Typography.callout)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(Color.white.opacity(0.15))
        )
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        let trimmedName = enteredName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            gameManager.userProgress.username = trimmedName
        }
        
        withAnimation {
            showOnboarding = false
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(GameManager(modelContext: ModelContext(try! ModelContainer(for: UserProgress.self, MultiplicationQuestion.self))))
}
