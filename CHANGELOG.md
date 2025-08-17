# Changelog

## 0.3.0

Added

- Universal conversions: `value.ok<E>()`, `value.some()`, and `'e'.err<T>()` for instant wrapping into Result/Option.
- Kotlin/Rust-style ergonomic aliases:
	- Result: `getOrNull()`, `getOrDefault(value)`, `getOrElse(fn)`.
	- Option: `okOr(error)`, `okOrElse(fn)`, `orNull()`, `unwrapOr(value)`, `unwrapOrElse(fn)`.

Changed

- Docs mention universal conversions and aliases. Version bump to 0.3.0.

---

## 0.2.0

Added

- Result: ensure/ensureElse to guard Ok values; swap to invert Ok/Err.
- Results: sequence and partition utilities.
- AsyncResult: ensure; AsyncResults.sequence/partition.
- Stream extensions: toResultStream and collectToResult.
- Tiny state management: Loadable (Loading/Data/Error) and LoadableController.

Changed

- Public library now exports stream_extensions.dart and loadable.dart.
- README (EN/ZH) refreshed with new APIs and examples.

Fixed

- Minor doc comments and tests coverage; added tests for all new APIs.

---

## 0.1.0

Initial release

- Result with core ops (`ok`, `err`, `map`, `flatMap`, `fold`) and utilities (`Results.combine`, `Results.traverse`).
- Option with `some`/`none`, map/flatMap/fold and utilities.
- Validation with error accumulation and built-in validators.
- AsyncResult (Future of Result) with async chaining; AsyncResults utilities.
- Extensions for String/List/Map/Future/num/bool.
