//
//  TrackingService.swift
//  ZMTemplate
//

import Foundation
import AdServices
import AppsFlyerLib
import FirebaseInstallations
import FirebaseMessaging
#if canImport(UIKit)
import UIKit
#endif

final class PushTokenStore: NSObject, MessagingDelegate {
    static let shared = PushTokenStore()

    private let queue = DispatchQueue(label: "push.token.store", attributes: .concurrent)
    private var storedToken: String?

    var currentToken: String? {
        queue.sync { storedToken }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        update(token: fcmToken)
    }

    func update(token: String?) {
        queue.async(flags: .barrier) {
            self.storedToken = token
        }
    }
}

final class TrackingService {
    private let persistence: PersistenceService
    private let pushTokenStore: PushTokenStore

    init(persistence: PersistenceService, pushTokenStore: PushTokenStore) {
        self.persistence = persistence
        self.pushTokenStore = pushTokenStore
    }

    func collectPayload() async -> TrackingPayload? {
        let appsFlyerID = AppsFlyerLib.shared().getAppsFlyerUID()
        async let appInstanceIDOpt = try? await Installations.installations().installationID()
        async let attTokenOpt = Self.fetchAttributionToken()
        async let deviceContext = Self.collectDeviceContext()
        #if targetEnvironment(simulator)
        let token = "simulator-token-\(UUID().uuidString)"
        #else
        async let fetchedToken = try? await Messaging.messaging().token()
        let savedToken = pushTokenStore.currentToken
        let instantToken = Messaging.messaging().fcmToken
        #endif

        guard let context = await deviceContext else { return nil }
        let firebaseID = await appInstanceIDOpt ?? ""
        let att = await attTokenOpt ?? ""

        #if !targetEnvironment(simulator)
        let asyncToken = await fetchedToken
        let token = savedToken ?? asyncToken ?? instantToken ?? ""
        #endif

        return TrackingPayload(
            appsFlyerID: appsFlyerID,
            appInstanceID: firebaseID,
            uuid: context.uuid,
            osVersion: context.osVersion,
            deviceModel: context.deviceModel,
            bundleID: context.bundleID,
            fcmToken: token,
            attToken: att
        )
    }

    private static func fetchAttributionToken() -> String? {
        try? AAAttribution.attributionToken()
    }

    private static func collectDeviceContext() -> (uuid: String, osVersion: String, deviceModel: String, bundleID: String)? {
        #if canImport(UIKit)
        let uuid = UUID().uuidString.lowercased()
        let osVersion = UIDevice.current.systemVersion

        var systemInfo = utsname()
        uname(&systemInfo)
        let deviceModel = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        guard let bundleID = Bundle.main.bundleIdentifier else { return nil }

        return (uuid, osVersion, deviceModel, bundleID)
        #else
        return nil
        #endif
    }
}
