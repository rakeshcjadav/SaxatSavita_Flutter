import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/services/notification_service.dart';

void main() {
  test('push text prefers the notification payload', () {
    final text = pushNotificationText(
      title: 'Sakshat Savita',
      body: 'Test notification',
      data: {'title': 'ignored', 'body': 'ignored'},
    );
    expect(text.title, pushTestTitle);
    expect(text.body, pushTestBody);
    expect(text.isEmpty, isFalse);
  });

  test('push text falls back to data title and body', () {
    final text = pushNotificationText(
      data: {'title': ' Sakshat Savita ', 'body': 'Test notification'},
    );
    expect(text.title, pushTestTitle);
    expect(text.body, pushTestBody);
  });

  test('blank push text is empty', () {
    expect(pushNotificationText().isEmpty, isTrue);
    expect(pushNotificationText(title: '  ', body: '').isEmpty, isTrue);
  });

  test('denied permission is reported without blocking a token', () {
    expect(fcmAuthorizationIsDenied(AuthorizationStatus.denied), isTrue);
    expect(
      fcmAuthorizationIsDenied(AuthorizationStatus.deniedPermanently),
      isTrue,
    );
    expect(fcmAuthorizationIsDenied(AuthorizationStatus.authorized), isFalse);
    expect(
      fcmAuthorizationIsDenied(AuthorizationStatus.provisional),
      isFalse,
    );
    expect(
      fcmAuthorizationIsDenied(AuthorizationStatus.notDetermined),
      isFalse,
    );
    expect(
      fcmAuthorizationAllowsTopicSubscribe(AuthorizationStatus.denied),
      isFalse,
    );
  });

  test('topic subscribe waits for granted permission', () {
    expect(
      fcmAuthorizationAllowsTopicSubscribe(AuthorizationStatus.authorized),
      isTrue,
    );
    expect(
      fcmAuthorizationAllowsTopicSubscribe(AuthorizationStatus.provisional),
      isTrue,
    );
    expect(
      fcmAuthorizationAllowsTopicSubscribe(AuthorizationStatus.denied),
      isFalse,
    );
    expect(
      fcmAuthorizationAllowsTopicSubscribe(AuthorizationStatus.notDetermined),
      isFalse,
    );
    expect(
      fcmAuthorizationAllowsTopicSubscribe(
        AuthorizationStatus.deniedPermanently,
      ),
      isFalse,
    );
  });

  test('incoming push ids stay clear of local reminder ids', () {
    expect(pushNotificationId(null), 82000);
    expect(pushNotificationId(''), 82000);
    final id = pushNotificationId('message-1');
    expect(id, inInclusiveRange(82000, 91999));
    expect(pushNotificationId('message-1'), id);
    expect(id, isNot(pushTestNotificationId));
  });

  test('all users topic and test copy', () {
    expect(fcmTopicAllUsers, 'all_users');
    expect(fcmPushChannelId, 'fcm_push');
    expect(pushTestTitle, 'Sakshat Savita');
    expect(pushTestBody, 'Test notification');
  });
}
