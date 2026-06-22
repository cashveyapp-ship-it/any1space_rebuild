import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Map<String, dynamic>> createBookingPaymentIntent({
    required String bookingId,
    required String hostId,
    required double amount,
  }) async {
    final callable = _functions.httpsCallable('createBookingPaymentIntentV2');

    final result = await callable.call({
      'bookingId': bookingId,
      'hostId': hostId,
      'amount': amount,
    });

    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> initializePaymentSheet({
    required String clientSecret,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Any1Space',
        style: ThemeMode.system,
      ),
    );
  }

  Future<void> presentPaymentSheet() async {
    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> markBookingPaidAfterPayment({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    final callable = _functions.httpsCallable('markBookingPaidAfterPaymentV2');

    await callable.call({
      'bookingId': bookingId,
      'paymentIntentId': paymentIntentId,
    });
  }

  Future<void> refundBookingPayment({
    required String bookingId,
  }) async {
    final callable = _functions.httpsCallable('refundBookingPayment');

    await callable.call({
      'bookingId': bookingId,
    });
  }

  Future<void> sendBookingReminder({
    required String bookingId,
  }) async {
    final callable = _functions.httpsCallable('sendBookingReminder');

    await callable.call({
      'bookingId': bookingId,
    });
  }

  Future<String> createStripeConnectAccount() async {
    final callable = _functions.httpsCallable('createStripeConnectAccount');
    final result = await callable.call();

    final data = Map<String, dynamic>.from(result.data as Map);
    return data['accountId']?.toString() ?? '';
  }

  Future<String> createHostConnectOnboardingLink() async {
    final callable =
        _functions.httpsCallable('createHostConnectOnboardingLink');

    final result = await callable.call();

    final data = Map<String, dynamic>.from(result.data as Map);
    return data['url']?.toString() ?? '';
  }

  Future<void> openHostConnectOnboarding() async {
    await createStripeConnectAccount();

    final url = await createHostConnectOnboardingLink();

    if (url.isEmpty) {
      throw Exception('Stripe onboarding URL was empty.');
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<Map<String, dynamic>> checkHostConnectStatus() async {
    final callable = _functions.httpsCallable('checkHostConnectStatus');
    final result = await callable.call();

    if (result.data == null) return {};
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> refreshStripeConnectAccountStatus() async {
    final callable =
        _functions.httpsCallable('refreshStripeConnectAccountStatus');

    final result = await callable.call();

    if (result.data == null) return {};
    return Map<String, dynamic>.from(result.data as Map);
  }
  Future<Map<String, dynamic>> createAttendantShiftPaymentIntent({
    required String shiftId,
  }) async {
    final callable = _functions.httpsCallable('createAttendantShiftPaymentIntent');

    final result = await callable.call({
      'shiftId': shiftId,
    });

    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> markAttendantShiftPaidAfterPayment({
    required String shiftId,
    required String paymentIntentId,
  }) async {
    final callable = _functions.httpsCallable('markAttendantShiftPaidAfterPayment');

    await callable.call({
      'shiftId': shiftId,
      'paymentIntentId': paymentIntentId,
    });
  }


  Future<String> createAttendantConnectAccount() async {
    final callable = _functions.httpsCallable('createAttendantConnectAccount');
    final result = await callable.call();

    final data = Map<String, dynamic>.from(result.data as Map);
    return data['accountId']?.toString() ?? '';
  }

  Future<String> createAttendantConnectOnboardingLink() async {
    final callable = _functions.httpsCallable('createAttendantConnectOnboardingLink');
    final result = await callable.call();

    final data = Map<String, dynamic>.from(result.data as Map);
    return data['url']?.toString() ?? '';
  }

  Future<void> openAttendantConnectOnboarding() async {
    await createAttendantConnectAccount();

    final url = await createAttendantConnectOnboardingLink();

    if (url.isEmpty) {
      throw Exception('Attendant Stripe onboarding URL was empty.');
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<Map<String, dynamic>> checkAttendantConnectStatus() async {
    final callable = _functions.httpsCallable('checkAttendantConnectStatus');
    final result = await callable.call();

    if (result.data == null) return {};
    return Map<String, dynamic>.from(result.data as Map);
  }
}

