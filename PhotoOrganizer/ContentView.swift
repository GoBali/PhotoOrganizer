//
//  ContentView.swift
//  PhotoOrganizer
//
//  Main entry point for the app UI
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LibraryView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(PhotoLibraryStore(context: PersistenceController.preview.container.viewContext))
}
