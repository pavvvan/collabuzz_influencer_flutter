import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'constants.dart';


class SocialMediaService {
  final Dio _dio;

  SocialMediaService()
      : _dio = Dio(BaseOptions(baseUrl: BASE_URL)) {
    _dio.interceptors.add(PrettyDioLogger(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
  }

  Future<bool> updateSocialProfile({
    required String platform,
    required String handle,
    String? url,
    int? followers,
    double? engagementRate,
    int? avgLikes,
    int? avgViews,
    String? contentType,
    int? pricePerPost,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("No token found");

      final data = {
        "platform": platform,
        "handle": handle,
        if (url != null && url.isNotEmpty) "url": url,
        if (followers != null) "followers": followers,
        if (engagementRate != null) "engagementRate": engagementRate,
        if (avgLikes != null) "avgLikes": avgLikes,
        if (avgViews != null) "avgViews": avgViews,
        if (contentType != null && contentType.isNotEmpty) "contentType": contentType,
        if (pricePerPost != null) "pricePerPost": pricePerPost,
      };

      final response = await _dio.post(
        '/influencer/updateSocialProfile',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return true;
      } else {
        debugPrint("API error: ${response.data['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("Error in updateSocialProfile: $e");
      return false;
    }
  }
}
