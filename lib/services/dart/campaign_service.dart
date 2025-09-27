import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class CampaignService {
  final Dio _dio;

  CampaignService()
      : _dio = Dio(BaseOptions(baseUrl: BASE_URL)) {
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
    ));
  }

  Future<List<dynamic>> getCampaigns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("No token found");
      }

      final response = await _dio.get(
        '/influencer/filter',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        // ✅ FIX: use 'Campaigns' with capital C
        return response.data['Campaigns'] ?? [];
      } else {
        throw Exception('Failed to fetch campaigns: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching campaigns: $e');
      return [];
    }
  }

  /// 🔹 Get awarded campaigns
  Future<List<dynamic>> getAwardedCampaigns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception("No token found");

      final response = await _dio.get(
        '/influencer/getAwardedCampaigns',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['Campaigns'] != null) {
        return response.data['Campaigns'];
      } else {
        throw Exception('Failed to fetch awarded campaigns');
      }
    } catch (e) {
      debugPrint('Error fetching awarded campaigns: $e');
      return [];
    }
  }

  Future<List<dynamic>> searchCampaigns(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("No token found");
      }

      final response = await _dio.get(
        '/influencer/search',
        queryParameters: {'searchTxt': query},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['Campaigns'] ?? [];
      } else {
        throw Exception('Failed to fetch campaigns: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching campaigns: $e');
      return [];
    }
  }

  Future<List<dynamic>> filterCampaigns({
    String? influencerCategory,
    String? influencerType,
    String? campaignType,
    String? platform,
    String? targetAudience,
    String? campaignStatus,
    String? contentType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("No token found");
      }

      // Build only non-empty parameters
      final Map<String, dynamic> queryParams = {};
      if (influencerCategory?.isNotEmpty == true) {
        queryParams['influencerCategory'] = influencerCategory;
      }
      if (influencerType?.isNotEmpty == true) {
        queryParams['influencerType'] = influencerType;
      }
      if (campaignType?.isNotEmpty == true) {
        queryParams['campaignType'] = campaignType;
      }
      if (platform?.isNotEmpty == true) {
        queryParams['platform'] = platform;
      }
      if (targetAudience?.isNotEmpty == true) {
        queryParams['targetAudience'] = targetAudience;
      }
      if (campaignStatus?.isNotEmpty == true) {
        queryParams['campaignStatus'] = campaignStatus;
      }
      if (contentType?.isNotEmpty == true) {
        queryParams['contentType'] = contentType;
      }

      final response = await _dio.get(
        '/influencer/filter',
        queryParameters: queryParams,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['Campaigns'] ?? [];
      } else {
        throw Exception('Failed to fetch campaigns: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching campaigns: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCampaignsByIds(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await _dio.get(
        '/influencer/getCampaignsByIds?ids=${ids.join(",")}',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['Campaigns'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching campaigns by ID: $e");
      return [];
    }
  }


  Future<Map<String, dynamic>> sendCampaignRequest(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await _dio.post(
      '/influencer/requestCampaign',
      data: payload,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.data; // return full response for success/failure check





  }

   Future<String?> openChat({
    required String campaignId,
    required String influencerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token!');

    try {
      final response = await _dio.post(
        'chat/open',
        data: jsonEncode({
          'campaignId': campaignId,
          'influencerId': influencerId,
        }),
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': Headers.jsonContentType,
        }),
      );

      if (response.data['success'] == true && response.data['chat'] != null) {
        return response.data['chat']['_id'];
      }
      return null;
    } catch (e) {
      print('Error opening chat: $e');
      return null;
    }
  }

   Future<List<Map<String, dynamic>>> getChatMessages({
    required String chatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token!');

    try {
      final response = await _dio.get(
        'chat/messages',
        queryParameters: {'chatId': chatId},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['messages'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching chat messages: $e');
      return [];
    }
  }

  uploadProof({required campaignId, required String influencerId, required String milestoneKey, required File file}) {}

  acknowledgeBrief({required campaignId, required String influencerId, required String milestoneKey}) {}





  // ✅ Contract Action (accept/reject)
  Future<Map<String, dynamic>> contractAction({
    required String campaignId,
    required String action,
  }) async
  {

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await _dio.post(
        "/influencer/contract-action", // 👈 match your Node API route
        data: {
          "campaignId": campaignId,
          "action": action, // "accept" or "reject"
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return {
          "status": false,
          "message": response.data?['message'] ?? "Something went wrong"
        };
      }
    } catch (e) {
      return {
        "status": false,
        "message": "Error while performing contract action: $e"
      };
    }
  }

  Future<Map<String, dynamic>> milestoneAction({
    required String campaignId,
    required String milestoneKey,
    required String action, // "accept" or "reject"
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await _dio.post(
        "/influencer/milestone-action",
        data: {
          "campaignId": campaignId,
          "milestoneKey": milestoneKey,
          "action": action,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data;
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }


  Future<Map<String, dynamic>> uploadDraft({
    required String campaignId,
    required String milestoneKey,
    required String description,
    required String link,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final resp = await _dio.post(
        "/influencer/upload-draft",
        data: {
          "campaignId": campaignId,
          "milestoneKey": milestoneKey, // keep dynamic in case you reuse
          "url": link,          // ✅ correct key for backend
          "notes": description, // ✅ correct key for backend
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return resp.data;
    } catch (e) {
      debugPrint("Upload Draft Error: $e");
      rethrow;
    }
  }


  Future<Map<String, dynamic>> uploadPostLive({
    required String campaignId,
    required String milestoneKey,
    required String link,
    String? description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final resp = await _dio.post(
        "/influencer/upload-post-live",
        data: {
          "campaignId": campaignId,
          "milestoneKey": milestoneKey,
          "url": link,
          "notes": description ?? "",
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return resp.data;
    } catch (e) {
      debugPrint("Upload Post Live Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitAnalytics({
    required String campaignId,
    required String milestoneKey,
    required int impressions,
    required int reach,
    required int engagements,
    int clicks = 0,
    double ctr = 0,
    double er = 0,
    required String postLink,   // ✅ make required
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final resp = await _dio.post(
      "/influencer/submit-analytics",
      data: {
        "campaignId": campaignId,
        "milestoneKey": milestoneKey,
        "impressions": impressions,
        "reach": reach,
        "engagements": engagements,
        "clicks": clicks,
        "ctr": ctr,
        "er": er,
        "postLink": postLink,   // ✅ send key matching API
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
    return resp.data;
  }












}
