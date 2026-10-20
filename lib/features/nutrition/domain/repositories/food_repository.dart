import '../models/food_item.dart';

abstract class FoodRepository {
  Future<List<FoodItem>> searchFoods(String query, {int limit = 30});
  Future<FoodItem?> getFoodByBarcode(String barcode);
  Future<void> saveFood(FoodItem food);
  Future<List<FoodItem>> getRecentFoods({int limit = 8});
}
