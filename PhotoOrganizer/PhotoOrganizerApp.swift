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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
