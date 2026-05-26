import 'package:flutter/material.dart';
import 'package:hyphen/models/city.dart';
import 'package:hyphen/services/api_client.dart';
import 'package:hyphen/data/indonesian_cities.dart';
import 'package:dio/dio.dart' as dio;

class ShippingManager extends ChangeNotifier {
  static final ShippingManager _instance = ShippingManager._internal();
  factory ShippingManager() => _instance;
  ShippingManager._internal();

  final Map<String, List<Map<String, dynamic>>> _shippingCache = {};
  final Map<String, DateTime> _shippingCacheTime = {};

  /// Fetches cities matching the query — tries RajaOngkir API first,
  /// falls back to local bundled data if the API is unavailable.
  Future<List<City>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await ApiClient().dio.get(
        '/shipping/cities',
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        if (data.isNotEmpty) {
          return data.map((json) => City.fromJson(json)).toList();
        }
      }
      // If API returned empty or non-200, fall back to local
      return searchLocalCities(query);
    } on dio.DioException catch (e) {
      debugPrint('City API unavailable (${e.message}), using local data');
      return searchLocalCities(query);
    } catch (e) {
      debugPrint('City search error: $e, using local data');
      return searchLocalCities(query);
    }
  }

  /// Fetches shipping costs from RajaOngkir with caching support
  Future<List<Map<String, dynamic>>> calculateShipping({
    required String originCityId,
    required String destinationCityId,
    required int weightGram,
    String? courier,
    bool force = false,
  }) async {
    final cacheKey = '${originCityId}_${destinationCityId}_${weightGram}_${courier ?? "all"}';

    if (!force && _shippingCache.containsKey(cacheKey) && _shippingCacheTime.containsKey(cacheKey)) {
      final cacheTime = _shippingCacheTime[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < const Duration(seconds: 30)) {
        debugPrint(' Using cached shipping costs for key: $cacheKey');
        return _shippingCache[cacheKey]!;
      }
    }

    try {
      final response = await ApiClient().dio.post(
        '/shipping/cost',
        data: {
          'originCityId': originCityId,
          'destinationCityId': destinationCityId,
          'weightGram': weightGram,
          if (courier != null) 'courier': courier,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final list = data.cast<Map<String, dynamic>>();

        // Store in cache
        _shippingCache[cacheKey] = list;
        _shippingCacheTime[cacheKey] = DateTime.now();

        return list;
      }
      return [];
    } on dio.DioException catch (e) {
      debugPrint('Error calculating shipping: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Error calculating shipping: $e');
      return [];
    }
  }
}
