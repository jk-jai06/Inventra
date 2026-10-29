import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventra/core/utils/gst_calculator.dart';
import 'package:inventra/core/utils/validators.dart';
import 'package:inventra/models/customer_model.dart';
import 'package:inventra/models/invoice_model.dart';
import 'package:inventra/models/prediction_model.dart';
import 'package:inventra/models/product_model.dart';
import 'package:inventra/models/stock_movement_model.dart';

void main() {
  group('ProductModel', () {
    test('toFirestore keeps the product fields intact', () {
      final product = ProductModel(
        productId: 'prod_123',
        productName: 'Rice 10kg',
        sku: 'RICE-10',
        category: 'Groceries',
        description: 'Premium rice',
        barcode: '8901234567890',
        purchasePrice: 42.5,
        sellingPrice: 58.0,
        gstPercentage: 5.0,
        stockQuantity: 25,
        minimumStockLevel: 10,
        unit: 'kg',
        supplierId: 'sup_42',
        shopId: 'shop_99',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        updatedAt: DateTime(2024, 1, 2, 11, 30),
      );

      final data = product.toFirestore();

      expect(data['productName'], 'Rice 10kg');
      expect(data['sku'], 'RICE-10');
      expect(data['category'], 'Groceries');
      expect(data['description'], 'Premium rice');
      expect(data['barcode'], '8901234567890');
      expect(data['purchasePrice'], 42.5);
      expect(data['sellingPrice'], 58.0);
      expect(data['gstPercentage'], 5.0);
      expect(data['stockQuantity'], 25);
      expect(data['minimumStockLevel'], 10);
      expect(data['unit'], 'kg');
      expect(data['shop_id'], 'shop_99');
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('low stock and out-of-stock calculations match the stock model', () {
      final inStock = ProductModel(
        productId: 'p1',
        productName: 'Milk',
        category: 'Dairy',
        purchasePrice: 30,
        sellingPrice: 40,
        stockQuantity: 12,
        minimumStockLevel: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final lowStock = inStock.copyWith(stockQuantity: 7);
      final outOfStock = inStock.copyWith(stockQuantity: 0);

      expect(inStock.isLowStock, false);
      expect(lowStock.isLowStock, true);
      expect(outOfStock.isOutOfStock, true);
      expect(outOfStock.inventoryValue, 0.0);
    });
  });

  group('CustomerModel', () {
    test('extracts state code from GSTIN correctly', () {
      final mhCustomer = CustomerModel(
        customerId: 'c1',
        name: 'Ramesh',
        gstin: '27AAPFU0955D1ZV',
        createdAt: DateTime.now(),
      );

      final kaCustomer = CustomerModel(
        customerId: 'c2',
        name: 'Suresh',
        gstin: '29ABCDE1234F1Z5',
        createdAt: DateTime.now(),
      );

      final unregistered = CustomerModel(
        customerId: 'c3',
        name: 'Walk-in',
        createdAt: DateTime.now(),
      );

      expect(mhCustomer.gstStateCode, '27');
      expect(kaCustomer.gstStateCode, '29');
      expect(unregistered.gstStateCode, isNull);
    });
  });

  group('GstCalculator Engine', () {
    test('calculates Intra-State GST (CGST + SGST) for same state', () {
      final items = [
        const InvoiceLineInput(unitPrice: 100.0, quantity: 2, gstPercent: 18.0),
      ];

      final totals = GstCalculator.calculateInvoiceTotals(
        items,
        shopStateCode: '27',
        customerStateCode: '27',
      );

      expect(totals.isInterState, isFalse);
      expect(totals.subtotal, 200.0);
      expect(totals.totalGst, 36.0);
      expect(totals.cgst, 18.0);
      expect(totals.sgst, 18.0);
      expect(totals.igst, 0.0);
      expect(totals.grandTotal, 236.0);
    });

    test('calculates Inter-State GST (IGST) for different states', () {
      final items = [
        const InvoiceLineInput(unitPrice: 100.0, quantity: 2, gstPercent: 18.0),
      ];

      final totals = GstCalculator.calculateInvoiceTotals(
        items,
        shopGstin: '27AAPFU0955D1ZV', // Maharashtra (27)
        customerGstin: '29ABCDE1234F1Z5', // Karnataka (29)
      );

      expect(totals.isInterState, isTrue);
      expect(totals.subtotal, 200.0);
      expect(totals.totalGst, 36.0);
      expect(totals.cgst, 0.0);
      expect(totals.sgst, 0.0);
      expect(totals.igst, 36.0);
      expect(totals.grandTotal, 236.0);
    });

    test('calculates Intra-State for B2C customer without GSTIN', () {
      final items = [
        const InvoiceLineInput(unitPrice: 50.0, quantity: 4, gstPercent: 5.0),
      ];

      final totals = GstCalculator.calculateInvoiceTotals(
        items,
        shopGstin: '27AAPFU0955D1ZV',
        customerGstin: null,
      );

      expect(totals.isInterState, isFalse);
      expect(totals.subtotal, 200.0);
      expect(totals.totalGst, 10.0);
      expect(totals.cgst, 5.0);
      expect(totals.sgst, 5.0);
      expect(totals.igst, 0.0);
      expect(totals.grandTotal, 210.0);
    });
  });

  group('InvoiceModel', () {
    test('serializes and deserializes invoice with inter-state GST correctly', () {
      final invoice = InvoiceModel(
        invoiceId: 'inv_101',
        invoiceNumber: 'INV-0042',
        shopId: 'shop_01',
        customerId: 'cust_01',
        customerName: 'Bangalore Retailers',
        customerPhone: '9876543210',
        customerGstin: '29ABCDE1234F1Z5',
        items: const [
          InvoiceItem(
            productId: 'prod_1',
            productName: 'Wheat Flour 5kg',
            sku: 'WHEAT-5',
            quantity: 2,
            unitPrice: 200.0,
            gstPercentage: 5.0,
            gstAmount: 20.0,
            taxableAmount: 400.0,
            total: 420.0,
          ),
        ],
        subtotal: 400.0,
        totalGst: 20.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 20.0,
        isInterState: true,
        grandTotal: 420.0,
        paymentMethod: 'cash',
        paymentStatus: PaymentStatus.paid,
        createdAt: DateTime(2024, 6, 1, 14, 0),
      );

      final map = invoice.toFirestore();
      expect(map['invoiceNumber'], 'INV-0042');
      expect(map['isInterState'], true);
      expect(map['igst'], 20.0);
      expect(map['cgst'], 0.0);
      expect(map['grandTotal'], 420.0);
      expect(map['paymentMethod'], 'cash');
      expect(map['shop_id'], 'shop_01');
    });
  });

  group('StockMovementModel', () {
    test('serializes stock movement correctly', () {
      final movement = StockMovementModel(
        movementId: 'm1',
        productId: 'p1',
        productName: 'Rice 10kg',
        movementType: 'sale',
        quantityChange: -2,
        previousQuantity: 10,
        newQuantity: 8,
        referenceId: 'INV-0001',
        shopId: 'shop_1',
        timestamp: DateTime(2024, 1, 1),
        notes: 'Sale INV-0001',
      );

      final map = movement.toFirestore();
      expect(map['productId'], 'p1');
      expect(map['quantityChange'], -2);
      expect(map['previousQuantity'], 10);
      expect(map['newQuantity'], 8);
      expect(map['referenceId'], 'INV-0001');
      expect(map['shop_id'], 'shop_1');
    });
  });

  group('AppValidators', () {
    test('rejects invalid product names and negative values', () {
      expect(AppValidators.productName('A'), isNotNull);
      expect(AppValidators.stockQuantity('-1'), isNotNull);
      expect(
        AppValidators.positiveNumber('-2', fieldName: 'Purchase price'),
        isNotNull,
      );
    });

    test('accepts valid pricing, GST and quantity values', () {
      expect(AppValidators.productName('Rice 10kg'), isNull);
      expect(AppValidators.sellingPrice('58.0'), isNull);
      expect(AppValidators.gstPercent('5.0'), isNull);
      expect(AppValidators.stockQuantity('25'), isNull);
      expect(
        AppValidators.positiveNumber('10', fieldName: 'Minimum stock level'),
        isNull,
      );
    });

    test('validates email and GSTIN formats correctly', () {
      expect(AppValidators.email('test@example.com'), isNull);
      expect(AppValidators.email('invalid-email'), isNotNull);
      expect(AppValidators.gstin('27AAPFU0955D1ZV'), isNull);
      expect(AppValidators.gstin('INVALID123'), isNotNull);
    });
  });

  group('PredictionModel', () {
    test('deserializes and computes needsReorder correctly', () {
      final json = {
        'product_id': 'p1',
        'product_name': 'Sunflower Oil 1L',
        'current_stock': 4,
        'predicted_demand': 15.0,
        'forecast_days': 7,
        'reorder_qty': 20,
        'recommendation': 'Restock high-velocity item',
        'confidence': 0.92,
        'generated_at': '2024-06-01T12:00:00.000Z',
      };

      final prediction = PredictionModel.fromJson(json);

      expect(prediction.productId, 'p1');
      expect(prediction.productName, 'Sunflower Oil 1L');
      expect(prediction.currentStock, 4);
      expect(prediction.predictedDemand, 15.0);
      expect(prediction.needsReorder, true);
      expect(prediction.reorderQty, 20);
      expect(prediction.confidence, 0.92);
    });
  });
}
