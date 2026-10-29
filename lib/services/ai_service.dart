import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import '../providers/product_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';

class AiService {
  AiService() {
    try {
      _model = FirebaseAI.vertexAI().generativeModel(model: 'gemini-3.5-flash');
    } catch (e) {
      debugPrint('Vertex AI init error: $e');
    }
  }

  GenerativeModel? _model;

  Future<String> askQuestion({
    required String query,
    required ProductProvider productProvider,
    required AnalyticsProvider analyticsProvider,
    required InvoiceProvider invoiceProvider,
    required CustomerProvider customerProvider,
  }) async {
    if (_model == null) {
      return 'Missing AI Integration: To enable conversational AI, you must integrate Firebase Vertex AI or a custom LLM backend. The current app is missing this dependency. Please enable Vertex AI in your Firebase project.';
    }

    try {
      final summary = analyticsProvider.summary;
      final products = productProvider.products;
      final lowStock = productProvider.lowStockProducts;

      final topProducts = analyticsProvider.topProducts;
      final customers = customerProvider.customers;

      final contextPrompt = '''
You are INVENTRA AI, an intelligent assistant for a retail shop.
Here is the current real-time shop data:
- Total Products: ${products.length}
- Low Stock Products: ${lowStock.length}
- Total Customers: ${customers.length}
- Today's Revenue: ₹${summary.todayRevenue.toStringAsFixed(2)}
- Total Lifetime Revenue: ₹${summary.totalRevenue.toStringAsFixed(2)}
- Total GST Collected: ₹${summary.totalGstCollected.toStringAsFixed(2)}
- Top Selling Products: ${topProducts.map((p) => p.productName).join(', ')}

Please answer the user's question concisely and accurately based on this data. Do not make up fake figures. 
If the question is unrelated to the shop, politely decline to answer.

User Question: $query
''';

      final response = await _model!.generateContent([Content.text(contextPrompt)]);
      return response.text ?? 'I could not generate a response.';
    } catch (e) {
      debugPrint('Vertex AI generateContent error: $e');
      return 'Missing AI Integration: Vertex AI failed to respond. Please ensure the Gemini API is enabled in your Firebase project and you have billing enabled. ($e)';
    }
  }
}
