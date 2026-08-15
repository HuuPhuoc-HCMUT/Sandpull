import SwiftUI
import AppKit

struct TimerListView: View {
    @ObservedObject var store: TimerStore
    var onEdit: (TimerItem) -> Void = { _ in }
    var onHelp: () -> Void = {}

    @State private var draft = ""
    @State private var duration = AppSettings.shared.defaultAddDuration
    @FocusState private var composeFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if store.items.isEmpty {
                emptyState
            } else {
                timerList
            }
            Divider()
            composer
        }
        .frame(width: 300)
        .pullPanel()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Theme.accent)
            Text("Drag the menu bar icon\nor start a timer below")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
    }

    private var timerList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !store.activeItems.isEmpty {
                    sectionHeader("Active")
                    rows(store.activeItems)
                }
                if !store.doneItems.isEmpty {
                    HStack {
                        sectionTitle("Done")
                        Spacer()
                        Button("Clear done") { store.clearDone() }
                            .buttonStyle(QuitButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, store.activeItems.isEmpty ? 14 : 10)
                    .padding(.bottom, 8)

                    rows(store.doneItems)
                }
            }
            .padding(.bottom, 10)
        }
        .frame(maxHeight: 420)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            sectionTitle(title)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .kerning(0.5)
            .textCase(.uppercase)
    }

    private func rows(_ items: [TimerItem]) -> some View {
        ForEach(items) { item in
            TimerRowView(item: item) {
                onEdit(item)
            } onDelete: {
                store.remove(id: item.id)
            }

            if item.id != items.last?.id {
                Divider().padding(.leading, 16)
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("What's this for?", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($composeFocused)
                    .onSubmit { submitAdd() }

                Button("Add") { submitAdd() }
                    .buttonStyle(QuitButtonStyle())
            }

            DurationSlider(duration: $duration)

            LabelChipRow(chips: LabelSuggestions.chips(from: store.items), selected: draft) { chip in
                draft = chip.title
                if let remembered = chip.duration {
                    duration = remembered
                }
            }

            HStack {
                Button {
                    onHelp()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .hoverable()
                .help("How it works")

                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(QuitButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func submitAdd() {
        let name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        store.add(TimerItem(title: name, duration: duration))
        draft = ""
        duration = AppSettings.shared.defaultAddDuration
        composeFocused = false
    }
}
