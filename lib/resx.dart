/// A powerful Dart library for functional error handling and type-safe operations.
///
/// Inspired by Rust's Result type and functional programming patterns from
/// multiple languages, this library provides an elegant API for handling
/// success/error cases, nullable values, validation, and async operations.
///
/// ## Core Types
///
/// - **`Result<T, E>`** - Type-safe success/error handling
/// - **`Option<T>`** - Safe nullable value operations
/// - **`Validation<E, T>`** - Error accumulating validation
/// - **`AsyncResult<T, E>`** - Async-aware result operations
///
/// ## Features
///
/// - 🚀 **High Performance** - Optimized for speed and memory efficiency
/// - 🔒 **Type Safe** - Full null safety and strong typing
/// - 🔗 **Chainable** - Fluent API with method chaining
/// - 📦 **Batch Operations** - Process collections efficiently
/// - 🎯 **Validation** - Accumulate multiple errors elegantly
/// - ⚡ **Async Support** - First-class async/await integration
/// - 🧩 **Extensions** - Native Dart type integrations
///
/// Basic usage example:
/// ```dart
/// import 'package:resx/resx.dart';
///
/// // Error handling
/// final result = Result.ok(42)
///   .map((x) => x * 2)
///   .flatMap((x) => x > 50 ? Result.ok(x) : Result.err('Too small'));
///
/// // Nullable handling
/// final option = Option.some('hello')
///   .map((s) => s.toUpperCase())
///   .filter((s) => s.length > 3);
///
/// // Validation with error accumulation
/// final validation = Validation.valid('user@example.com')
///   .and(Validation.valid(25))
///   .and(Validation.valid('John'));
/// ```
library resx;

export 'src/result.dart';
export 'src/option.dart';
export 'src/validation.dart';
export 'src/async_result.dart';
export 'src/extensions.dart';
export 'src/stream_extensions.dart';
export 'src/loadable.dart';
