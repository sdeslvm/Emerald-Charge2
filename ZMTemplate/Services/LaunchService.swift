//
//  LaunchService.swift
//  ZMTemplate
//

import Foundation

final class LaunchService {
    private let persistence: PersistenceService
    private let trackingService: TrackingService
    private let remoteConfigService: FirebaseRealtimeService
    private let backendClient: BackendClient
    private let linkAssemblyService: LinkAssemblyService
    private let cookieStore: CookieStoreManager

    init(persistence: PersistenceService,
         trackingService: TrackingService,
         remoteConfigService: FirebaseRealtimeService,
         backendClient: BackendClient,
         linkAssemblyService: LinkAssemblyService,
         cookieStore: CookieStoreManager) {
        self.persistence = persistence
        self.trackingService = trackingService
        self.remoteConfigService = remoteConfigService
        self.backendClient = backendClient
        self.linkAssemblyService = linkAssemblyService
        self.cookieStore = cookieStore
    }

    func initialOutcome() -> LaunchOutcome {
        if persistence.shouldShowStub {
            return .showStub
        }

        if let cachedURL = persistence.cachedURL {
            print("LaunchService.initialOutcome cachedURL=", cachedURL.absoluteString)
            return .showWeb(cachedURL)
        }

        return .loading
    }

    func resolveOutcome() async -> LaunchOutcome {
        if persistence.shouldShowStub {
            return .showStub
        }

        if let cached = persistence.cachedURL {
            print("LaunchService.resolveOutcome cachedURL=", cached.absoluteString)
            return .showWeb(cached)
        }

        guard let payload = await trackingService.collectPayload() else {
            persistence.shouldShowStub = true
            return .showStub
        }

        do {
            let linkParts = try await remoteConfigService.fetchLinkParts()
            print("LaunchService.resolveOutcome linkParts=", linkParts)

            let backendURLOpt = linkAssemblyService.buildBackendURL(parts: linkParts, payload: payload)
            print("LaunchService.resolveOutcome backendURL=", backendURLOpt?.absoluteString ?? "nil")
            guard let backendURL = backendURLOpt else {
                persistence.shouldShowStub = true
                return .showStub
            }

            let response = try await backendClient.requestFinalLink(url: backendURL)
            print("LaunchService.resolveOutcome response.finalURL=", response.finalURL?.absoluteString ?? "nil")
            guard let finalURL = response.finalURL else {
                persistence.shouldShowStub = true
                return .showStub
            }

            print("LaunchService.resolveOutcome finalURL=", finalURL.absoluteString)
            persistence.cachedURL = finalURL
            persistence.shouldShowStub = false
            cookieStore.persistCookies()
            return .showWeb(finalURL)
        } catch {
            print("LaunchService.resolveOutcome error=", String(describing: error))
            persistence.shouldShowStub = true
            return .showStub
        }
    }
}
