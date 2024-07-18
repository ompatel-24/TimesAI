//
//  TimesAIApp.swift
//  TimesAI
//
//  Created by Om Patel on 2024-06-10.
//

//import SwiftUI
//import SwiftData
//
//@main
//struct TimesAIApp: App {
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            Item.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        .modelContainer(sharedModelContainer)
//    }
//}

import SwiftUI

@main
struct TimesAIApp: App {
    @StateObject private var dataManager = QuestionDataManager()
    @StateObject private var starsDataManager = StarsDataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(starsDataManager)
        }
    }
}


