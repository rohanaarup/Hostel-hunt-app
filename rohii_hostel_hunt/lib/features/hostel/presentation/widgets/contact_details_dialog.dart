import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/booking_contact.dart';

/// Asks for the name and phone number the hostel owner will see on the booking.
/// Returns null if the person cancels. Used when the profile has no phone (signed up with an email)
/// or when nobody is signed in. What is typed here is used for this booking only.
Future<ContactReady?> askForContact(
  BuildContext context, {
  String name = '',
  String phone = '',
}) {
  return showDialog<ContactReady>(
    context: context,
    builder: (_) => _ContactDetailsDialog(initialName: name, initialPhone: phone),
  );
}

class _ContactDetailsDialog extends StatefulWidget {
  const _ContactDetailsDialog({required this.initialName, required this.initialPhone});

  final String initialName;
  final String initialPhone;

  @override
  State<_ContactDetailsDialog> createState() => _ContactDetailsDialogState();
}

class _ContactDetailsDialogState extends State<_ContactDetailsDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  late final TextEditingController _phone = TextEditingController(text: widget.initialPhone);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, ContactReady(name: _name.text.trim(), phone: _phone.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your contact details'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The hostel owner uses these to reach you about this booking.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: (value) =>
                  isUsablePhone(value ?? '') ? null : 'Enter a phone number with at least $kMinPhoneDigits digits',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}
