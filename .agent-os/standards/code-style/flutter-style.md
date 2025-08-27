# Flutter Style Guide

## Formatting

### Use dart format
- Always use `dart format .` to format code before committing
- Use 2 spaces for indentation (Dart default)
- Configure analysis_options.yaml for linting rules

### Line Length
- Prefer 80 characters per line
- Break long widget constructors at logical boundaries
- Use trailing commas for better git diffs

### Widget Constructors

```dart
// Good: Use trailing commas and proper formatting
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.0),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      'Hello, World!',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  );
}
```

## Widget Design

### File Size & Component Breakdown
- **No Large Files**: Keep Flutter widget files small and focused (~100-150 lines max)
- **Break Down Components**: Extract widgets into separate files when they exceed size limits
- **Single Responsibility**: Each widget file should have one primary responsibility
- **Modular Design**: Create reusable components that can be imported and used across the app
- **Composition Over Complexity**: Build complex UIs by composing smaller, focused widgets

### Stateless vs Stateful
```dart
// GOOD: Small, focused widget in its own file (user_avatar.dart)
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.onTap,
  });

  final String imageUrl;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

// GOOD: Extracted component (user_info_section.dart)
class UserInfoSection extends StatelessWidget {
  const UserInfoSection({
    super.key,
    required this.name,
    required this.email,
    this.subtitle,
  });

  final String name;
  final String email;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

// GOOD: Composed from smaller components (user_card.dart)
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.onAvatarTap,
  });

  final User user;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: UserAvatar(
          imageUrl: user.avatarUrl,
          onTap: onAvatarTap,
        ),
        title: UserInfoSection(
          name: user.name,
          email: user.email,
          subtitle: user.lastActive,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Good: Use StatefulWidget only when state is needed
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_counter'),
        ElevatedButton(
          onPressed: _incrementCounter,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

## Refactoring & Code Cleanup

### Clean Refactoring Practices
```dart
// BAD: Leaving historical comments and dead code
class UserService {
  final ApiClient _client;

  UserService(this._client);

  // TODO: Remove this method after migration - 2023-12-01
  // This was the old way of fetching users
  /*
  Future<User> fetchUserOld(String id) async {
    // Old implementation that we don't use anymore
    final response = await _client.get('/users/$id');
    return User.fromJson(response.data);
  }
  */

  /// Fetches user data from the API
  /// Updated: 2024-01-15 - Added error handling
  /// Modified: 2024-02-10 - Changed to use new endpoint
  Future<User> fetchUser(String id) async {
    try {
      // Call the API endpoint (updated to v2)
      final response = await _client.get('/api/v2/users/$id');
      
      // Parse the response data into a User object
      return User.fromJson(response.data);
    } catch (e) {
      // Handle any errors that occur during the fetch
      throw UserFetchException('Failed to fetch user: $e');
    }
  }
}

// GOOD: Clean, focused code with only necessary comments
class UserService {
  final ApiClient _client;

  UserService(this._client);

  Future<User> fetchUser(String id) async {
    try {
      final response = await _client.get('/api/v2/users/$id');
      return User.fromJson(response.data);
    } catch (e) {
      throw UserFetchException('Failed to fetch user: $e');
    }
  }
}

// BAD: Renaming old files and keeping them around
// Files in project:
// - user_widget_old.dart (renamed but still exists)
// - user_widget_v1.dart (old version kept for reference)
// - user_widget_backup.dart (backup copy)
// - user_widget.dart (current version)

// GOOD: Clean file structure after refactoring
// Files in project:
// - user_widget.dart (current, clean implementation)
// Old files deleted completely from repository

// BAD: Widget with historical baggage
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      // FIXME: This padding was changed from 8.0 to 16.0 on 2024-01-20
      // TODO: Consider using theme padding instead
      // NOTE: Design team requested this change in ticket ABC-123
      margin: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Old image loading approach - now using cached network image
          /*
          Image.network(
            product.imageUrl,
            height: 200,
            fit: BoxFit.cover,
          ),
          */
          CachedNetworkImage(
            imageUrl: product.imageUrl,
            height: 200,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(product.name),
          ),
        ],
      ),
    );
  }
}

// GOOD: Clean, refactored widget
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: product.imageUrl,
            height: 200,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(product.name),
          ),
        ],
      ),
    );
  }
}
```

## Architecture Principles

### Separation of Concerns Example
```dart
// GOOD: Pure, testable widget with no business logic
class UserProfileView extends StatelessWidget {
  const UserProfileView({
    super.key,
    required this.user,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onEdit,
  });

  // All data comes from external state
  final User? user;
  final bool isLoading;
  final String? error;
  
  // Actions are passed as callbacks
  final VoidCallback onRefresh;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Pure presentation logic only
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (user == null) {
      return const Center(child: Text('No user data'));
    }
    
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(user!.avatarUrl),
        ),
        const SizedBox(height: 16),
        Text(
          user!.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(user!.email),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onEdit,
          child: const Text('Edit Profile'),
        ),
      ],
    );
  }
}

// GOOD: Business logic isolated in Cubit
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._repository) : super(const UserProfileState.initial());

  final UserRepository _repository;

  Future<void> loadUser(String userId) async {
    emit(const UserProfileState.loading());
    
    try {
      final user = await _repository.getUser(userId);
      emit(UserProfileState.loaded(user));
    } catch (error) {
      emit(UserProfileState.error(error.toString()));
    }
  }

  Future<void> refreshUser() async {
    final currentState = state;
    if (currentState is _Loaded) {
      await loadUser(currentState.user.id);
    }
  }

  Future<void> updateUser(User updatedUser) async {
    try {
      await _repository.updateUser(updatedUser);
      emit(UserProfileState.loaded(updatedUser));
    } catch (error) {
      emit(UserProfileState.error('Failed to update user: ${error.toString()}'));
    }
  }
}

// GOOD: Container widget that connects state to view
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileCubit(
        context.read<UserRepository>(),
      )..loadUser(userId),
      child: Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (user) => UserProfileView(
                user: user,
                isLoading: false,
                error: null,
                onRefresh: () => context.read<UserProfileCubit>().refreshUser(),
                onEdit: () => _navigateToEditPage(context, user),
              ),
              error: (message) => UserProfileView(
                user: null,
                isLoading: false,
                error: message,
                onRefresh: () => context.read<UserProfileCubit>().loadUser(userId),
                onEdit: () {}, // Disabled when error
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToEditPage(BuildContext context, User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditUserPage(user: user),
      ),
    );
  }
}

// GOOD: Easy to test in isolation
void main() {
  group('UserProfileView', () {
    testWidgets('displays loading state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileView(
            user: null,
            isLoading: true,
            error: null,
            onRefresh: () {},
            onEdit: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileView(
            user: null,
            isLoading: false,
            error: 'Network error',
            onRefresh: () {},
            onEdit: () {},
          ),
        ),
      );

      expect(find.text('Error: Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays user data correctly', (tester) async {
      final testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileView(
            user: testUser,
            isLoading: false,
            error: null,
            onRefresh: () {},
            onEdit: () {},
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is tapped', (tester) async {
      bool editCalled = false;
      
      final testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileView(
            user: testUser,
            isLoading: false,
            error: null,
            onRefresh: () {},
            onEdit: () => editCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Edit Profile'));
      expect(editCalled, isTrue);
    });
  });
}
```

### BLoC/Cubit State Management
```dart
// Good: Use Freezed for data classes
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_state.freezed.dart';

@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(User user) = _Loaded;
  const factory UserState.error(String message) = _Error;
}

// Good: Use Cubit for simple state management
import 'package:flutter_bloc/flutter_bloc.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit(this._repository) : super(const UserState.initial());

  final UserRepository _repository;

  Future<void> loadUser(String userId) async {
    emit(const UserState.loading());
    
    try {
      final user = await _repository.getUser(userId);
      emit(UserState.loaded(user));
    } catch (error) {
      emit(UserState.error(error.toString()));
    }
  }
}

// Good: Use BLoC for complex state management with events
import 'package:flutter_bloc/flutter_bloc.dart';

@freezed
class UserEvent with _$UserEvent {
  const factory UserEvent.loadUser(String userId) = _LoadUser;
  const factory UserEvent.updateUser(User user) = _UpdateUser;
  const factory UserEvent.deleteUser(String userId) = _DeleteUser;
}

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this._repository) : super(const UserState.initial()) {
    on<_LoadUser>(_onLoadUser);
    on<_UpdateUser>(_onUpdateUser);
    on<_DeleteUser>(_onDeleteUser);
  }

  final UserRepository _repository;

  Future<void> _onLoadUser(_LoadUser event, Emitter<UserState> emit) async {
    emit(const UserState.loading());
    
    try {
      final user = await _repository.getUser(event.userId);
      emit(UserState.loaded(user));
    } catch (error) {
      emit(UserState.error(error.toString()));
    }
  }

  Future<void> _onUpdateUser(_UpdateUser event, Emitter<UserState> emit) async {
    try {
      await _repository.updateUser(event.user);
      emit(UserState.loaded(event.user));
    } catch (error) {
      emit(UserState.error(error.toString()));
    }
  }

  Future<void> _onDeleteUser(_DeleteUser event, Emitter<UserState> emit) async {
    try {
      await _repository.deleteUser(event.userId);
      emit(const UserState.initial());
    } catch (error) {
      emit(UserState.error(error.toString()));
    }
  }
}

// Good: Use BlocBuilder to rebuild only when needed
class UserProfile extends StatelessWidget {
  const UserProfile({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Text('No user selected'),
          loading: () => const CircularProgressIndicator(),
          loaded: (user) => UserCard(user: user),
          error: (message) => Text('Error: $message'),
        );
      },
    );
  }
}
```

### Drift Database
```dart
// Good: Define database tables with Drift
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get bio => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
}

// Good: Database setup with migrations
@DriftDatabase(tables: [Users, UserProfiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
  );

  // Good: Define queries as methods
  Future<List<User>> getAllUsers() => select(users).get();
  
  Future<User?> getUserById(int id) => 
    (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<int> insertUser(UsersCompanion user) => 
    into(users).insert(user);

  Future<bool> updateUser(User user) => 
    update(users).replace(user);

  Future<int> deleteUser(int id) => 
    (delete(users)..where((u) => u.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// Good: Repository pattern with Drift
class UserRepository {
  UserRepository(this._database);

  final AppDatabase _database;

  Future<List<User>> getUsers() => _database.getAllUsers();

  Future<User?> getUser(int id) => _database.getUserById(id);

  Future<int> createUser({
    required String name,
    required String email,
  }) {
    return _database.insertUser(
      UsersCompanion(
        name: Value(name),
        email: Value(email),
      ),
    );
  }

  Future<bool> updateUser(User user) => _database.updateUser(user);

  Future<void> deleteUser(int id) => _database.deleteUser(id);
}
```

## File Organization

### Directory Structure
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   ├── theme/
│   └── database/
│       ├── app_database.dart
│       ├── tables/
│       └── migrations/
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   └── models/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── blocs/
│   │       ├── cubits/
│   │       ├── pages/
│   │       └── widgets/
│   └── user_profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── blocs/
│           ├── cubits/
│           ├── pages/
│           └── widgets/
├── shared/
│   ├── widgets/
│   ├── services/
│   ├── blocs/
│   └── repositories/
└── l10n/
```

### File Naming & Organization
```dart
// Good: Use snake_case for file names
user_profile_screen.dart
authentication_service.dart
app_constants.dart

// Good: Group related components and keep files small
widgets/
├── buttons/
│   ├── primary_button.dart        // ~50 lines
│   ├── secondary_button.dart      // ~40 lines
│   └── icon_button.dart           // ~30 lines
├── cards/
│   ├── user_card.dart             // ~60 lines (composes smaller widgets)
│   ├── user_avatar.dart           // ~40 lines
│   ├── user_info_section.dart     // ~50 lines
│   └── product_card.dart          // ~80 lines
├── forms/
│   ├── login_form.dart            // ~120 lines (composes form fields)
│   ├── email_field.dart           // ~40 lines
│   ├── password_field.dart        // ~50 lines
│   └── submit_button.dart         // ~30 lines
├── lists/
│   ├── user_list.dart             // ~80 lines
│   ├── user_list_item.dart        // ~60 lines
│   └── empty_state.dart           // ~40 lines
└── common/
    ├── loading_indicator.dart     // ~25 lines
    ├── error_message.dart         // ~35 lines
    └── custom_divider.dart        // ~20 lines

// BAD: Large monolithic file
user_profile_page.dart             // 500+ lines ❌

// GOOD: Broken into focused components
pages/user_profile/
├── user_profile_page.dart         // ~100 lines (main page structure)
├── widgets/
│   ├── profile_header.dart        // ~80 lines
│   ├── profile_stats.dart         // ~60 lines
│   ├── profile_bio.dart           // ~40 lines
│   ├── profile_actions.dart       // ~70 lines
│   └── profile_avatar.dart        // ~50 lines
```

## Error Handling

### Async Operations
```dart
// Good: Handle errors properly with try-catch
Future<User> fetchUser(String userId) async {
  try {
    final response = await dio.get('/users/$userId');
    return User.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      throw UserNotFoundException(userId);
    }
    throw NetworkException(e.message);
  } catch (e) {
    throw UnknownException(e.toString());
  }
}

// Good: Use Result pattern for error handling
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final String error;
}

Future<Result<User>> fetchUserSafe(String userId) async {
  try {
    final user = await fetchUser(userId);
    return Success(user);
  } catch (e) {
    return Failure(e.toString());
  }
}
```

## Testing

### Widget Tests
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import '../lib/widgets/user_card.dart';
import '../lib/models/user.dart';
import '../lib/blocs/user_cubit.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('UserCard', () {
    late User testUser;

    setUp(() {
      testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      );
    });

    testWidgets('displays user information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UserCard(user: testUser),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: UserCard(
            user: testUser,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });
  });

  group('UserCubit', () {
    late MockUserRepository mockRepository;
    late UserCubit userCubit;

    setUp(() {
      mockRepository = MockUserRepository();
      userCubit = UserCubit(mockRepository);
    });

    tearDown(() {
      userCubit.close();
    });

    blocTest<UserCubit, UserState>(
      'emits [loading, loaded] when loadUser is called successfully',
      build: () {
        when(() => mockRepository.getUser(any()))
            .thenAnswer((_) async => testUser);
        return userCubit;
      },
      act: (cubit) => cubit.loadUser('1'),
      expect: () => [
        const UserState.loading(),
        UserState.loaded(testUser),
      ],
    );

    blocTest<UserCubit, UserState>(
      'emits [loading, error] when loadUser fails',
      build: () {
        when(() => mockRepository.getUser(any()))
            .thenThrow(Exception('Network error'));
        return userCubit;
      },
      act: (cubit) => cubit.loadUser('1'),
      expect: () => [
        const UserState.loading(),
        const UserState.error('Exception: Network error'),
      ],
    );
  });
}
```

### Integration Tests
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete user flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test login flow
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      
      await tester.enterText(
        find.byKey(const Key('email_field')), 
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')), 
        'password123',
      );
      
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Verify navigation to home screen
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
    });
  });
}
```

## Performance Best Practices

### Efficient Widget Building
```dart
// Good: Use const constructors
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('Hello World'),
    );
  }
}

// Good: Extract widgets to avoid rebuilds
class ExpensiveWidget extends StatelessWidget {
  const ExpensiveWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Header(),
        _Body(),
        _Footer(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Title'));
  }
}
```

### List Performance
```dart
// Good: Use ListView.builder for large lists
Widget buildUserList(List<User> users) {
  return ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, index) {
      final user = users[index];
      return UserCard(
        key: ValueKey(user.id),
        user: user,
      );
    },
  );
}

// Good: Use AutomaticKeepAliveClientMixin for expensive widgets
class ExpensiveListItem extends StatefulWidget {
  const ExpensiveListItem({super.key, required this.data});

  final ComplexData data;

  @override
  State<ExpensiveListItem> createState() => _ExpensiveListItemState();
}

class _ExpensiveListItemState extends State<ExpensiveListItem>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return ComplexWidget(data: widget.data);
  }
}
```