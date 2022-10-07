//
//  AdaptWidgetApp.swift
//  AdaptWidget
//
//  Created by Quentin Mazars Simon on 10/7/22.
//

import SwiftUI

@main
struct AdaptWidgetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
