//
//  LinkAssemblyService.swift
//  ZMTemplate
//

import Foundation

struct LinkAssemblyService {
    func buildBackendURL(parts: RemoteLinkParts, payload: TrackingPayload) -> URL? {
        let query = payload.toQueryString()
        guard let encoded = query.data(using: .utf8)?.base64EncodedString() else {
            return nil
        }
        let combinedPath = "\(parts.host)\(parts.path)"
        return URL(string: "https://\(combinedPath)?data=\(encoded)")
    }
}
