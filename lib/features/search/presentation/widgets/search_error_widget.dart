// lib/features/search/presentation/widgets/search_error_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failure.dart';
import '../bloc/search_cubit.dart';

class SearchErrorWidget extends StatelessWidget {
  final Failure? failure;

  const SearchErrorWidget({super.key, this.failure});

  bool get _isNetwork => failure is NetworkFailure;
  bool get _isAuth => failure is AuthFailure;

  String get _title {
    if (_isNetwork) return 'No internet connection';
    if (_isAuth) return 'Session expired';
    return 'Something went wrong';
  }

  String get _subtitle {
    if (_isNetwork) return 'Check your connection and try again';
    if (_isAuth) return 'Please log in again';
    return 'Please try again';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              color: Colors.white24,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // submittedQuery بدل query القديم
                final query = context.read<SearchCubit>().state.submittedQuery;
                if (query.isNotEmpty) {
                  context.read<SearchCubit>().submitSearch(query);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF5500),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
