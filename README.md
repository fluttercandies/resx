# Resx

[![pub package](https://img.shields.io/pub/v/resx.svg)](https://pub.dev/packages/resx)
[![documentation](https://img.shields.io/badge/documentation-pub.dev-blue.svg)](https://pub.dev/documentation/resx/latest/)
[![license: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A tiny-yet-complete functional error handling toolkit for Dart: Result, Option, Validation, AsyncResult, Stream helpers, and a minimal Loadable state.

**English** | [中文](README_zh.md)

## Features

🚀 **High Performance** - Optimized for speed and memory efficiency  
🔒 **Type Safe** - Full null safety and strong typing  
🔗 **Chainable** - Fluent API with method chaining  
📦 **Batch Operations** - Process collections efficiently  
🎯 **Validation** - Accumulate multiple errors elegantly  
⚡ **Async Support** - First-class async/await integration  
🧩 **Extensions** - Native Dart type integrations

## Core Types

### Result&lt;T, E&gt; - Error Handling

Type-safe error handling inspired by Rust's Result type.

```dart
import 'package:resx/resx.dart';

// Create results
final success = Result.ok(42);
final failure = Result.err('Something went wrong');

// Chain operations
final result = Result.ok(5)
  .map((x) => x * 2)
  .flatMap((x) => x > 5 ? Result.ok(x) : Result.err('Too small'));

// Handle both cases
final message = result.fold(
  (value) => 'Success: $value',
  (error) => 'Error: $error',
);

// Exception catching
final parsed = Result.from(() => int.parse('42')); // Ok(42)
final failed = Result.from(() => int.parse('abc')); // Err(FormatException)

// Guards and swap
final guarded = Result.ok(10).ensure((v) => v > 5, 'Too small');
final swapped = Result.ok(1).swap(); // Err(1)
```

### Option&lt;T&gt; - Nullable Values

Safe nullable value handling with Some/None variants.

```dart
// Create options
final some = Option.some('Hello');
final none = Option<String>.none();

// Safe operations
final result = Option.some('world')
  .map((s) => s.toUpperCase())
  .filter((s) => s.length > 3)
  .orElse(() => 'DEFAULT');

// From nullable
String? nullable = getValue();
final option = Option.fromNullable(nullable);
```

### Validation&lt;E, T&gt; - Error Accumulation

Collect multiple validation errors instead of failing fast.

```dart
// Built-in validators
final emailValidation = Validators.email('user@example.com', 'Invalid email');
final rangeValidation = Validators.range(25, 18, 65, 'Age out of range');

// Accumulate errors
final userValidation = Validators.notEmpty('John', 'Name required')
  .and(Validators.email('invalid-email', 'Email invalid'))
  .and(Validators.range(150, 0, 120, 'Age invalid'));

// Result: Invalid(['Email invalid', 'Age invalid'])
```

### AsyncResult&lt;T, E&gt; - Async Operations

First-class async support for Result operations.

```dart
// Create async results
final asyncResult = AsyncResult.ok(42);
final fromFuture = AsyncResult.from(fetchData());

// Chain async operations
final result = await AsyncResult.ok(5)
  .map((x) => x * 2)
  .flatMap((x) => AsyncResult.ok(x + 1));

// Handle async errors safely
final safeResult = await AsyncResult.from(riskyOperation())
  .orElse((error) => AsyncResult.ok('fallback'));

// Guard async values
final ensured = await AsyncResult.ok<int, String>(10)
  .ensure((v) => v > 0, 'non-positive');
```

## Dart Extensions

### String Extensions

```dart
// Parsing with results
final number = '42'.parseIntResult(); // Ok(42)
final invalid = 'abc'.parseIntResult(); // Err('Invalid integer')

// Validation
final email = 'user@example.com'.validateEmail(); // Valid(...)
final url = 'https://example.com'.validateUrl(); // Valid(...)
```

### List, Stream and Nullable Extensions

```dart
final numbers = [1, 2, 3, 4, 5];
final results = numbers.map((x) => x.isEven ? Result.ok(x) : Result.err('odd'));
final combined = Results.sequence(results); // Ok([...]) or first Err
final (oks, errs) = Results.partition(results);

// Stream helpers
final stream = Stream.fromIterable([1,2,3]);
final asResults = stream.toResultStream<Object>();
final collected = await stream.collectToResult<Object>();
```

### Nullable Extensions

```dart
String? nullable = getValue();
final option = nullable.toOption(); // Option<String>

final result = nullable.toResult('Value is null'); // Result<String, String>
```

## Batch Operations

```dart
// Combine multiple results
final results = [Result.ok(1), Result.ok(2), Result.ok(3)];
final combined = Results.combine(results); // Ok([1, 2, 3])

// Partition successes and errors
final mixed = [Result.ok(1), Result.err('error'), Result.ok(3)];
final (values, errors) = Results.partition(mixed); // ([1, 3], ['error'])

// Applicative operations
final sum = Results.lift2(
  Result.ok(2),
  Result.ok(3),
  (a, b) => a + b,
); // Ok(5)
```

## Advanced Usage

### Custom Validators

```dart
final customValidator = Validator<String, String>(
  (value) => value.startsWith('prefix_') 
    ? Validation.valid(value)
    : Validation.invalid(['Must start with prefix_']),
);

final result = customValidator.validate('test'); // Invalid(...)
```

### Pattern Matching

```dart
final result = Result.ok(42);

final message = result.match(
  ok: (value) => 'Got value: $value',
  err: (error) => 'Got error: $error',
);
```

### Railway-Oriented Programming

```dart
final pipeline = (String input) => Result.ok(input)
  .flatMap(validateInput)
  .flatMap(processData)
  .flatMap(saveToDatabase)
  .map(formatResponse);

final result = pipeline('user input');
```

## Performance

Focused API, minimal indirections, idiomatic Dart sealed classes and extension types. No magic.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  resx: ^0.2.0
```

Then run:

```bash
dart pub get
```

## Examples

Check out the [example](example/) directory for comprehensive usage examples:

- [Basic Usage](example/main.dart) - Core functionality
- [Enhanced Features](example/enhanced_features_demo.dart) - All features showcase

## API Documentation

Complete API documentation with examples is available at [pub.dev](https://pub.dev/documentation/resx/latest/).

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) and feel free to submit issues and pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ for the Dart community
