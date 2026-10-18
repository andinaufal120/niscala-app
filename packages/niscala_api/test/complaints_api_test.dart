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


/// tests for ComplaintsApi
void main() {
  // final instance = ComplaintsApi();

  group('tests for ComplaintsApi', () {
    // Change Complaint Status
    //
    // Move a complaint to its next status, optionally with a handling note.
    //
    //Future<Complaint> changeComplaintStatus(String complaintId, ComplaintStatusChangeInput complaintStatusChangeInput) async
    test('test changeComplaintStatus', () async {
      // TODO
    });

    // Classify Complaint
    //
    // Set a complaint's category and urgency manually.
    //
    //Future<Complaint> classifyComplaint(String complaintId, ComplaintClassificationInput complaintClassificationInput) async
    test('test classifyComplaint', () async {
      // TODO
    });

    // Create Complaint
    //
    // Submit a complaint as the calling tenant.  The complaint is saved before it is classified in the background.
    //
    //Future<Complaint> createComplaint(ComplaintInput complaintInput) async
    test('test createComplaint', () async {
      // TODO
    });

    // Get Complaint
    //
    // Return a complaint's detail with its status history.
    //
    //Future<Complaint> getComplaint(String complaintId) async
    test('test getComplaint', () async {
      // TODO
    });

    // Get Complaint Photo
    //
    // Return the complaint photo.
    //
    //Future getComplaintPhoto(String complaintId) async
    test('test getComplaintPhoto', () async {
      // TODO
    });

    // List Complaint Categories
    //
    // Return the categories a complaint can be classified into.
    //
    //Future<ComplaintCategoryList> listComplaintCategories() async
    test('test listComplaintCategories', () async {
      // TODO
    });

    // List Complaints
    //
    // List the caller's complaints: a tenant's own, or those on accessible properties.
    //
    //Future<ComplaintList> listComplaints() async
    test('test listComplaints', () async {
      // TODO
    });

    // Upload Complaint Photo
    //
    // Attach or replace the complaint photo.
    //
    //Future<Complaint> uploadComplaintPhoto(String complaintId, MultipartFile file) async
    test('test uploadComplaintPhoto', () async {
      // TODO
    });

  });
}
