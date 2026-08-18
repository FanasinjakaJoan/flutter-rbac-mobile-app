import 'package:flutter/material.dart';
import 'package:rbac_mobile_app/app.dart';
import 'package:rbac_mobile_app/core/app_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RbacApp(dependencies: AppDependencies.bootstrap()));
}
