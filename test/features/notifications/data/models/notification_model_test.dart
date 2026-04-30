import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_model.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';

void main() {
	group('NotificationModel.fromJson', () {
		test('maps actor metadata and builds track message for like', () {
			final model = NotificationModel.fromJson({
				'id': 'not_1',
				'type': 'like',
				'message': 'abdallah liked your track',
				'actorDisplayName': 'abdallah',
				'actorHandle': 'abdallah',
				'actorAvatarUrl': 'https://img/avatar.png',
				'entityType': 'track',
				'entityId': 'trk_91',
				'target': {'title': 'Song2'},
				'isRead': false,
				'createdAt': '2026-03-07T10:20:00Z',
			});

			expect(model.id, 'not_1');
			expect(model.type, NotificationType.like);
			expect(model.actorDisplayName, 'abdallah');
			expect(model.actorHandle, 'abdallah');
			expect(model.actorAvatarUrl, 'https://img/avatar.png');
			expect(model.trackName, 'Song2');
			expect(model.message, 'abdallah liked your track Song2');
			expect(model.isRead, false);
		});

		test('extracts track title from quoted message fallback', () {
			final model = NotificationModel.fromJson({
				'id': 'not_2',
				'type': 'comment',
				'message': 'John commented on your track "My Song"',
				'actorHandle': 'john',
				'entityType': 'track',
				'entityId': 'trk_5',
				'createdAt': '2026-03-07T10:20:00Z',
			});

			expect(model.trackName, 'My Song');
			expect(model.message, 'john commented on your track My Song');
		});

		test('maps follow notification as user entity id by handle', () {
			final model = NotificationModel.fromJson({
				'id': 'not_3',
				'type': 'followed',
				'message': 'Ali followed you',
				'actor': {
					'handle': 'ali',
					'displayName': 'Ali',
				},
				'target': {
					'handle': 'artist_1',
					'type': 'user',
				},
				'createdAt': '2026-03-07T10:20:00Z',
			});

			expect(model.type, NotificationType.follow);
			expect(model.entityId, 'artist_1');
			expect(model.message, 'Ali followed you');
		});
	});

	test('toJson serializes notification fields', () {
		final model = NotificationModel(
			id: 'not_4',
			type: NotificationType.repost,
			message: 'Sam reposted your track Song4',
			actorId: 'usr_4',
			actorDisplayName: 'Sam',
			actorHandle: 'sam',
			actorAvatarUrl: 'https://img/sam.png',
			entityType: 'track',
			entityId: 'trk_4',
			trackName: 'Song4',
			isRead: true,
			createdAt: DateTime.parse('2026-03-07T10:20:00Z'),
		);

		final json = model.toJson();

		expect(json['id'], 'not_4');
		expect(json['type'], 'repost');
		expect(json['actorDisplayName'], 'Sam');
		expect(json['actorHandle'], 'sam');
		expect(json['entityId'], 'trk_4');
		expect(json['trackName'], 'Song4');
		expect(json['isRead'], true);
	});
}
