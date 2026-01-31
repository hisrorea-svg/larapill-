import 'package:flutter_test/flutter_test.dart';

import 'package:larapill/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:larapill/features/inventory/domain/entities/inventory_stats.dart';
import 'package:larapill/features/inventory/domain/failures/inventory_failure.dart';
import 'package:larapill/features/inventory/domain/usecases/get_inventory_stats_use_case.dart';

import '../../mocks/mock_inventory_datasources.dart';
import '../../mocks/test_data.dart';

void main() {
  group('GetInventoryStatsUseCase', () {
    late MockInventoryLocalDataSource mockLocalDataSource;
    late InventoryRepositoryImpl repository;
    late GetInventoryStatsUseCase useCase;

    setUp(() {
      mockLocalDataSource = MockInventoryLocalDataSource();
      repository = InventoryRepositoryImpl(mockLocalDataSource);
      useCase = GetInventoryStatsUseCase(repository);
    });

    tearDown(() {
      mockLocalDataSource.dispose();
    });

    group('call', () {
      test('should return inventory stats successfully', () async {
        // Arrange
        final stats = TestData.createInventoryStatsModel(
          totalProducts: 100,
          lowStockCount: 10,
          criticalStockCount: 5,
          outOfStockCount: 2,
          expiredCount: 3,
          expiringSoonCount: 8,
          inventoryValue: 50000.0,
          totalCost: 30000.0,
          expectedProfit: 20000.0,
          pendingSyncCount: 5,
        );
        mockLocalDataSource.setStats(stats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right, isA<InventoryStatsEntity>());
        expect(result.right.totalProducts, 100);
        expect(result.right.lowStockCount, 10);
        expect(result.right.criticalStockCount, 5);
        expect(result.right.outOfStockCount, 2);
        expect(result.right.expiredCount, 3);
        expect(result.right.expiringSoonCount, 8);
        expect(result.right.inventoryValue, 50000.0);
        expect(result.right.totalCost, 30000.0);
        expect(result.right.expectedProfit, 20000.0);
        expect(result.right.pendingSyncCount, 5);
      });

      test('should return zero stats when inventory is empty', () async {
        // Arrange
        final stats = TestData.createInventoryStatsModel(
          totalProducts: 0,
          lowStockCount: 0,
          criticalStockCount: 0,
          outOfStockCount: 0,
          expiredCount: 0,
          expiringSoonCount: 0,
          inventoryValue: 0.0,
          totalCost: 0.0,
          expectedProfit: 0.0,
          pendingSyncCount: 0,
        );
        mockLocalDataSource.setStats(stats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right.totalProducts, 0);
        expect(result.right.inventoryValue, 0.0);
      });

      test('should return DatabaseFailure when repository fails', () async {
        // Arrange
        mockLocalDataSource.throwCacheException('Stats calculation failed');

        // Act
        final result = await useCase();

        // Assert
        expect(result.isLeft, true);
        expect(result.left, isA<DatabaseFailure>());
      });

      test('should calculate profit correctly', () async {
        // Arrange
        final stats = TestData.createInventoryStatsModel(
          inventoryValue: 100000.0,
          totalCost: 60000.0,
          expectedProfit: 40000.0,
        );
        mockLocalDataSource.setStats(stats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right.inventoryValue - result.right.totalCost,
            result.right.expectedProfit);
      });

      test('should handle large inventory values', () async {
        // Arrange
        final stats = TestData.createInventoryStatsModel(
          totalProducts: 1000000,
          inventoryValue: 999999999.0,
          totalCost: 888888888.0,
          expectedProfit: 111111111.0,
        );
        mockLocalDataSource.setStats(stats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right.totalProducts, 1000000);
        expect(result.right.inventoryValue, 999999999.0);
      });

      test('should return correct pending sync count', () async {
        // Arrange
        final stats = TestData.createInventoryStatsModel(
          pendingSyncCount: 15,
        );
        mockLocalDataSource.setStats(stats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right.pendingSyncCount, 15);
      });

      test('should handle negative profit (loss scenario)', () async {
        // Arrange
        final stats = TestData.createInventoryStatsModel(
          inventoryValue: 50000.0,
          totalCost: 60000.0,
          expectedProfit: -10000.0,
        );
        mockLocalDataSource.setStats(stats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isRight, true);
        expect(result.right.expectedProfit, -10000.0);
      });
    });
  });
}
