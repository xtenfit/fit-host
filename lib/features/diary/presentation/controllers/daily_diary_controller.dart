import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../data/daily_diary_repository.dart';

class DiaryCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;

  void setCategory(String category) => state = category;
}

final diarySelectedCategoryProvider =
    NotifierProvider<DiaryCategoryNotifier, String>(DiaryCategoryNotifier.new);

class DiarySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;

  void setSearchQuery(String query) => state = query;
}

final diarySearchQueryProvider =
    NotifierProvider<DiarySearchQueryNotifier, String>(DiarySearchQueryNotifier.new);

final diaryEntriesStreamProvider = StreamProvider<List<DailyDiaryEntry>>((ref) {
  final repo = ref.watch(dailyDiaryRepositoryProvider);
  final category = ref.watch(diarySelectedCategoryProvider);
  final search = ref.watch(diarySearchQueryProvider);
  return repo.watchEntries(category: category, searchQuery: search);
});
