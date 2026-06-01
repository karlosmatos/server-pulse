import Testing
import Foundation
@testable import ServerPulse

@Suite("SSHCommandParser")
struct SSHCommandParserTests {

    @Test func processCommandSanitizesUnsafeFilterCharacters() {
        let cmd = SSHCommandParser.processCommand(count: 10, filter: "nginx; rm -rf /")
        #expect(!cmd.contains(";"))
        #expect(cmd.contains("grep -iF 'nginxrm-rf'"))
        #expect(cmd.contains("head -10"))
    }

    @Test func systemdCommandRejectsUnsafeServiceName() {
        let cmd = SSHCommandParser.systemdCommand(services: "nginx,postgresql;reboot")
        #expect(cmd == "for s in nginx; do echo \"$s:$(systemctl is-active $s)\"; done")
    }

    @Test func parseDockerOutputParsesPsAndStatsSections() {
        let output = """
        c1|web|nginx:latest|Up 2 hours
        ---
        c1|12.5%|40.0%|120MiB / 1GiB
        """

        let parsed = SSHCommandParser.parseDockerOutput(from: output)
        #expect(parsed.count == 1)
        #expect(parsed[0].id == "c1")
        #expect(parsed[0].name == "web")
        #expect(parsed[0].cpuPercent == 12.5)
        #expect(parsed[0].memPercent == 40.0)
    }

    @Test func parseSnapshotExtractsSectionBodies() {
        let output = """
        __SP_CPU__
        cpu line
        __SP_PROCESS__
        proc 1
        proc 2
        __SP_DOCKER__
        docker line
        ---
        stats line
        """

        let parsed = SSHCommandParser.parseSnapshot(from: output)
        #expect(parsed["CPU"] == "cpu line")
        #expect(parsed["PROCESS"] == "proc 1\nproc 2")
        #expect(parsed["DOCKER"] == "docker line\n---\nstats line")
    }

    @Test func snapshotCommandSkipsHeavySectionsWhenDisabled() {
        let config = ServerConfig(
            name: "Test",
            sshHost: "127.0.0.1",
            sshUser: "root",
            dockerEnabled: true,
            systemdServices: "nginx"
        )

        let command = SSHCommandParser.snapshotCommand(config: config, includeHeavyData: false)
        #expect(!command.contains("__SP_DOCKER__"))
        #expect(!command.contains("__SP_SYSTEMD__"))
        #expect(command.contains("__SP_PROCESS__"))
    }
}

@Suite("SSHConfigValidator")
struct SSHConfigValidatorTests {

    @Test func rejectsOptionLikeHost() throws {
        var config = makeServer(id: UUID(), key: "")
        config.sshHost = "-oProxyCommand=touch/tmp/pwned"
        #expect(throws: SSHConfigError.invalidHost) {
            try SSHConfigValidator.destination(for: config)
        }
    }

    @Test func rejectsOptionLikeUser() throws {
        var config = makeServer(id: UUID(), key: "")
        config.sshHost = "127.0.0.1"
        config.sshUser = "-lroot"
        #expect(throws: SSHConfigError.invalidUser) {
            try SSHConfigValidator.destination(for: config)
        }
    }

    @Test func buildsSafeDestination() throws {
        let config = ServerConfig(
            name: "Test",
            sshHost: "server-01.example.com",
            sshUser: "deploy_user",
            sshKeyPath: "",
            sshPort: 22
        )
        #expect(try SSHConfigValidator.destination(for: config) == "deploy_user@server-01.example.com")
    }
}

@Suite("N8NClient")
struct N8NClientTests {

    @Test func rejectsInvalidScheme() async {
        let config = ServerConfig(
            name: "Test",
            sshHost: "127.0.0.1",
            sshUser: "root",
            n8nBaseURL: "example.com",
            n8nAPIKey: "abc"
        )
        let client = N8NClient(config: config)
        await #expect(throws: N8NError.invalidScheme) {
            _ = try await client.fetchWorkflows()
        }
    }

    @Test func rejectsPlainHTTP() async {
        let config = ServerConfig(
            name: "Test",
            sshHost: "127.0.0.1",
            sshUser: "root",
            n8nBaseURL: "http://n8n.local",
            n8nAPIKey: "abc"
        )
        let client = N8NClient(config: config)
        await #expect(throws: N8NError.invalidScheme) {
            _ = try await client.fetchWorkflows()
        }
    }
}

@Suite("AppSettings")
struct AppSettingsTests {

    @Test func saveServersDeletesRemovedServerKeychainEntry() {
        let deps = makeTestSettingsDeps()
        let settings = AppSettings(userDefaults: deps.defaults, keychain: deps.keychain)

        let serverA = makeServer(id: UUID(), key: "a-key")
        let serverB = makeServer(id: UUID(), key: "b-key")

        #expect(settings.saveServers([serverA, serverB]))
        #expect(deps.keychain.values[serverA.id.uuidString] == "a-key")
        #expect(deps.keychain.values[serverB.id.uuidString] == "b-key")

        #expect(settings.saveServers([serverA]))
        #expect(deps.keychain.values[serverA.id.uuidString] == "a-key")
        #expect(deps.keychain.values[serverB.id.uuidString] == nil)
        #expect(deps.keychain.deletedAccounts.contains(serverB.id.uuidString))
    }

    @Test func saveServersFailsWhenKeychainWriteFails() {
        let deps = makeTestSettingsDeps()
        let server = makeServer(id: UUID(), key: "secret")
        deps.keychain.failSetAccounts.insert(server.id.uuidString)

        let settings = AppSettings(userDefaults: deps.defaults, keychain: deps.keychain)
        #expect(!settings.saveServers([server]))
        #expect(deps.defaults.data(forKey: "servers.list") == nil)
    }

    @Test func loadServersMigratesLegacyJSONKeyToKeychain() throws {
        let deps = makeTestSettingsDeps()
        let serverID = UUID()
        let legacyJSON = """
        [{
          "id": "\(serverID.uuidString)",
          "name": "Legacy",
          "sshHost": "127.0.0.1",
          "sshUser": "root",
          "sshKeyPath": "",
          "sshPort": 22,
          "n8nBaseURL": "https://n8n.local",
          "n8nAPIKey": "legacy-secret",
          "pollingInterval": 30,
          "processCount": 10,
          "processFilter": "",
          "dockerEnabled": false,
          "systemdServices": ""
        }]
        """

        deps.defaults.set(Data(legacyJSON.utf8), forKey: "servers.list")
        let settings = AppSettings(userDefaults: deps.defaults, keychain: deps.keychain)

        let servers = settings.loadServers()
        #expect(servers.count == 1)
        #expect(servers[0].n8nAPIKey == "legacy-secret")
        #expect(deps.keychain.values[serverID.uuidString] == "legacy-secret")

        let resaved = try #require(deps.defaults.data(forKey: "servers.list"))
        let resavedText = try #require(String(data: resaved, encoding: .utf8))
        #expect(!resavedText.contains("n8nAPIKey"))
    }
}

@Suite("AppEnvironment")
struct AppEnvironmentTests {

    @Test @MainActor func stalePollingResultDoesNotOverwriteNewServiceState() async throws {
        let deps = makeTestSettingsDeps()
        let settings = AppSettings(userDefaults: deps.defaults, keychain: deps.keychain)
        let serverID = UUID()
        let original = makeServer(id: serverID, key: "v1", interval: 3_600)
        let updated = makeServer(id: serverID, key: "v2", interval: 3_600)

        var callIndex = 0
        let env = AppEnvironment(
            settings: settings,
            pollingServiceFactory: { config in
                callIndex += 1
                if callIndex == 1 {
                    return PollingService(config: config, pollOverride: {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        var result = PollResult()
                        result.status = .offline
                        return result
                    })
                }
                return PollingService(config: config, pollOverride: {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    var result = PollResult()
                    result.status = .online
                    return result
                })
            },
            notificationPermissionRequester: {},
            autoStartPolling: false
        )

        env.addServer(original)
        env.updateServer(updated)

        try? await Task.sleep(nanoseconds: 700_000_000)
        let status = env.serverStates[serverID]?.status
        #expect(status == .online)
    }
}

// MARK: - Helpers

private func makeServer(id: UUID, key: String, interval: Double = 30) -> ServerConfig {
    ServerConfig(
        id: id,
        name: "Test",
        sshHost: "127.0.0.1",
        sshUser: "root",
        sshKeyPath: "",
        sshPort: 22,
        n8nBaseURL: "https://n8n.local",
        n8nAPIKey: key,
        pollingInterval: interval,
        processCount: 10,
        processFilter: "",
        dockerEnabled: false,
        systemdServices: ""
    )
}

private func makeTestSettingsDeps() -> (defaults: UserDefaults, keychain: MockKeychainStore) {
    let suiteName = "ServerPulseTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return (defaults, MockKeychainStore())
}

private final class MockKeychainStore: KeychainStoring {
    var values: [String: String] = [:]
    var failSetAccounts = Set<String>()
    var deletedAccounts = Set<String>()

    @discardableResult
    func set(_ value: String, account: String) -> Bool {
        if failSetAccounts.contains(account) { return false }
        if value.isEmpty {
            values.removeValue(forKey: account)
            return true
        }
        values[account] = value
        return true
    }

    @discardableResult
    func delete(account: String) -> Bool {
        deletedAccounts.insert(account)
        values.removeValue(forKey: account)
        return true
    }

    func get(account: String) -> String? {
        values[account]
    }
}
