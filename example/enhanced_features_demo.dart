/// Enhanced Features Demo
///
/// This example demonstrates the core features of the resx library,
/// including async operations, validation, state management, and extensions.
library;

import 'dart:math' as math;
import 'package:resx/resx.dart';

// Mock classes for demonstration
class User {
  final String name;
  final int age;
  final String email;

  const User(this.name, this.age, this.email);

  @override
  String toString() => 'User(name: $name, age: $age, email: $email)';
}

class AppState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const AppState({required this.users, this.isLoading = false, this.error});

  AppState copyWith({List<User>? users, bool? isLoading, String? error}) {
    return AppState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'AppState(users: ${users.length}, isLoading: $isLoading, error: $error)';
}

void main() async {
  print('=== Enhanced Features Demo ===\n');

  // 1. Async Result Operations
  await demonstrateAsyncOperations();

  // 2. Validation and Data Transformation
  demonstrateValidation();

  // 3. State Management
  await demonstrateStateManagement();

  // 4. Extension Methods
  demonstrateExtensions();
}

/// Demonstrates async result operations and chaining
Future<void> demonstrateAsyncOperations() async {
  print('1. Async Result Operations:');

  // Async result creation and chaining
  const results = [
    Result.ok('user1'),
    Result.ok('user2'),
    Result.err('Invalid user'),
  ];

  // Combine results
  final combinedResult = Results.combine(results);
  print('Combined results: $combinedResult');

  // Advanced async operations
  final futureValue = Future.value('async_value');
  final asyncResult = futureValue.toAsyncResult();
  final transformed =
      asyncResult.then((result) => result.map((value) => value.toUpperCase()));
  print('Async transformed: ${await transformed}');

  // Multiple async operations
  final future1 = Future.value(1);
  final future2 = Future.value(2);
  final asyncResult1 = future1.toAsyncResult();
  final asyncResult2 = future2.toAsyncResult();
  final combined = await AsyncResults.combine([asyncResult1, asyncResult2]);
  print('Async combined: $combined');

  print('');
}

/// Demonstrates validation and data transformation
void demonstrateValidation() {
  print('2. Validation and Data Transformation:');

  // User creation with validation
  const userData = [
    {'name': 'Alice', 'age': 25, 'email': 'alice@example.com'},
    {'name': 'Bob', 'age': 17, 'email': 'invalid-email'},
    {'name': '', 'age': 30, 'email': 'charlie@example.com'},
  ];

  final userResults = userData.map(validateUser).toList();

  for (final result in userResults) {
    print('User validation: $result');
  }

  // Chain validation operations
  final userValidationChain = validateUserChain('Bob', 25, 'bob@example.com');
  print('User validation chain: $userValidationChain');

  // Validation with built-in validators
  final emailValidation = Validators.email('test@example.com');
  print('Email validation: $emailValidation');

  final positiveNumber = Validators.positive(25);
  print('Positive number validation: $positiveNumber');

  final rangeValidation = Validators.range(25, 18, 65);
  print('Age range validation: $rangeValidation');

  print('');
}

/// Demonstrates state management with Result types
Future<void> demonstrateStateManagement() async {
  print('3. State Management:');

  // Initial state
  var appState = const AppState(users: []);

  // Simulate loading users
  appState = appState.copyWith(isLoading: true);
  print('Loading state: $appState');

  // Load users with error handling
  final loadResult = await loadUsers();
  appState = loadResult.fold(
    (users) => appState.copyWith(users: users, isLoading: false),
    (error) => appState.copyWith(error: error, isLoading: false),
  );

  print('Final state: $appState');

  // State transitions with validation
  const stateTransitions = [
    AppState(users: [], isLoading: true),
    AppState(users: [User('Alice', 25, 'alice@example.com')], isLoading: false),
    AppState(users: [], isLoading: false, error: 'Network error'),
  ];

  for (final state in stateTransitions) {
    final validatedState = validateAppState(state);
    print('State validation: $validatedState');
  }

  print('');
}

/// Demonstrates extension methods
void demonstrateExtensions() {
  print('4. Extension Methods:');

  // String extensions
  const name = 'Alice';
  final nameOption = name.toOption();
  print('Name as Option: $nameOption');

  const emptyName = '';
  final emptyOption = emptyName.toOption();
  print('Empty name as Option: $emptyOption');

  // List extensions
  const numbers = [1, 2, 3, 4, 5];
  final firstEven = numbers.findOption((n) => n % 2 == 0);
  print('First even number: $firstEven');

  // Async extensions
  final futureValue = Future.value(42);
  final asyncResult = futureValue.toAsyncResult();
  asyncResult.then((result) => print('Future as AsyncResult: $result'));

  // Map extensions
  const userMap = {'name': 'Bob', 'age': 30};
  final userName = userMap.getOption('name');
  print('User name from map: $userName');

  print('');
}

// Helper functions

Result<User, String> validateUser(Map<String, dynamic> data) {
  final name = data['name'] as String?;
  final age = data['age'] as int?;
  final email = data['email'] as String?;

  if (name == null || name.isEmpty) {
    return const Result.err('Name is required');
  }

  if (age == null || age < 18) {
    return const Result.err('Age must be 18 or older');
  }

  if (email == null || !email.contains('@')) {
    return const Result.err('Valid email is required');
  }

  return Result.ok(User(name, age, email));
}

Result<User, String> validateUserChain(String name, int age, String email) {
  return Result<String, String>.ok(name)
      .flatMap((n) => n.isEmpty
          ? const Result<String, String>.err('Name required')
          : Result<String, String>.ok(n))
      .flatMap((_) => age < 18
          ? const Result<String, String>.err('Too young')
          : Result<String, String>.ok(name))
      .flatMap((_) => !email.contains('@')
          ? const Result<String, String>.err('Invalid email')
          : Result<String, String>.ok(name))
      .map((_) => User(name, age, email));
}

Future<Result<List<User>, String>> loadUsers() async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 100));

  // Simulate random success/failure
  if (math.Random().nextBool()) {
    return const Result.ok([
      User('Alice', 25, 'alice@example.com'),
      User('Bob', 30, 'bob@example.com'),
    ]);
  } else {
    return const Result.err('Network error: Unable to load users');
  }
}

Result<AppState, String> validateAppState(AppState state) {
  if (state.isLoading && state.users.isNotEmpty) {
    return const Result.err('Cannot have users while loading');
  }

  if (state.error != null && state.users.isNotEmpty) {
    return const Result.err('Cannot have users with error');
  }

  return Result.ok(state);
}
