//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library niscala_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/account_api.dart';
part 'api/auth_api.dart';
part 'api/complaints_api.dart';
part 'api/dashboard_api.dart';
part 'api/invitations_api.dart';
part 'api/managers_api.dart';
part 'api/notifications_api.dart';
part 'api/properties_api.dart';
part 'api/rent_bills_api.dart';
part 'api/rooms_api.dart';
part 'api/sessions_api.dart';
part 'api/subscriptions_api.dart';
part 'api/tenants_api.dart';
part 'api/user_accounts_api.dart';

part 'model/account.dart';
part 'model/account_property_ref.dart';
part 'model/account_tenancy.dart';
part 'model/active_lease_summary.dart';
part 'model/add_local_password_input.dart';
part 'model/ai_complaint_classification.dart';
part 'model/auth_session.dart';
part 'model/auth_tokens.dart';
part 'model/bank_account.dart';
part 'model/billing_cycle.dart';
part 'model/cash_payment_input.dart';
part 'model/complaint.dart';
part 'model/complaint_category_list.dart';
part 'model/complaint_classification.dart';
part 'model/complaint_classification_input.dart';
part 'model/complaint_classification_state.dart';
part 'model/complaint_input.dart';
part 'model/complaint_list.dart';
part 'model/complaint_status.dart';
part 'model/complaint_status_change.dart';
part 'model/complaint_status_change_input.dart';
part 'model/complaint_summary.dart';
part 'model/complaint_urgency.dart';
part 'model/current_lease.dart';
part 'model/current_lease_result.dart';
part 'model/current_lease_room.dart';
part 'model/device_info.dart';
part 'model/editable_account_status.dart';
part 'model/email_confirmation_input.dart';
part 'model/email_verification_sent.dart';
part 'model/emergency_contact.dart';
part 'model/error_body.dart';
part 'model/facility_suggestion_list.dart';
part 'model/google_auth_input.dart';
part 'model/invitation_acceptance_preview.dart';
part 'model/invitation_blocker.dart';
part 'model/invitation_google_activation_input.dart';
part 'model/invitation_link_status.dart';
part 'model/invitation_password_activation_input.dart';
part 'model/invitation_preview.dart';
part 'model/invitation_property.dart';
part 'model/invitation_role.dart';
part 'model/lease.dart';
part 'model/lease_input.dart';
part 'model/link_google_input.dart';
part 'model/login_input.dart';
part 'model/login_method.dart';
part 'model/manager.dart';
part 'model/manager_account_status.dart';
part 'model/manager_input.dart';
part 'model/manager_invitation.dart';
part 'model/manager_list.dart';
part 'model/manager_property.dart';
part 'model/manager_ref.dart';
part 'model/manager_summary.dart';
part 'model/new_tenant_input.dart';
part 'model/notification.dart';
part 'model/notification_category.dart';
part 'model/notification_complaint.dart';
part 'model/notification_list.dart';
part 'model/notification_rent_bill.dart';
part 'model/notification_setting_item.dart';
part 'model/notification_settings.dart';
part 'model/notification_settings_input.dart';
part 'model/notification_type.dart';
part 'model/notification_urgency_scope.dart';
part 'model/occupancy.dart';
part 'model/occupancy_dashboard.dart';
part 'model/occupancy_room.dart';
part 'model/occupancy_summary.dart';
part 'model/order_status.dart';
part 'model/paid_plan_code.dart';
part 'model/password_change_input.dart';
part 'model/password_change_result.dart';
part 'model/password_reset_input.dart';
part 'model/password_reset_preview.dart';
part 'model/password_reset_request_input.dart';
part 'model/payment.dart';
part 'model/payment_method.dart';
part 'model/payment_overview.dart';
part 'model/payment_overview_item.dart';
part 'model/payment_pattern.dart';
part 'model/payment_pattern_list.dart';
part 'model/payment_status.dart';
part 'model/payment_status_change.dart';
part 'model/payment_status_change_input.dart';
part 'model/plan_code.dart';
part 'model/property.dart';
part 'model/property_input.dart';
part 'model/property_list.dart';
part 'model/property_occupancy.dart';
part 'model/property_ref.dart';
part 'model/property_summary.dart';
part 'model/purchase_verification_input.dart';
part 'model/push_token_input.dart';
part 'model/reauthentication.dart';
part 'model/reauthentication_google_input.dart';
part 'model/reauthentication_password_input.dart';
part 'model/receipt_rejection_input.dart';
part 'model/refresh_input.dart';
part 'model/register_owner_input.dart';
part 'model/rent_bill.dart';
part 'model/rent_bill_list.dart';
part 'model/rent_bill_summary.dart';
part 'model/room.dart';
part 'model/room_input.dart';
part 'model/room_lease.dart';
part 'model/room_lease_summary.dart';
part 'model/room_list.dart';
part 'model/room_ref.dart';
part 'model/room_summary.dart';
part 'model/scheduled_downgrade.dart';
part 'model/scheduled_downgrade_input.dart';
part 'model/session.dart';
part 'model/session_list.dart';
part 'model/subscription.dart';
part 'model/subscription_order.dart';
part 'model/subscription_order_input.dart';
part 'model/subscription_period.dart';
part 'model/subscription_plan.dart';
part 'model/subscription_plan_list.dart';
part 'model/subscription_plan_price.dart';
part 'model/subscription_status.dart';
part 'model/tenant.dart';
part 'model/tenant_account_status.dart';
part 'model/tenant_input.dart';
part 'model/tenant_invitation.dart';
part 'model/tenant_list.dart';
part 'model/tenant_ref.dart';
part 'model/tenant_summary.dart';
part 'model/token_input.dart';
part 'model/user_account.dart';
part 'model/user_account_input.dart';
part 'model/user_account_list.dart';
part 'model/user_account_status.dart';
part 'model/user_account_summary.dart';
part 'model/user_role.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
