//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:niscala_api/api.dart';
import 'package:test/test.dart';


/// tests for TenantsApi
void main() {
  // final instance = TenantsApi();

  group('tests for TenantsApi', () {
    // Create Tenant
    //
    // Add a tenant to a vacant room of a property and create their invitation.
    //
    //Future<Tenant> createTenant(String propertyId, NewTenantInput newTenantInput) async
    test('test createTenant', () async {
      // TODO
    });

    // Delete Tenant
    //
    // End a tenant's lease, revoke their access and free the room; history is kept.
    //
    //Future deleteTenant(String tenantId) async
    test('test deleteTenant', () async {
      // TODO
    });

    // Get My Lease
    //
    // Return the calling tenant's active lease, or null when it has ended.
    //
    //Future<CurrentLeaseResult> getMyLease() async
    test('test getMyLease', () async {
      // TODO
    });

    // Get Tenant
    //
    // Return a tenant's detail.
    //
    //Future<Tenant> getTenant(String tenantId) async
    test('test getTenant', () async {
      // TODO
    });

    // List Tenants
    //
    // List a property's tenants.
    //
    //Future<TenantList> listTenants(String propertyId) async
    test('test listTenants', () async {
      // TODO
    });

    // Regenerate Tenant Invitation
    //
    // Create a new invitation link for a tenant, invalidating the old one.
    //
    //Future<TenantInvitation> regenerateTenantInvitation(String tenantId) async
    test('test regenerateTenantInvitation', () async {
      // TODO
    });

    // Update Tenant
    //
    // Replace a tenant's fields. The room cannot be changed.
    //
    //Future<Tenant> updateTenant(String tenantId, TenantInput tenantInput) async
    test('test updateTenant', () async {
      // TODO
    });

  });
}
