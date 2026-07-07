import 'package:flutter_test/flutter_test.dart';
import 'package:oneclick_cars/views/write_review_screen.dart';
import 'package:oneclick_cars/views/admin_panel_screen.dart';
import 'package:oneclick_cars/views/public_profile_screen.dart';
import 'package:oneclick_cars/services/recommendation_service.dart';
import 'package:oneclick_cars/views/price_estimation_screen.dart';

void main() {
  test('Imports work and classes are defined', () {
    expect(WriteReviewScreen, isNotNull);
    expect(AdminPanelScreen, isNotNull);
    expect(PublicProfileScreen, isNotNull);
    expect(RecommendationService, isNotNull);
    expect(PriceEstimationScreen, isNotNull);
  });
}
