import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/verify_email_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late VerifyEmailUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = VerifyEmailUseCase(repository);
  });

  test('should call repository.verifyEmail with the provided code', () async {
    // Arrange
    const tCode = '123456';

    // نجهز الـ mock بناءً على التوقيع الجديد في الـ Repository
    // الـ UseCase بيبعت الـ email كـ String فارغ حالياً
    when(() => repository.verifyEmail(email: any(named: 'email'), code: tCode))
        .thenAnswer((_) async => {});

    // Act
    await useCase(code: tCode);

    // Assert
    // نتحقق أن الـ UseCase نادى على الـ Repository بالـ code الصح
    verify(() =>
            repository.verifyEmail(email: any(named: 'email'), code: tCode))
        .called(1);
    verifyNoMoreInteractions(repository);
  });
}
