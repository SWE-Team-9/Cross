import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum AudioPickerPermission {
  audio,
  storage,
}

enum AudioPickerPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

abstract class AudioPickerPermissionGateway {
  Future<AudioPickerPermissionStatus> statusOf(
    AudioPickerPermission permission,
  );

  Future<AudioPickerPermissionStatus> request(
    AudioPickerPermission permission,
  );
}

class PermissionHandlerAudioPickerPermissionGateway
    implements AudioPickerPermissionGateway {
  const PermissionHandlerAudioPickerPermissionGateway();

  @override
  Future<AudioPickerPermissionStatus> statusOf(
    AudioPickerPermission permission,
  ) async {
    final status = await _resolvePermission(permission).status;
    return _mapStatus(status);
  }

  @override
  Future<AudioPickerPermissionStatus> request(
    AudioPickerPermission permission,
  ) async {
    final status = await _resolvePermission(permission).request();
    return _mapStatus(status);
  }

  Permission _resolvePermission(AudioPickerPermission permission) {
    switch (permission) {
      case AudioPickerPermission.audio:
        return Permission.audio;
      case AudioPickerPermission.storage:
        return Permission.storage;
    }
  }

  AudioPickerPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return AudioPickerPermissionStatus.granted;
    }

    if (status.isPermanentlyDenied) {
      return AudioPickerPermissionStatus.permanentlyDenied;
    }

    return AudioPickerPermissionStatus.denied;
  }
}

abstract class AudioPickerPermissionService {
  Future<void> ensurePermissionGranted();
}

class AudioPickerPermissionServiceImpl implements AudioPickerPermissionService {
  AudioPickerPermissionServiceImpl({
    AudioPickerPermissionGateway? gateway,
    bool? isAndroidOverride,
  })  : _gateway =
            gateway ?? const PermissionHandlerAudioPickerPermissionGateway(),
        _requiresRuntimePermission = isAndroidOverride ?? Platform.isAndroid;

  final AudioPickerPermissionGateway _gateway;
  final bool _requiresRuntimePermission;

  @override
  Future<void> ensurePermissionGranted() async {
    if (!_requiresRuntimePermission) {
      return;
    }

    final audioStatus = await _ensure(AudioPickerPermission.audio);
    if (audioStatus == AudioPickerPermissionStatus.granted) {
      return;
    }

    final storageStatus = await _ensure(AudioPickerPermission.storage);
    if (storageStatus == AudioPickerPermissionStatus.granted) {
      return;
    }

    if (audioStatus == AudioPickerPermissionStatus.permanentlyDenied ||
        storageStatus == AudioPickerPermissionStatus.permanentlyDenied) {
      throw Exception(
        'Audio file permission is permanently denied. Please enable it from system settings.',
      );
    }

    throw Exception(
      'Audio file permission was denied. Please allow access to continue.',
    );
  }

  Future<AudioPickerPermissionStatus> _ensure(
    AudioPickerPermission permission,
  ) async {
    final currentStatus = await _gateway.statusOf(permission);

    if (currentStatus == AudioPickerPermissionStatus.granted ||
        currentStatus == AudioPickerPermissionStatus.permanentlyDenied) {
      return currentStatus;
    }

    return _gateway.request(permission);
  }
}
