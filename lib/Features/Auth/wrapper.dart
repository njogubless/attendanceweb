
import 'package:attendanceweb/Features/Auth/SignIn.dart';
import 'package:attendanceweb/Features/Auth/auth.dart';
import 'package:attendanceweb/Screens/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Wrapper extends ConsumerWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStreamProvider);
    
    return authState.when(
      data: (client) {
        // If client is not null, show home screen, otherwise show auth screen
        return client != null ? const Homepage() : const SignIn();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}