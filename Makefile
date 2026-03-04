.PHONY: verify-phase1-safety verify-phase2-hotkey-controls verify-phase3-hotkey-execution verify-phase4-hotkey-disabled-state verify-phase5-mixed-payload verify-phase6-hotkey-conflict verify-phase7-hotkey-e2e verify-phase7-hotkey-smoke install-app

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

verify-phase4-hotkey-disabled-state:
	swift test --filter HotkeyDisabledStateInvariantTests
	swift test --filter HotkeyMenuIntegrationTests
	$(MAKE) verify-phase3-hotkey-execution

verify-phase5-mixed-payload:
	swift test --filter SystemPasteboardGatewayTests
	swift test --filter MixedPayloadFlowIntegrityTests
	$(MAKE) verify-phase4-hotkey-disabled-state

verify-phase6-hotkey-conflict:
	swift test --filter GlobalHotkeyServiceValidationTests
	swift test --filter HotkeySettingsCoordinatorTests
	swift test --filter HotkeyMenuIntegrationTests
	$(MAKE) verify-phase5-mixed-payload

verify-phase7-hotkey-e2e:
	swift test --filter CoreBaselineInvariantTests
	swift test --filter CleanupServiceTests
	swift test --filter HotkeyExecutionCoordinatorTests
	swift test --filter HotkeyPermissionGuidanceTests
	$(MAKE) verify-phase6-hotkey-conflict

verify-phase7-hotkey-smoke:
	bash scripts/verify-hotkey-smoke.sh

install-app:
	bash scripts/install-app.sh
