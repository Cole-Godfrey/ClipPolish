import AppKit
import KeyboardShortcuts
import SwiftUI

struct MenuBarAction {
    private let runManualCleanup: () -> Void
    private let setHotkeyEnabled: (Bool) -> Void
    private let setHotkeyShortcut: (KeyboardShortcuts.Shortcut?) -> HotkeyShortcutUpdateOutcome
    private let currentHotkeySettings: (() -> HotkeySettingsState)?
    private let requestAutomationPermission: () -> Void
    private let openAccessibilitySettings: () -> Void

    init(
        runManualCleanup: @escaping () -> Void,
        setHotkeyEnabled: @escaping (Bool) -> Void = { _ in },
        setHotkeyShortcut: @escaping (KeyboardShortcuts.Shortcut?) -> HotkeyShortcutUpdateOutcome = { shortcut in
            shortcut == nil ? .invalidShortcut : .accepted
        },
        currentHotkeySettings: (() -> HotkeySettingsState)? = nil,
        requestAutomationPermission: @escaping () -> Void = {},
        openAccessibilitySettings: @escaping () -> Void = {}
    ) {
        self.runManualCleanup = runManualCleanup
        self.setHotkeyEnabled = setHotkeyEnabled
        self.setHotkeyShortcut = setHotkeyShortcut
        self.currentHotkeySettings = currentHotkeySettings
        self.requestAutomationPermission = requestAutomationPermission
        self.openAccessibilitySettings = openAccessibilitySettings
    }

    func cleanClipboardTextSelected() {
        runManualCleanup()
    }

    func hotkeyEnabledChanged(_ isEnabled: Bool) {
        setHotkeyEnabled(isEnabled)
    }

    func hotkeyShortcutChanged(_ shortcut: KeyboardShortcuts.Shortcut?) -> HotkeyShortcutUpdateOutcome {
        setHotkeyShortcut(shortcut)
    }

    func refreshedHotkeySettings() -> HotkeySettingsState? {
        currentHotkeySettings?()
    }

    func requestAutomationPermissionSelected() {
        requestAutomationPermission()
    }

    func openAccessibilitySettingsSelected() {
        openAccessibilitySettings()
    }
}

struct MenuBarScene: Scene {
    @ObservedObject var statusPresenter: StatusPresenter
    @State private var hotkeySettings: HotkeySettingsState
    @State private var hotkeyHelperMessage: String?
    let menuBarAction: MenuBarAction

    init(
        statusPresenter: StatusPresenter,
        initialHotkeySettings: HotkeySettingsState,
        onCleanClipboardText: @escaping () -> Void,
        onHotkeyEnabledChanged: @escaping (Bool) -> Void,
        onHotkeyShortcutChanged: @escaping (KeyboardShortcuts.Shortcut?) -> HotkeyShortcutUpdateOutcome,
        currentHotkeySettings: @escaping () -> HotkeySettingsState,
        onRequestAutomationPermission: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void
    ) {
        self.statusPresenter = statusPresenter
        _hotkeySettings = State(initialValue: initialHotkeySettings)
        _hotkeyHelperMessage = State(initialValue: nil)
        self.menuBarAction = MenuBarAction(
            runManualCleanup: onCleanClipboardText,
            setHotkeyEnabled: onHotkeyEnabledChanged,
            setHotkeyShortcut: onHotkeyShortcutChanged,
            currentHotkeySettings: currentHotkeySettings,
            requestAutomationPermission: onRequestAutomationPermission,
            openAccessibilitySettings: onOpenAccessibilitySettings
        )
    }

    var body: some Scene {
        MenuBarExtra("ClipPolish", systemImage: "sparkles") {
            Toggle("Enable Global Hotkey", isOn: hotkeyEnabledBinding)
            KeyboardShortcuts.Recorder("Shortcut", name: HotkeyShortcutName.cleanAndPaste) { shortcut in
                handleRecorderChange(shortcut)
            }
            Text(hotkeySettings.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Enable to use clean-and-paste; if permission is needed, guidance appears below.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let hotkeyHelperMessage {
                Text(hotkeyHelperMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let message = statusPresenter.currentMessage {
                Text(message.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let guidance = message.permissionGuidance {
                    Text(guidance.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(guidance.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(guidance.settingsPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(Array(guidance.manualSteps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Button(guidance.actionTitle, action: menuBarAction.requestAutomationPermissionSelected)
                    Button("Open Accessibility Settings", action: menuBarAction.openAccessibilitySettingsSelected)
                }

                Divider()
            }

            Button("Clean Clipboard Text", action: menuBarAction.cleanClipboardTextSelected)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var hotkeyEnabledBinding: Binding<Bool> {
        Binding(
            get: { hotkeySettings.isEnabled },
            set: { isEnabled in
                hotkeyHelperMessage = nil

                menuBarAction.hotkeyEnabledChanged(isEnabled)
                hotkeySettings = menuBarAction.refreshedHotkeySettings()
                    ?? HotkeySettingsState(
                        isEnabled: isEnabled,
                        shortcut: hotkeySettings.shortcut
                    )
            }
        )
    }

    private func handleRecorderChange(_ shortcut: KeyboardShortcuts.Shortcut?) {
        let outcome = menuBarAction.hotkeyShortcutChanged(shortcut)

        switch outcome {
        case .accepted:
            hotkeySettings = menuBarAction.refreshedHotkeySettings()
                ?? HotkeySettingsState(
                    isEnabled: hotkeySettings.isEnabled,
                    shortcut: shortcut
                )
            hotkeyHelperMessage = nil
        case .blockedConflict(let suggestions):
            let suggestion = suggestions.first.map { " Suggested: \($0)." } ?? ""
            hotkeyHelperMessage = "Shortcut is unavailable.\(suggestion)"
            if let refreshed = menuBarAction.refreshedHotkeySettings() {
                hotkeySettings = refreshed
            }
        case .invalidShortcut:
            hotkeyHelperMessage = "Shortcut must include one or more modifiers."
            if let refreshed = menuBarAction.refreshedHotkeySettings() {
                hotkeySettings = refreshed
            }
        }
    }
}
