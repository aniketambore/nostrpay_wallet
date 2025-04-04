import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.isInitial});
  final bool isInitial;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    if (widget.isInitial) {
      Timer(const Duration(milliseconds: 3600), () {
        Navigator.of(context).pushReplacementNamed('/intro');
      });
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: (widget.isInitial)
            ? const Center(
                child: Icon(
                  Icons.currency_bitcoin_outlined,
                  size: 40,
                ),
              )
            : const SizedBox(),
      ),
    );
  }
}
