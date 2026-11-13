import 'package:material_ui/material_ui.dart';

import 'constants.dart';

class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required Widget page, super.settings})
    : super(
        transitionDuration: kPage,
        reverseTransitionDuration: kPage,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final outOpacity = Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Interval(0, 0.3, curve: kExit),
            ),
          );
          final inOpacity = CurvedAnimation(
            parent: animation,
            curve: Interval(0.3, 1, curve: kEnter),
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: kEnter));
          return SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: inOpacity,
              child: FadeTransition(opacity: outOpacity, child: child),
            ),
          );
        },
      );
}

class SheetUpRoute<T> extends PageRouteBuilder<T> {
  SheetUpRoute({required Widget page, super.settings})
    : super(
        transitionDuration: kPage,
        reverseTransitionDuration: kPage,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: kEnter));
          return SlideTransition(position: slide, child: child);
        },
      );

  @override
  AnimationController? get controller => super.controller;
}
