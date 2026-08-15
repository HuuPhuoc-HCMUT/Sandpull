import SwiftUI
import AppKit
import ServiceManagement

extension UserDefaults {
    var remindersEnabled: Bool {
        get { bool(forKey: "remindersEnabled") }
        set { set(newValue, forKey: "remindersEnabled") }
    }
    var notificationSoundEnabled: Bool {
        get { object(forKey: "notificationSoundEnabled") == nil ? true : bool(forKey: "notificationSoundEnabled") }
        set { set(newValue, forKey: "notificationSoundEnabled") }
    }
    var launchAtLogin: Bool {
        get { bool(forKey: "launchAtLogin") }
        set { set(newValue, forKey: "launchAtLogin") }
    }
}

struct SettingsView: View {
    var onClose: (() -> Void)? = nil
    var onHelp: (() -> Void)? = nil
    @ObservedObject private var settings = AppSettings.shared
    @State private var remindersEnabled = UserDefaults.standard.remindersEnabled
    @State private var soundEnabled = UserDefaults.standard.notificationSoundEnabled
    @State private var launchAtLogin = UserDefaults.standard.launchAtLogin
    @State private var advancedOpen = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.system(size: 15, weight: .medium))
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button {
                    onHelp?()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .hoverable()
                .help("How it works")
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    generalSection
                    Divider()
                    advancedSection
                }
            }
            .frame(maxHeight: 440)

            Divider()

            HStack {
                Text("PullTimer 1.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Close") { onClose?() }
                    .buttonStyle(QuitButtonStyle())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .frame(width: 320)
        .pullPanel()
        .task {
            let hasAccess = await RemindersManager.shared.checkAccess()
            if remindersEnabled && !hasAccess {
                remindersEnabled = false
                UserDefaults.standard.remindersEnabled = false
            }
        }
    }

    private var generalSection: some View {
        VStack(spacing: 0) {
            settingRow(
                icon: "bell.badge.fill",
                iconColor: Theme.accent,
                title: "Notification Sound",
                subtitle: "Play sound when timer ends",
                isOn: $soundEnabled
            ) {
                UserDefaults.standard.notificationSoundEnabled = soundEnabled
            }

            Divider().padding(.leading, 48)

            settingRow(
                icon: "checklist",
                iconColor: .orange,
                title: "Sync with Reminders",
                subtitle: "Add timers to Apple Reminders",
                isOn: $remindersEnabled
            ) {
                if remindersEnabled {
                    Task {
                        let granted = await RemindersManager.shared.requestAccess()
                        await MainActor.run {
                            remindersEnabled = granted
                            UserDefaults.standard.remindersEnabled = granted
                        }
                    }
                } else {
                    UserDefaults.standard.remindersEnabled = false
                }
            }

            Divider().padding(.leading, 48)

            settingRow(
                icon: "arrow.up.circle.fill",
                iconColor: .blue,
                title: "Launch at Login",
                subtitle: "Start PullTimer automatically",
                isOn: $launchAtLogin
            ) {
                setLaunchAtLogin(launchAtLogin)
            }
        }
        .padding(.vertical, 6)
    }

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.16)) { advancedOpen.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Text("Advanced")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.4)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(advancedOpen ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverRow()

            if advancedOpen {
                VStack(spacing: 0) {
                    stepperRow(
                        title: "Default timer",
                        subtitle: "Used when tapping Add",
                        value: defaultAddLabel
                    ) {
                        settings.defaultAddMinutes = max(1, settings.defaultAddMinutes - 5)
                    } onIncrement: {
                        settings.defaultAddMinutes = min(120, settings.defaultAddMinutes + 5)
                    }

                    Divider().padding(.leading, 16)

                    sliderRow(
                        title: "Drag start",
                        subtitle: "Distance before a timer begins",
                        valueLabel: "\(Int(settings.deadZone.rounded())) px",
                        value: $settings.deadZone,
                        range: 64...176
                    )

                    Divider().padding(.leading, 16)

                    pickerRow(title: "Duration curve", subtitle: "How quickly minutes grow") {
                        Picker("", selection: $settings.dragFeel) {
                            ForEach(DragFeel.allCases) { feel in
                                Text(feel.title).tag(feel)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    Divider().padding(.leading, 16)

                    pickerRow(title: "Max duration", subtitle: "Upper end of a full drag") {
                        Picker("", selection: $settings.maxDurationHours) {
                            Text("8h").tag(8)
                            Text("12h").tag(12)
                            Text("24h").tag(24)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    Divider().padding(.leading, 16)

                    settingRow(
                        icon: "clock.fill",
                        iconColor: Theme.accent,
                        title: "Menu bar countdown",
                        subtitle: "Show remaining time next to icon",
                        isOn: $settings.showMenuBarCountdown
                    )

                    Divider().padding(.leading, 48)

                    settingRow(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: Theme.sandDeep,
                        title: "Hourglass rotation",
                        subtitle: "Spin the glass while dragging",
                        isOn: $settings.rotateHourglass
                    )

                    Divider().padding(.leading, 48)

                    settingRow(
                        icon: "paintpalette.fill",
                        iconColor: Theme.sandDeep,
                        title: "Quarter-hour highlight",
                        subtitle: "Sand color when the end time hits :00, :15, :30, :45",
                        isOn: $settings.highlightQuarterHours
                    )

                    Divider().padding(.leading, 48)

                    settingRow(
                        icon: "hand.tap.fill",
                        iconColor: .orange,
                        title: "Haptic on cancel",
                        subtitle: "Click when entering the trash zone",
                        isOn: $settings.hapticOnCancel
                    )

                    Divider().padding(.leading, 16)

                    HStack {
                        Spacer()
                        Button("Reset to defaults") { settings.resetAdvanced() }
                            .buttonStyle(QuitButtonStyle())
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private var defaultAddLabel: String {
        let m = settings.defaultAddMinutes
        if m >= 60 && m % 60 == 0 { return "\(m / 60)h" }
        return "\(m)m"
    }

    private func settingRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onChange: @escaping () -> Void = {}
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(Theme.accent)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) { _ in onChange() }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .hoverRow()
    }

    private func stepperRow(
        title: String,
        subtitle: String,
        value: String,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                stepButton(systemName: "minus", action: onDecrement)
                Text(value)
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .frame(minWidth: 36)
                stepButton(systemName: "plus", action: onIncrement)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func sliderRow(
        title: String,
        subtitle: String,
        valueLabel: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(valueLabel)
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
                .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func pickerRow<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder picker: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            picker()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(QuitButtonStyle())
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        UserDefaults.standard.launchAtLogin = enabled
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[PullTimer] Launch at login: \(error)")
            }
        }
    }
}
