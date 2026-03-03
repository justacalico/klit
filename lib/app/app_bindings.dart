import 'package:klit/app/data/nav_items.dart';
import 'package:klit/shared/controller/navigation_controller.dart';
import 'package:get/get.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<NavigationController>(
      NavigationController(items: appNavItems, mobilePrimaryCount: 4),
      permanent: true,
    );
  }
}
