
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {

  static const Map<String, String> _testTokens
  = { '1111222233334444': 'tok_visa',
    '1111222233334404': 'tok_visa_debit',
    '1111222233334414': 'tok_mastercard',
    '1111222233334424': 'tok_mastercard_debit',
    '1111222233334434': 'tok_chargeDeclined',
    '1111222233334454': 'tok_chargeDeclinedInsufficient',
  };

  static Future <Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = _testTokens[cleanCard];

    if (token == null) {
      return <String, dynamic>{
        'success': false,
        'error': 'unknown test card'
      };
    }

    try {
      final response = await http.post(
          Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
          headers: <String, String>{
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
            'Content-Type': 'application/x-www-form-urledoded',
          },
          body: <String, String>{
            'amount': amountInCentavos,
            'currency': 'php',
            'payment_method_types[]': 'card',
            'payment_method_data[type]': 'card',
            'payment_method_data[card][token]': token,
            'confirm': 'true',
          }
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'succeeded') {
        final paidAmount = (data['ammount'] as num) / 100;
        return <String, dynamic>{
          'success': true,
          'id': data['id'].toString(),
          'ammount': paidAmount,
          'status': data['status'].toString(),

        };
      } else {
        final errorMessage = data['error'] is Map
            ? (data['error'] as Map) ['message']?.toString() ?? 'payment failed'
            : 'payment failed';
        return <String, dynamic>{
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

