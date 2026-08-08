import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stripe-hosted Checkout used only by the Any1Space web application.
///
/// This service does not replace or modify the Android/iOS PaymentSheet flow.
class StripeWebCheckoutService {
  StripeWebCheckoutService();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<String> createBookingCheckoutSession({
    required String bookingId,
    required String hostId,
    required double amount,
  }) async {
    if (bookingId.trim().isEmpty) {
      throw ArgumentError('Booking ID is required.');
    }

    if (hostId.trim().isEmpty) {
      throw ArgumentError('Host ID is required.');
    }

    if (amount <= 0) {
      throw ArgumentError('The payment amount must be greater than zero.');
    }

    final currentUrl = Uri.base.toString();

    final callable = _functions.httpsCallable(
      'createBookingWebCheckoutSession',
    );

    final result = await callable.call(<String, dynamic>{
      'bookingId': bookingId,
      'hostId': hostId,
      'amount': amount,
      'successUrl': currentUrl,
      'cancelUrl': currentUrl,
    });

    if (result.data is! Map) {
      throw StateError('The web Checkout response was invalid.');
    }

    final data = Map<String, dynamic>.from(result.data as Map);
    final checkoutUrl = data['url']?.toString().trim() ?? '';

    if (checkoutUrl.isEmpty) {
      throw StateError('Stripe did not return a Checkout URL.');
    }

    return checkoutUrl;
  }

  Future<void> openBookingCheckout({
    required String bookingId,
    required String hostId,
    required double amount,
  }) async {
    final checkoutUrl = await createBookingCheckoutSession(
      bookingId: bookingId,
      hostId: hostId,
      amount: amount,
    );

    final uri = Uri.tryParse(checkoutUrl);

    if (uri == null || !uri.isScheme('https')) {
      throw StateError('Stripe returned an invalid Checkout URL.');
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      throw StateError('The Stripe Checkout page could not be opened.');
    }
  }
}
