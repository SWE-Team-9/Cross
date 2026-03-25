import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../routes/auth_routes.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';
import '../widgets/auth_text_field.dart';

class CompleteProfilePage extends StatefulWidget {
  final Map<String, String> registrationData;

  const CompleteProfilePage({
    super.key,
    required this.registrationData,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final TextEditingController _displayNameController = TextEditingController();

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
    'December'
  ];

  final List<String> genders = const [
    'Male',
    'Female',
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  List<String> get days => List.generate(31, (index) => '${index + 1}');

  List<String> get years {
    final currentYear = DateTime.now().year;
    return List.generate(100, (index) => '${currentYear - index}');
  }

  String _getGenderEnumValue(String genderUiString) {
    switch (genderUiString) {
      case 'Male':
        return 'MALE';
      case 'Female':
        return 'FEMALE';
      default:
        return 'MALE';
    }
  }

  void _onContinuePressed() {
    final displayName = _displayNameController.text.trim();

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

    final monthIndexNum = months.indexOf(selectedMonth!);
    final dayNum = int.parse(selectedDay!);
    final yearNum = int.parse(selectedYear!);

    final birthDateObj = DateTime(yearNum, monthIndexNum, dayNum);
    final currentDate = DateTime.now();

    int age = currentDate.year - birthDateObj.year;
    if (currentDate.month < birthDateObj.month ||
        (currentDate.month == birthDateObj.month &&
            currentDate.day < birthDateObj.day)) {
      age--;
    }

    if (age < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be at least 13 years old to register.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final monthIndex = monthIndexNum.toString().padLeft(2, '0');
    final dayStr = selectedDay!.padLeft(2, '0');
    final birthDate = "$selectedYear-$monthIndex-$dayStr";

    context.read<AuthCubit>().register(
          email: widget.registrationData['email']!,
          password: widget.registrationData['password']!,
          passwordConfirm: widget.registrationData['passwordConfirm']!,
          displayName: displayName,
          dateOfBirth: birthDate,
          gender: _getGenderEnumValue(selectedGender!),
          captchaToken: widget.registrationData['captchaToken']!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: AuthScreenWrapper(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthRegisterSuccess) {
                context.go(AuthRoutes.verifyEmail,
                    extra: widget.registrationData['email']);
              }
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.redAccent),
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
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AuthTextField(
                      controller: _displayNameController,
                      hintText: 'Display name',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your display name can be anything you like. Your name or artist name are good choices.',
                      style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 14),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Date of birth (required)',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _AuthDropdown(
                            value: selectedMonth,
                            hint: 'Month',
                            items: months.skip(1).toList(),
                            onChanged: (val) =>
                                setState(() => selectedMonth = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AuthDropdown(
                            value: selectedDay,
                            hint: 'Day',
                            items: days,
                            onChanged: (val) =>
                                setState(() => selectedDay = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AuthDropdown(
                            value: selectedYear,
                            hint: 'Year',
                            items: years,
                            onChanged: (val) =>
                                setState(() => selectedYear = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    _AuthDropdown(
                      value: selectedGender,
                      hint: 'Gender (required)',
                      items: genders,
                      onChanged: (val) => setState(() => selectedGender = val),
                    ),
                    const SizedBox(height: 32),
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
        ),
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
      dropdownColor: const Color(0xFF2C2C2E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
