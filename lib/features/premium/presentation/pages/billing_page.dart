import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/billing_invoice.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';
import '../bloc/subscription_cubit.dart';
import '../bloc/subscription_state.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  String? _handledBillingReturnSignature;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final handledReturn = _handleBillingReturnIfNeeded();

      if (!handledReturn) {
        context.read<SubscriptionCubit>().loadBilling();
      }
    });
  }

  bool _handleBillingReturnIfNeeded() {
    final queryParameters = _billingReturnQueryParameters();

    if (queryParameters.isEmpty ||
        !_hasBillingReturnParameter(queryParameters)) {
      return false;
    }

    final signature = _billingReturnSignature(queryParameters);

    if (_handledBillingReturnSignature == signature) {
      return true;
    }

    _handledBillingReturnSignature = signature;

    final status = _readReturnParameter(
      queryParameters,
      const <String>[
        'status',
        'payment_status',
        'paymentStatus',
        'billing_status',
        'billingStatus',
      ],
    );

    final planCode = _readReturnParameter(
      queryParameters,
      const <String>[
        'plan',
        'plan_code',
        'planCode',
        'tier',
        'subscription_type',
        'subscriptionType',
      ],
    );

    if (_isSuccessStatus(status)) {
      final planSuffix =
          planCode == null ? '' : ' for ${planCode.trim().toUpperCase()}';

      _showSnackBar(
          'Payment confirmed$planSuffix. Refreshing billing details.');
    } else if (_isCancelStatus(status)) {
      _showSnackBar('Checkout was canceled. No billing changes were made.');
    } else if (status != null && status.trim().isNotEmpty) {
      _showSnackBar(
          'Billing returned with status: ${status.trim()}. Refreshing details.');
    } else {
      _showSnackBar('Returned from billing. Refreshing billing details.');
    }

    unawaited(context.read<SubscriptionCubit>().loadBilling());

    return true;
  }

  Map<String, String> _billingReturnQueryParameters() {
    try {
      return Map<String, String>.from(
        GoRouterState.of(context).uri.queryParameters,
      );
    } catch (_) {
      return const <String, String>{};
    }
  }

  bool _hasBillingReturnParameter(Map<String, String> queryParameters) {
    return _readReturnParameter(
          queryParameters,
          const <String>[
            'status',
            'payment_status',
            'paymentStatus',
            'billing_status',
            'billingStatus',
            'plan',
            'plan_code',
            'planCode',
            'tier',
            'subscription_type',
            'subscriptionType',
            'session_id',
            'sessionId',
            'billing_session_id',
            'billingSessionId',
            'portal_session_id',
            'portalSessionId',
            'checkout_session_id',
            'checkoutSessionId',
            'checkout_id',
            'checkoutId',
            'subscription_id',
            'subscriptionId',
            'sub',
            'cs',
          ],
        ) !=
        null;
  }

  String _billingReturnSignature(Map<String, String> queryParameters) {
    final entries = queryParameters.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return entries
        .map((entry) => '${entry.key.trim()}=${entry.value.trim()}')
        .join('&');
  }

  String? _readReturnParameter(
    Map<String, String> queryParameters,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = queryParameters[key]?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  bool _isSuccessStatus(String? status) {
    final normalized = status?.trim().toUpperCase() ?? '';

    return normalized == 'SUCCESS' ||
        normalized == 'COMPLETED' ||
        normalized == 'PAID' ||
        normalized == 'ACTIVE';
  }

  bool _isCancelStatus(String? status) {
    final normalized = status?.trim().toUpperCase() ?? '';

    return normalized == 'CANCEL' ||
        normalized == 'CANCELED' ||
        normalized == 'CANCELLED';
  }

  Future<void> _openBillingPortal() async {
    try {
      final portalUrl =
          await context.read<SubscriptionCubit>().openBillingPortal();

      if (!mounted) return;

      if (portalUrl.trim().isEmpty) {
        _showSnackBar('Billing portal is not available right now.');
        return;
      }

      await _launchExternalUrl(portalUrl);
    } catch (_) {
      // Cubit emits the readable error message.
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

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text(
            'Cancel subscription?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Your premium features will stay active until the end of the current billing period.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep plan'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel plan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<SubscriptionCubit>().cancel();
  }

  Future<void> _confirmResume() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text(
            'Resume subscription?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Your plan will renew normally at the end of the billing period.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                foregroundColor: Colors.white,
              ),
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<SubscriptionCubit>().resume();
  }

  Future<void> _confirmCancelPlanChange() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text(
            'Cancel scheduled plan change?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Your current plan will continue without switching at the next billing period.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep schedule'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel change'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<SubscriptionCubit>().cancelPlanChange();
  }

  Future<void> _changePlan(Plan plan) async {
    final planCode = _readSubscriptionChangePlanCode(plan);

    if (planCode == null) {
      _showSnackBar(
        'This plan cannot be switched from here. Use cancel subscription to return to Free.',
      );
      return;
    }

    await context.read<SubscriptionCubit>().changePlan(planCode);
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

        if (_handledBillingReturnSignature != null &&
            state.actionErrorMessage == null &&
            state.errorMessage == null &&
            state.actionMessage == 'Billing details loaded.') {
          return;
        }

        _showSnackBar(message);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Billing'),
            actions: [
              IconButton(
                tooltip: 'Refresh billing',
                onPressed: state.isActionLoading
                    ? null
                    : () => context.read<SubscriptionCubit>().loadBilling(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<SubscriptionCubit>().loadBilling(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.isActionLoading && state.invoices.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5500),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed(
                        [
                          _SubscriptionSummaryCard(
                            subscription: state.subscription,
                            isActionLoading: state.isActionLoading,
                            onOpenPortal: state.subscription.isPremium
                                ? _openBillingPortal
                                : null,
                            onCancel: state.subscription.isPremium &&
                                    !state.subscription.cancelAtPeriodEnd
                                ? _confirmCancel
                                : null,
                            onResume: state.subscription.canResume
                                ? _confirmResume
                                : null,
                          ),
                          const SizedBox(height: 22),
                          if (state.subscription.hasPendingDowngrade) ...[
                            _PendingPlanChangeCard(
                              subscription: state.subscription,
                              isActionLoading: state.isActionLoading,
                              onCancelPlanChange: _confirmCancelPlanChange,
                            ),
                            const SizedBox(height: 22),
                          ],
                          _PlanManagementSection(
                            plans: state.upgradePlans,
                            currentPlanCode:
                                state.subscription.normalizedPlanCode,
                            isActionLoading: state.isActionLoading,
                            onChangePlan: _changePlan,
                          ),
                          const SizedBox(height: 22),
                          _InvoicesSection(
                            invoices: state.invoices,
                            onRefresh: () =>
                                context.read<SubscriptionCubit>().loadBilling(),
                          ),
                        ],
                      ),
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

class _SubscriptionSummaryCard extends StatelessWidget {
  const _SubscriptionSummaryCard({
    required this.subscription,
    required this.isActionLoading,
    required this.onOpenPortal,
    required this.onCancel,
    required this.onResume,
  });

  final Subscription subscription;
  final bool isActionLoading;
  final VoidCallback? onOpenPortal;
  final VoidCallback? onCancel;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  subscription.displayPlanName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              _StatusBadge(
                text: subscription.isPremium ? 'Premium' : 'Free',
                highlighted: subscription.isPremium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BillingInfoLine(
            icon: Icons.cloud_upload_outlined,
            label: 'Uploads',
            value:
                '${subscription.displayRemainingUploads} remaining / ${subscription.displayUploadLimit}',
          ),
          const SizedBox(height: 10),
          _BillingInfoLine(
            icon: Icons.download_for_offline_outlined,
            label: 'Downloads',
            value: subscription.canDownload ? 'Unlocked' : 'Locked',
          ),
          const SizedBox(height: 10),
          _BillingInfoLine(
            icon: Icons.campaign_outlined,
            label: 'Ads',
            value: subscription.adsEnabled ? 'Enabled' : 'Ad-free',
          ),
          if (subscription.nextBillingDate != null) ...[
            const SizedBox(height: 10),
            _BillingInfoLine(
              icon: Icons.event_available_outlined,
              label: subscription.cancelAtPeriodEnd ? 'Ends on' : 'Renews on',
              value: _formatDate(subscription.nextBillingDate!),
            ),
          ],
          if (subscription.paymentMethodSummary != null &&
              subscription.paymentMethodSummary!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _BillingInfoLine(
              icon: Icons.credit_card_rounded,
              label: 'Payment',
              value: subscription.paymentMethodSummary!,
            ),
          ],
          if (subscription.cancelAtPeriodEnd) ...[
            const SizedBox(height: 14),
            const _NoticeBox(
              text:
                  'Cancellation is scheduled. You can resume before the billing period ends.',
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: isActionLoading ? null : onOpenPortal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open portal'),
              ),
              if (onCancel != null)
                OutlinedButton.icon(
                  onPressed: isActionLoading ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
              if (onResume != null)
                FilledButton.icon(
                  onPressed: isActionLoading ? null : onResume,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5500),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Resume'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingPlanChangeCard extends StatelessWidget {
  const _PendingPlanChangeCard({
    required this.subscription,
    required this.isActionLoading,
    required this.onCancelPlanChange,
  });

  final Subscription subscription;
  final bool isActionLoading;
  final VoidCallback onCancelPlanChange;

  @override
  Widget build(BuildContext context) {
    final pendingPlanName = _readPendingPlanName(subscription.pendingDowngrade);
    final effectiveDate = _readPendingPlanEffectiveDate(
      subscription.pendingDowngrade,
    );

    return _SectionCard(
      title: 'Scheduled plan change',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NoticeBox(
            text:
                'A plan change is scheduled for your next billing period. Your current plan remains active until then.',
          ),
          const SizedBox(height: 14),
          _BillingInfoLine(
            icon: Icons.workspace_premium_outlined,
            label: 'Next plan',
            value: pendingPlanName,
          ),
          if (effectiveDate != null) ...[
            const SizedBox(height: 10),
            _BillingInfoLine(
              icon: Icons.event_available_outlined,
              label: 'Effective date',
              value: _formatDate(effectiveDate),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: isActionLoading ? null : onCancelPlanChange,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Cancel plan change'),
          ),
        ],
      ),
    );
  }
}

class _PlanManagementSection extends StatelessWidget {
  const _PlanManagementSection({
    required this.plans,
    required this.currentPlanCode,
    required this.isActionLoading,
    required this.onChangePlan,
  });

  final List<Plan> plans;
  final String currentPlanCode;
  final bool isActionLoading;
  final ValueChanged<Plan> onChangePlan;

  @override
  Widget build(BuildContext context) {
    final currentBackendPlanCode = _normalizeSubscriptionChangePlanCode(
      currentPlanCode,
    );

    final switchablePlans = plans.where((plan) {
      final planCode = _readSubscriptionChangePlanCode(plan);

      if (planCode == null) {
        return false;
      }

      return planCode != currentBackendPlanCode;
    }).toList(growable: false);

    if (switchablePlans.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Change plan',
      child: Column(
        children: [
          for (int index = 0; index < switchablePlans.length; index++) ...[
            _PlanChangeTile(
              plan: switchablePlans[index],
              isCurrentPlan: false,
              isActionLoading: isActionLoading,
              onChangePlan: onChangePlan,
            ),
            if (index != switchablePlans.length - 1)
              const Divider(color: Colors.white10, height: 1),
          ],
        ],
      ),
    );
  }}
class _PlanChangeTile extends StatelessWidget {
  const _PlanChangeTile({
    required this.plan,
    required this.isCurrentPlan,
    required this.isActionLoading,
    required this.onChangePlan,
  });

  final Plan plan;
  final bool isCurrentPlan;
  final bool isActionLoading;
  final ValueChanged<Plan> onChangePlan;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        plan.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${plan.displayPrice} • ${plan.displayUploadLimit} uploads',
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: isCurrentPlan
          ? const _StatusBadge(text: 'Current', highlighted: true)
          : TextButton(
              onPressed: isActionLoading ? null : () => onChangePlan(plan),
              child: const Text('Switch'),
            ),
    );
  }
}
class _InvoicesSection extends StatelessWidget {
  const _InvoicesSection({
    required this.invoices,
    required this.onRefresh,
  });

  final List<BillingInvoice> invoices;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Invoices',
      trailing: TextButton(
        onPressed: onRefresh,
        child: const Text('Refresh'),
      ),
      child: invoices.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'No invoices yet.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          : Column(
              children: [
                for (int index = 0; index < invoices.length; index++) ...[
                  _InvoiceTile(invoice: invoices[index]),
                  if (index != invoices.length - 1)
                    const Divider(color: Colors.white10, height: 1),
                ],
              ],
            ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});

  final BillingInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final date = invoice.paidAt ?? invoice.createdAt ?? invoice.dueAt;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            invoice.isPaid ? const Color(0x3334C759) : const Color(0x33FF5500),
        child: Icon(
          invoice.isPaid ? Icons.check_rounded : Icons.receipt_long_outlined,
          color: invoice.isPaid ? Colors.greenAccent : const Color(0xFFFF5500),
        ),
      ),
      title: Text(
        invoice.displayPlanName.isEmpty
            ? invoice.invoiceId
            : invoice.displayPlanName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        [
          invoice.displayStatus,
          if (date != null) _formatDate(date),
        ].join(' • '),
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: Text(
        invoice.displayAmountPaid,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BillingInfoLine extends StatelessWidget {
  const _BillingInfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF5500), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.highlighted,
  });

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFF5500) : Colors.white10,
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

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.text});

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

String _readPendingPlanName(Map<String, dynamic>? pendingDowngrade) {
  if (pendingDowngrade == null || pendingDowngrade.isEmpty) {
    return 'Next plan';
  }

  final candidates = <dynamic>[
    pendingDowngrade['planName'],
    pendingDowngrade['plan_name'],
    pendingDowngrade['name'],
    pendingDowngrade['targetPlanName'],
    pendingDowngrade['target_plan_name'],
    pendingDowngrade['newPlanName'],
    pendingDowngrade['new_plan_name'],
    pendingDowngrade['planCode'],
    pendingDowngrade['plan_code'],
    pendingDowngrade['targetPlanCode'],
    pendingDowngrade['target_plan_code'],
    pendingDowngrade['newPlanCode'],
    pendingDowngrade['new_plan_code'],
  ];

  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';

    if (value.isNotEmpty) {
      return _formatPlanName(value);
    }
  }

  return 'Next plan';
}

DateTime? _readPendingPlanEffectiveDate(
  Map<String, dynamic>? pendingDowngrade,
) {
  if (pendingDowngrade == null || pendingDowngrade.isEmpty) {
    return null;
  }

  final candidates = <dynamic>[
    pendingDowngrade['effectiveDate'],
    pendingDowngrade['effective_date'],
    pendingDowngrade['currentPeriodEnd'],
    pendingDowngrade['current_period_end'],
    pendingDowngrade['scheduledAt'],
    pendingDowngrade['scheduled_at'],
    pendingDowngrade['startsAt'],
    pendingDowngrade['starts_at'],
  ];

  for (final candidate in candidates) {
    final parsed = DateTime.tryParse(candidate?.toString().trim() ?? '');

    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

String _formatPlanName(String value) {
  final normalized = value.trim().toUpperCase();

  switch (normalized) {
    case 'GO_PLUS':
    case 'GO+':
      return 'GO+';
    case 'PRO':
      return 'Pro';
    case 'FREE':
      return 'Free';
    default:
      return value.trim();
  }
}
String? _readSubscriptionChangePlanCode(Plan plan) {
  final candidates = <String>[
    plan.code,
    plan.tier,
    plan.name,
    plan.displayName,
  ];

  for (final candidate in candidates) {
    final normalized = _normalizeSubscriptionChangePlanCode(candidate);

    if (normalized == 'PRO' || normalized == 'GO_PLUS') {
      return normalized;
    }
  }

  return null;
}

String _normalizeSubscriptionChangePlanCode(String value) {
  final normalized = value
      .trim()
      .toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

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
String _formatDate(DateTime date) {
  final normalized = date.toLocal();
  final day = normalized.day.toString().padLeft(2, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final year = normalized.year.toString();

  return '$day/$month/$year';
}
