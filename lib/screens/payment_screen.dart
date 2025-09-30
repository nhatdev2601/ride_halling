import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;

  final List<PaymentOption> _paymentOptions = [
    PaymentOption(
      method: PaymentMethod.cash,
      title: 'Tiền mặt',
      subtitle: 'Thanh toán trực tiếp với tài xế',
      icon: Icons.money,
      isEnabled: true,
    ),
    PaymentOption(
      method: PaymentMethod.wallet,
      title: 'Ví RideApp',
      subtitle: 'Số dư: 250,000đ',
      icon: Icons.account_balance_wallet,
      isEnabled: true,
    ),
    PaymentOption(
      method: PaymentMethod.creditCard,
      title: 'Thẻ tín dụng',
      subtitle: '**** **** **** 1234',
      icon: Icons.credit_card,
      isEnabled: true,
    ),
    PaymentOption(
      method: PaymentMethod.debitCard,
      title: 'Thẻ ghi nợ',
      subtitle: 'Chưa có thẻ nào',
      icon: Icons.payment,
      isEnabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phương thức thanh toán',
          style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Payment methods list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paymentOptions.length,
              itemBuilder: (context, index) {
                final option = _paymentOptions[index];
                final isSelected = _selectedMethod == option.method;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.lightGrey,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: option.isEnabled
                          ? () {
                              setState(() {
                                _selectedMethod = option.method;
                              });
                            }
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Payment icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryGreen.withOpacity(0.1)
                                    : AppTheme.lightGrey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                option.icon,
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : AppTheme.grey,
                                size: 24,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Payment info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: option.isEnabled
                                          ? AppTheme.black
                                          : AppTheme.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.subtitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: option.isEnabled
                                          ? AppTheme.grey
                                          : AppTheme.grey.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Selection indicator
                            if (option.isEnabled)
                              Radio<PaymentMethod>(
                                value: option.method,
                                groupValue: _selectedMethod,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedMethod = value;
                                    });
                                  }
                                },
                                activeColor: AppTheme.primaryGreen,
                              )
                            else
                              Icon(
                                Icons.add_circle_outline,
                                color: AppTheme.grey.withOpacity(0.6),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Add new payment method
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  _showAddPaymentMethod();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppTheme.primaryGreen,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Text(
                          'Thêm phương thức thanh toán',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.primaryGreen,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedMethod);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Thêm phương thức thanh toán',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildAddPaymentOption(
                    Icons.credit_card,
                    'Thẻ tín dụng/ghi nợ',
                    'Thêm thẻ Visa, Mastercard',
                    () {
                      Navigator.pop(context);
                      _showAddCardForm();
                    },
                  ),
                  _buildAddPaymentOption(
                    Icons.account_balance,
                    'Liên kết ngân hàng',
                    'Kết nối với tài khoản ngân hàng',
                    () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildAddPaymentOption(
                    Icons.phone_android,
                    'Ví điện tử',
                    'MoMo, ZaloPay, ViettelPay',
                    () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPaymentOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCardForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thẻ mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Số thẻ',
                hintText: '1234 5678 9012 3456',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/25',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tên chủ thẻ',
                hintText: 'nhá',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thêm thẻ thành công!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Thêm thẻ'),
          ),
        ],
      ),
    );
  }
}

class PaymentOption {
  final PaymentMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isEnabled;

  PaymentOption({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isEnabled,
  });
}
