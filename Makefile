.PHONY: verify-phase1-safety verify-phase2-hotkey-controls verify-phase3-hotkey-execution install-app

verify-phase1-safety:
	swift test --filter ClipboardNoOpSafetyTests
	swift test --filter ManualCleanupFlowTests
	bash scripts/verify-safety-constraints.sh

verify-phase2-hotkey-controls:
	swift test --filter HotkeyMenuIntegrationTests
	swift test --filter MenuBarActionTests
	swift test --filter HotkeyPreferencesStoreTests
	$(MAKE) verify-phase1-safety

verify-phase3-hotkey-execution:
	swift test --filter HotkeyExecutionCoordinatorTests
	swift test --filter HotkeyPermissionGuidanceTests
	$(MAKE) verify-phase2-hotkey-controls

install-app:
	bash scripts/install-app.sh
