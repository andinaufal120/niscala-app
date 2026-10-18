//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of niscala_api;

class ApiClient {
  ApiClient({this.basePath = 'http://localhost', this.authentication,});

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
     _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType,
  ) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty ? '?${urlEncodedQueryParams.join('&')}' : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (
        body is MultipartFile && (contentType == null ||
        !contentType.toLowerCase().startsWith('multipart/form-data'))
      ) {
        final request = StreamedRequest(method, uri);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
          request.sink.add,
          onDone: request.sink.close,
          // ignore: avoid_types_on_closure_parameters
          onError: (Object error, StackTrace trace) => request.sink.close(),
          cancelOnError: true,
        );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = MultipartRequest(method, uri);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
        ? formParams
        : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      switch(method) {
        case 'POST': return await _client.post(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'PUT': return await _client.put(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'DELETE': return await _client.delete(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'PATCH': return await _client.patch(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'HEAD': return await _client.head(uri, headers: nullableHeaderParams,);
        case 'GET': return await _client.get(uri, headers: nullableHeaderParams,);
      }
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }

    throw ApiException(
      HttpStatus.badRequest,
      'Invalid HTTP operation: $method $path',
    );
  }

  Future<dynamic> deserializeAsync(String value, String targetType, {bool growable = false,}) async =>
    // ignore: deprecated_member_use_from_same_package
    deserialize(value, targetType, growable: growable);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(String value, String targetType, {bool growable = false,}) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType = targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
      ? value
      : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(dynamic value, String targetType, {bool growable = false,}) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'Account':
          return Account.fromJson(value);
        case 'AccountPropertyRef':
          return AccountPropertyRef.fromJson(value);
        case 'AccountTenancy':
          return AccountTenancy.fromJson(value);
        case 'ActiveLeaseSummary':
          return ActiveLeaseSummary.fromJson(value);
        case 'AddLocalPasswordInput':
          return AddLocalPasswordInput.fromJson(value);
        case 'AiComplaintClassification':
          return AiComplaintClassification.fromJson(value);
        case 'AuthSession':
          return AuthSession.fromJson(value);
        case 'AuthTokens':
          return AuthTokens.fromJson(value);
        case 'BankAccount':
          return BankAccount.fromJson(value);
        case 'BillingCycle':
          return BillingCycleTypeTransformer().decode(value);
        case 'CashPaymentInput':
          return CashPaymentInput.fromJson(value);
        case 'Complaint':
          return Complaint.fromJson(value);
        case 'ComplaintCategoryList':
          return ComplaintCategoryList.fromJson(value);
        case 'ComplaintClassification':
          return ComplaintClassification.fromJson(value);
        case 'ComplaintClassificationInput':
          return ComplaintClassificationInput.fromJson(value);
        case 'ComplaintClassificationState':
          return ComplaintClassificationStateTypeTransformer().decode(value);
        case 'ComplaintInput':
          return ComplaintInput.fromJson(value);
        case 'ComplaintList':
          return ComplaintList.fromJson(value);
        case 'ComplaintStatus':
          return ComplaintStatusTypeTransformer().decode(value);
        case 'ComplaintStatusChange':
          return ComplaintStatusChange.fromJson(value);
        case 'ComplaintStatusChangeInput':
          return ComplaintStatusChangeInput.fromJson(value);
        case 'ComplaintSummary':
          return ComplaintSummary.fromJson(value);
        case 'ComplaintUrgency':
          return ComplaintUrgencyTypeTransformer().decode(value);
        case 'CurrentLease':
          return CurrentLease.fromJson(value);
        case 'CurrentLeaseResult':
          return CurrentLeaseResult.fromJson(value);
        case 'CurrentLeaseRoom':
          return CurrentLeaseRoom.fromJson(value);
        case 'DeviceInfo':
          return DeviceInfo.fromJson(value);
        case 'EditableAccountStatus':
          return EditableAccountStatusTypeTransformer().decode(value);
        case 'EmailConfirmationInput':
          return EmailConfirmationInput.fromJson(value);
        case 'EmailVerificationSent':
          return EmailVerificationSent.fromJson(value);
        case 'EmergencyContact':
          return EmergencyContact.fromJson(value);
        case 'FacilitySuggestionList':
          return FacilitySuggestionList.fromJson(value);
        case 'GoogleAuthInput':
          return GoogleAuthInput.fromJson(value);
        case 'InvitationAcceptancePreview':
          return InvitationAcceptancePreview.fromJson(value);
        case 'InvitationBlocker':
          return InvitationBlockerTypeTransformer().decode(value);
        case 'InvitationGoogleActivationInput':
          return InvitationGoogleActivationInput.fromJson(value);
        case 'InvitationLinkStatus':
          return InvitationLinkStatusTypeTransformer().decode(value);
        case 'InvitationPasswordActivationInput':
          return InvitationPasswordActivationInput.fromJson(value);
        case 'InvitationPreview':
          return InvitationPreview.fromJson(value);
        case 'InvitationProperty':
          return InvitationProperty.fromJson(value);
        case 'InvitationRole':
          return InvitationRoleTypeTransformer().decode(value);
        case 'Lease':
          return Lease.fromJson(value);
        case 'LeaseInput':
          return LeaseInput.fromJson(value);
        case 'LinkGoogleInput':
          return LinkGoogleInput.fromJson(value);
        case 'LoginInput':
          return LoginInput.fromJson(value);
        case 'LoginMethod':
          return LoginMethodTypeTransformer().decode(value);
        case 'Manager':
          return Manager.fromJson(value);
        case 'ManagerAccountStatus':
          return ManagerAccountStatusTypeTransformer().decode(value);
        case 'ManagerInput':
          return ManagerInput.fromJson(value);
        case 'ManagerInvitation':
          return ManagerInvitation.fromJson(value);
        case 'ManagerList':
          return ManagerList.fromJson(value);
        case 'ManagerProperty':
          return ManagerProperty.fromJson(value);
        case 'ManagerRef':
          return ManagerRef.fromJson(value);
        case 'ManagerSummary':
          return ManagerSummary.fromJson(value);
        case 'NewTenantInput':
          return NewTenantInput.fromJson(value);
        case 'Notification':
          return Notification.fromJson(value);
        case 'NotificationCategory':
          return NotificationCategoryTypeTransformer().decode(value);
        case 'NotificationComplaint':
          return NotificationComplaint.fromJson(value);
        case 'NotificationList':
          return NotificationList.fromJson(value);
        case 'NotificationRentBill':
          return NotificationRentBill.fromJson(value);
        case 'NotificationSettingItem':
          return NotificationSettingItem.fromJson(value);
        case 'NotificationSettings':
          return NotificationSettings.fromJson(value);
        case 'NotificationSettingsInput':
          return NotificationSettingsInput.fromJson(value);
        case 'NotificationType':
          return NotificationTypeTypeTransformer().decode(value);
        case 'NotificationUrgencyScope':
          return NotificationUrgencyScopeTypeTransformer().decode(value);
        case 'Occupancy':
          return OccupancyTypeTransformer().decode(value);
        case 'OccupancyDashboard':
          return OccupancyDashboard.fromJson(value);
        case 'OccupancyRoom':
          return OccupancyRoom.fromJson(value);
        case 'OccupancySummary':
          return OccupancySummary.fromJson(value);
        case 'OrderStatus':
          return OrderStatusTypeTransformer().decode(value);
        case 'PaidPlanCode':
          return PaidPlanCodeTypeTransformer().decode(value);
        case 'PasswordChangeInput':
          return PasswordChangeInput.fromJson(value);
        case 'PasswordChangeResult':
          return PasswordChangeResult.fromJson(value);
        case 'PasswordResetInput':
          return PasswordResetInput.fromJson(value);
        case 'PasswordResetPreview':
          return PasswordResetPreview.fromJson(value);
        case 'PasswordResetRequestInput':
          return PasswordResetRequestInput.fromJson(value);
        case 'Payment':
          return Payment.fromJson(value);
        case 'PaymentMethod':
          return PaymentMethodTypeTransformer().decode(value);
        case 'PaymentOverview':
          return PaymentOverview.fromJson(value);
        case 'PaymentOverviewItem':
          return PaymentOverviewItem.fromJson(value);
        case 'PaymentPattern':
          return PaymentPattern.fromJson(value);
        case 'PaymentPatternList':
          return PaymentPatternList.fromJson(value);
        case 'PaymentStatus':
          return PaymentStatusTypeTransformer().decode(value);
        case 'PaymentStatusChange':
          return PaymentStatusChange.fromJson(value);
        case 'PaymentStatusChangeInput':
          return PaymentStatusChangeInput.fromJson(value);
        case 'PlanCode':
          return PlanCodeTypeTransformer().decode(value);
        case 'Property':
          return Property.fromJson(value);
        case 'PropertyInput':
          return PropertyInput.fromJson(value);
        case 'PropertyList':
          return PropertyList.fromJson(value);
        case 'PropertyOccupancy':
          return PropertyOccupancy.fromJson(value);
        case 'PropertyRef':
          return PropertyRef.fromJson(value);
        case 'PropertySummary':
          return PropertySummary.fromJson(value);
        case 'PurchaseVerificationInput':
          return PurchaseVerificationInput.fromJson(value);
        case 'PushTokenInput':
          return PushTokenInput.fromJson(value);
        case 'Reauthentication':
          return Reauthentication.fromJson(value);
        case 'ReauthenticationGoogleInput':
          return ReauthenticationGoogleInput.fromJson(value);
        case 'ReauthenticationPasswordInput':
          return ReauthenticationPasswordInput.fromJson(value);
        case 'ReceiptRejectionInput':
          return ReceiptRejectionInput.fromJson(value);
        case 'RefreshInput':
          return RefreshInput.fromJson(value);
        case 'RegisterOwnerInput':
          return RegisterOwnerInput.fromJson(value);
        case 'RentBill':
          return RentBill.fromJson(value);
        case 'RentBillList':
          return RentBillList.fromJson(value);
        case 'RentBillSummary':
          return RentBillSummary.fromJson(value);
        case 'Room':
          return Room.fromJson(value);
        case 'RoomInput':
          return RoomInput.fromJson(value);
        case 'RoomLease':
          return RoomLease.fromJson(value);
        case 'RoomLeaseSummary':
          return RoomLeaseSummary.fromJson(value);
        case 'RoomList':
          return RoomList.fromJson(value);
        case 'RoomRef':
          return RoomRef.fromJson(value);
        case 'RoomSummary':
          return RoomSummary.fromJson(value);
        case 'ScheduledDowngrade':
          return ScheduledDowngrade.fromJson(value);
        case 'ScheduledDowngradeInput':
          return ScheduledDowngradeInput.fromJson(value);
        case 'Session':
          return Session.fromJson(value);
        case 'SessionList':
          return SessionList.fromJson(value);
        case 'Subscription':
          return Subscription.fromJson(value);
        case 'SubscriptionOrder':
          return SubscriptionOrder.fromJson(value);
        case 'SubscriptionOrderInput':
          return SubscriptionOrderInput.fromJson(value);
        case 'SubscriptionPeriod':
          return SubscriptionPeriodTypeTransformer().decode(value);
        case 'SubscriptionPlan':
          return SubscriptionPlan.fromJson(value);
        case 'SubscriptionPlanList':
          return SubscriptionPlanList.fromJson(value);
        case 'SubscriptionPlanPrice':
          return SubscriptionPlanPrice.fromJson(value);
        case 'SubscriptionStatus':
          return SubscriptionStatusTypeTransformer().decode(value);
        case 'Tenant':
          return Tenant.fromJson(value);
        case 'TenantAccountStatus':
          return TenantAccountStatusTypeTransformer().decode(value);
        case 'TenantInput':
          return TenantInput.fromJson(value);
        case 'TenantInvitation':
          return TenantInvitation.fromJson(value);
        case 'TenantList':
          return TenantList.fromJson(value);
        case 'TenantRef':
          return TenantRef.fromJson(value);
        case 'TenantSummary':
          return TenantSummary.fromJson(value);
        case 'TokenInput':
          return TokenInput.fromJson(value);
        case 'UserAccount':
          return UserAccount.fromJson(value);
        case 'UserAccountInput':
          return UserAccountInput.fromJson(value);
        case 'UserAccountList':
          return UserAccountList.fromJson(value);
        case 'UserAccountStatus':
          return UserAccountStatusTypeTransformer().decode(value);
        case 'UserAccountSummary':
          return UserAccountSummary.fromJson(value);
        case 'UserRole':
          return UserRoleTypeTransformer().decode(value);
        default:
          dynamic match;
          if (value is List && (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toList(growable: growable);
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toSet();
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,)),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(HttpStatus.internalServerError, 'Exception during deserialization.', error, trace,);
    }
    throw ApiException(HttpStatus.internalServerError, 'Could not find a suitable class for deserialization',);
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : ApiClient.fromJson(
        json.decode(message.json),
        targetType,
        growable: message.growable,
      );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async => value == null ? '' : json.encode(value);
