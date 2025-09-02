# Notification App - Clean Architecture

This Flutter app demonstrates a notification list feature built with clean architecture principles and a modern, mobile-first UI/UX.

The README below is a compact "gitdocity" for contributors and reviewers — it highlights architecture, key UX changes (swipe-to-delete, optimistic updates, undo), developer notes, and how to run/test the app.

## Highlights — Modern UI & UX

- Searchable notifications: the AppBar includes a search field (live filtering by title/body).
- Polished cards: animated, elevated notification cards with avatar, date, and concise content preview.
- Swipe-to-delete: swipe a card to delete; deletion is optimistic and shows a floating UNDO snack.
- Optimistic mark-as-read: tapping a notification marks it read instantly and shows a floating UNDO snack; a background API call persists the change and the UI rolls back on failure.
- Mark-all-read: optimistic bulk operation with UNDO and backend persistence checks.
- Modern SnackBar UX: floating, iconified snackbars (helper `_showSnack`) with consistent colors, optional action, and automatic clearing of previous snacks.

## Key Files (updated)

- `lib/screen/notification_screen.dart` — main UI for the notifications list; contains:
    - search box and unread counters
    - `_buildCard` with polished card styling
    - swipe-to-delete implementation with UNDO
    - `_showSnack` helper and `SnackType` enum for consistent floating snacks
    - optimistic `_markAsRead` and `_markAllRead` flows with backend persistence and rollback
- `lib/screen/bloc/notification_repository.dart` — data layer; API calls and static fallback
- `lib/model/notification_model.dart` — notification model with `copyWith`

## UX flow summaries

- Delete flow
    1. User swipes a notification.
    2. App removes the item locally and shows a floating snack: "Deleted" with UNDO.
    3. App performs backend delete; if it fails, it restores the item and shows an error snack.

- Mark-as-read (single)
    1. User taps a notification.
    2. App marks the item read immediately (optimistic) and shows a "Marked as read" snack with UNDO.
    3. App persists the change to backend; on failure it rolls back and shows an error snack.

- Mark-all-read
    1. User taps the mark-all button.
    2. App optimistically marks all as read and shows UNDO.
    3. App attempts to persist changes per-notification; if any fail it restores previous state and notifies the user.

## Developer notes

- `_showSnack(String message, {SnackType type, String? actionLabel, VoidCallback? onAction, Duration? duration})` is implemented inside `notification_screen.dart` for now. Consider extracting it to `lib/utils/snack_helper.dart` and reusing across the app.
- Persistence methods are currently implemented in `NotificationRepository` using JSONPlaceholder endpoints as examples; the repo also provides a `getStaticNotifications()` fallback for offline/demo scenarios.
- The optimistic updates rely on `copyWith` and local state mutation — if you adopt a global state solution (Bloc, Riverpod, Provider), mirror the optimistic + rollback logic in the chosen architecture.

## How to run & test

1. Ensure Flutter SDK is installed and your environment is set up.
2. From project root run:

```bash
flutter pub get
flutter run
```

3. Try actions:

    - Pull to refresh

    - Search for text in the search box

    - Tap a notification to mark it read (try UNDO)

    - Swipe a notification to delete (try UNDO)

    - Tap the mark-all-read button (try UNDO)

## Quality & checks

- Static analysis: `dart analyze` — used during development (no analyzer issues after recent edits).
- Suggested tests to add:
        - Widget test for list rendering and search filtering.
        - Integration test for optimistic delete + undo and backend-failure rollback.
        - Unit test for `NotificationModel.copyWith` and repo fallback behavior.

## Suggested follow-ups

- Extract snack helper and UI pieces into `lib/widgets/` or `lib/utils/` for reuse.
- Add animations for list add/remove (AnimatedList) for smoother UX.
- Replace per-item update calls with a batch API for `mark-all-read` to reduce network overhead.
- Integrate a global state solution if the app complexity grows.

---

If you want, I can extract `_showSnack` into a shared helper file and add a small widget test that covers the UNDO flow; tell me which you'd prefer next.
# 5BB_Testing
