# Resx ⚡️

[![pub package](https://img.shields.io/pub/v/resx.svg)](https://pub.dev/packages/resx)
[![documentation](https://img.shields.io/badge/documentation-pub.dev-blue.svg)](https://pub.dev/documentation/resx/latest/)
[![license: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

一个小而全的 Dart 函数式错误处理工具集：Result、Option、Validation、AsyncResult、Stream 帮助器与极简 Loadable 状态。

[English](README.md) | **中文**

## 特性 ✨

🚀 **高性能** - 为速度和内存效率优化  
🔒 **类型安全** - 完全空安全和强类型  
🔗 **链式调用** - 流畅的方法链式 API  
📦 **批量操作** - 高效处理集合  
🎯 **验证** - 优雅地累积多个错误  
⚡ **异步支持** - 一流的 async/await 集成  
🧩 **扩展** - 原生 Dart 类型集成

## 核心类型 🧠

### Result&lt;T, E&gt; - 错误处理 ✅/❌

受 Rust Result 类型启发的类型安全错误处理。

```dart
import 'package:resx/resx.dart';

// 创建结果
final success = Result.ok(42);
final failure = Result.err('出错了');

// 链式操作
final result = Result.ok(5)
  .map((x) => x * 2)
  .flatMap((x) => x > 5 ? Result.ok(x) : Result.err('太小了'));

// 处理两种情况
final message = result.fold(
  (value) => '成功: $value',
  (error) => '错误: $error',
);

// 捕获异常
final parsed = Result.from(() => int.parse('42')); // Ok(42)
final failed = Result.from(() => int.parse('abc')); // Err(FormatException)

// 守卫与交换
final ensured = Result.ok(10).ensure((v) => v > 5, '太小');
final swapped = Result.ok(1).swap(); // Err(1)
```

### Option&lt;T&gt; - 可空值 ❓

使用 Some/None 变体安全处理可空值。

```dart
// 创建选项
final some = Option.some('Hello');
final none = Option<String>.none();

// 安全操作
final result = Option.some('world')
  .map((s) => s.toUpperCase())
  .filter((s) => s.length > 3)
  .unwrapOr('DEFAULT');
```

### Validation&lt;E, T&gt; - 错误累积

收集多个验证错误而不是快速失败。

```dart
// 内置验证器
final emailValidation = Validations.email('user@example.com');
final rangeValidation = Validations.range(25, 18, 65);

// 累积错误验证
final userValidation = validateUser(
  name: 'John',
  email: 'invalid-email',
  age: 150,
);
```

### AsyncResult&lt;T, E&gt; - 异步操作

对 Result 操作的一流异步支持。

```dart
// 创建异步结果
final asyncResult = Future.value(42).toAsyncResult();

// 链式异步操作
final result = await asyncResult.then((r) => r.map((x) => x * 2));

// 异步守卫
final ensuredAsync = await AsyncResult.ok<int, String>(10)
  .ensure((v) => v > 0, '非正数');
```

## Dart 扩展 🧩

### String 扩展 🔤

```dart
// 转换为 Option
final name = 'John'.some(); // Some('John')
// 仅 null -> None，如需过滤空串请用 nonEmpty()
final empty = ''.nonEmpty(); // None

// 解析数字（Result）
final ok = '42'.parseInt(); // Ok(42)
final err = 'abc'.parseInt(); // Err(FormatException)

// 转换为 Result
final result = 'valid'.toResult('错误信息');
```

### List/Stream/Nullable 扩展 🔁

```dart
final numbers = [1, 2, 3, 4, 5];

// 安全获取元素
final first = numbers.firstOption(); // Some(1)
final element = numbers.getOption(2); // Some(3)
final notFound = numbers.getOption(10); // None

// 查找元素
final even = numbers.findOption((x) => x.isEven); // Some(2)
```

### Map 扩展

```dart
final config = {'host': 'localhost', 'port': '8080'};

// 安全获取值
final host = config.getOption('host'); // Some('localhost')
final timeout = config.getOption('timeout'); // None
```

### Future 扩展

```dart
// 转换为 AsyncResult
final futureValue = Future.value(42);
final asyncResult = futureValue.toAsyncResult();
```

## 批量操作与流

```dart
// 组合多个结果
final results = [Result.ok(1), Result.err('e'), Result.ok(3)];
final combined = Results.combine(results); // Err('e')

// 处理混合结果
final (values, errors) = Results.partition(results);
// values: [1, 3], errors: ['错误']

// Stream 帮助器
final stream = Stream.fromIterable([1,2,3]);
final asResults = stream.toResultStream<Object>();
final collected = await stream.collectToResult<Object>();
```

## 实际应用示例

### API 错误处理

```dart
class ApiClient {
  AsyncResult<User, String> getUser(int id) {
    return http.get('/users/$id')
        .toAsyncResult()
        .then((response) => response.flatMap(_parseUser));
  }
  
  Result<User, String> _parseUser(String json) {
    try {
      final data = jsonDecode(json);
      return Result.ok(User.fromJson(data));
    } catch (e) {
      return Result.err('解析用户数据失败: $e');
    }
  }
}

// 使用
final user = await apiClient.getUser(123)
    .then((result) => result.fold(
      (user) => '欢迎, ${user.name}!',
      (error) => '加载用户失败: $error',
    ));
```

### 表单验证

```dart
Result<User, String> validateUser({
  required String name,
  required String email,
  required int age,
}) {
  // 验证姓名
  if (name.isEmpty) {
    return const Result.err('姓名不能为空');
  }
  
  // 验证邮箱
  if (!email.contains('@')) {
    return const Result.err('邮箱格式无效');
  }
  
  // 验证年龄
  if (age < 0 || age > 120) {
    return const Result.err('年龄必须在 0-120 之间');
  }
  
  return Result.ok(User(name, email, age));
}

// 使用
final userResult = validateUser(
  name: 'John',
  email: 'john@example.com',
  age: 25,
);

final message = userResult.fold(
  (user) => '用户创建成功: ${user.name}',
  (error) => '验证失败: $error',
);
```

### 通用与可空快速转换

```dart
String? nullable = getValue();
final option = nullable.toOption(); // Option<String>

final result = nullable.toResult('值为空'); // Result<String, String>

// 通用：快速包装任意值
final r1 = 42.ok<String>();          // Result<int, String>::Ok(42)
final r2 = 'boom'.err<int>();         // Result<int, String>::Err('boom')
final o1 = 'hello'.some();            // Option<String>::Some('hello')
```

```dart
class AppState {
  final List<User> users;
  final bool isLoading;
  final Option<String> error;
  
  const AppState({
    required this.users,
    this.isLoading = false,
    this.error = const Option.none(),
  });
  
  AppState copyWith({
    List<User>? users,
    bool? isLoading,
    Option<String>? error,
  }) {
    return AppState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 状态处理函数
AppState handleLoadUsers(AppState state) {
  return state.copyWith(
    isLoading: true, 
    error: const Option.none(),
  );
}

AppState handleUsersLoaded(AppState state, Result<List<User>, String> result) {
  return result.fold(
    (users) => state.copyWith(
      users: users,
      isLoading: false,
      error: const Option.none(),
    ),
    (error) => state.copyWith(
      isLoading: false,
      error: Option.some(error),
    ),
  );
}
```

## 安装

添加到你的 `pubspec.yaml`:

```yaml
dependencies:
  resx: any
```

然后运行:

```bash
dart pub get
```

## 示例

查看 [example](example/) 目录获取完整使用示例：

- [基础用法](example/main.dart) - 核心功能演示
- [增强特性](example/enhanced_features_demo.dart) - 所有特性展示

## API 文档

完整的 API 文档可在 [pub.dev](https://pub.dev/documentation/resx/latest/) 查看。

## 贡献

欢迎贡献！请随时提交问题和拉取请求。

## 许可证

本项目在 MIT 许可证下授权 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

由 FlutterCandies 以 💙 制作
