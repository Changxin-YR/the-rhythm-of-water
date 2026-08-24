# Background Reminder and Top-Aligned Short Pages Design

## Goal

Confirm that hydration reminders are delivered by HarmonyOS outside the app, and keep short page content anchored immediately below the page header instead of vertically centering it.

## Selected Approach

The app will continue to use `reminderAgentManager` with `REMINDER_TYPE_ALARM`. This is the platform-owned scheduling mechanism and remains active when the UI is in the background or the application process is stopped. An in-process timer is rejected because it cannot satisfy the cross-application requirement. A background worker is also rejected because it would duplicate system scheduling and provide weaker alarm semantics.

Both reminder modes remain cross-application. Gentle mode publishes a system reminder with no app-requested ring duration or snooze action. Active mode publishes the same system-owned alarm with a short ring and one snooze action. Saving remains truthful: only a fully published schedule is reported as successful.

For short pages, the scroll content column will have a minimum height equal to its viewport and retain start justification. This removes the Scroll container's short-child centering while preserving natural scrolling when content is taller than the device. Changing individual card margins is rejected because it only masks the container behavior on one screen size.

## Components and Data Flow

- `ReminderSettingsPage` persists `ReminderConfig`, then calls `ReminderService.scheduleReminders()`.
- `ReminderService` cancels the previous schedule, checks the reminder permission and inventory, builds weekly slots, and publishes each slot through Reminder Agent.
- Device verification will publish a near-future slot, background the app, and capture the system reminder plus platform logs/inventory evidence.
- `DataManagePage` keeps its header fixed and lets the Scroll viewport fill the remainder. Its child column starts at the viewport's top for both short and long content.

## Error Handling

Permission, cancellation, inventory, quota, and publication failures remain distinct. A failed system publication keeps the settings page open and must not be described as an active reminder schedule.

## Verification

- A rendered-layout regression check fails while the Scroll child starts below its viewport and passes only when both top coordinates match.
- Build and install the HAP on the connected API 22 device.
- Dump the rendered hierarchy and assert that the Scroll child top equals the Scroll viewport top within layout rounding.
- Schedule a near-future active reminder, place another app in the foreground, observe the system reminder, and then restore the user's original reminder configuration.

## Acceptance Criteria

1. Reminder slots are owned by HarmonyOS Reminder Agent, not an app-process timer.
2. A reminder is observed while WaterReminder is not in the foreground.
3. Gentle mode remains quiet; active mode rings and offers the configured actions.
4. Data management cards begin directly below the header on tall screens and remain scrollable on smaller screens.
