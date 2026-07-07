import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oneclick_cars/services/draft_service.dart'; 
import 'package:oneclick_cars/services/search_service.dart';

void main() {
  group('DraftService Tests', () {
    test('Save and Get Draft', () async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      final data = {
        'title': 'Test Product',
        'price': '1000',
        'category': 'Véhicules'
      };

      await DraftService.saveDraft(data);
      
      final loaded = await DraftService.getDraft();
      
      expect(loaded, isNotNull);
      expect(loaded!['title'], 'Test Product');
      expect(loaded['price'], '1000');
    });

    test('Clear Draft', () async {
      SharedPreferences.setMockInitialValues({'product_draft': '{"title": "Old"}'});
      
      await DraftService.clearDraft();
      
      final loaded = await DraftService.getDraft();
      expect(loaded, isNull);
    });
  });

  group('SearchService Tests', () {
    test('Init does not crash without keys', () {
       // Load empty env to avoid NotInitializedError
       dotenv.testLoad(fileInput: "");
       
       SearchService.init();
       // Assert nothing throws
       expect(true, true);
    });
  });
}
