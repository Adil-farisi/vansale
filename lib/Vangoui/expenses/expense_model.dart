class ExpenseModel {
  String voucherNo;
  String date;
  String category;
  String amount;
  String paymentMethod;
  String remark;

  ExpenseModel({
    required this.voucherNo,
    required this.date,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.remark,
  });

  Map<String, dynamic> toJson() {
    return {
      "voucherNo": voucherNo,
      "date": date,
      "category": category,
      "amount": amount,
      "paymentMethod": paymentMethod,
      "remark": remark,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      voucherNo: json["voucherNo"],
      date: json["date"],
      category: json["category"],
      amount: json["amount"],
      paymentMethod: json["paymentMethod"],
      remark: json["remark"],
    );
  }
}
