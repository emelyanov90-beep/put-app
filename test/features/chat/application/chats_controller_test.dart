import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vput/features/chat/application/chats_controller.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ChatsController', () {
    test('the same person and trip reuse one thread', () {
      final container = _container();
      final controller = container.read(chatsProvider.notifier);

      final first = controller.openThread(
        peerId: 'passenger_1',
        peerName: 'Виктор О.',
        tripId: 'trip_1',
      );
      final second = controller.openThread(
        peerId: 'passenger_1',
        peerName: 'Виктор О.',
        tripId: 'trip_1',
      );

      expect(second, first);
      expect(container.read(chatsProvider), hasLength(1));
    });

    test('another trip with the same person is its own thread', () {
      final container = _container();
      final controller = container.read(chatsProvider.notifier);

      controller.openThread(
        peerId: 'passenger_1',
        peerName: 'Виктор О.',
        tripId: 'trip_1',
      );
      controller.openThread(
        peerId: 'passenger_1',
        peerName: 'Виктор О.',
        tripId: 'trip_2',
      );

      expect(container.read(chatsProvider), hasLength(2));
    });

    test('a message lands in the thread and blank text is ignored', () {
      final container = _container();
      final controller = container.read(chatsProvider.notifier);
      final id = controller.openThread(
        peerId: 'passenger_1',
        peerName: 'Виктор О.',
      );

      controller
        ..send(id, '   ')
        ..send(id, '  Буду через 5 минут  ');

      final thread = container.read(chatsProvider).single;
      expect(thread.messages, hasLength(1));
      expect(thread.messages.single.text, 'Буду через 5 минут');
      expect(thread.messages.single.fromMe, isTrue);
    });

    test('«Чаты» lists only threads with messages, newest first', () {
      final container = _container();
      final controller = container.read(chatsProvider.notifier);
      final quiet = controller.openThread(
        peerId: 'passenger_1',
        peerName: 'Виктор О.',
      );
      final older = controller.openThread(
        peerId: 'passenger_2',
        peerName: 'Мария П.',
      );
      final newer = controller.openThread(
        peerId: 'passenger_3',
        peerName: 'Анастасия К.',
      );

      controller
        ..send(older, 'Еду', now: DateTime(2026, 5, 15, 9))
        ..send(newer, 'Уже на месте', now: DateTime(2026, 5, 15, 10));

      final threads = container.read(chatThreadsProvider);
      expect(threads.map((thread) => thread.id).toList(), [newer, older]);
      expect(threads.any((thread) => thread.id == quiet), isFalse);
    });
  });
}
