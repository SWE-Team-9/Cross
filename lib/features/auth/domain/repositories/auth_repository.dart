import '../entities/user.dart';

abstract class AuthRepository {
  // قمنا بحذف checkEmailExists لأنها لم تعد موجودة في الـ API

  Future<User> login({
    required String email,
    required String password,
  });

  // تحديث دالة التسجيل لتشمل كل البيانات المطلوبة
Future<User> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String displayName,
    required String dateOfBirth,
    required String gender,
  });

  Future<void> forgotPassword({
    required String email,
  });

 
  Future<void> resetPassword({
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  });
  
  Future<void> sendEmailVerification({
    required String email,
  });

  Future<void> verifyEmail({
    required String email, 
    required String code,
  });


  Future<User?> getCurrentUser();

  Future<void> logout();

  Future<bool> isLoggedIn();
}