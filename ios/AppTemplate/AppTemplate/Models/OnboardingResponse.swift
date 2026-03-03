import Foundation

// MARK: - OnboardingResponse
// Represents a single quiz answer sent to the API.

struct OnboardingResponse: Codable {
    let questionKey: String
    let answer: AnyCodable

    enum CodingKeys: String, CodingKey {
        case questionKey = "question_key"
        case answer
    }
}

// MARK: - AnyCodable
// Lightweight helper to encode/decode any JSON-compatible value.

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let string = try? container.decode(String.self) { value = string }
        else if let array = try? container.decode([AnyCodable].self) { value = array.map({ $0.value }) }
        else if let dict = try? container.decode([String: AnyCodable].self) { value = dict.mapValues { $0.value } }
        else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Int:    try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool:   try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [Any]:
            try container.encode(v.map { AnyCodable($0) })
        case let v as [String: Any]:
            try container.encode(v.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Submit Request

struct SubmitOnboardingRequest: Encodable {
    let responses: [OnboardingResponse]
}

struct SubmitOnboardingResponse: Decodable {
    let ok: Bool
    let data: SavedData

    struct SavedData: Decodable { let saved: Int }
}
