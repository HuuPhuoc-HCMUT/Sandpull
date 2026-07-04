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
    @State private var remindersEnabled = UserDefaults.standard.remindersEnabled
    @State private var soundEnabled = UserDefaults.standard.notificationSoundEnabled
    @State private var launchAtLogin = UserDefaults.standard.launchAtLogin

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.purple)
                    .font(.system(size: 15, weight: .medium))
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            VStack(spacing: 0) {
                settingRow(
                    icon: "bell.badge.fill",
                    iconColor: .purple,
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
        .frame(width: 300)
        .background(.regularMaterial)
        .task {
            // Sync Reminders toggle with actual system authorization on every open
            let hasAccess = await RemindersManager.shared.checkAccess()
            if remindersEnabled && !hasAccess {
                remindersEnabled = false
                UserDefaults.standard.remindersEnabled = false
            }
        }
    }

    private func settingRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onChange: @escaping () -> Void
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
                .tint(.purple)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) { _ in onChange() }
                .pointerCursor()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
