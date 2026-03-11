import Foundation

// MARK: - APIClient
// Async/await HTTP client that injects the Supabase JWT into every request.

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    private static let iso8601FractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = APIClient.iso8601FractionalFormatter.date(from: value)
                ?? APIClient.iso8601Formatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(value)")
        }
    }

    // MARK: - Public

    func get<T: Decodable>(_ urlString: String) async throws -> T {
        let request = try await buildRequest(urlString, method: "GET")
        return try await perform(request)
    }

    func post<B: Encodable, T: Decodable>(_ urlString: String, body: B) async throws -> T {
        var request = try await buildRequest(urlString, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    func put<B: Encodable, T: Decodable>(_ urlString: String, body: B) async throws -> T {
        var request = try await buildRequest(urlString, method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    func delete<T: Decodable>(_ urlString: String) async throws -> T {
        let request = try await buildRequest(urlString, method: "DELETE")
        return try await perform(request)
    }

    // MARK: - Private

    private func buildRequest(_ urlString: String, method: String) async throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw APIError.badRequest("Invalid URL: \(urlString)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Inject auth token
        if let token = await AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if error is CancellationError {
                throw error
            }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw CancellationError()
            }
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(-1)
        }

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 400:
            let body = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
            let msg = (body?["error"] as? [String: Any])?["message"] as? String ?? "Bad request"
            throw APIError.badRequest(msg)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 500...599:
            let body = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
            let msg = (body?["error"] as? [String: Any])?["message"] as? String ?? "Server error"
            throw APIError.serverError(msg)
        default:
            throw APIError.unknown(http.statusCode)
        }
    }
}
