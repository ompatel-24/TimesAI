//
//  ProfileView.swift
//  TimesAI
//
//  Created on 2024-10-21.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showingNameEditor = false
    @State private var editedName = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Profile header
                    profileHeader
                    
                    // Settings sections
                    soundsSection
                    
                    aboutSection
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.appBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingNameEditor) {
            nameEditorSheet
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.primary, AppTheme.Colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Text(String(gameManager.userProgress.username.prefix(1)).uppercased())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 20)
            
            // Name
            Button {
                editedName = gameManager.userProgress.username
                showingNameEditor = true
            } label: {
                HStack(spacing: 8) {
                    Text(gameManager.userProgress.username)
                        .font(AppTheme.Typography.title)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            // Level badge
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .foregroundColor(AppTheme.Colors.warning)
                
                Text("Level \(gameManager.userProgress.level)")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.warning.opacity(0.15))
            )
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(AppTheme.Colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }
    
    // MARK: - Sounds & Haptics Section
    
    private var soundsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Preferences")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: 0) {
                settingRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sound Effects",
                    subtitle: "Play sounds for answers and achievements",
                    toggle: $gameManager.userProgress.soundEnabled
                )
                
                Divider()
                    .padding(.leading, 56)
                
                settingRow(
                    icon: "hand.tap.fill",
                    title: "Haptic Feedback",
                    subtitle: "Feel vibrations for interactions",
                    toggle: $gameManager.userProgress.hapticsEnabled
                )
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .fill(AppTheme.Colors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 4)
            )
        }
    }
    
    private func settingRow(icon: String, title: String, subtitle: String, toggle: Binding<Bool>) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.primary.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: toggle)
                .labelsHidden()
        }
        .padding(AppTheme.Spacing.md)
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("About")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: 0) {
                infoRow(icon: "info.circle.fill", title: "Version", value: "2.0.0")
                
                Divider()
                    .padding(.leading, 56)
                
                Button {
                    // Reset progress
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.Colors.error.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.Colors.error)
                        }
                        
                        Text("Reset All Progress")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.error)
                        
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .fill(AppTheme.Colors.surface)
                    .shadow(color: .black.opacity(0.05), radius: 4)
            )
        }
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.info.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.info)
            }
            
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
    }
    
    // MARK: - Name Editor Sheet
    
    private var nameEditorSheet: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                TextField("Your Name", text: $editedName)
                    .font(AppTheme.Typography.title3)
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .fill(AppTheme.Colors.appBackground)
                    )
                
                Text("This is how you'll be identified in the app")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.surface)
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingNameEditor = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            gameManager.userProgress.username = editedName
                        }
                        showingNameEditor = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ProfileView()
        .environmentObject(GameManager(modelContext: ModelContext(try! ModelContainer(for: UserProgress.self, MultiplicationQuestion.self))))
}
