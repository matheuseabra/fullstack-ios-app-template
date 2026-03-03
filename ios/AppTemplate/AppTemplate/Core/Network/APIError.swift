import Foundation

// MARK: - APIError
enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case badRequest(String)
    case rateLimited
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:          return "You are not authenticated."
        case .notFound:              return "The requested resource was not found."
        case .badRequest(let msg):   return "Bad request: \(msg)"
        case .rateLimited:           return "Too many requests. Please try again shortly."
        case .serverError(let msg):  return "Server error: \(msg)"
        case .networkError(let err): return err.localizedDescription
        case .decodingError(let err):return "Failed to decode response: \(err.localizedDescription)"
        case .unknown(let code):     return "Unexpected error (HTTP \(code))."
        }
    }
}
