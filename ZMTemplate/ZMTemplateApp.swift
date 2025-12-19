//
//  ZMTemplateApp.swift
//  ZMTemplate
//
//  Created by alex on 12/12/25.
//

import SwiftUI

@main
struct ZMTemplateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
       
            RootView(viewModel: RootViewModel(launchService: dependencies.launchService))
                .environmentObject(dependencies.webViewCoordinator)
                .background(Color.black)
        }
    }
}
