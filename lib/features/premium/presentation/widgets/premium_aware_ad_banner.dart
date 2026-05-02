import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../bloc/subscription_cubit.dart';
import '../bloc/subscription_state.dart';

class PremiumAwareAdBanner extends StatelessWidget {
  const PremiumAwareAdBanner({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(14, 8, 14, 4),
    this.title = 'Create without limits',
    this.subtitle =
        'Upgrade to remove ads, unlock offline downloads, and get more uploads.',
    this.actionLabel = 'Go Premium',
  });

  final EdgeInsetsGeometry margin;
  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final subscriptionCubit = _subscriptionCubitOf(context);

    if (subscriptionCubit == null) {
      return _AdBannerContent(
        margin: margin,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
      );
    }

    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      builder: (context, state) {
        if (state.isInitial || state.isLoading) {
          return const SizedBox.shrink();
        }

        if (!state.subscription.adsEnabled) {
          return const SizedBox.shrink();
        }

        return _AdBannerContent(
          margin: margin,
          title: title,
          subtitle: subtitle,
          actionLabel: actionLabel,
        );
      },
    );
  }

  SubscriptionCubit? _subscriptionCubitOf(BuildContext context) {
    try {
      return context.read<SubscriptionCubit>();
    } catch (_) {
      final getIt = GetIt.I;

      if (getIt.isRegistered<SubscriptionCubit>()) {
        return getIt<SubscriptionCubit>();
      }

      return null;
    }
  }
}

class _AdBannerContent extends StatelessWidget {
  const _AdBannerContent({
    required this.margin,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final EdgeInsetsGeometry margin;
  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF5500).withValues(alpha: 0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5500).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFF5500),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sponsored',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => context.go('/upgrade'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5500),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}