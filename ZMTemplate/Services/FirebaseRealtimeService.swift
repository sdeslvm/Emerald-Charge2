//
//  FirebaseRealtimeService.swift
//  ZMTemplate
//

import Foundation
import FirebaseDatabase

enum RemoteConfigError: Error {
    case invalidPayload
    case decodingFailed
}

final class FirebaseRealtimeService {
    private let databaseURL: String

    init(databaseURL: String = "https://zm-team-21088-default-rtdb.firebaseio.com/") {
        self.databaseURL = databaseURL
    }

    private var databaseReference: DatabaseReference {
        Database.database(url: databaseURL).reference()
    }

    func fetchLinkParts() async throws -> RemoteLinkParts {
        try await withCheckedThrowingContinuation { continuation in
            databaseReference.observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value else {
                    continuation.resume(throwing: RemoteConfigError.invalidPayload)
                    return
                }

                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
                    let parts = try JSONDecoder().decode(RemoteLinkParts.self, from: data)
                    continuation.resume(returning: parts)
                } catch {
                    continuation.resume(throwing: RemoteConfigError.decodingFailed)
                }
            }
        }
    }
}

