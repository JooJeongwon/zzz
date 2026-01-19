import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/partner_status.dart';
import '../models/user_status.dart';
import '../models/chat_message.dart';

class ApiService {
  // Android Emulator: 10.0.2.2, iOS Simulator/Web: localhost
  static String get baseUrl {
    // 1. Check .env first
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // 2. Fallback to smart defaults
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api/v1';
    return 'http://Joo-MacBookAir.local:8080/api/v1';
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // Register
  static Future<bool> register(String email, String password, String nickname) async {
    try {
      final url = Uri.parse('$baseUrl/users/register');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "nickname": nickname,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Register Error: $e");
      return false;
    }
  }

  // Login
  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/users/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final userId = data['userId'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        if (refreshToken != null) {
          await prefs.setString('refreshToken', refreshToken);
        }
        if (userId != null) {
          await prefs.setInt('userId', userId);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    }
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
  }

  // --- Couple & Status APIs ---

  // Get Partner Status
  // Returns PartnerStatus object if successful, null if error (or not couple)
  static Future<PartnerStatus?> getPartnerStatus() async {
    try {
      final url = Uri.parse('$baseUrl/couples/partner-status');
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return PartnerStatus.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else if (response.statusCode == 403) {
        throw HttpException('403 Forbidden');
      } else {
        debugPrint("GetPartnerStatus Failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      if (e.toString().contains('403 Forbidden')) rethrow;
      debugPrint("GetPartnerStatus Error: $e");
      return null;
    }
  }

  // Update My Status
  static Future<bool> updateStatus(UserStatus status, {int? durationMinutes}) async {
    try {
      final url = Uri.parse('$baseUrl/users/status');
      final headers = await _getAuthHeaders();
      final body = {
        "status": status.name,
        if (durationMinutes != null) "duration": durationMinutes,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("UpdateStatus Error: $e");
      return false;
    }
  }

  // Create Invite Code
  static Future<CoupleInvite?> createInviteCode() async {
    try {
      final url = Uri.parse('$baseUrl/couples/invite');
      final headers = await _getAuthHeaders();
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return CoupleInvite.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("CreateInviteCode Error: $e");
      return null;
    }
  }

  // Connect Couple
  static Future<bool> connectCouple(String code) async {
    try {
      final url = Uri.parse('$baseUrl/couples/connect');
      final headers = await _getAuthHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"code": code}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("ConnectCouple Error: $e");
      return false;
    }
  }

  // --- Chat APIs ---

  static Future<List<ChatMessage>> getChatHistory(int partnerId, {int page = 0, int size = 20}) async {
    try {
      final url = Uri.parse('$baseUrl/chat/history?partnerId=$partnerId&page=$page&size=$size');
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // Spring Page object structure: { content: [], pageable: ... }
        final List<dynamic> content = data['content'];
        return content.map((json) => ChatMessage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("GetChatHistory Error: $e");
      return [];
    }
  }

  static Future<ChatMessage?> sendMessage(int receiverId, String content) async {
    try {
      final url = Uri.parse('$baseUrl/chat/send');
      final headers = await _getAuthHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "receiverId": receiverId,
          "content": content,
        }),
      );

      if (response.statusCode == 200) {
        return ChatMessage.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      debugPrint("SendMessage Error: $e");
      return null;
    }
  }

  // Update FCM Token
  static Future<bool> updateFcmToken(String token) async {
    try {
      final url = Uri.parse('$baseUrl/users/fcm-token');
      final headers = await _getAuthHeaders();
      final body = {
        "fcmToken": token,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("UpdateFcmToken Error: $e");
      return false;
    }
  }
}
