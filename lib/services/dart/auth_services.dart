// lib/services/auth_services.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';


class AuthServices {
  final Dio _dio;

  AuthServices()
      : _dio = Dio(BaseOptions(baseUrl: BASE_URL)) {
    _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: true,
          error: true,
          compact: true,
        ));


  }

  Future<Map<String, dynamic>> sendOtpLogin(String phone) async {
    try {
      final response = await _dio.post(
        'influencer/loginsendotp',
        data: {'phone': phone},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      print('Login Send OTP error: $e');

      if (e is DioError) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          return errorData;
        } else if (e.message != null) {
          return {
            'status': false,
            'message': e.message,
          };
        }
      }

      return {
        'status': false,
        'message': 'Login failed due to network or server error.',
      };
    }
  }


  Future<Map<String, dynamic>> influencerLogin(String phone, String otp) async {
    try {
      final response = await _dio.post(
        '/influencer/influencerlogin',
        data: {
          'phone': phone,
          'otp': otp,
        },
      );
      return response.data;
    } catch (e) {
      print('Login API error: $e');
      // You might want to throw or return a specific failure structure
      return {'status': false, 'message': 'Login failed due to network or server error'};
    }
  }

  Future<Map<String, dynamic>> signupVerify(
      String phone,
      String otp, {
        required String name,
        required String email,
        required String city,
        required String state,
      }) async {
    try {
      final response = await _dio.post(
        '/influencer/addinfluencer',
        data: {
          'phone': phone,
          'otp': otp,
          'influencerName': name,
          'email': email,
          'city': city,
          'state': state,
        },
      );
      return response.data;
    } catch (e) {
      print('Signup verification API error: $e');
      return {
        'status': false,
        'message': 'Signup failed due to network or server error'
      };
    }
  }


  Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'] as String?;
    final userId = data['userData']['_id'] as String?;
    final userData = data['userData'] as Map<String, dynamic>?;

    if (token != null) {
      await prefs.setString('token', token);
      await prefs.setString('userId', userId!);
    }
    if (userData != null) {
      await prefs.setString('userData', userData.toString()); // You can save as JSON string if you want
    }
  }




  Future<Map<String, dynamic>> sendOtpSignup(String phone) async {
    try {
      final response = await _dio.post(
        'influencer/signupsendotp',
        data: {'phone': phone},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      print('Signup Send OTP error: $e');

      if (e is DioError) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          return errorData;
        } else if (e.message != null) {
          return {
            'status': false,
            'message': e.message,
          };
        }
      }

      return {
        'status': false,
        'message': 'Signup failed due to network or server error.',
      };
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception("Token not found");

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('influencer/getprofile');

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint("Get profile error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception("Token not found");

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('admin/getallmetadata');

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Metadata fetch error: $e');
      return null;
    }
  }


  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final formData = FormData.fromMap({
        "profileimage": await MultipartFile.fromFile(imageFile.path, filename: "profile.jpg"),
      });

      final response = await _dio.post(
        'influencer/uploadimage',
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data["profileImage"]; // returns image URL
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Upload Image Error: $e");
      return null;
    }
  }


  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await _dio.post(
        'influencer/updateprofile',
        data: profileData,
        options: Options(headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        }),
      );

      return response.statusCode == 200 && response.data["status"] == true;
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      return false;
    }
  }






}
