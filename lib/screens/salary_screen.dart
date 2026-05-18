import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    final double basicSalary = user?.basicSalary ?? 0.0;
    final double transportAllowance = user?.allowances['transport'] ?? 0.0;
    final double housingAllowance = user?.allowances['housing'] ?? 0.0;
    final double medicalAllowance = user?.allowances['medical'] ?? 0.0;
    final double otherAllowance = user?.allowances['other'] ?? 0.0;
    
    final double totalAllowances = transportAllowance + housingAllowance + medicalAllowance + otherAllowance;
    final double netSalary = basicSalary + totalAllowances;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('كشف الراتب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'الراتب الإجمالي',
                    style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.9), fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${netSalary.toStringAsFixed(0)} ج.م',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              'تفاصيل الراتب',
              [
                _buildRowItem('الراتب الأساسي', '${basicSalary.toStringAsFixed(0)} ج.م', Icons.attach_money_rounded),
                if (transportAllowance > 0) ...[
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildRowItem('بدل انتقال', '${transportAllowance.toStringAsFixed(0)} ج.م', Icons.directions_car_filled_outlined),
                ],
                if (housingAllowance > 0) ...[
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildRowItem('بدل سكن', '${housingAllowance.toStringAsFixed(0)} ج.م', Icons.home_work_outlined),
                ],
                if (medicalAllowance > 0) ...[
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildRowItem('بدل طبي', '${medicalAllowance.toStringAsFixed(0)} ج.م', Icons.medical_services_outlined),
                ],
                if (otherAllowance > 0) ...[
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildRowItem('بدلات أخرى', '${otherAllowance.toStringAsFixed(0)} ج.م', Icons.more_horiz_rounded),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'الاستقطاعات',
              [
                _buildRowItem('تأمينات اجتماعية', '0 ج.م', Icons.security_rounded),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildRowItem('ضرائب', '0 ج.م', Icons.account_balance_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildRowItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const Spacer(),
          Text(value, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
