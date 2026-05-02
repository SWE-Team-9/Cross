# Manual FCM Notification Testing Guide

This guide explains how to manually test FCM notifications locally without Firebase Console access.

## Quick Start

### 1. **UI Button (Easiest)**

In debug mode, a purple bug icon appears in the top-right corner:

- **Tap the bug icon** → Menu opens
- **Select a notification type** (Repost, Like, Follow)
- **Notification appears** in your app's notification list

No code needed! This is perfect for quick testing while developing.

### 2. **Outside the App: Local HTTP Trigger**

This is the closest thing to a real background push without Firebase access.

1. Keep the app running on the emulator or device.
2. Make sure the app is in the background, not foreground.
3. Send a POST request to the local debug endpoint:

```bash
curl -X POST http://127.0.0.1:4040/debug/notifications/repost \
  -H "Content-Type: application/json" \
  -d "{\"trackId\":\"track-123\",\"trackTitle\":\"My Track\",\"actorName\":\"Test User\",\"actorHandle\":\"testuser\"}"
```

The app will route that request through the same background handler used by FCM, then show the local notification and refresh the list.

If you are using an Android emulator from the host machine, you can also use `adb reverse` if you want to target the device port directly:

```bash
adb reverse tcp:4040 tcp:4040
```

---

## Programmatic Testing

### 2. **Trigger Repost Notification**

```dart
import 'package:soundcloud_clone/core/debug/manual_notification_trigger.dart';

// In your widget or test:
ManualNotificationTrigger.simulateRepostNotificationInApp(
  trackId: 'my-track-id',
  trackTitle: 'My Awesome Track',
  actorHandle: 'someuser',
  actorName: 'Some User',
  actorAvatarUrl: 'https://example.com/avatar.png',
);
```

### 3. **Trigger Like Notification**

```dart
ManualNotificationTrigger.simulateLikeNotificationInApp(
  trackId: 'track-id-456',
  trackTitle: 'Another Track',
  actorHandle: 'anotheruser',
  actorName: 'Another User',
);
```

### 4. **Trigger Follow Notification**

```dart
ManualNotificationTrigger.simulateFollowNotificationInApp(
  actorHandle: 'newfollower',
  actorName: 'New Follower',
  actorAvatarUrl: 'https://example.com/avatar.png',
);
```

---

## Advanced: Simulate Full FCM Message

If you want to test the complete FCM pipeline (background handler, local notifications, etc.):

```dart
import 'package:soundcloud_clone/core/debug/fcm_notification_simulator.dart';
import 'package:soundcloud_clone/core/debug/manual_notification_trigger.dart';

// Create a simulated FCM message
final message = FcmNotificationSimulator.createRepostNotification(
  trackId: 'track-123',
  trackTitle: 'My Track',
  actorHandle: 'testuser',
  actorName: 'Test User',
);

// Log the message for debugging
FcmNotificationSimulator.logNotification(message);

// Trigger it as if it came from FCM
await ManualNotificationTrigger.simulateFcmMessage(message);
```

---

## What Gets Tested?

### ✅ Repost Notifications
- Actor username and avatar
- Track title and ID
- Notification message formatting
- Notification list UI updates
- Unread count increment

### ✅ Like Notifications
- Similar to repost, different type

### ✅ Follow Notifications
- Actor info display
- Different entity type (user vs track)

### ✅ Handlers
- `onMessage` listener (foreground)
- `onMessageOpenedApp` listener (tapping notification)
- Background handler
- Local notification display
- Bloc state updates

---

## How It Works

### The Flow:

1. **Debug UI Button** → `ManualNotificationTrigger.simulateRepostNotificationInApp()`
2. Creates a `NotificationModel` (mimics what server sends)
3. Emits `RealtimeNotificationReceived` event to `NotificationsBloc`
4. Bloc adds notification to state
5. **UI automatically updates** with new notification
6. Unread count increments

### Behind the Scenes:

```dart
// What happens when you tap "Repost":
final notification = NotificationModel(
  id: 'debug-notif-timestamp',
  type: NotificationType.repost,
  message: 'Some User reposted your track "My Track"',
  actorId: 'someuser',
  actorDisplayName: 'Some User',
  actorHandle: 'someuser',
  actorAvatarUrl: '...',
  entityType: 'track',
  entityId: 'track-123',
  trackName: 'My Track',
  isRead: false,
  createdAt: DateTime.now(),
);

// Sent directly to bloc:
bloc.add(RealtimeNotificationReceived(notification));
```

---

## Testing in Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/debug/manual_notification_trigger.dart';

void main() {
  testWidgets('Notification appears when repost is triggered', (WidgetTester tester) async {
    // ... setup code ...

    // Trigger notification
    ManualNotificationTrigger.simulateRepostNotificationInApp(
      trackId: 'test-track',
      trackTitle: 'Test Song',
      actorName: 'Test User',
    );

    await tester.pumpWidget(MyApp());

    // Verify notification appears
    expect(find.text('Test User reposted your track "Test Song"'), findsOneWidget);
  });
}
```

---

## File Reference

### Files Created:

| File | Purpose |
|------|---------|
| `lib/core/debug/fcm_notification_simulator.dart` | Creates simulated FCM message objects |
| `lib/core/debug/manual_notification_trigger.dart` | Triggers notifications in the app |
| `lib/core/widgets/debug_notification_test_overlay.dart` | Debug UI with test buttons |

### Modified Files:

| File | Changes |
|------|---------|
| `lib/main.dart` | Added debug listeners and overlay wrapper |

---

## Debug Output

Check the console/logcat for formatted debug messages:

```
╔════════════════════════════════════════════════
║ 📬 FOREGROUND MESSAGE RECEIVED
╠════════════════════════════════════════════════
║ Title: Track Reposted
║ Body: Test User reposted your track "My Track"
║ Type: repost
║ Actor: Test User
║ Track: My Track
╚════════════════════════════════════════════════

✅ Simulated repost notification added to app
📬 Notification emitted to bloc: Test User reposted your track "My Track"
```

---

## Limitations

- ❌ **Release builds**: Debug features only work in debug mode
- ❌ **Background handler**: Not fully simulated (but notification shows in app)
- ❌ **Firebase**: No actual FCM token registration for manual notifications
- ✅ **App state**: Properly updates as if real notification arrived
- ✅ **BLoC flow**: Identical to production flow

---

## Debugging Tips

**If nothing happens:**
1. Make sure you're in **debug mode** (`flutter run`)
2. Check logcat: `flutter logs`
3. Verify NotificationsBloc is registered in DI container
4. Make sure notifications page is open or visible

**To see all notifications:**
1. Navigate to the Notifications page
2. Tap the debug button
3. Select notification type
4. It appears instantly in the list

**To test different scenarios:**
- Change actor names/IDs in the UI button
- Modify parameters in programmatic calls
- Create custom notification objects using `FcmNotificationSimulator`
