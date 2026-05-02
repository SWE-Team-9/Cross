import 'package:get_it/get_it.dart';

import '../../core/network/dio_client.dart';
import '../offline/data/repositories/offline_repository.dart';
import '../offline/presentation/bloc/offline_cubit.dart';
import '../upload/domain/usecases/check_upload_limit_usecase.dart';
import 'data/datasources/subscription_remote_data_source.dart';
import 'data/repositories/subscription_repository_impl.dart';
import 'domain/repositories/subscription_repository.dart';
import 'domain/usecases/subscription_usecases.dart';
import 'presentation/bloc/subscription_cubit.dart';

void registerPremiumDependencies(GetIt getIt) {
  if (!getIt.isRegistered<SubscriptionRemoteDataSource>()) {
    getIt.registerLazySingleton<SubscriptionRemoteDataSource>(
      () => SubscriptionRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<SubscriptionRepository>()) {
    getIt.registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(
        getIt<SubscriptionRemoteDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetMySubscriptionUseCase>()) {
    getIt.registerLazySingleton<GetMySubscriptionUseCase>(
      () => GetMySubscriptionUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<GetSubscriptionPlansUseCase>()) {
    getIt.registerLazySingleton<GetSubscriptionPlansUseCase>(
      () => GetSubscriptionPlansUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateCheckoutUseCase>()) {
    getIt.registerLazySingleton<CreateCheckoutUseCase>(
      () => CreateCheckoutUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<SubscribeUseCase>()) {
    getIt.registerLazySingleton<SubscribeUseCase>(
      () => SubscribeUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<OpenBillingPortalUseCase>()) {
    getIt.registerLazySingleton<OpenBillingPortalUseCase>(
      () => OpenBillingPortalUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<OpenBillingPortalUrlUseCase>()) {
    getIt.registerLazySingleton<OpenBillingPortalUrlUseCase>(
      () => OpenBillingPortalUrlUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<GetBillingInvoicesUseCase>()) {
    getIt.registerLazySingleton<GetBillingInvoicesUseCase>(
      () => GetBillingInvoicesUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<CancelSubscriptionUseCase>()) {
    getIt.registerLazySingleton<CancelSubscriptionUseCase>(
      () => CancelSubscriptionUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<ResumeSubscriptionUseCase>()) {
    getIt.registerLazySingleton<ResumeSubscriptionUseCase>(
      () => ResumeSubscriptionUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<ChangeSubscriptionPlanUseCase>()) {
    getIt.registerLazySingleton<ChangeSubscriptionPlanUseCase>(
      () => ChangeSubscriptionPlanUseCase(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<GetOfflineTrackEntitlementUseCase>()) {
    getIt.registerLazySingleton<GetOfflineTrackEntitlementUseCase>(
      () => GetOfflineTrackEntitlementUseCase(
        getIt<SubscriptionRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<CheckUploadLimitUseCase>()) {
    getIt.registerLazySingleton<CheckUploadLimitUseCase>(
      () => const CheckUploadLimitUseCase(),
    );
  }

  if (!getIt.isRegistered<SubscriptionCubit>()) {
    getIt.registerFactory<SubscriptionCubit>(
      () => SubscriptionCubit(getIt<SubscriptionRepository>()),
    );
  }

  if (!getIt.isRegistered<OfflineRepository>()) {
    getIt.registerLazySingleton<OfflineRepository>(
      () => OfflineRepository(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<OfflineCubit>()) {
    getIt.registerLazySingleton<OfflineCubit>(
      () => OfflineCubit(getIt<OfflineRepository>()),
    );
  }
}