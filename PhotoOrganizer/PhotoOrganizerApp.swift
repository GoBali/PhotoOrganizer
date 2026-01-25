//
//  PhotoOrganizerApp.swift
//  PhotoOrganizer
//
//  Created by Shinuk Yi on 5/12/24.
//

import SwiftUI

@main
struct PhotoOrganizerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var libraryStore: PhotoLibraryStore

    init() {
        let context = persistenceController.container.viewContext
        _libraryStore = StateObject(wrappedValue: PhotoLibraryStore(context: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(libraryStore)
        }
    }
}
