//
//  ContentView.swift
//  Sample
//
//  Created by Nicolas Miyasato on 07/10/2023.
//

import SwiftUI

struct ContentView: View {
    let viewModel = SampleViewModel()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .task {
            await viewModel.getUser()
        }
    }
}

#Preview {
    ContentView()
}
