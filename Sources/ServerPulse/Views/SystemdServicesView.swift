import SwiftUI

@MainActor
struct SystemdServicesView: View {
    @Environment(AppEnvironment.self) private var appEnv

    private var services: [SystemdService] { appEnv.systemdServices }
    private var activeCount: Int { services.filter { $0.state == .active }.count }

    var body: some View {
        SectionCard(icon: "gearshape.2", title: "Services", tint: .accentViolet) {
            Text("\(activeCount)/\(services.count)")
                .font(.system(size: 11)).monospacedDigit().foregroundStyle(.tertiary)
        } content: {
            VStack(spacing: 0) {
                ForEach(services) { service in
                    DotRow(
                        color: service.state.color,
                        name: service.name,
                        value: service.state == .active ? nil : service.state.label.lowercased(),
                        valueColor: service.state.color
                    )
                }
            }
        }
    }
}
