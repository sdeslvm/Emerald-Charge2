//
//  RemoteLinkModels.swift
//  ZMTemplate
//

import Foundation

struct RemoteLinkParts: Decodable, Sendable {
    let host: String
    let path: String

    private enum CodingKeys: String, CodingKey {
        case host = "stray"
        case path = "swap"
    }
}

struct BackendLinkResponse: Decodable, Sendable {
    let domain: String
    let tld: String

    private enum CodingKeys: String, CodingKey {
        case domain = "more"
        case tld = "sea"
    }

    var finalURL: URL? {
        guard !domain.isEmpty, !tld.isEmpty else { return nil }
        return URL(string: "https://\(domain)\(tld)")
    }
}

enum LaunchOutcome: Sendable {
    case showWeb(URL)
    case showStub
    case loading
}
