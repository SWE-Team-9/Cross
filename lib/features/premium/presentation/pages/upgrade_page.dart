import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/plan.dart';
import '../bloc/subscription_cubit.dart';
import '../bloc/subscription_state.dart';

class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final cubit = context.read<SubscriptionCubit>();
      if (cubit.state.isInitial || cubit.state.isFailure) {
        cubit.loadSubscription();
      }
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/home');
  }

  Future<void> _handleUpgrade(Plan plan) async {
    final planCode = _readSubscriptionUpgradePlanCode(plan);

    if (planCode == null) {
      _showSnackBar(
        'Free is your default plan. You can return to Free by canceling premium from Billing.',
      );
      return;
    }

    try {
      final checkoutUrl = await context.read<SubscriptionCubit>().upgrade(
            planCode,
          );
      if (!mounted) return;

      if (checkoutUrl.trim().isEmpty) {
        _showSnackBar('Checkout link is not available right now.');
        return;
      }

      await _launchExternalUrl(checkoutUrl);
    } catch (_) {
      // The cubit already emits a readable actionErrorMessage.
    }
  }

  Future<void> _launchExternalUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());

    if (uri == null || !uri.hasScheme) {
      _showSnackBar('Invalid link returned from the server.');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;

    if (!launched) {
      _showSnackBar('Could not open the link.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listenWhen: (previous, current) {
        return previous.actionMessage != current.actionMessage ||
            previous.actionErrorMessage != current.actionErrorMessage ||
            previous.errorMessage != current.errorMessage;
      },
      listener: (context, state) {
        final message = state.actionErrorMessage ??
            state.errorMessage ??
            state.actionMessage;

        if (message == null || message.trim().isEmpty) {
          return;
        }

        _showSnackBar(message);
      },
      builder: (context, state) {
        final rawPlans =
            state.upgradePlans.isEmpty ? state.plans : state.upgradePlans;

        final currentPlanCode = _normalizeSubscriptionUpgradePlanCode(
          state.subscription.normalizedPlanCode,
        );

        final plans = rawPlans.where((plan) {
          final planCode = _readSubscriptionUpgradePlanCode(plan);

          if (planCode == null) {
            return false;
          }

          return planCode != currentPlanCode;
        }).toList(growable: false);
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Back',
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Upgrade'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: state.isLoading
                    ? null
                    : () =>
                        context.read<SubscriptionCubit>().loadSubscription(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<SubscriptionCubit>().loadSubscription(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroHeader(state: state),
                        const SizedBox(height: 20),
                        _CurrentPlanCard(
                          state: state,
                          onOpenBilling: state.subscription.isPremium &&
                                  !state.isActionLoading
                              ? () => context.push('/billing')
                              : null,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Choose your plan',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upgrade to unlock more uploads, ad-free listening, offline downloads, and priority support.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.isLoading && !state.hasPlans)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5500),
                      ),
                    ),
                  )
                else if (state.isFailure && !state.hasPlans)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: state.errorMessage ??
                          'Could not load subscription plans.',
                      onRetry: () =>
                          context.read<SubscriptionCubit>().loadSubscription(),
                    ),
                  )
                else if (plans.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      onRetry: () =>
                          context.read<SubscriptionCubit>().loadSubscription(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList.separated(
                      itemCount: plans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        final isCurrentPlan = plan.normalizedCode ==
                            state.subscription.normalizedPlanCode;

                        return _PlanCard(
                          plan: plan,
                          isCurrentPlan: isCurrentPlan,
                          isActionLoading: state.isActionLoading,
                          onUpgrade:
                              isCurrentPlan ? null : () => _handleUpgrade(plan),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.state});

  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final title = state.subscription.isPremium
        ? 'You are on ${state.subscription.displayPlanName}'
        : 'Unlock IQA3 Premium';

    final subtitle = state.subscription.isPremium
        ? 'Manage your plan, billing, and premium features from one place.'
        : 'Create more, listen without ads, and save tracks for offline playback.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5500),
            Color(0xFFB53600),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55333333),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              height: 1.35,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.state,
    required this.onOpenBilling,
  });

  final SubscriptionState state;
  final VoidCallback? onOpenBilling;

  @override
  Widget build(BuildContext context) {
    final subscription = state.subscription;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current plan',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  subscription.displayPlanName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _PlanBadge(
                text: subscription.isPremium ? 'Premium' : 'Free',
                isHighlighted: subscription.isPremium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FeatureLine(
            icon: Icons.cloud_upload_outlined,
            text:
                '${subscription.displayRemainingUploads} uploads remaining / ${subscription.displayUploadLimit}',
          ),
          const SizedBox(height: 8),
          _FeatureLine(
            icon: subscription.adsEnabled
                ? Icons.campaign_outlined
                : Icons.block_rounded,
            text: subscription.adsEnabled ? 'Ads enabled' : 'Ad-free listening',
          ),
          const SizedBox(height: 8),
          _FeatureLine(
            icon: Icons.download_for_offline_outlined,
            text: subscription.canDownload
                ? 'Offline downloads unlocked'
                : 'Offline downloads locked',
          ),
          if (subscription.cancelAtPeriodEnd) ...[
            const SizedBox(height: 12),
            const _WarningBox(
              text:
                  'Your subscription is scheduled to cancel at the end of the current billing period.',
            ),
          ],
          if (subscription.isPremium) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenBilling,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Manage billing'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isActionLoading,
    required this.onUpgrade,
  });

  final Plan plan;
  final bool isCurrentPlan;
  final bool isActionLoading;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = plan.isPro || plan.isGoPlus;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isHighlighted ? const Color(0xFF1D130D) : const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFF5500) : Colors.white10,
          width: isHighlighted ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (isCurrentPlan)
                const _PlanBadge(
                  text: 'Current',
                  isHighlighted: true,
                )
              else if (plan.trialDays > 0)
                _PlanBadge(
                  text: '${plan.trialDays}-day trial',
                  isHighlighted: false,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.displayPrice,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFFF5500),
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (plan.billingIntervalLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.billingIntervalLabel,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
          const SizedBox(height: 18),
          _FeatureLine(
            icon: Icons.cloud_upload_outlined,
            text: '${plan.displayUploadLimit} uploads',
          ),
          const SizedBox(height: 8),
          _FeatureLine(
            icon:
                plan.adsEnabled ? Icons.campaign_outlined : Icons.block_rounded,
            text: plan.adsEnabled ? 'Ads supported' : 'Ad-free listening',
          ),
          const SizedBox(height: 8),
          _FeatureLine(
            icon: Icons.download_for_offline_outlined,
            text: plan.canDownload
                ? 'Offline downloads'
                : 'Online streaming only',
          ),
          const SizedBox(height: 8),
          _FeatureLine(
            icon: Icons.support_agent_rounded,
            text: '${plan.supportLevel} support',
          ),
          if (plan.highlightedFeatures.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...plan.highlightedFeatures.take(4).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _FeatureLine(
                      icon: Icons.check_circle_outline_rounded,
                      text: feature,
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isCurrentPlan || isActionLoading ? null : onUpgrade,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: isActionLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isCurrentPlan
                          ? 'Current plan'
                          : 'Upgrade to ${plan.displayName}',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFFFF5500),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.text,
    required this.isHighlighted,
  });

  final String text;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFF5500) : Colors.white10,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x22FF5500),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55FF5500)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFFF5500),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF5500),
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5500),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            color: Colors.white38,
            size: 52,
          ),
          const SizedBox(height: 14),
          const Text(
            'No premium plans are available right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

String? _readSubscriptionUpgradePlanCode(Plan plan) {
  final candidates = <String>[
    plan.code,
    plan.tier,
    plan.name,
    plan.displayName,
  ];

  for (final candidate in candidates) {
    final normalized = _normalizeSubscriptionUpgradePlanCode(candidate);

    if (normalized == 'PRO' || normalized == 'GO_PLUS') {
      return normalized;
    }
  }

  return null;
}

String _normalizeSubscriptionUpgradePlanCode(String value) {
  final normalized =
      value.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (normalized.isEmpty) {
    return '';
  }

  if (normalized == 'GO+' ||
      normalized == 'GO_PLUS' ||
      normalized.contains('GO_PLUS') ||
      normalized.contains('GO+')) {
    return 'GO_PLUS';
  }

  if (normalized == 'PRO' || normalized.contains('PRO')) {
    return 'PRO';
  }

  if (normalized == 'FREE' || normalized.contains('FREE')) {
    return 'FREE';
  }

  return normalized;
}
