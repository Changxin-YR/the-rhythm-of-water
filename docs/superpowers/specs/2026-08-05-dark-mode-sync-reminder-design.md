# Dark Mode, Data Sync, and Reminder Reliability Design

## Goal

Make dark mode, system chrome, and all in-app surfaces visually coherent; make record-derived pages update immediately; make reminder persistence and scheduling observable and reliable; remove the unused cup-management UI without deleting existing local cup data.

## Scope

- Apply one resolved light or dark palette to every page, shared component, dialog, input, divider, progress track, and selection surface.
- Apply the resolved page background and matching icon contrast to the status bar and navigation bar.
- Keep content inside safe areas. The app will look continuous with the system chrome without moving headers or tab controls underneath cutouts or gesture areas.
- Publish a data revision after every drink-record mutation so mounted Home, Stats, and Achievement pages reload without an app restart.
- Persist reminder settings independently from reminder publication, request or verify reminder permission before publication, and return actionable scheduling results.
- Remove the CupPage route and Settings entry. Do not clear the existing preferences key or remove cup fields from backups.

## Non-Goals

- No visual redesign of unrelated screens.
- No removal of user records, beverages, plants, reminders, or persisted cup data.
- No claim that a reminder works until its system publication is verified on the device.
- No fullscreen layout that places content beneath the status or navigation bar.

## Architecture

### Resolved Theme and System Chrome

`ThemeColors` will gain semantic values for muted surfaces, selected surfaces, input fields, dividers, progress tracks, positive and destructive states, dialog overlays, and system bars. Light and dark palettes will define every semantic value. Theme color selection continues to override only the accent family; it must not replace the dark neutral surfaces or text contrast values.

`GlassCard` will no longer default to an opaque white fill. Each caller will provide the resolved card color, and reusable components will receive the semantic colors they render. Existing hard-coded white, pale gray, pale green, and pale blue UI colors will be replaced with semantic tokens. Brand accents, emoji glyphs, and transparent overlays may remain fixed only where their contrast is independently preserved.

`EntryAbility` and the main shell will own a small system-bar applicator. When application settings or the OS color mode changes, it will resolve the palette and update both system-bar backgrounds and system-bar icon colors. Detail routes inherit the same resolved app surface, so pushing a settings subpage cannot return the device to white chrome.

### Live Data Revision

The app already has `refreshSignal`, but drink mutations do not publish it. A focused refresh helper will update the AppStorage revision after a successful write. Home record creation, undo, deletion, and detail-page deletion will publish after their related record, plant, and achievement state is reconciled. Home, Stats, Achievement, Main, and Settings will continue to watch that revision and reload their local view state.

The main shell deliberately retains tab pages in memory. The revision event is therefore the source of truth for cross-tab refreshes; visibility changes and lifecycle callbacks are supplementary only.

### Reminder Persistence and Publication

Saving the configuration and publishing alarms are separate outcomes. `PreferencesService.saveReminderConfig` remains the durable source of truth. `ReminderService` will return a result that distinguishes:

- configuration saved but reminders disabled;
- publication succeeded for all requested slots;
- publication blocked by missing permission;
- cancellation or publication failed, including the platform error code/message and failed-slot count.

Before publishing, the reminder settings flow will check the declared reminder permission and request it when the platform requires an interactive grant. The service will log cancellation and publication failures with error code, message, requested slot, and mode. A failed cancellation will not be disguised as a failed preference save: the page will keep the saved configuration, stay open, and explain that the reminder schedule still needs attention. It will not publish new alarms after a failed cancellation, avoiding duplicate schedules.

The verification flow will use a short time range and a future slot on device, then check both persisted settings and the resulting system reminder. Notification-policy or device permission blocks will be reported distinctly from code failures.

### Cup Management Removal

The Settings tile, route constant, route registration, and `CupPage` will be removed. The cup preferences store, serialized data, and backup compatibility remain untouched, so removing the screen neither clears existing data nor invalidates old backups. There is no active consumer of cups in quick-add or record creation, so no replacement UI is required.

## Test Strategy

- Add pure-rule tests for complete light/dark semantic palettes and for refresh revision generation.
- Extend reminder-rule tests for clear publication-result classification without accessing the device API.
- Run the existing Hypium test suite before and after each behavioral fix, then run an HAP build.
- Audit all ArkTS pages and components for fixed neutral surface/text/divider colors. Fixed colors remaining after the change must be intentional accents or transparency overlays.
- On device, verify: dark and light system bars on every tab and detail route; custom amount dialog contrast; beverage and plant forms; immediate Stats and Achievement updates after add, undo, and delete; cup route absence; reminder reopening persistence; reminder schedule result; and an actual short-window reminder publication.

## Acceptance Criteria

1. No dark-mode page presents a white default card, light input field, invisible text, or unreadable divider.
2. Status and navigation bars match the resolved app background and use legible icon contrast in both themes.
3. Adding, undoing, or deleting a drink updates Home, Stats, and Achievement data before process restart.
4. A reminder save distinguishes persisted configuration from failed scheduling and exposes the platform reason when scheduling fails.
5. Reminder behavior is confirmed through a published device reminder, not only unit tests or a success toast.
6. Cup management cannot be reached from Settings or routing, and existing cup storage is not cleared.
