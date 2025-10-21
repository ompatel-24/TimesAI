//
//  TimesAIApp.swift
//  TimesAI
//
//  Completely rebuilt on 2024-10-21.
//

import SwiftUI
import SwiftData

@main
struct TimesAIApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: UserProgress.self, MultiplicationQuestion.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(GameManager(modelContext: modelContainer.mainContext))
        }
        .modelContainer(modelContainer)
    }
}


