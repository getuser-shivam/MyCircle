// Test Coverage Runner for MyCircle AI Chat Features
// Run this script to generate comprehensive test coverage reports

import 'dart:io';

void main() async {
  print('🧪 Running Test Coverage Analysis for MyCircle AI Chat...\n');

  // Run unit tests with coverage
  print('📋 Running Unit Tests...');
  final unitResult = await Process.run('flutter', [
    'test',
    '--coverage',
    'test/unit/',
    '--reporter=expanded'
  ]);

  if (unitResult.exitCode != 0) {
    print('❌ Unit tests failed:');
    print(unitResult.stderr);
    return;
  }

  print('✅ Unit tests passed!\n');

  // Run widget tests with coverage
  print('🎨 Running Widget Tests...');
  final widgetResult = await Process.run('flutter', [
    'test',
    '--coverage',
    'test/widgets/',
    '--reporter=expanded'
  ]);

  if (widgetResult.exitCode != 0) {
    print('❌ Widget tests failed:');
    print(widgetResult.stderr);
    return;
  }

  print('✅ Widget tests passed!\n');

  // Run integration tests
  print('🔗 Running Integration Tests...');
  final integrationResult = await Process.run('flutter', [
    'test',
    'test/integration/',
    '--reporter=expanded'
  ]);

  if (integrationResult.exitCode != 0) {
    print('❌ Integration tests failed:');
    print(integrationResult.stderr);
    return;
  }

  print('✅ Integration tests passed!\n');

  // Generate coverage report
  print('📊 Generating Coverage Report...');
  final coverageResult = await Process.run('genhtml', [
    'coverage/lcov.info',
    '-o',
    'coverage/html'
  ]);

  if (coverageResult.exitCode == 0) {
    print('✅ Coverage report generated: coverage/html/index.html');
  } else {
    print('⚠️ Could not generate HTML coverage report (genhtml not available)');
  }

  // Show coverage summary
  print('\n📈 Coverage Summary:');
  print('Run the following commands for detailed coverage:');
  print('  flutter test --coverage');
  print('  lcov --summary coverage/lcov.info');
  print('  open coverage/html/index.html (if genhtml available)');

  print('\n🎉 All tests completed successfully!');
}
