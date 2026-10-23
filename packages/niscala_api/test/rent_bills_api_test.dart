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


/// tests for RentBillsApi
void main() {
  // final instance = RentBillsApi();

  group('tests for RentBillsApi', () {
    // Change Payment Status
    //
    // Manually set a bill's payment status, with a reason.
    //
    //Future<RentBill> changePaymentStatus(String rentBillId, PaymentStatusChangeInput paymentStatusChangeInput) async
    test('test changePaymentStatus', () async {
      // TODO
    });

    // Get Payment Overview
    //
    // Show each tenant's bill covering a date, defaulting to today.
    //
    //Future<PaymentOverview> getPaymentOverview(String propertyId, { DateTime date }) async
    test('test getPaymentOverview', () async {
      // TODO
    });

    // Get Payment Patterns
    //
    // Show each tenant's payment pattern over their most recent bills.
    //
    //Future<PaymentPatternList> getPaymentPatterns(String propertyId) async
    test('test getPaymentPatterns', () async {
      // TODO
    });

    // Get Receipt
    //
    // Return the receipt image of a rent bill.
    //
    //Future getReceipt(String rentBillId) async
    test('test getReceipt', () async {
      // TODO
    });

    // Get Rent Bill
    //
    // Return a rent bill's detail.
    //
    //Future<RentBill> getRentBill(String rentBillId) async
    test('test getRentBill', () async {
      // TODO
    });

    // List Rent Bills
    //
    // List the caller's rent bills: a tenant's own, or those on accessible properties.
    //
    //Future<RentBillList> listRentBills({ String tenantId, String propertyId, List<PaymentStatus> paymentStatus }) async
    test('test listRentBills', () async {
      // TODO
    });

    // Record Cash Payment
    //
    // Record a cash payment and mark the bill as paid.
    //
    //Future<RentBill> recordCashPayment(String rentBillId, CashPaymentInput cashPaymentInput) async
    test('test recordCashPayment', () async {
      // TODO
    });

    // Reject Receipt
    //
    // Reject a transfer receipt with a reason.
    //
    //Future<RentBill> rejectReceipt(String rentBillId, ReceiptRejectionInput receiptRejectionInput) async
    test('test rejectReceipt', () async {
      // TODO
    });

    // Upload Receipt
    //
    // Attach a transfer receipt image and mark the bill as awaiting verification.
    //
    //Future<RentBill> uploadReceipt(String rentBillId, MultipartFile file) async
    test('test uploadReceipt', () async {
      // TODO
    });

    // Verify Receipt
    //
    // Accept a transfer receipt and mark the bill as paid.
    //
    //Future<RentBill> verifyReceipt(String rentBillId) async
    test('test verifyReceipt', () async {
      // TODO
    });

  });
}
