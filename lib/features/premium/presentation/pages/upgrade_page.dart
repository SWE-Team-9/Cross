import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/core/widgets/bottom_nav_bar.dart';
import '../bloc/upgrade_cubit.dart';
import '../bloc/upgrade_state.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';

class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UpgradeCubit(getIt<SubscriptionRepository>()),
      child: const _UpgradeView(),
    );
  }
}

class _UpgradeView extends StatefulWidget {
  const _UpgradeView();

  @override
  State<_UpgradeView> createState() => _UpgradeViewState();
}

class _UpgradeViewState extends State<_UpgradeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String _selectedOption = 'monthly';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      bottomNavigationBar: const BottomNavBar(selected: 4),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5500),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'IQA3 Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<UpgradeCubit, UpgradeState>(
        listener: (context, state) {
          if (state.status == UpgradeStatus.success) {
            context.read<SubscriptionCubit>().upgrade('PRO');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFFF5500),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: const Row(
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Welcome to IQA3 Pro 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<UpgradeCubit>();

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HERO ──────────────────────────────────────────
                    const _HeroSection(),

                    // ── BODY ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          Text(
                            'CHOOSE YOUR PLAN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Monthly
                          _PlanCard(
                            title: 'IQA3 Pro',
                            subtitle: 'Monthly',
                            price: 'EGP 175',
                            period: '/ month',
                            isSelected: _selectedOption == 'monthly',
                            savingsBadge: null,
                            features: const [
                              'Unlimited uploads',
                              'Advanced insights & analytics',
                              'Replace tracks without losing stats',
                              'Priority support',
                            ],
                            onTap: () {
                              setState(() => _selectedOption = 'monthly');
                              cubit.selectPlan('PRO');
                            },
                          ),

                          const SizedBox(height: 14),

                          // Yearly
                          _PlanCard(
                            title: 'IQA3 Pro',
                            subtitle: 'Yearly',
                            price: 'EGP 1055',
                            period: '/ year',
                            isSelected: _selectedOption == 'yearly',
                            savingsBadge: 'Save 50%',
                            features: const [
                              'Everything in monthly',
                              'Early access to new features',
                            ],
                            onTap: () {
                              setState(() => _selectedOption = 'yearly');
                              cubit.selectPlan('PRO');
                            },
                          ),

                          const SizedBox(height: 32),

                          // Feature highlights
                          _FeatureHighlights(),

                          const SizedBox(height: 32),

                          // CTA
                          _CtaButton(
                            isLoading: state.status == UpgradeStatus.loading,
                            onPressed: () => cubit.subscribe(),
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: Text(
                              'Cancel anytime · Secure payment',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient bg
        Container(
          height: 270,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A0800),
                Color(0xFF0A0A0A),
              ],
            ),
          ),
        ),

        // Orange glow blob
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF5500).withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRO badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5500).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFF5500).withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '⚡  PRO MEMBERSHIP',
                    style: TextStyle(
                      color: Color(0xFFFF5500),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "What's next in\nmusic starts here.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Unlock unlimited uploads, premium tools,\nand analytics built for creators.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PLAN CARD
// ────────────────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final bool isSelected;
  final String? savingsBadge;
  final List<String> features;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.isSelected,
    required this.features,
    required this.onTap,
    this.savingsBadge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF5500).withValues(alpha: 0.08)
              : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5500)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFFFF5500) : Colors.white24,
                      width: 2,
                    ),
                    color: isSelected
                        ? const Color(0xFFFF5500)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 14),

                // Title + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              period,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Savings badge
                if (savingsBadge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5500),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      savingsBadge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
              const SizedBox(height: 14),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: isSelected
                            ? const Color(0xFFFF5500)
                            : Colors.white30,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        f,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// FEATURE HIGHLIGHTS
// ────────────────────────────────────────────────────────────────────────────
class _FeatureHighlights extends StatelessWidget {
  final _highlights = const [
    (Icons.cloud_upload_rounded, 'Unlimited\nUploads'),
    (Icons.bar_chart_rounded, 'Deep\nAnalytics'),
    (Icons.swap_horiz_rounded, 'Track\nReplacement'),
    (Icons.headset_mic_rounded, 'Priority\nSupport'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVERYTHING YOU GET',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _highlights
              .map((h) => _HighlightTile(icon: h.$1, label: h.$2))
              .toList(),
        ),
      ],
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HighlightTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Icon(icon, color: const Color(0xFFFF5500), size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CTA BUTTON
// ────────────────────────────────────────────────────────────────────────────
class _CtaButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _CtaButton({required this.isLoading, required this.onPressed});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5500)
                    .withValues(alpha: 0.25 + _pulse.value * 0.2),
                blurRadius: 20 + _pulse.value * 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5500),
            disabledBackgroundColor:
                const Color(0xFFFF5500).withValues(alpha: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Upgrade to IQA3 Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
