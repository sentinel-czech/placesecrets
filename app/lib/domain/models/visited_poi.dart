import 'package:freezed_annotation/freezed_annotation.dart';

part 'visited_poi.freezed.dart';

@freezed
class VisitedPoiModel with _$VisitedPoiModel {
  const factory VisitedPoiModel({
    required int localId,
    required String poiId,
    required String cityId,
    required String poiName,
    required double latitude,
    required double longitude,
    required DateTime visitedAt,
    String? userNote,
    String? userPhotoPath,
    @Default(false) bool isSynced,
    @Default(false) bool exportedToPdf,
  }) = _VisitedPoiModel;
}
