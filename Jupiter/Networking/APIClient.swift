import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get<T: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) async throws -> T {
        var components = URLComponents(url: AppConfig.baseURL, resolvingAgainstBaseURL: false)
        components?.path = path
        if !query.isEmpty {
            components?.queryItems = query
        }
        guard let url = components?.url else {
            throw APIError(statusCode: -1, message: "Invalid URL", code: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !headers.isEmpty {
            request.allHTTPHeaderFields = headers
        }
        return try await send(request)
    }

    func post<T: Decodable, Body: Encodable>(
        path: String,
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: AppConfig.baseURL) else {
            throw APIError(statusCode: -1, message: "Invalid URL", code: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !headers.isEmpty {
            request.allHTTPHeaderFields = headers.merging(request.allHTTPHeaderFields ?? [:]) { new, _ in new }
        }
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    func delete<T: Decodable>(
        path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: AppConfig.baseURL) else {
            throw APIError(statusCode: -1, message: "Invalid URL", code: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if !headers.isEmpty {
            request.allHTTPHeaderFields = headers
        }
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(statusCode: -1, message: "Invalid response", code: nil)
        }

        if (200..<300).contains(http.statusCode) {
            return try JSONDecoder().decode(T.self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            let message = apiError.error ?? apiError.err ?? "Request failed"
            throw APIError(statusCode: http.statusCode, message: message, code: apiError.code)
        }

        throw APIError(statusCode: http.statusCode, message: "Request failed", code: nil)
    }
}
