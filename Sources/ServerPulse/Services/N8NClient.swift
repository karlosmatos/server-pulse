import Foundation

enum N8NError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:   return "n8n API key not configured"
        case .invalidURL:      return "Invalid n8n URL"
        case .httpError(let c): return "n8n HTTP \(c)"
        }
    }
}

struct N8NClient {
    let settings: AppSettings

    func fetchWorkflows() async throws -> [N8NWorkflow] {
        guard !settings.n8nAPIKey.isEmpty else { throw N8NError.missingAPIKey }
        let data = try await get("/api/v1/workflows?limit=50")
        return try decode(N8NWorkflowsResponse.self, from: data).data
    }

    func fetchRecentExecutions(limit: Int = 20) async throws -> [N8NExecution] {
        guard !settings.n8nAPIKey.isEmpty else { throw N8NError.missingAPIKey }
        let data = try await get("/api/v1/executions?limit=\(limit)&includeData=false")
        return try decode(N8NExecutionsResponse.self, from: data).data
    }

    // MARK: - Private helpers

    private func get(_ path: String) async throws -> Data {
        let base = settings.n8nBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + path) else { throw N8NError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue(settings.n8nAPIKey, forHTTPHeaderField: "X-N8N-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw N8NError.httpError(http.statusCode)
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}
