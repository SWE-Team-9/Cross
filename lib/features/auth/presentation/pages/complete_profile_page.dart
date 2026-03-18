import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';
import '../widgets/auth_text_field.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  late final TextEditingController displayNameController;

  String? selectedMonth;
  String? selectedDay;
  String? selectedYear;
  String? selectedGender;

  final List<String> months = const [
    'Month',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> genders = const [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    displayNameController.dispose();
    super.dispose();
  }

  List<String> get days => List.generate(31, (index) => '${index + 1}');

  List<String> get years {
    final currentYear = DateTime.now().year;
    return List.generate(100, (index) => '${currentYear - index}');
  }

  void _onContinuePressed() {
    final displayName = displayNameController.text.trim();

    if (displayName.isEmpty ||
        selectedMonth == null ||
        selectedDay == null ||
        selectedYear == null ||
        selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    final monthIndex = months.indexOf(selectedMonth!);

    context.read<AuthCubit>().completeProfile(
          displayName: displayName,
          birthMonth: monthIndex,
          birthDay: int.parse(selectedDay!),
          birthYear: int.parse(selectedYear!),
          gender: selectedGender!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenWrapper(
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthProfileCompleted || state is AuthAuthenticated) {
            context.go(AppRoutes.home);
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const AuthBackButton(),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Tell us more about you',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: displayNameController,
                  hintText: 'Display name',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your display name can be anything you like. Your name or artist name are good choices.',
                  style: TextStyle(
                    color: Color(0xFF9B9B9B),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Date of birth (required)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 380) {
                      return Column(
                        children: [
                          _AuthDropdown(
                            value: selectedMonth,
                            hint: 'Month',
                            items: months.skip(1).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMonth = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _AuthDropdown(
                            value: selectedDay,
                            hint: 'Day',
                            items: days,
                            onChanged: (value) {
                              setState(() {
                                selectedDay = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _AuthDropdown(
                            value: selectedYear,
                            hint: 'Year',
                            items: years,
                            onChanged: (value) {
                              setState(() {
                                selectedYear = value;
                              });
                            },
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _AuthDropdown(
                            value: selectedMonth,
                            hint: 'Month',
                            items: months.skip(1).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMonth = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AuthDropdown(
                            value: selectedDay,
                            hint: 'Day',
                            items: days,
                            onChanged: (value) {
                              setState(() {
                                selectedDay = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AuthDropdown(
                            value: selectedYear,
                            hint: 'Year',
                            items: years,
                            onChanged: (value) {
                              setState(() {
                                selectedYear = value;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your date of birth is used to verify your age and is not shared publicly.',
                  style: TextStyle(
                    color: Color(0xFF9B9B9B),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 26),
                _AuthDropdown(
                  value: selectedGender,
                  hint: 'Gender (required)',
                  items: genders,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                ),
                const SizedBox(height: 26),
                AuthButton(
                  text: 'Continue',
                  isLoading: isLoading,
                  onPressed: _onContinuePressed,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _AuthDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF2C2C2E),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF8B8B8B),
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4C4C4E),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4C4C4E),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4C4C4E),
          ),
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.white,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
