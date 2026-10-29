import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventra/services/ai_service.dart';
import 'package:inventra/providers/product_provider.dart';
import 'package:inventra/providers/analytics_provider.dart';
import 'package:inventra/providers/invoice_provider.dart';
import 'package:inventra/providers/customer_provider.dart';
import 'package:inventra/providers/auth_provider.dart';
import 'package:inventra/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test AI Service with a real request', (WidgetTester tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final authProvider = AuthProvider();
    final aiService = AiService();
    final productProvider = ProductProvider(authProvider);
    final analyticsProvider = AnalyticsProvider(authProvider);
    final invoiceProvider = InvoiceProvider(authProvider);
    final customerProvider = CustomerProvider(authProvider);
    
    final response = await aiService.askQuestion(
      query: 'Say hello world and do not add any other text',
      productProvider: productProvider,
      analyticsProvider: analyticsProvider,
      invoiceProvider: invoiceProvider,
      customerProvider: customerProvider,
    );
    
    print('AI Response: $response');
    expect(response, isNotNull);
    expect(response.isNotEmpty, true);
    expect(response.contains('Missing AI Integration'), false, reason: 'AI returned error fallback message');
  });
}
