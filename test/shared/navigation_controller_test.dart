import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilt/shared/controller/navigation_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  group('NavigationNotifier sidebar', () {
    test('toggleSidebar marks a manual collapse', () {
      final notifier = container.read(navigationProvider.notifier);
      notifier.toggleSidebar();
      final state = container.read(navigationProvider);
      expect(state.sidebarCollapsed, isTrue);
      expect(state.sidebarUserCollapsed, isTrue);
    });

    test('toggleSidebar back clears the manual flag', () {
      final notifier = container.read(navigationProvider.notifier);
      notifier.toggleSidebar();
      notifier.toggleSidebar();
      final state = container.read(navigationProvider);
      expect(state.sidebarCollapsed, isFalse);
      expect(state.sidebarUserCollapsed, isFalse);
    });

    test('autoExpandSidebar is skipped after a manual collapse', () {
      final notifier = container.read(navigationProvider.notifier);
      notifier.toggleSidebar();
      notifier.autoExpandSidebar();
      expect(container.read(navigationProvider).sidebarCollapsed, isTrue);
    });

    test('autoExpandSidebar expands when collapse was automatic', () {
      final notifier = container.read(navigationProvider.notifier);
      notifier.setSidebarCollapsed(true);
      expect(container.read(navigationProvider).sidebarUserCollapsed, isFalse);
      notifier.autoExpandSidebar();
      expect(container.read(navigationProvider).sidebarCollapsed, isFalse);
    });

    test('manual expand re-enables auto-expand', () {
      final notifier = container.read(navigationProvider.notifier);
      notifier.toggleSidebar();
      notifier.toggleSidebar();
      notifier.setSidebarCollapsed(true);
      notifier.autoExpandSidebar();
      expect(container.read(navigationProvider).sidebarCollapsed, isFalse);
    });
  });
}
