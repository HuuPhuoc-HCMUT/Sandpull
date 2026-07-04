import SwiftUI

struct TimerListView: View {
    @ObservedObject var store: TimerStore

    var body: some View {
        VStack(spacing: 0) {
            if store.items.isEmpty {
                emptyState
            } else {
                timerList
            }
            Divider()
            footer
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            Text("Drag the menu bar icon\nto create a timer")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
    }

    private var timerList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Active Timers")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .kerning(0.5)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            ForEach(store.items) { item in
                TimerRowView(item: item) {
                    store.remove(id: item.id)
                }

                if item.id != store.items.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
            .padding(.bottom, 10)
        }
    }

    private var footer: some View {
        HStack {
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(QuitButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
