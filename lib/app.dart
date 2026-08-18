import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rbac_mobile_app/core/app_dependencies.dart';
import 'package:rbac_mobile_app/core/constants/app_constants.dart';
import 'package:rbac_mobile_app/core/router/app_router.dart';
import 'package:rbac_mobile_app/core/theme/app_theme.dart';

class RbacApp extends StatefulWidget {
  const RbacApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<RbacApp> createState() => _RbacAppState();
}

class _RbacAppState extends State<RbacApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(
      authBloc: widget.dependencies.authBloc,
      authRepository: widget.dependencies.authRepository,
    );
  }

  @override
  void dispose() {
    _appRouter.dispose();
    widget.dependencies.authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: widget.dependencies.authBloc,
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _appRouter.router,
        ),
      );
}
