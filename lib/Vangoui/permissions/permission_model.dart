class PermissionResponse {
  final String result;
  final String message;
  final List<PermissionData> permissiondet;

  PermissionResponse({
    required this.result,
    required this.message,
    required this.permissiondet,
  });

  factory PermissionResponse.fromJson(Map<String, dynamic> json) {
    return PermissionResponse(
      result: json['result'] ?? '0',
      message: json['message'] ?? '',
      permissiondet: (json['permissiondet'] as List?)
          ?.map((p) => PermissionData.fromJson(p))
          .toList() ?? [],
    );
  }

  bool get isSuccess => result == '1';
}

class PermissionData {
  final String invoiceView;
  final String newBill;
  final String invoiceSaleCredit;
  final String invoiceUnitRate;
  final String invoiceGstEdit;
  final String invoiceDiscountAllow;
  final String creditnoteView;
  final String receiptAdd;
  final String receiptDueAmount;
  final String receiptDateChange;
  final String receiptEdit;
  final String receiptView;
  final String receiptDelete;
  final String receiptDeleteReason;
  final String receiptWhatsapp;
  final String chequeAdd;
  final String chequeView;
  final String chequeEdit;
  final String chequeClear;
  final String chequeBounce;
  final String chequeDelete;
  final String chequeDeleteReason;
  final String discountAdd;
  final String discountDueAmount;
  final String discountDateChange;
  final String discountAllowed;
  final String discountEdit;
  final String discountView;
  final String discountDelete;
  final String discountDeleteReason;
  final String stockView;
  final String customerAdd;
  final String customerView;
  final String customerEdit;
  final String customerStatus;
  final dynamic agedReceivable;
  final String salesReport;
  final String salesDetail;
  final String salesOther;
  final String receiptReport;
  final String salesReturnReport;
  final String salesReturnDetail;
  final String discountReport;
  final String allReportExcel;
  final String debitors;
  final String debitorsWhatsapp;
  final String debitorsExcel;
  final String dayBook;
  final String customerLedger;
  final String ledgerExcel;
  final String accountSales;
  final String accountReceipt;
  final String accountSalesReturn;
  final String accountDiscount;

  PermissionData({
    required this.invoiceView,
    required this.newBill,
    required this.invoiceSaleCredit,
    required this.invoiceUnitRate,
    required this.invoiceGstEdit,
    required this.invoiceDiscountAllow,
    required this.creditnoteView,
    required this.receiptAdd,
    required this.receiptDueAmount,
    required this.receiptDateChange,
    required this.receiptEdit,
    required this.receiptView,
    required this.receiptDelete,
    required this.receiptDeleteReason,
    required this.receiptWhatsapp,
    required this.chequeAdd,
    required this.chequeView,
    required this.chequeEdit,
    required this.chequeClear,
    required this.chequeBounce,
    required this.chequeDelete,
    required this.chequeDeleteReason,
    required this.discountAdd,
    required this.discountDueAmount,
    required this.discountDateChange,
    required this.discountAllowed,
    required this.discountEdit,
    required this.discountView,
    required this.discountDelete,
    required this.discountDeleteReason,
    required this.stockView,
    required this.customerAdd,
    required this.customerView,
    required this.customerEdit,
    required this.customerStatus,
    required this.agedReceivable,
    required this.salesReport,
    required this.salesDetail,
    required this.salesOther,
    required this.receiptReport,
    required this.salesReturnReport,
    required this.salesReturnDetail,
    required this.discountReport,
    required this.allReportExcel,
    required this.debitors,
    required this.debitorsWhatsapp,
    required this.debitorsExcel,
    required this.dayBook,
    required this.customerLedger,
    required this.ledgerExcel,
    required this.accountSales,
    required this.accountReceipt,
    required this.accountSalesReturn,
    required this.accountDiscount,
  });

  factory PermissionData.fromJson(Map<String, dynamic> json) {
    return PermissionData(
      invoiceView: json['invoice_view']?.toString().toLowerCase() ?? 'no',
      newBill: json['new_bill']?.toString().toLowerCase() ?? 'no',
      invoiceSaleCredit: json['invoice_sale_credit']?.toString().toLowerCase() ?? 'no',
      invoiceUnitRate: json['invoice_unit_rate']?.toString().toLowerCase() ?? 'no',
      invoiceGstEdit: json['invoice_gst_edit']?.toString().toLowerCase() ?? 'no',
      invoiceDiscountAllow: json['invoice_discount_allow']?.toString().toLowerCase() ?? 'no',
      creditnoteView: json['creditnote_view']?.toString().toLowerCase() ?? 'no',
      receiptAdd: json['receipt_add']?.toString().toLowerCase() ?? 'no',
      receiptDueAmount: json['receipt_due_amount']?.toString().toLowerCase() ?? 'no',
      receiptDateChange: json['receipt_date_change']?.toString().toLowerCase() ?? 'no',
      receiptEdit: json['receipt_edit']?.toString().toLowerCase() ?? 'no',
      receiptView: json['receipt_view']?.toString().toLowerCase() ?? 'no',
      receiptDelete: json['receipt_delete']?.toString().toLowerCase() ?? 'no',
      receiptDeleteReason: json['receipt_delete_reason']?.toString().toLowerCase() ?? 'no',
      receiptWhatsapp: json['receipt_whatsapp']?.toString().toLowerCase() ?? 'no',
      chequeAdd: json['cheque_add']?.toString().toLowerCase() ?? 'no',
      chequeView: json['cheque_view']?.toString().toLowerCase() ?? 'no',
      chequeEdit: json['cheque_edit']?.toString().toLowerCase() ?? 'no',
      chequeClear: json['cheque_clear']?.toString().toLowerCase() ?? 'no',
      chequeBounce: json['cheque_bounce']?.toString().toLowerCase() ?? 'no',
      chequeDelete: json['cheque_delete']?.toString().toLowerCase() ?? 'no',
      chequeDeleteReason: json['cheque_delete_reason']?.toString().toLowerCase() ?? 'no',
      discountAdd: json['discount_add']?.toString().toLowerCase() ?? 'no',
      discountDueAmount: json['discount_due_amount']?.toString().toLowerCase() ?? 'no',
      discountDateChange: json['discount_date_change']?.toString().toLowerCase() ?? 'no',
      discountAllowed: json['discount_allowed']?.toString().toLowerCase() ?? 'no',
      discountEdit: json['discount_edit']?.toString().toLowerCase() ?? 'no',
      discountView: json['discount_view']?.toString().toLowerCase() ?? 'no',
      discountDelete: json['discount_delete']?.toString().toLowerCase() ?? 'no',
      discountDeleteReason: json['discount_delete_reason']?.toString().toLowerCase() ?? 'no',
      stockView: json['stock_view']?.toString().toLowerCase() ?? 'no',
      customerAdd: json['customer_add']?.toString().toLowerCase() ?? 'no',
      customerView: json['customer_view']?.toString().toLowerCase() ?? 'no',
      customerEdit: json['customer_edit']?.toString().toLowerCase() ?? 'no',
      customerStatus: json['customer_status']?.toString().toLowerCase() ?? 'no',
      agedReceivable: json['aged_receivable'],
      salesReport: json['sales_report']?.toString().toLowerCase() ?? 'no',
      salesDetail: json['sales_detail']?.toString().toLowerCase() ?? 'no',
      salesOther: json['sales_other']?.toString().toLowerCase() ?? 'no',
      receiptReport: json['receipt_report']?.toString().toLowerCase() ?? 'no',
      salesReturnReport: json['sales_return_report']?.toString().toLowerCase() ?? 'no',
      salesReturnDetail: json['sales_return_detail']?.toString().toLowerCase() ?? 'no',
      discountReport: json['discount_report']?.toString().toLowerCase() ?? 'no',
      allReportExcel: json['all_report_excel']?.toString().toLowerCase() ?? 'no',
      debitors: json['debitors']?.toString().toLowerCase() ?? 'no',
      debitorsWhatsapp: json['debitors_whatsapp']?.toString().toLowerCase() ?? 'no',
      debitorsExcel: json['debitors_excel']?.toString().toLowerCase() ?? 'no',
      dayBook: json['day_book']?.toString().toLowerCase() ?? 'no',
      customerLedger: json['customer_ledger']?.toString().toLowerCase() ?? 'no',
      ledgerExcel: json['ledger_excel']?.toString().toLowerCase() ?? 'no',
      accountSales: json['account_sales']?.toString().toLowerCase() ?? 'no',
      accountReceipt: json['account_receipt']?.toString().toLowerCase() ?? 'no',
      accountSalesReturn: json['account_sales_return']?.toString().toLowerCase() ?? 'no',
      accountDiscount: json['account_discount']?.toString().toLowerCase() ?? 'no',
    );
  }

  // Helper getters
  bool get canAddCustomer => customerAdd == 'yes';
  bool get canViewCustomer => customerView == 'yes';
  bool get canEditCustomer => customerEdit == 'yes';
  bool get canViewStock => stockView == 'yes';
  bool get canCreateNewBill => newBill == 'yes';
  bool get canViewInvoice => invoiceView == 'yes';
  bool get canAddReceipt => receiptAdd == 'yes';
  bool get canAddDiscount => discountAdd == 'yes';
  bool get canAddCheque => chequeAdd == 'yes';
  bool get canViewSalesReport => salesReport == 'yes';
  bool get canViewDebitors => debitors == 'yes';
  bool get canViewDayBook => dayBook == 'yes';

  // Check if user has any invoice permissions
  bool get hasInvoicePermissions =>
      canCreateNewBill || canViewInvoice;

  @override
  String toString() {
    return '''
PermissionData:
- Customer Add: $customerAdd
- Customer View: $customerView
- Customer Edit: $customerEdit
- New Bill: $newBill
- Stock View: $stockView
- Invoice View: $invoiceView
- Receipt Add: $receiptAdd
- Discount Add: $discountAdd
- Sales Report: $salesReport
- Debitors: $debitors
- Day Book: $dayBook
''';
  }
}