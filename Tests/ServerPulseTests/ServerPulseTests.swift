import XCTest
@testable import ServerPulse

final class ServerPulseTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
    }

    func testProcessCommandSanitizesUnsafeFilterCharacters() {
        let cmd = SSHCommandParser.processCommand(count: 10, filter: "nginx; rm -rf /")
        XCTAssertFalse(cmd.contains(";"))
        XCTAssertTrue(cmd.contains("grep -iF 'nginxrm-rf'"))
        XCTAssertTrue(cmd.contains("head -10"))
    }

    func testSystemdCommandRejectsUnsafeServiceName() {
        let cmd = SSHCommandParser.systemdCommand(services: "nginx,postgresql;reboot")
        XCTAssertEqual(cmd, "for s in nginx; do echo \"$s:$(systemctl is-active $s)\"; done")
    }

    func testSSHConfigValidatorRejectsOptionLikeHostAndUser() {
        var config = makeServer(id: UUID(), key: "")
        config.sshHost = "-oProxyCommand=touch/tmp/pwned"
        XCTAssertThrowsError(try SSHConfigValidator.destination(for: config)) { error in
            XCTAssertEqual(error as? SSHConfigError, .invalidHost)
        }

        config.sshHost = "127.0.0.1"
        config.sshUser = "-lroot"
        XCTAssertThrowsError(try SSHConfigValidator.destination(for: config)) { error in
            XCTAssertEqual(error as? SSHConfigError, .invalidUser)
        }
    }

    func testSSHConfigValidatorBuildsSafeDestination() throws {
        let config = ServerConfig(
            name: "Test",
            sshHost: "server-01.example.com",
            sshUser: "deploy_user",
            sshKeyPath: "",
            sshPort: 22
        )

        XCTAssertEqual(try SSHConfigValidator.destination(for: config), "deploy_user@server-01.example.com")
    }

    func testTerminalLauncherDisplayNamesIncludeCmux() {
        XCTAssertEqual(TerminalLauncher.displayName(for: "terminal"), "Terminal.app")
        XCTAssertEqual(TerminalLauncher.displayName(for: "iterm2"), "iTerm2")
        XCTAssertEqual(TerminalLauncher.displayName(for: "cmux"), "cmux")
        XCTAssertEqual(TerminalLauncher.displayName(for: "unknown"), "Terminal.app")
    }

    func testParseDockerOutputParsesPsAndStatsSections() {
        let output = """
        c1|web|nginx:latest|Up 2 hours
        ---
        c1|12.5%|40.0%|120MiB / 1GiB
        """

        let parsed = SSHCommandParser.parseDockerOutput(from: output)
        XCTAssertEqual(parsed.count, 1)
        XCTAssertEqual(parsed[0].id, "c1")
        XCTAssertEqual(parsed[0].name, "web")
        XCTAssertEqual(parsed[0].cpuPercent, 12.5)
        XCTAssertEqual(parsed[0].memPercent, 40.0)
    }

    func testParseSnapshotExtractsSectionBodies() {
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
        XCTAssertEqual(parsed["CPU"], "cpu line")
        XCTAssertEqual(parsed["PROCESS"], "proc 1\nproc 2")
        XCTAssertEqual(parsed["DOCKER"], "docker line\n---\nstats line")
    }

    func testSnapshotCommandSkipsHeavySectionsWhenDisabled() {
        let config = ServerConfig(
            name: "Test",
            sshHost: "127.0.0.1",
            sshUser: "root",
            dockerEnabled: true,
            systemdServices: "nginx"
        )

        let command = SSHCommandParser.snapshotCommand(config: config, includeHeavyData: false)
        XCTAssertFalse(command.contains("__SP_DOCKER__"))
        XCTAssertFalse(command.contains("__SP_SYSTEMD__"))
        XCTAssertTrue(command.contains("__SP_PROCESS__"))
    }

    func testN8NClientRejectsInvalidScheme() async {
        let config = ServerConfig(
            name: "Test",
            sshHost: "127.0.0.1",
            sshUser: "root",
            n8nBaseURL: "example.com",
            n8nAPIKey: "abc"
        )

        let client = N8NClient(config: config)

        do {
            _ = try await client.fetchWorkflows()
            XCTFail("Expected invalidScheme error")
        } catch let error as N8NError {
            guard case .invalidScheme = error else {
                XCTFail("Expected invalidScheme, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected N8NError.invalidScheme, got \(error)")
        }
    }

    func testN8NClientRejectsPlainHTTP() async {
        let config = ServerConfig(
            name: "Test",
            sshHost: "127.0.0.1",
            sshUser: "root",
            n8nBaseURL: "http://n8n.local",
            n8nAPIKey: "abc"
        )

        let client = N8NClient(config: config)

        do {
            _ = try await client.fetchWorkflows()
            XCTFail("Expected invalidScheme error")
        } catch let error as N8NError {
            guard case .invalidScheme = error else {
                XCTFail("Expected invalidScheme, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected N8NError.invalidScheme, got \(error)")
        }
    }

    func testSaveServersDeletesRemovedServerKeychainEntry() {
        let deps = makeTestSettingsDeps()
        let settings = AppSettings(userDefaults: deps.defaults, keychain: deps.keychain)

        let serverA = makeServer(id: UUID(), key: "a-key")
        let serverB = makeServer(id: UUID(), key: "b-key")

        XCTAssertTrue(settings.saveServers([serverA, serverB]))
        XCTAssertEqual(deps.keychain.values[serverA.id.uuidString], "a-key")
        XCTAssertEqual(deps.keychain.values[serverB.id.uuidString], "b-key")

        XCTAssertTrue(settings.saveServers([serverA]))
        XCTAssertEqual(deps.keychain.values[serverA.id.uuidString], "a-key")
        XCTAssertNil(deps.keychain.values[serverB.id.uuidString])
        XCTAssertTrue(deps.keychain.deletedAccounts.contains(serverB.id.uuidString))
    }

    func testSaveServersFailsWhenKeychainWriteFails() {
        let deps = makeTestSettingsDeps()
        let server = makeServer(id: UUID(), key: "secret")
        deps.keychain.failSetAccounts.insert(server.id.uuidString)

        let settings = AppSettings(userDefaults: deps.defaults, keychain: deps.keychain)
        XCTAssertFalse(settings.saveServers([server]))
        XCTAssertNil(deps.defaults.data(forKey: "servers.list"))
    }

    func testLoadServersMigratesLegacyJSONKeyToKeychain() throws {
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
        XCTAssertEqual(servers.count, 1)
        XCTAssertEqual(servers[0].n8nAPIKey, "legacy-secret")
        XCTAssertEqual(deps.keychain.values[serverID.uuidString], "legacy-secret")

        let resaved = try XCTUnwrap(deps.defaults.data(forKey: "servers.list"))
        let resavedText = try XCTUnwrap(String(data: resaved, encoding: .utf8))
        XCTAssertFalse(resavedText.contains("n8nAPIKey"))
    }

    @MainActor
    func testStalePollingResultDoesNotOverwriteNewServiceState() async throws {
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
        XCTAssertEqual(status, .online)
    }

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
}

private final class MockKeychainStore: KeychainStoring {
    var values: [String: String] = [:]
    var failSetAccounts = Set<String>()
    var deletedAccounts = Set<String>()

    @discardableResult
    func set(_ value: String, account: String) -> Bool {
        if failSetAccounts.contains(account) {
            return false
        }
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
