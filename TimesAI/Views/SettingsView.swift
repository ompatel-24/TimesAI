//
//  SettingsView.swift
//  TimesAI
//
//  Created by Om Patel on 2024-06-15.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            let columns = [GridItem(.adaptive(minimum: 150))]
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach((1...10), id: \.self) { index in
                    Button("\(index)") {
                        
                    }
                    .padding()
                    .background(.green)
                    .cornerRadius(50)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontDesign(.serif)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
