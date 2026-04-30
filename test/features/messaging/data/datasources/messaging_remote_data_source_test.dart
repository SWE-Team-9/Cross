import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/messaging/data/datasources/messaging_remote_data_source.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late MessagingRemoteDataSourceImpl dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = MessagingRemoteDataSourceImpl(dioClient);
  });

  Response<dynamic> response(dynamic data) {
    return Response<dynamic>(
      data: data,
      requestOptions: RequestOptions(path: '/test'),
      statusCode: 200,
    );
  }

  Map<String, dynamic> participantJson() {
    return <String, dynamic>{
      'id': 'user-1',
      '_id': 'user-1',
      'userId': 'user-1',
      'username': 'listener',
      'name': 'Listener One',
      'displayName': 'Listener One',
      'avatarUrl': 'https://example.com/avatar.png',
    };
  }

  Map<String, dynamic> messageJson() {
    return <String, dynamic>{
      'id': 'message-1',
      '_id': 'message-1',
      'messageId': 'message-1',
      'conversationId': 'conversation-1',
      'senderId': 'user-2',
      'receiverId': 'user-1',
      'text': 'Hello',
      'content': 'Hello',
      'type': 'text',
      'createdAt': '2026-04-30T10:00:00.000Z',
      'updatedAt': '2026-04-30T10:01:00.000Z',
      'isMine': false,
      'isRead': true,
    };
  }

  Map<String, dynamic> conversationJson({
    String conversationId = 'conversation-1',
  }) {
    return <String, dynamic>{
      'conversationId': conversationId,
      'participant': participantJson(),
      'lastMessage': messageJson(),
      'unreadCount': 2,
      'updatedAt': '2026-04-30T10:10:00.000Z',
      'isArchived': false,
      'isBlockedByMe': false,
      'hasBlockedMe': false,
      'canMessage': true,
      'blockReason': null,
    };
  }

  Map<String, dynamic> conversationListPageJson() {
    return <String, dynamic>{
      'items': <Map<String, dynamic>>[
        conversationJson(),
      ],
      'conversations': <Map<String, dynamic>>[
        conversationJson(),
      ],
      'data': <Map<String, dynamic>>[
        conversationJson(),
      ],
      'page': 1,
      'limit': 20,
      'total': 1,
      'totalPages': 1,
      'hasMore': false,
    };
  }

  Map<String, dynamic> conversationMessagesPageJson() {
    return <String, dynamic>{
      'items': <Map<String, dynamic>>[
        messageJson(),
      ],
      'messages': <Map<String, dynamic>>[
        messageJson(),
      ],
      'data': <Map<String, dynamic>>[
        messageJson(),
      ],
      'page': 1,
      'limit': 50,
      'total': 1,
      'totalPages': 1,
      'hasMore': false,
    };
  }

  group('getMyConversations', () {
    test('calls conversations endpoint with default query parameters',
        () async {
      when(
        () => dioClient.get(
          ApiConstants.messagingConversationsPath,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => response(conversationListPageJson()));

      final result = await dataSource.getMyConversations();

      expect(result, isNotNull);

      verify(
        () => dioClient.get(
          ApiConstants.messagingConversationsPath,
          queryParameters: <String, dynamic>{
            'page': 1,
            'limit': 20,
            'archived': false,
          },
        ),
      ).called(1);
    });

    test('calls conversations endpoint with custom query parameters', () async {
      when(
        () => dioClient.get(
          ApiConstants.messagingConversationsPath,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
          (_) async => response(jsonEncode(conversationListPageJson())));

      final result = await dataSource.getMyConversations(
        page: 3,
        limit: 10,
        archived: true,
      );

      expect(result, isNotNull);

      verify(
        () => dioClient.get(
          ApiConstants.messagingConversationsPath,
          queryParameters: <String, dynamic>{
            'page': 3,
            'limit': 10,
            'archived': true,
          },
        ),
      ).called(1);
    });
  });

  group('getConversationMessages', () {
    test('calls conversation messages endpoint with default pagination',
        () async {
      when(
        () => dioClient.get(
          ApiConstants.messagingConversationByIdPath('conversation-1'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => response(conversationMessagesPageJson()));

      final result = await dataSource.getConversationMessages('conversation-1');

      expect(result, isNotNull);

      verify(
        () => dioClient.get(
          ApiConstants.messagingConversationByIdPath('conversation-1'),
          queryParameters: <String, dynamic>{
            'page': 1,
            'limit': 50,
          },
        ),
      ).called(1);
    });

    test('decodes string JSON response', () async {
      when(
        () => dioClient.get(
          ApiConstants.messagingConversationByIdPath('conversation-1'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => response(jsonEncode(conversationMessagesPageJson())),
      );

      final result = await dataSource.getConversationMessages(
        'conversation-1',
        page: 2,
        limit: 25,
      );

      expect(result, isNotNull);

      verify(
        () => dioClient.get(
          ApiConstants.messagingConversationByIdPath('conversation-1'),
          queryParameters: <String, dynamic>{
            'page': 2,
            'limit': 25,
          },
        ),
      ).called(1);
    });
  });

  test('getConversationMeta calls meta endpoint and returns dto', () async {
    when(
      () => dioClient.get(
        ApiConstants.messagingConversationMetaPath('conversation-1'),
      ),
    ).thenAnswer((_) async => response(conversationJson()));

    final result = await dataSource.getConversationMeta('conversation-1');

    expect(result.conversationId, 'conversation-1');

    verify(
      () => dioClient.get(
        ApiConstants.messagingConversationMetaPath('conversation-1'),
      ),
    ).called(1);
  });

  test('getOrCreateDirectConversation posts receiverId and returns dto',
      () async {
    when(
      () => dioClient.post(
        ApiConstants.messagingDirectConversationPath,
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => response(conversationJson()));

    final result = await dataSource.getOrCreateDirectConversation(
      receiverId: 'user-1',
    );

    expect(result.conversationId, 'conversation-1');

    verify(
      () => dioClient.post(
        ApiConstants.messagingDirectConversationPath,
        data: <String, dynamic>{
          'receiverId': 'user-1',
        },
      ),
    ).called(1);
  });

  test('sendTextMessage posts receiverId and text and returns message dto',
      () async {
    when(
      () => dioClient.post(
        ApiConstants.messagingBase,
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => response(messageJson()));

    final result = await dataSource.sendTextMessage(
      receiverId: 'user-1',
      text: 'Hello',
    );

    expect(result, isNotNull);

    verify(
      () => dioClient.post(
        ApiConstants.messagingBase,
        data: <String, dynamic>{
          'receiverId': 'user-1',
          'text': 'Hello',
        },
      ),
    ).called(1);
  });

  group('shareTrack', () {
    test('posts receiverId and trackId without blank text', () async {
      when(
        () => dioClient.post(
          ApiConstants.messagingShareTrackPath,
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response(messageJson()));

      final result = await dataSource.shareTrack(
        receiverId: 'user-1',
        trackId: 'track-1',
        text: '   ',
      );

      expect(result, isNotNull);

      verify(
        () => dioClient.post(
          ApiConstants.messagingShareTrackPath,
          data: <String, dynamic>{
            'receiverId': 'user-1',
            'trackId': 'track-1',
          },
        ),
      ).called(1);
    });

    test('trims non-empty text before posting', () async {
      when(
        () => dioClient.post(
          ApiConstants.messagingShareTrackPath,
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response(messageJson()));

      await dataSource.shareTrack(
        receiverId: 'user-1',
        trackId: 'track-1',
        text: '  listen to this  ',
      );

      verify(
        () => dioClient.post(
          ApiConstants.messagingShareTrackPath,
          data: <String, dynamic>{
            'receiverId': 'user-1',
            'trackId': 'track-1',
            'text': 'listen to this',
          },
        ),
      ).called(1);
    });
  });

  group('sharePlaylist', () {
    test('posts receiverId and playlistId without null text', () async {
      when(
        () => dioClient.post(
          ApiConstants.messagingSharePlaylistPath,
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response(messageJson()));

      final result = await dataSource.sharePlaylist(
        receiverId: 'user-1',
        playlistId: 'playlist-1',
      );

      expect(result, isNotNull);

      verify(
        () => dioClient.post(
          ApiConstants.messagingSharePlaylistPath,
          data: <String, dynamic>{
            'receiverId': 'user-1',
            'playlistId': 'playlist-1',
          },
        ),
      ).called(1);
    });

    test('trims non-empty text before posting', () async {
      when(
        () => dioClient.post(
          ApiConstants.messagingSharePlaylistPath,
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response(messageJson()));

      await dataSource.sharePlaylist(
        receiverId: 'user-1',
        playlistId: 'playlist-1',
        text: '  new playlist  ',
      );

      verify(
        () => dioClient.post(
          ApiConstants.messagingSharePlaylistPath,
          data: <String, dynamic>{
            'receiverId': 'user-1',
            'playlistId': 'playlist-1',
            'text': 'new playlist',
          },
        ),
      ).called(1);
    });
  });

  test('getUnreadCount calls unread count endpoint', () async {
    when(
      () => dioClient.get(ApiConstants.messagingUnreadCountPath),
    ).thenAnswer(
      (_) async => response(<String, dynamic>{
        'count': 5,
        'unreadCount': 5,
      }),
    );

    final result = await dataSource.getUnreadCount();

    expect(result, isNotNull);

    verify(
      () => dioClient.get(ApiConstants.messagingUnreadCountPath),
    ).called(1);
  });

  test('markConversationAsRead calls read endpoint', () async {
    when(
      () => dioClient.patch(
        ApiConstants.messagingMarkConversationReadPath('conversation-1'),
      ),
    ).thenAnswer((_) async => response(null));

    await dataSource.markConversationAsRead('conversation-1');

    verify(
      () => dioClient.patch(
        ApiConstants.messagingMarkConversationReadPath('conversation-1'),
      ),
    ).called(1);
  });

  test('markConversationAsUnread calls unread endpoint', () async {
    when(
      () => dioClient.patch(
        ApiConstants.messagingMarkConversationUnreadPath('conversation-1'),
      ),
    ).thenAnswer((_) async => response(null));

    await dataSource.markConversationAsUnread('conversation-1');

    verify(
      () => dioClient.patch(
        ApiConstants.messagingMarkConversationUnreadPath('conversation-1'),
      ),
    ).called(1);
  });

  test('archiveConversation calls archive endpoint', () async {
    when(
      () => dioClient.patch(
        ApiConstants.messagingArchiveConversationPath('conversation-1'),
      ),
    ).thenAnswer((_) async => response(null));

    await dataSource.archiveConversation('conversation-1');

    verify(
      () => dioClient.patch(
        ApiConstants.messagingArchiveConversationPath('conversation-1'),
      ),
    ).called(1);
  });

  test('unarchiveConversation calls unarchive endpoint', () async {
    when(
      () => dioClient.patch(
        ApiConstants.messagingUnarchiveConversationPath('conversation-1'),
      ),
    ).thenAnswer((_) async => response(null));

    await dataSource.unarchiveConversation('conversation-1');

    verify(
      () => dioClient.patch(
        ApiConstants.messagingUnarchiveConversationPath('conversation-1'),
      ),
    ).called(1);
  });

  test('deleteMessage calls delete message endpoint', () async {
    when(
      () => dioClient.delete(
        ApiConstants.messagingMessageByIdPath('message-1'),
      ),
    ).thenAnswer((_) async => response(null));

    await dataSource.deleteMessage('message-1');

    verify(
      () => dioClient.delete(
        ApiConstants.messagingMessageByIdPath('message-1'),
      ),
    ).called(1);
  });

  test('throws StateError when API response is not a JSON object', () async {
    when(
      () => dioClient.get(
        ApiConstants.messagingConversationMetaPath('conversation-1'),
      ),
    ).thenAnswer((_) async => response(<dynamic>['invalid']));

    expect(
      () => dataSource.getConversationMeta('conversation-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('propagates dioClient exceptions', () async {
    final exception = DioException(
      requestOptions:
          RequestOptions(path: ApiConstants.messagingUnreadCountPath),
    );

    when(
      () => dioClient.get(ApiConstants.messagingUnreadCountPath),
    ).thenThrow(exception);

    expect(
      () => dataSource.getUnreadCount(),
      throwsA(same(exception)),
    );
  });
}
