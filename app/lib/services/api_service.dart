import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/result.dart';
import '../models/partner_status.dart';
import '../models/user_status.dart';
import '../models/chat_message.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  String get baseUrl => _dio.options.baseUrl;

  // Helper to extract error message
  String _handleError(DioException e) {
    if (e.response != null) {
      return "Server Error: ${e.response?.statusCode} ${e.response?.data}";
    } else {
      return "Network Error: ${e.message}";
    }
  }

  // Register
  Future<Result<bool>> register(String email, String password, String nickname) async {
    try {
      await _dio.post('/users/register', data: {
        "email": email,
        "password": password,
        "nickname": nickname,
      });
      return const Success(true);
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // Login
  Future<Result<bool>> login(String email, String password) async {
    try {
      final response = await _dio.post('/users/login', data: {
        "email": email,
        "password": password,
      });

      final data = response.data;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final userId = data['userId'];

      final prefs = await SharedPreferences.getInstance();
      if (accessToken != null) await prefs.setString('accessToken', accessToken);
      if (refreshToken != null) await prefs.setString('refreshToken', refreshToken);
      if (userId != null) await prefs.setInt('userId', userId);

      return const Success(true);
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // Token Helpers
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('refreshToken');
  }

  // --- Couple & Status APIs ---

  // Get Partner Status
  Future<Result<PartnerStatus?>> getPartnerStatus() async {
    try {
      final response = await _dio.get('/couples/partner-status');
      if (response.data == null || (response.data is String && response.data.isEmpty)) {
        return const Success(null);
      }
      return Success(PartnerStatus.fromJson(response.data));
    } on DioException catch (e) {
      // 403 handling specific logic could be checked here or in the caller
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // Update My Status
  Future<Result<bool>> updateStatus(UserStatus status, {int? durationMinutes}) async {
    try {
      final body = {
        "status": status.name,
        if (durationMinutes != null) "duration": durationMinutes,
      };
      
      await _dio.post('/users/status', data: body);
      return const Success(true);
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // Create Invite Code
  Future<Result<CoupleInvite?>> createInviteCode() async {
    try {
      final response = await _dio.post('/couples/invite');
      return Success(CoupleInvite.fromJson(response.data));
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // Connect Couple
  Future<Result<bool>> connectCouple(String code) async {
    try {
      await _dio.post('/couples/connect', data: {"code": code});
      return const Success(true);
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // Disconnect Couple
  Future<Result<bool>> disconnectCouple() async {
    try {
      await _dio.post('/couples/disconnect');
      return const Success(true);
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // --- Chat APIs ---

  Future<Result<List<ChatMessage>>> getChatHistory(int partnerId, {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/chat/history', queryParameters: {
        'partnerId': partnerId,
        'page': page,
        'size': size,
      });

      final List<dynamic> content = response.data['content'];
      final list = content.map((json) => ChatMessage.fromJson(json)).toList();
      return Success(list);
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<ChatMessage?>> sendMessage(int receiverId, String content) async {
    try {
      final response = await _dio.post('/chat/send', data: {
        "receiverId": receiverId,
        "content": content,
      });
      return Success(ChatMessage.fromJson(response.data));
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // Update FCM Token
  Future<Result<bool>> updateFcmToken(String token) async {
    try {
      await _dio.post('/users/fcm-token', data: {"fcmToken": token});
      return const Success(true);
    } on DioException catch (e) {
      return Failure(_handleError(e), e);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}