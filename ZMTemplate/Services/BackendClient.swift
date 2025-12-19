//
//  BackendClient.swift
//  ZMTemplate
//

import Foundation

enum BackendError: Error {
    case invalidURL
    case invalidResponse
    case decodingFailed
}

final class BackendClient {
    func requestFinalLink(url: URL) async throws -> BackendLinkResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = nil

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw BackendError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(BackendLinkResponse.self, from: data)
        } catch {
            throw BackendError.decodingFailed
        }
    }
}
