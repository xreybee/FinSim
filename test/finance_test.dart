import 'package:flutter_test/flutter_test.dart';
import 'package:finsim/controllers/finance_controller.dart';
import 'package:finsim/services/firebase_service.dart';

void main() {
  group('Finsim Budget Calculations Tests', () {
    test('Verify automatic 6 pos limits are calculated correctly', () async {
      final finance = FinanceController();
      
      // Initialize mock service database
      FirebaseService.initMock();
      finance.init('mock_uid_123');

      // Wait for async stream event emission
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify salary is mapped
      expect(finance.monthlySalary, 12000000.0);

      // Verify limits (40/10/10/10/10/20)
      expect(finance.limitSurvival, 12000000.0 * 0.40);     // 4,800,000
      expect(finance.limitTransport, 12000000.0 * 0.10);    // 1,200,000
      expect(finance.limitStyle, 12000000.0 * 0.10);        // 1,200,000
      expect(finance.limitEntertainment, 12000000.0 * 0.10); // 1,200,000
      expect(finance.limitEmergency, 12000000.0 * 0.10);     // 1,200,000
      expect(finance.limitGoals, 12000000.0 * 0.20);         // 2,400,000
    });

    test('Verify category overspending triggers status change', () async {
      final finance = FinanceController();
      FirebaseService.initMock();
      finance.init('mock_uid_123');

      // Wait for async stream event emission
      await Future.delayed(const Duration(milliseconds: 50));

      // Style has 1.6M expense, exceeding the 1.2M limit
      final styleStatus = finance.getCategoryStatus('Style');
      expect(styleStatus['isHealthy'], false);
      expect(styleStatus['status'], 'Kurang Sehat');

      // Survival has 250k expense, which is under the 4.8M limit
      final survivalStatus = finance.getCategoryStatus('Survival');
      expect(survivalStatus['isHealthy'], true);
      expect(survivalStatus['status'], 'Sehat');
    });
  });
}
