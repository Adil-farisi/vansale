class CustomerModel {
  final String custid;
  final String custname;
  final String custType;
  final String custTypeName;
  final String address;
  final String gst;
  final String phone;
  final String email;
  final String landPhone;
  final double opBln;
  final String state;
  final String stateCode;
  final int creditDays;
  final String opAcc;
  final String status;
  final String balance;
  final String slex;
  final String? outstandingAmount; // ADDED: Outstanding amount field

  CustomerModel({
    required this.custid,
    required this.custname,
    required this.custType,
    required this.custTypeName,
    required this.address,
    required this.gst,
    required this.phone,
    required this.email,
    required this.landPhone,
    required this.opBln,
    required this.state,
    required this.stateCode,
    required this.creditDays,
    required this.opAcc,
    required this.status,
    required this.balance,
    required this.slex,
    this.outstandingAmount, // ADDED: Make it optional
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      custid: json['custid'] ?? '',
      custname: json['custname'] ?? '',
      custType: json['cust_type'] ?? '0',
      custTypeName: json['cust_type_name'] ?? '',
      address: json['address'] ?? '',
      gst: json['gst'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      landPhone: json['land_phone'] ?? '',
      opBln: double.tryParse(json['op_bln']?.toString() ?? '0') ?? 0.0,
      state: json['state'] ?? '',
      stateCode: json['state_code'] ?? '',
      creditDays: int.tryParse(json['credit_days']?.toString() ?? '0') ?? 0,
      opAcc: json['op_acc'] ?? 'dr',
      status: json['status']?.toLowerCase() ?? 'inactive',
      balance: json['balance'] ?? '0.00',
      slex: json['slex'] ?? '',
      outstandingAmount: json['outstand_amt'] ?? json['outstandingAmount'] ?? '0.00', // ADDED: Get from JSON if available
    );
  }

  // Update copyWith to include slex and outstandingAmount
  CustomerModel copyWith({
    String? custid,
    String? custname,
    String? custType,
    String? custTypeName,
    String? address,
    String? gst,
    String? phone,
    String? email,
    String? landPhone,
    double? opBln,
    String? state,
    String? stateCode,
    int? creditDays,
    String? opAcc,
    String? status,
    String? balance,
    String? slex,
    String? outstandingAmount, // ADDED
  }) {
    return CustomerModel(
      custid: custid ?? this.custid,
      custname: custname ?? this.custname,
      custType: custType ?? this.custType,
      custTypeName: custTypeName ?? this.custTypeName,
      address: address ?? this.address,
      gst: gst ?? this.gst,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      landPhone: landPhone ?? this.landPhone,
      opBln: opBln ?? this.opBln,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      creditDays: creditDays ?? this.creditDays,
      opAcc: opAcc ?? this.opAcc,
      status: status ?? this.status,
      balance: balance ?? this.balance,
      slex: slex ?? this.slex,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount, // ADDED
    );
  }

  // Helper getter for isActive
  bool get isActive => status.toLowerCase() == 'active';

  // Helper getter for formatted balance
  String get formattedBalance {
    try {
      // Handle comma in balance like "314,272.50"
      final cleanBalance = balance.replaceAll(',', '');
      final balanceValue = double.tryParse(cleanBalance.split(' ').first) ?? 0.0;
      return '₹${balanceValue.toStringAsFixed(2)}';
    } catch (e) {
      return '₹0.00';
    }
  }

  // Helper getter for formatted outstanding amount
  String get formattedOutstanding {
    try {
      final outstanding = outstandingAmount ?? '0.00';
      // Handle comma in outstanding amount like "314,872.50 Cr"
      final cleanOutstanding = outstanding.replaceAll(',', '');
      final parts = cleanOutstanding.split(' ');
      final amountStr = parts.first;
      final amountValue = double.tryParse(amountStr) ?? 0.0;
      final type = parts.length > 1 ? parts[1] : '';
      return '₹${amountValue.toStringAsFixed(2)} ${type.toUpperCase()}';
    } catch (e) {
      return '₹0.00';
    }
  }

  // Helper getter for outstanding amount without formatting
  String get rawOutstanding {
    return outstandingAmount ?? '0.00';
  }

  // Helper getter for balance type (Dr/Cr)
  String get balanceType {
    if (balance.toLowerCase().contains('cr')) return 'Cr';
    return 'Dr';
  }

  // Helper getter for outstanding type (Dr/Cr)
  String get outstandingType {
    final outstanding = outstandingAmount ?? '0.00';
    if (outstanding.toLowerCase().contains('cr')) return 'Cr';
    if (outstanding.toLowerCase().contains('dr')) return 'Dr';
    return '';
  }

  // Helper getter for outstanding amount value (as double)
  double get outstandingValue {
    try {
      final outstanding = outstandingAmount ?? '0.00';
      final cleanOutstanding = outstanding.replaceAll(',', '');
      final amountStr = cleanOutstanding.split(' ').first;
      return double.tryParse(amountStr) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Helper to check if customer has outstanding amount
  bool get hasOutstanding => outstandingValue != 0.0;

  // Helper to get outstanding amount color (Red for Cr, Green for Dr)
  int get outstandingColor {
    if (outstandingType == 'Cr') return 0xFFFF0000; // Red
    if (outstandingType == 'Dr') return 0xFF4CAF50; // Green
    return 0xFF000000; // Black
  }
}