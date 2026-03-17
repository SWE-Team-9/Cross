import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/audioFilePickerDataSource.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/uploadRepository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pickAudioFileUseCase.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerCubit.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('setupDependencies registers core and upload dependencies', () {
    setupDependencies();

    expect(getIt.isRegistered<DioClient>(), isTrue);
    expect(getIt.isRegistered<AudioFilePickerDataSource>(), isTrue);
    expect(getIt.isRegistered<UploadRepository>(), isTrue);
    expect(getIt.isRegistered<PickAudioFileUseCase>(), isTrue);
    expect(getIt.isRegistered<UploadPickerCubit>(), isTrue);

    final cubit = getIt<UploadPickerCubit>();
    expect(cubit, isA<UploadPickerCubit>());
    cubit.close();
  });
}