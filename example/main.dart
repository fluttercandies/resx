import 'package:resx/resx.dart';

void main() {
  // Basic Result usage
  final result = divide(10, 2);
  final output = result.fold(
    (value) => 'Result: $value',
    (error) => 'Error: $error',
  );
  print(output); // Result: 5.0

  // Chain operations
  final chainedResult = const Result.ok(5)
      .map((x) => x * 2)
      .flatMap((x) => x > 5 ? Result.ok(x) : const Result.err('Too small'))
      .map((x) => 'Final: $x');

  if (chainedResult.isOk) {
    print(chainedResult.value); // Final: 10
  }

  // Option usage for nullable values
  const option = Option.some(42);
  final doubled = option
      .map((x) => x * 2)
      .filter((x) => x > 50)
      .orElse(() => const Option.some(0));

  if (doubled.isSome) {
    print(doubled.value); // 84
  }

  // Validation with error accumulation
  final validation = validateUser('John', 25, 'john@example.com');
  validation.fold(
    (user) => print('Valid user: $user'),
    (errors) => print('Validation errors: $errors'),
  );

  // Async operations
  asyncExample();
}

/// Divides two numbers safely
Result<double, String> divide(double a, double b) {
  if (b == 0) {
    return const Result.err('Division by zero');
  }
  return Result.ok(a / b);
}

/// Validates user data with error accumulation
Validation<String, User> validateUser(String name, int age, String email) {
  final nameValidation = name.isNotEmpty
      ? Validation<String, String>.valid(name)
      : const Validation<String, String>.invalid(['Name cannot be empty']);

  final ageValidation = age >= 0
      ? Validation<String, int>.valid(age)
      : const Validation<String, int>.invalid(['Age must be positive']);

  final emailValidation = email.contains('@')
      ? Validation<String, String>.valid(email)
      : const Validation<String, String>.invalid(['Invalid email format']);

  // Combine validations
  final combined = Validations.combine([
    nameValidation,
    ageValidation,
    emailValidation,
  ]);
  return combined.isValid
      ? Validation.valid(User(name, age, email))
      : Validation.invalid(combined.errors);
}

/// Demonstrates async operations with Future
Future<void> asyncExample() async {
  final futureResult = Future.value(const Result.ok(42));

  final result = await futureResult;
  final processed = result.map((x) => x * 2).map((x) => x.toString());

  print(
    'Async result: ${processed.fold((v) => v, (e) => 'Error: $e')}',
  ); // Async result: 84
}

class User {
  final String name;
  final int age;
  final String email;

  User(this.name, this.age, this.email);

  @override
  String toString() => 'User($name, $age, $email)';
}
