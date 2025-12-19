//
//  RootViewModel.swift
//  ZMTemplate
//

import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    @Published private(set) var state: LaunchState = .loading
    @Published private(set) var isFallbackMode = false
    @Published var errorMessage: String?

    private let launchService: LaunchService
    
    /// Fallback URL, который открывается вместо заглушки
    private let fallbackURL = URL(string: "https://emeraldchargex.world/assets")!
    
    /// DEBUG: поменяй на true чтобы принудительно показать fallback
    private let forceStub = false

    init(launchService: LaunchService) {
        self.launchService = launchService
        state = mapOutcome(launchService.initialOutcome())
    }

    func start() {
        Task {
            await executeResolve()
        }
    }

    func retry() {
        errorMessage = nil
        state = .loading
        start()
    }

    private func executeResolve() async {
        let outcome = await launchService.resolveOutcome()
        await MainActor.run {
            self.state = self.mapOutcome(outcome)
        }
    }

    private func mapOutcome(_ outcome: LaunchOutcome) -> LaunchState {
        // DEBUG: принудительный fallback
        if forceStub {
            isFallbackMode = true
            return .web(url: fallbackURL)
        }
        
        switch outcome {
        case .loading:
            return .loading
        case .showStub:
            // Вместо заглушки открываем fallback URL в WebView
            isFallbackMode = true
            return .web(url: fallbackURL)
        case .showWeb(let url):
            isFallbackMode = false
            return .web(url: url)
        }
    }
}
