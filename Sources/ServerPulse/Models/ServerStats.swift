struct ServerStats {
    let cpuUsage: Double        // 0–100
    let ramUsed: Int            // MB
    let ramTotal: Int           // MB
    let diskUsed: String        // e.g. "12G"
    let diskTotal: String       // e.g. "50G"
    let diskUsagePercent: Double // 0–100
    let uptime: String

    var ramUsagePercent: Double {
        guard ramTotal > 0 else { return 0 }
        return Double(ramUsed) / Double(ramTotal) * 100
    }
}
