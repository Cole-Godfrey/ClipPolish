import Foundation
import KeyboardShortcuts

@MainActor
protocol GlobalHotkeyServing: Sendable {
    var selectedShortcut: KeyboardShortcuts.Shortcut? { get }
    func register(shortcut: KeyboardShortcuts.Shortcut)
    func unregister()
    func bindHotkeyHandler(_ handler: @escaping @MainActor @Sendable () -> Void)
    func apply(isEnabled: Bool, shortcut: KeyboardShortcuts.Shortcut?)
    func validate(shortcut: KeyboardShortcuts.Shortcut) -> HotkeyShortcutValidationResult
}

enum HotkeyShortcutValidationResult: Equatable {
    case accepted
    case blockedConflict(suggestions: [String])
    case invalidShortcut
}

enum HotkeyShortcutName {
    static let cleanAndPaste = KeyboardShortcuts.Name("cleanAndPaste")
}

@MainActor
final class GlobalHotkeyService: GlobalHotkeyServing {
    private let name: KeyboardShortcuts.Name
    private let conflictDetector: any HotkeyConflictDetecting
    private var isHotkeyHandlerBound: Bool = false

    init(
        name: KeyboardShortcuts.Name = HotkeyShortcutName.cleanAndPaste,
        conflictDetector: any HotkeyConflictDetecting = ProductionHotkeyConflictDetector()
    ) {
        self.name = name
        self.conflictDetector = conflictDetector
    }

    var selectedShortcut: KeyboardShortcuts.Shortcut? {
        KeyboardShortcuts.getShortcut(for: name)
    }

    func register(shortcut: KeyboardShortcuts.Shortcut) {
        KeyboardShortcuts.setShortcut(shortcut, for: name)
        KeyboardShortcuts.enable(name)
    }

    func unregister() {
        KeyboardShortcuts.disable(name)
    }

    func bindHotkeyHandler(_ handler: @escaping @MainActor @Sendable () -> Void) {
        guard !isHotkeyHandlerBound else {
            return
        }

        isHotkeyHandlerBound = true
        KeyboardShortcuts.onKeyUp(for: name, action: handler)
    }

    func apply(isEnabled: Bool, shortcut: KeyboardShortcuts.Shortcut?) {
        guard isEnabled, let shortcut else {
            unregister()
            return
        }

        register(shortcut: shortcut)
    }

    func validate(shortcut: KeyboardShortcuts.Shortcut) -> HotkeyShortcutValidationResult {
        guard !shortcut.modifiers.isEmpty else {
            return .invalidShortcut
        }

        if let conflict = conflictDetector.conflict(for: shortcut) {
            return .blockedConflict(suggestions: Self.suggestions(for: conflict))
        }

        return .accepted
    }

    private static func suggestions(for conflict: HotkeyConflict) -> [String] {
        switch conflict {
        case .systemReserved:
            return [
                "Try Command-Shift-Option-V",
                "Try Command-Option-V",
                "Try Control-Shift-V"
            ]
        case .appMenu:
            return [
                "Try Command-Shift-Option-V",
                "Try Command-Option-V",
                "Try Control-Option-V"
            ]
        }
    }
}
