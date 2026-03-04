import AppKit
import Carbon.HIToolbox
import Foundation
import KeyboardShortcuts

enum HotkeyConflict: Equatable, Sendable {
    case systemReserved
    case appMenu
}

protocol HotkeyConflictDetecting: Sendable {
    @MainActor
    func conflict(for shortcut: KeyboardShortcuts.Shortcut) -> HotkeyConflict?
}

struct ProductionHotkeyConflictDetector: HotkeyConflictDetecting {
    @MainActor
    func conflict(for shortcut: KeyboardShortcuts.Shortcut) -> HotkeyConflict? {
        if isSystemReserved(shortcut) {
            return .systemReserved
        }

        if isTakenByAppMainMenu(shortcut) {
            return .appMenu
        }

        return nil
    }

    private func isSystemReserved(_ shortcut: KeyboardShortcuts.Shortcut) -> Bool {
        // Preserve KeyboardShortcuts behavior where raw F12 is not considered blocked.
        if shortcut == KeyboardShortcuts.Shortcut(.f12, modifiers: []) {
            return false
        }

        return systemReservedShortcuts().contains(shortcut)
    }

    private func systemReservedShortcuts() -> Set<KeyboardShortcuts.Shortcut> {
        var shortcutsUnmanaged: Unmanaged<CFArray>?
        guard
            CopySymbolicHotKeys(&shortcutsUnmanaged) == noErr,
            let shortcuts = shortcutsUnmanaged?.takeRetainedValue() as? [[String: Any]]
        else {
            return []
        }

        let mappedShortcuts = shortcuts.compactMap { entry -> KeyboardShortcuts.Shortcut? in
            guard
                (entry[kHISymbolicHotKeyEnabled] as? Bool) == true,
                let carbonKeyCode = entry[kHISymbolicHotKeyCode] as? Int,
                let carbonModifiers = entry[kHISymbolicHotKeyModifiers] as? Int
            else {
                return nil
            }

            return KeyboardShortcuts.Shortcut(
                carbonKeyCode: carbonKeyCode,
                carbonModifiers: carbonModifiers
            )
        }

        return Set(mappedShortcuts)
    }

    private func isTakenByAppMainMenu(_ shortcut: KeyboardShortcuts.Shortcut) -> Bool {
        guard let mainMenu = NSApp.mainMenu else {
            return false
        }

        return menuContainsShortcut(shortcut, in: mainMenu)
    }

    private func menuContainsShortcut(_ shortcut: KeyboardShortcuts.Shortcut, in menu: NSMenu) -> Bool {
        for item in menu.items {
            if menuItem(item, matches: shortcut) {
                return true
            }

            if
                let submenu = item.submenu,
                menuContainsShortcut(shortcut, in: submenu)
            {
                return true
            }
        }

        return false
    }

    private func menuItem(_ item: NSMenuItem, matches shortcut: KeyboardShortcuts.Shortcut) -> Bool {
        guard let shortcutKeyEquivalent = keyEquivalent(for: shortcut) else {
            return false
        }

        var itemKeyEquivalent = item.keyEquivalent
        var itemModifierMask = item.keyEquivalentModifierMask

        if shortcut.modifiers.contains(.shift), itemKeyEquivalent.lowercased() != itemKeyEquivalent {
            itemKeyEquivalent = itemKeyEquivalent.lowercased()
            itemModifierMask.insert(.shift)
        }

        return shortcutKeyEquivalent == itemKeyEquivalent && shortcut.modifiers == itemModifierMask
    }

    // Mirrors the KeyboardShortcuts key-equivalent lookup to avoid relying on internal APIs.
    private func keyEquivalent(for shortcut: KeyboardShortcuts.Shortcut) -> String? {
        if
            let key = shortcut.key,
            let keyEquivalent = Self.keyToKeyEquivalentString[key]
        {
            return keyEquivalent
        }

        guard
            let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
            let layoutDataPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else {
            return nil
        }

        let layoutData = unsafeBitCast(layoutDataPointer, to: CFData.self)
        let keyLayout = unsafeBitCast(
            CFDataGetBytePtr(layoutData),
            to: UnsafePointer<CoreServices.UCKeyboardLayout>.self
        )
        var deadKeyState: UInt32 = 0
        let maxLength = 4
        var length = 0
        var characters = [UniChar](repeating: 0, count: maxLength)

        let error = CoreServices.UCKeyTranslate(
            keyLayout,
            UInt16(shortcut.carbonKeyCode),
            UInt16(CoreServices.kUCKeyActionDisplay),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(CoreServices.kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            maxLength,
            &length,
            &characters
        )

        guard error == noErr else {
            return nil
        }

        return String(utf16CodeUnits: characters, count: length)
    }

    private static let keyToKeyEquivalentString: [KeyboardShortcuts.Key: String] = [
        .space: stringFromKeyCode(0x20),
        .f1: stringFromKeyCode(NSF1FunctionKey),
        .f2: stringFromKeyCode(NSF2FunctionKey),
        .f3: stringFromKeyCode(NSF3FunctionKey),
        .f4: stringFromKeyCode(NSF4FunctionKey),
        .f5: stringFromKeyCode(NSF5FunctionKey),
        .f6: stringFromKeyCode(NSF6FunctionKey),
        .f7: stringFromKeyCode(NSF7FunctionKey),
        .f8: stringFromKeyCode(NSF8FunctionKey),
        .f9: stringFromKeyCode(NSF9FunctionKey),
        .f10: stringFromKeyCode(NSF10FunctionKey),
        .f11: stringFromKeyCode(NSF11FunctionKey),
        .f12: stringFromKeyCode(NSF12FunctionKey),
        .f13: stringFromKeyCode(NSF13FunctionKey),
        .f14: stringFromKeyCode(NSF14FunctionKey),
        .f15: stringFromKeyCode(NSF15FunctionKey),
        .f16: stringFromKeyCode(NSF16FunctionKey),
        .f17: stringFromKeyCode(NSF17FunctionKey),
        .f18: stringFromKeyCode(NSF18FunctionKey),
        .f19: stringFromKeyCode(NSF19FunctionKey),
        .f20: stringFromKeyCode(NSF20FunctionKey)
    ]

    private static func stringFromKeyCode(_ keyCode: Int) -> String {
        String(format: "%C", keyCode)
    }
}
