

import Foundation
import UIKit


enum ClaidError: LocalizedError {
    case offline
    case timeout
    case unauthorized
    case noCredits
    case rateLimited
    case invalidRequest(String)
    case contentFiltered
    case server(Int)
    case badResponse
    case aiEditFailed(String)

    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection. Check your network and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .unauthorized, .noCredits:
            return "The AI service is temporarily unavailable. Please try again later."
        case .rateLimited:
            return "Too many requests right now. Wait a few seconds and try again."
        case .invalidRequest(let message):
            return message.isEmpty ? "These settings can't be applied to this photo. Try different options." : message
        case .contentFiltered:
            return "The safety filter blocked this result. Try a different prompt."
        case .server:
            return "The AI service had a hiccup. Please try again."
        case .badResponse:
            return "Unexpected response from the AI service. Please try again."
        case .aiEditFailed(let message):
            return message.isEmpty ? "The AI couldn't apply this edit. Try rephrasing your instruction." : message
        }
    }

    var isServiceProblem: Bool {
        switch self {
        case .unauthorized, .noCredits, .server, .badResponse: return true
        default: return false
        }
    }
}


final class ClaidClient {

    static let shared = ClaidClient()

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
    }


    private var usesProxy: Bool { !Secrets.proxyBaseURL.isEmpty }

    private var baseURL: String {
        if usesProxy {
            var value = Secrets.proxyBaseURL
            while value.hasSuffix("/") { value.removeLast() }
            return value
        }
        return APIConfig.directHost
    }

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else { throw ClaidError.badResponse }
        return url
    }

    private func authorize(_ request: inout URLRequest) {
        if usesProxy {
            if !Secrets.proxySecret.isEmpty {
                request.setValue(Secrets.proxySecret, forHTTPHeaderField: "X-App-Secret")
            }
        } else {
            request.setValue("Bearer \(Secrets.claidAPIKey)", forHTTPHeaderField: "Authorization")
        }
    }


    func edit(imageData: Data,
              operations: [String: Any],
              output: [String: Any]? = nil) async throws -> URL {
        var payload: [String: Any] = ["operations": operations]
        if let output { payload["output"] = output }
        let json = try JSONSerialization.data(withJSONObject: payload, options: [])

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: try makeURL(APIConfig.editUploadPath))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        authorize(&request)

        let body = Self.multipartBody(boundary: boundary, file: imageData, json: json)
        let (data, response) = try await send(request, body: body)
        try validate(response, data: data)

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObject = root["data"] as? [String: Any],
              let outputObject = dataObject["output"] as? [String: Any],
              let tmp = outputObject["tmp_url"] as? String,
              let url = URL(string: tmp) else {
            throw ClaidError.badResponse
        }
        return url
    }

  
    func upload(imageData: Data) async throws -> URL {
        let operations: [String: Any] = [
            "resizing": ["width": "100%", "height": "100%", "fit": "bounds"]
        ]
        return try await edit(imageData: imageData, operations: operations)
    }


    func aiEdit(inputURL: URL,
                prompt: String,
                onStatus: @escaping (String) -> Void) async throws -> URL {
        let body: [String: Any] = [
            "input": inputURL.absoluteString,
            "options": ["prompt": prompt],
            "output": ["format": "jpeg", "number_of_images": 1]
        ]
        var request = URLRequest(url: try makeURL(APIConfig.aiEditPath))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        authorize(&request)
        let json = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await send(request, body: json)
        try validate(response, data: data)

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObject = root["data"] as? [String: Any],
              let taskID = dataObject["id"] as? Int else {
            throw ClaidError.badResponse
        }

        onStatus("Reading your instruction…")
        let deadline = Date().addingTimeInterval(180)
        var attempt = 0

        while Date() < deadline {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            try Task.checkCancellation()
            attempt += 1

            var poll = URLRequest(url: try makeURL("\(APIConfig.aiEditPath)/\(taskID)"))
            poll.httpMethod = "GET"
            authorize(&poll)

            let (pollData, pollResponse) = try await send(poll, body: nil)
            try validate(pollResponse, data: pollData)

            guard let pollRoot = try? JSONSerialization.jsonObject(with: pollData) as? [String: Any],
                  let state = pollRoot["data"] as? [String: Any],
                  let status = state["status"] as? String else {
                continue
            }

            switch status.uppercased() {
            case "DONE":
                if let result = state["result"] as? [String: Any],
                   let outputs = result["output_objects"] as? [[String: Any]],
                   let tmp = outputs.first?["tmp_url"] as? String,
                   let url = URL(string: tmp) {
                    return url
                }
                throw ClaidError.badResponse
            case "ERROR", "CANCELLED":
                let errors = state["errors"] as? [[String: Any]]
                let message = (errors?.first?["error"] as? String) ?? ""
                throw ClaidError.aiEditFailed(message)
            default:
                onStatus(attempt < 3 ? "Understanding the photo…" : "Applying your edit…")
            }
        }
        throw ClaidError.timeout
    }

    func generate(prompt: String, count: Int, guidance: Double) async throws -> [URL] {
        let body: [String: Any] = [
            "input": prompt,
            "options": [
                "number_of_images": max(1, min(4, count)),
                "guidance_scale": guidance
            ]
        ]
        var request = URLRequest(url: try makeURL(APIConfig.generatePath))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        authorize(&request)
        let json = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await send(request, body: json)
        try validate(response, data: data)

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObject = root["data"] as? [String: Any],
              let outputs = dataObject["output"] as? [[String: Any]] else {
            throw ClaidError.badResponse
        }
        let urls = outputs.compactMap { ($0["tmp_url"] as? String).flatMap(URL.init(string:)) }
        if urls.isEmpty { throw ClaidError.badResponse }
        return urls
    }

    func download(_ url: URL) async throws -> Data {
        var lastError: Error = ClaidError.badResponse
        for attempt in 0..<3 {
            try Task.checkCancellation()
            do {
                let (data, response) = try await session.data(from: url)
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), !data.isEmpty {
                    return data
                }
                lastError = ClaidError.badResponse
            } catch let urlError as URLError {
                if urlError.code == .cancelled { throw CancellationError() }
                lastError = Self.map(urlError)
            }
            if attempt < 2 { try await Task.sleep(nanoseconds: 700_000_000) }
        }
        throw lastError
    }


    private func send(_ request: URLRequest, body: Data?) async throws -> (Data, URLResponse) {
        do {
            if let body {
                return try await session.upload(for: request, from: body)
            }
            return try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .cancelled { throw CancellationError() }
            throw Self.map(urlError)
        }
    }

    private static func map(_ error: URLError) -> ClaidError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return .offline
        case .timedOut:
            return .timeout
        default:
            return .server(error.errorCode)
        }
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw ClaidError.badResponse }
        switch http.statusCode {
        case 200...299:
            return
        case 401, 403:
            print("⚠️ Claid: unauthorized (check API key / proxy secret)")
            throw ClaidError.unauthorized
        case 402:
            print("⚠️ Claid: out of API credits — top up your Claid balance")
            throw ClaidError.noCredits
        case 429:
            throw ClaidError.rateLimited
        case 400, 422:
            let message = Self.errorMessage(from: data)
            print("⚠️ Claid: invalid request — \(message)")
            throw ClaidError.invalidRequest(Self.userFacing(message))
        default:
            print("⚠️ Claid: HTTP \(http.statusCode)")
            throw ClaidError.server(http.statusCode)
        }
    }

    private static func errorMessage(from data: Data) -> String {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return "" }
        if let message = root["error_message"] as? String { return message }
        if let error = root["error"] as? [String: Any], let message = error["error_message"] as? String { return message }
        return ""
    }

    private static func userFacing(_ message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("size") || lower.contains("mp") || lower.contains("megapixel") {
            return "This photo is too large for these settings. Try a smaller scale or a different photo."
        }
        return ""
    }

    private static func multipartBody(boundary: String, file: Data, json: Data) -> Data {
        var body = Data()
        func append(_ string: String) {
            if let data = string.data(using: .utf8) { body.append(data) }
        }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n")
        append("Content-Type: \(file.isPNG ? "image/png" : "image/jpeg")\r\n\r\n")
        body.append(file)
        append("\r\n")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"data\"\r\n")
        append("Content-Type: application/json\r\n\r\n")
        body.append(json)
        append("\r\n")
        append("--\(boundary)--\r\n")
        return body
    }
}
