/// Centralized GST calculator for Inventra.
///
/// All GST calculation logic lives here.
/// Handles both Intra-State (CGST + SGST) and Inter-State (IGST) calculations
/// based on 2-digit GST state codes embedded in GSTIN.
class GstCalculator {
  GstCalculator._();

  /// Default Indian State Code (e.g. '27' for Maharashtra or '29' for Karnataka, '07' for Delhi)
  static const String defaultStateCode = '27';

  /// Extracts the 2-digit state code from a GSTIN.
  static String? extractStateCode(String? gstin) {
    if (gstin == null) return null;
    final trimmed = gstin.trim();
    if (trimmed.length >= 2) {
      final code = trimmed.substring(0, 2);
      if (int.tryParse(code) != null) {
        return code;
      }
    }
    return null;
  }

  /// Determines whether a transaction is Inter-State (IGST) or Intra-State (CGST + SGST).
  ///
  /// Intra-State: Customer has no GSTIN (B2C/Walk-in) OR customer state matches shop state.
  /// Inter-State: Customer has a valid GSTIN with a state code differing from the shop's state code.
  static bool isInterState({
    String? shopGstin,
    String? customerGstin,
    String? shopStateCode,
    String? customerStateCode,
  }) {
    final effectiveCustomerState = customerStateCode ?? extractStateCode(customerGstin);
    // If customer has no GSTIN / state code, default to intra-state B2C
    if (effectiveCustomerState == null || effectiveCustomerState.isEmpty) {
      return false;
    }

    final effectiveShopState = shopStateCode ?? extractStateCode(shopGstin) ?? defaultStateCode;
    return effectiveCustomerState != effectiveShopState;
  }

  /// Calculates the GST amount for a given taxable amount and GST percentage.
  static double gstAmount(double taxableAmount, double gstPercent) {
    if (gstPercent <= 0 || taxableAmount <= 0) return 0.0;
    return (taxableAmount * gstPercent) / 100.0;
  }

  /// CGST = GST / 2 (intra-state billing).
  static double cgst(double taxableAmount, double gstPercent) {
    return gstAmount(taxableAmount, gstPercent) / 2.0;
  }

  /// SGST = GST / 2 (intra-state billing).
  static double sgst(double taxableAmount, double gstPercent) {
    return gstAmount(taxableAmount, gstPercent) / 2.0;
  }

  /// IGST = GST (inter-state billing).
  static double igst(double taxableAmount, double gstPercent) {
    return gstAmount(taxableAmount, gstPercent);
  }

  /// Taxable amount for a line item (before GST).
  static double lineItemTaxable(double unitPrice, int quantity) {
    return unitPrice * quantity;
  }

  /// Total for a single line item including GST.
  static double lineItemTotal(
    double unitPrice,
    int quantity,
    double gstPercent,
  ) {
    final taxable = lineItemTaxable(unitPrice, quantity);
    return taxable + gstAmount(taxable, gstPercent);
  }

  /// Summarises a full invoice from a list of [InvoiceLineInput].
  static InvoiceTotals calculateInvoiceTotals(
    List<InvoiceLineInput> items, {
    String? shopGstin,
    String? customerGstin,
    String? shopStateCode,
    String? customerStateCode,
    bool? forceInterState,
  }) {
    double subtotal = 0.0;
    double totalGst = 0.0;

    for (final item in items) {
      final taxable = item.unitPrice * item.quantity;
      subtotal += taxable;
      totalGst += gstAmount(taxable, item.gstPercent);
    }

    final interState = forceInterState ??
        isInterState(
          shopGstin: shopGstin,
          customerGstin: customerGstin,
          shopStateCode: shopStateCode,
          customerStateCode: customerStateCode,
        );

    final double totalCgst = interState ? 0.0 : totalGst / 2.0;
    final double totalSgst = interState ? 0.0 : totalGst / 2.0;
    final double totalIgst = interState ? totalGst : 0.0;
    final double grandTotal = subtotal + totalGst;

    return InvoiceTotals(
      subtotal: subtotal,
      totalGst: totalGst,
      cgst: totalCgst,
      sgst: totalSgst,
      igst: totalIgst,
      isInterState: interState,
      grandTotal: grandTotal,
    );
  }
}

/// Input for a single invoice line item.
class InvoiceLineInput {
  const InvoiceLineInput({
    required this.unitPrice,
    required this.quantity,
    required this.gstPercent,
  });

  final double unitPrice;
  final int quantity;
  final double gstPercent;
}

/// Calculated totals for an invoice.
class InvoiceTotals {
  const InvoiceTotals({
    required this.subtotal,
    required this.totalGst,
    required this.cgst,
    required this.sgst,
    this.igst = 0.0,
    this.isInterState = false,
    required this.grandTotal,
  });

  final double subtotal;
  final double totalGst;
  final double cgst;
  final double sgst;
  final double igst;
  final bool isInterState;
  final double grandTotal;
}
