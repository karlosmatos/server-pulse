import Foundation

struct N8NWorkflow: Identifiable, Decodable {
    let id: String
    let name: String
    let active: Bool
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey { case id, name, active, updatedAt }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try (try? c.decode(String.self, forKey: .id)) ?? String(c.decode(Int.self, forKey: .id))
        name = try c.decode(String.self, forKey: .name)
        active = try c.decode(Bool.self, forKey: .active)
        updatedAt = try? c.decode(Date.self, forKey: .updatedAt)
    }
}

struct N8NExecution: Identifiable, Decodable {
    let id: String
    let workflowId: String?
    let workflowName: String?
    let status: String
    let startedAt: Date?
    let stoppedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, workflowId, status, startedAt, stoppedAt, workflowData
    }
    private enum WorkflowDataKeys: String, CodingKey { case name }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try (try? c.decode(String.self, forKey: .id)) ?? String(c.decode(Int.self, forKey: .id))
        workflowId = try? c.decode(String.self, forKey: .workflowId)
        status = (try? c.decode(String.self, forKey: .status)) ?? "unknown"
        startedAt = try? c.decode(Date.self, forKey: .startedAt)
        stoppedAt = try? c.decode(Date.self, forKey: .stoppedAt)
        workflowName = try? c.nestedContainer(keyedBy: WorkflowDataKeys.self, forKey: .workflowData)
            .decode(String.self, forKey: .name)
    }
}

struct N8NWorkflowsResponse: Decodable { let data: [N8NWorkflow] }
struct N8NExecutionsResponse: Decodable { let data: [N8NExecution] }
