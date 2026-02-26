import SwiftUI

struct SystemdServicesView: View {
    @Environment(AppEnvironment.self) private var appEnv

    private var services: [SystemdService] { appEnv.systemdServices }

    var body: some View {
        SectionCard(icon: "gearshape.2", title: "Services", tint: .indigo) {
            HStack(spacing: 6) {
                CountBadge(count: services.filter { $0.state == .active }.count, color: .green)
                CountBadge(count: services.filter { $0.state != .active }.count, color: .gray)
            }
        } content: {
            VStack(spacing: 6) {
                ForEach(services) { service in
                    ServiceRow(service: service)
                    if service.id != services.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
    }
}

private struct ServiceRow: View {
    let service: SystemdService

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: service.state == .active ? "circle.fill" : "circle")
                .font(.system(size: 7))
                .foregroundStyle(service.state.color)
                .frame(width: 14)

            Text(service.name).font(.caption).fontWeight(.medium).lineLimit(1)
            Spacer()

            Text(service.state.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(service.state.color)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(service.state.color.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, 2)
    }
}
