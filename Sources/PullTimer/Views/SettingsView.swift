import SwiftUI
import AppKit
import ServiceManagement
import EventKit

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
    @State private var calendarAuthorized = false
    @State private var hasMicrosoftCalendar = false
    @State private var hasGoogleCalendar = false

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

            // Calendar sources hint — always shown
            calendarSourcesSection
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
            // Check calendar sources (independent of EventKit permission)
            let provider = AppleCalendarProvider.shared
            hasMicrosoftCalendar = provider.hasExchangeSource
            hasGoogleCalendar = provider.hasCalDAVSource
        }
    }

    @ViewBuilder
    private var calendarSourcesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Calendar Sources")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            if !hasMicrosoftCalendar {
                calendarHintRow(
                    icon: "envelope.badge.fill",
                    iconColor: Color(red: 0.0, green: 0.47, blue: 0.84),
                    title: "Connect Microsoft Calendar",
                    subtitle: "See Outlook & Teams meetings on the timeline",
                    action: openInternetAccounts
                )
            }

            if !hasGoogleCalendar {
                if !hasMicrosoftCalendar { Divider().padding(.leading, 48) }
                calendarHintRow(
                    icon: "globe",
                    iconColor: Color(red: 0.26, green: 0.63, blue: 0.28),
                    title: "Connect Google Calendar",
                    subtitle: "See Google meet events on the timeline",
                    action: openInternetAccounts
                )
            }

            if hasMicrosoftCalendar && hasGoogleCalendar {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 13))
                    Text("All calendar sources connected")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
    }

    private func calendarHintRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointerCursor()
    }

    private func openInternetAccounts() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.internetaccounts")!
        )
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
