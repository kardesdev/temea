import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:temea/db/db.dart';
import 'package:temea/providers/isar/isar.dart';
import 'package:temea/providers/uuid/uuid.dart';
import 'package:temea/utils/constants.dart';
import 'package:temea/models/models.dart';

class CategoryNotifier extends AsyncNotifier<List<Category>>
    implements CategoryRepo {
  @override
  Future<List<Category>> build() {
    return getCategories();
  }

  @override
  Future<List<Category>> getCategories() async {
    final isar = ref.watch(isarProvider).value;
    final categories = await isar?.category.where().findAll() ?? [];
    return categories
        .map((cat) => Category(
              id: cat.id,
              name: cat.name,
              color: cat.color,
              createdAt: cat.createdAt,
            ))
        .toList();
  }

  @override
  Future<void> saveCategory(String name, CategoryColor color) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final isar = ref.watch(isarProvider).value;
      final uuid = ref.watch(uuidProvider);
      final cat = Category(
        id: uuid.v4(),
        name: name,
        color: color,
        createdAt: DateTime.now(),
      );
      await isar?.writeTxn(() async {
        await isar.category.put(CategoryDb()
          ..id = cat.id
          ..name = cat.name
          ..color = cat.color
          ..createdAt = cat.createdAt);
      });
      return getCategories();
    });
  }

  // TODO: handle side effects (delete all activities?, show popup?)
  @override
  Future<void> deleteCategory(String uuid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final isar = ref.watch(isarProvider).value;
      await isar?.writeTxn(() async {
        await isar.category.filter().idEqualTo(uuid).deleteAll();
      });
      return getCategories();
    });
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
  () => CategoryNotifier(),
);
