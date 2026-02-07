import Foundation

struct APIError: Error, LocalizedError {
    let statusCode: Int
    let message: String
    let code: String?

    var errorDescription: String? {
        message
    }
}

struct APIErrorResponse: Codable {
    let ok: Bool?
    let error: String?
    let err: String?
    let code: String?
}
