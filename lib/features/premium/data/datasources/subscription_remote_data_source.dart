import 'dart:convert';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/billing_invoice.dart';
import '../../domain/entities/billing_portal_session.dart';
import '../../domain/entities/offline_track_entitlement.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';

abstract class SubscriptionRemoteDataSource {
  Future<Subscription> getMySubscription();

  Future<List<Plan>> getPlans();

  Future<String> createCheckout({
    required String planCode,
    String? returnUrl,
    String? cancelUrl,
  });

  Future<String> subscribe({
    required String subscriptionType,
    String? paymentMethodId,
  });

  Future<BillingPortalSession> openBillingPortalSession({
    String? returnUrl,
    String flow = 'billing',
  });

  Future<List<BillingInvoice>> getInvoices();

  Future<void> cancelSubscription();

  Future<Subscription> resumeSubscription();

  Future<Subscription> changePlan({
    required String planCode,
  });

  Future<Subscription> cancelPlanChange();

  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement({
    required String trackId,
  });
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  const SubscriptionRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<Subscription> getMySubscription() async {
    final response = await _dioClient.get(ApiConstants.mySubscription);
    final payload = _extractPayloadMap(response.data);

    return Subscription.fromJson(payload);
  }

  @override
  Future<List<Plan>> getPlans() async {
    final response = await _dioClient.get(ApiConstants.subscriptionPlans);
    final items = _extractPayloadList(response.data);

    return items
        .map((item) => Plan.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  @override
  Future<String> createCheckout({
    required String planCode,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.subscriptionCheckout,
      data: <String, dynamic>{
        'planCode': planCode,
        if (_isNotBlank(returnUrl)) 'returnUrl': returnUrl!.trim(),
        if (_isNotBlank(cancelUrl)) 'cancelUrl': cancelUrl!.trim(),
      },
    );

    final payload = _extractPayloadMap(response.data);
    return _extractUrlOrMessage(payload);
  }

  @override
  Future<String> subscribe({
    required String subscriptionType,
    String? paymentMethodId,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.subscriptionSubscribe,
      data: <String, dynamic>{
        'subscriptionType': subscriptionType,
        if (_isNotBlank(paymentMethodId))
          'paymentMethodId': paymentMethodId!.trim(),
      },
    );

    final payload = _extractPayloadMap(response.data);
    return _extractUrlOrMessage(payload);
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession({
    String? returnUrl,
    String flow = 'billing',
  }) async {
    final response = await _dioClient.post(
      ApiConstants.subscriptionPortal,
      data: <String, dynamic>{
        if (_isNotBlank(returnUrl)) 'returnUrl': returnUrl!.trim(),
        if (_isNotBlank(flow)) 'flow': flow.trim(),
      },
    );

    final payload = _normalizePortalPayload(
      _extractPayloadMap(response.data),
    );

    return BillingPortalSession.fromJson(payload);
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    final response = await _dioClient.get(ApiConstants.subscriptionInvoices);
    final items = _extractPayloadList(response.data);

    return items
        .map((item) => BillingInvoice.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  @override
  Future<void> cancelSubscription() async {
    await _dioClient.post(ApiConstants.subscriptionCancel);
  }

  @override
  Future<Subscription> resumeSubscription() async {
    final response = await _dioClient.post(ApiConstants.subscriptionResume);
    final payload = _extractPayloadMap(response.data);

    return Subscription.fromJson(payload);
  }

  @override
  Future<Subscription> changePlan({
    required String planCode,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.subscriptionChangePlan,
      data: <String, dynamic>{
        'planCode': planCode,
      },
    );

    final payload = _extractPayloadMap(response.data);
    return Subscription.fromJson(payload);
  }

  @override
  Future<Subscription> cancelPlanChange() async {
    final response = await _dioClient.post(
      ApiConstants.subscriptionCancelPlanChange,
    );

    final payload = _extractPayloadMap(response.data);
    return Subscription.fromJson(payload);
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement({
    required String trackId,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.subscriptionOfflineTrackPath(trackId),
    );

    final payload = _extractPayloadMap(response.data);
    return OfflineTrackEntitlement.fromJson(payload);
  }
}

dynamic _decodeJsonIfNeeded(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(trimmed);
  }

  return value;
}

Map<String, dynamic> _extractPayloadMap(dynamic responseData) {
  final decoded = _decodeJsonIfNeeded(responseData);
  final map = _asMap(decoded);

  final data = map['data'];
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  final subscription = map['subscription'];
  if (subscription is Map) {
    return Map<String, dynamic>.from(subscription);
  }

  final result = map['result'];
  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }

  return map;
}

List<dynamic> _extractPayloadList(dynamic responseData) {
  final decoded = _decodeJsonIfNeeded(responseData);

  if (decoded is List) {
    return decoded;
  }

  final map = _asMap(decoded);

  final data = map['data'];
  if (data is List) {
    return data;
  }

  final items = map['items'];
  if (items is List) {
    return items;
  }

  final results = map['results'];
  if (results is List) {
    return results;
  }

  final invoices = map['invoices'];
  if (invoices is List) {
    return invoices;
  }

  final plans = map['plans'];
  if (plans is List) {
    return plans;
  }

  throw const FormatException('Expected a JSON list response.');
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw FormatException(
    'Expected a JSON object but got ${value.runtimeType}.',
  );
}

String _extractUrlOrMessage(Map<String, dynamic> payload) {
  final candidates = <dynamic>[
    payload['checkoutUrl'],
    payload['checkout_url'],
    payload['url'],
    payload['portalUrl'],
    payload['portal_url'],
    payload['redirectUrl'],
    payload['redirect_url'],
    payload['message'],
  ];

  for (final candidate in candidates) {
    final parsed = candidate?.toString().trim() ?? '';
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }

  return '';
}

Map<String, dynamic> _normalizePortalPayload(Map<String, dynamic> payload) {
  final normalized = Map<String, dynamic>.from(payload);

  normalized['sessionId'] ??=
      normalized['portalSessionId'] ?? normalized['portal_session_id'];
  normalized['url'] ??= normalized['portalUrl'] ?? normalized['portal_url'];

  final paymentMethodSummary = normalized['paymentMethodSummary'] ??
      normalized['payment_method_summary'];

  if (paymentMethodSummary is Map) {
    normalized['paymentMethod'] ??= Map<String, dynamic>.from(
      paymentMethodSummary,
    );
    normalized['paymentMethodSummary'] = _formatPaymentMethodSummary(
      Map<String, dynamic>.from(paymentMethodSummary),
    );
  }

  final capabilities = normalized['capabilities'];
  if (capabilities is Map) {
    final capabilitiesMap = Map<String, dynamic>.from(capabilities);

    normalized['canUpdatePaymentMethod'] ??=
        capabilitiesMap['canUpdatePaymentMethod'] ??
            capabilitiesMap['can_update_payment_method'];

    normalized['canCancel'] ??=
        capabilitiesMap['canCancel'] ?? capabilitiesMap['can_cancel'];

    normalized['canResume'] ??=
        capabilitiesMap['canResume'] ?? capabilitiesMap['can_resume'];

    normalized['canChangePlan'] ??=
        capabilitiesMap['canChangePlan'] ?? capabilitiesMap['can_change_plan'];
  }

  return normalized;
}

String _formatPaymentMethodSummary(Map<String, dynamic> paymentMethod) {
  final brand = paymentMethod['brand']?.toString().trim() ?? '';
  final last4 = paymentMethod['last4']?.toString().trim() ?? '';

  if (brand.isEmpty && last4.isEmpty) {
    return '';
  }

  if (brand.isEmpty) {
    return '•••• $last4';
  }

  final formattedBrand = brand[0].toUpperCase() + brand.substring(1);

  if (last4.isEmpty) {
    return formattedBrand;
  }

  return '$formattedBrand •••• $last4';
}

bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
