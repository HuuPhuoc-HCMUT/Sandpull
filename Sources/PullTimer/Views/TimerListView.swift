import SwiftUI
import AppKit

struct TimerListView: View {
    @ObservedObject var store: TimerStore
    var onAdd: () -> Void = {}

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
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Theme.accent.opacity(0.7))
            Text("Drag the menu bar icon\nor add a timer below")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Add Timer") { onAdd() }
                .buttonStyle(SaveButtonStyle())
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
    }

    private var timerList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tasks")
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
            Button {
                onAdd()
            } label: {
                Label("Add", systemImage: "plus")
            }
            .buttonStyle(QuitButtonStyle())

            Spacer()

            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(QuitButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
