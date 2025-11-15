import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  static const route = '/terms-privacy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Terms of Use',
              content: '''
Welcome to GrabShow. By using our service, you agree to the following terms:

1. **Booking Policy**
   - All ticket bookings are subject to availability.
   - Prices are subject to change without notice.
   - Once confirmed, bookings cannot be modified except through cancellation.

2. **Cancellation Policy**
   - Cancellations are allowed up to 2 hours before showtime.
   - Refunds will be processed within 5-7 business days.
   - No refunds for missed shows.

3. **User Responsibilities**
   - You are responsible for maintaining the confidentiality of your account.
   - You must provide accurate information when booking.
   - You agree not to use the service for any unlawful purpose.

4. **Service Availability**
   - We reserve the right to modify or discontinue the service at any time.
   - We are not liable for any technical issues or service interruptions.

Last updated: ${DateTime.now().year}-01-01
''',
            ),
            const SizedBox(height: 32),
            _Section(
              title: 'Privacy Policy',
              content: '''
Your privacy is important to us. This policy explains how we collect, use, and protect your information.

1. **Information We Collect**
   - Personal information (name, email, phone number)
   - Payment information (processed securely through third-party providers)
   - Booking history and preferences
   - Device information and usage data

2. **How We Use Your Information**
   - To process bookings and payments
   - To send booking confirmations and updates
   - To improve our services
   - To send promotional offers (with your consent)

3. **Data Security**
   - We use industry-standard encryption to protect your data
   - Payment information is handled by secure third-party processors
   - We never store your full payment card details

4. **Your Rights**
   - You can access and update your personal information
   - You can request deletion of your account and data
   - You can opt-out of promotional communications

5. **Third-Party Services**
   - We may use third-party services for payment processing and analytics
   - These services have their own privacy policies

6. **Cookies**
   - We use cookies to enhance your experience
   - You can manage cookie preferences in your browser settings

For questions about this policy, contact us at privacy@grabshow.com

Last updated: ${DateTime.now().year}-01-01
''',
            ),
            const SizedBox(height: 32),
            _Section(
              title: 'Cancellation Policy',
              content: '''
**Standard Cancellation**
- Cancellations allowed up to 2 hours before showtime
- Full refund minus processing fees
- Refunds processed within 5-7 business days

**Premium Bookings**
- Same cancellation policy applies
- No additional cancellation fees

**Special Events**
- Some special events may have different cancellation policies
- Check event details before booking

**Refund Method**
- Refunds are processed to the original payment method
- Processing time: 5-7 business days
''',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

