import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/space_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'qr_pass_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final SpaceModel space;

  const CheckoutScreen({
    super.key,
    required this.space,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _plateController = TextEditingController();

  int _hours = 1;
  String? _selectedSpaceNumber;
  bool _acceptedLiability = true;
  bool _saving = false;

  double get _subtotal => widget.space.hourlyPrice * _hours;
  double get _platformFee => _subtotal * 0.20;
  double get _hostReceives => _subtotal * 0.80;
  double get _total => _subtotal;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _continueBooking() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final plate = _plateController.text.trim();
    final selectedNumber = _selectedSpaceNumber;

    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a license plate.')),
      );
      return;
    }

    if (selectedNumber == null || selectedNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a space number.')),
      );
      return;
    }

    if (!_acceptedLiability) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must accept the liability agreement.')),
      );
      return;
    }

    if (_total < 0.50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum Stripe charge is 50 cents. Please increase the parking duration or price.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final bookingId = await BookingService().createPendingBooking(
        space: widget.space,
        licensePlate: plate,
        amount: _total,
        hours: _hours,
      ).timeout(const Duration(seconds: 30));

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
        'spaceNumber': selectedNumber,
        'platformFee': _platformFee,
        'hostPayout': _hostReceives,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final stripe = StripeService();

      final payment = await stripe.createBookingPaymentIntent(
        bookingId: bookingId,
        hostId: widget.space.hostId,
        amount: _total,
      ).timeout(const Duration(seconds: 45));

      await stripe.initializePaymentSheet(
        clientSecret: payment['clientSecret'].toString(),
      ).timeout(const Duration(seconds: 30));

      await stripe.presentPaymentSheet().timeout(const Duration(seconds: 120));

      await stripe.markBookingPaidAfterPayment(
        bookingId: bookingId,
        paymentIntentId: payment['paymentIntentId'].toString(),
      ).timeout(const Duration(seconds: 45));

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
        'status': 'paid',
        'paymentStatus': 'paid',
        'paymentIntentId': payment['paymentIntentId'].toString(),
        'spaceNumber': selectedNumber,
        'platformFee': _platformFee,
        'hostPayout': _hostReceives,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('spaces').doc(widget.space.id).set({
        'occupiedSpaceNumbers': FieldValue.arrayUnion([selectedNumber]),
        'availableSpaces': widget.space.availableSpaces > 0
            ? widget.space.availableSpaces - 1
            : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QrPassScreen(bookingId: bookingId),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _spaceNumberSelector() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('spaces')
          .doc(widget.space.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final total = ((data['totalSpaces'] ?? widget.space.totalSpaces) as num).toInt();

        final numbers = List<String>.from(
          data['spaceNumbers'] ??
              List.generate(total, (index) => (index + 1).toString()),
        );

        final occupied = List<String>.from(data['occupiedSpaceNumbers'] ?? []);

        final available = numbers
            .where((number) => !occupied.contains(number))
            .toList();

        return DropdownButtonFormField<String>(
          initialValue: available.contains(_selectedSpaceNumber)
              ? _selectedSpaceNumber
              : null,
          decoration: InputDecoration(
            labelText: 'Select Space Number',
            helperText: '${available.length} space(s) available',
            border: const OutlineInputBorder(),
          ),
          items: available.map((number) {
            return DropdownMenuItem<String>(
              value: number,
              child: Text('Space #$number'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedSpaceNumber = value);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final space = widget.space;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Checkout'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            22,
            22,
            22,
            22 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            Text(
              space.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(space.address),
            const SizedBox(height: 22),
            TextField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'License Plate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            _spaceNumberSelector(),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              initialValue: _hours,
              decoration: const InputDecoration(
                labelText: 'Parking Duration',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                24,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text('${index + 1} Hour(s)'),
                ),
              ),
              onChanged: (value) {
                if (value != null) setState(() => _hours = value);
              },
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _row('Hourly Rate', '\$${space.hourlyPrice.toStringAsFixed(2)}'),
                    _row('Hours', _hours.toString()),
                    _row(
                      'Space Number',
                      _selectedSpaceNumber == null ? 'Not selected' : '#$_selectedSpaceNumber',
                    ),
                    const Divider(),
                    _row('Driver Pays', '\$${_total.toStringAsFixed(2)}'),
                    _row('Any1Space 20%', '\$${_platformFee.toStringAsFixed(2)}'),
                    _row('Host Receives', '\$${_hostReceives.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            CheckboxListTile(
              value: _acceptedLiability,
              onChanged: (value) {
                setState(() => _acceptedLiability = value ?? false);
              },
              title: const Text('I accept the liability agreement'),
              subtitle: const Text(
                'Any1Space is a facilitator. Hosts are responsible for their parking spaces.',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _continueBooking,
                icon: const Icon(Icons.payment_rounded),
                label: FittedBox(
                  child: Text(_saving ? 'Processing...' : 'Pay & Create QR Pass'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
