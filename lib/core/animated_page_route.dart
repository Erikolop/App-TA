import 'package:flutter/material.dart';

/// Custom page route with slide and fade transition animation
class AnimatedPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final RouteTransitionsBuilder? transitionBuilder;
  final Duration transitionDuration;

  AnimatedPageRoute({
    required this.builder,
    this.transitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionBuilder != null) {
      return transitionBuilder!(context, animation, secondaryAnimation, child);
    }

    // Default: Slide from right with fade
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );
    final offsetAnimation = animation.drive(tween);
    final fadeAnimation = animation.drive(
      Tween<double>(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: curve),
      ),
    );

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  @override
  bool get maintainState => true;
}

/// Slide up transition (useful for modals/sheets)
class SlideUpPageRoute<T> extends AnimatedPageRoute<T> {
  SlideUpPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          builder: builder,
          settings: settings,
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            final offsetAnimation = animation.drive(tween);
            final fadeAnimation = animation.drive(
              Tween<double>(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: Curves.easeIn),
              ),
            );

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Fade transition only
class FadePageRoute<T> extends AnimatedPageRoute<T> {
  FadePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          builder: builder,
          settings: settings,
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(
                Tween<double>(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: Curves.easeInOut),
                ),
              ),
              child: child,
            );
          },
        );
}

/// Scale transition (useful for dialogs)
class ScalePageRoute<T> extends AnimatedPageRoute<T> {
  ScalePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          builder: builder,
          settings: settings,
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 0.8, end: 1.0).chain(
                  CurveTween(curve: Curves.easeOutBack),
                ),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

/// Extension to make navigation with custom routes easier
extension AnimatedNavigator on BuildContext {
  /// Navigate with default slide animation
  Future<T?> pushAnimated<T>(Widget page) {
    return Navigator.of(this).push<T>(
      AnimatedPageRoute(builder: (_) => page),
    );
  }

  /// Navigate with slide up animation
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(
      SlideUpPageRoute(builder: (_) => page),
    );
  }

  /// Navigate with fade animation
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      FadePageRoute(builder: (_) => page),
    );
  }

  /// Navigate with scale animation
  Future<T?> pushScale<T>(Widget page) {
    return Navigator.of(this).push<T>(
      ScalePageRoute(builder: (_) => page),
    );
  }
}
