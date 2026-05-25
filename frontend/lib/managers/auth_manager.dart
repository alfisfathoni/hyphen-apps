import 'package:flutter/foundation.dart';
import 'package:hyphen/services/api_client.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class AuthManager extends ChangeNotifier {
  // Singleton pattern
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  bool _isLoggedIn = false;
  String _userId = '';
  String _userName = 'Guest';
  String _email = '';
  String _fullName = '';
  String _phone = '';
  String _dob = '';
  String _location = '';
  String _photoUrl = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get userName => _userName;
  String get email => _email;
  String get fullName => _fullName.isEmpty ? _userName : _fullName;
  String get phone => _phone;
  String get dob => _dob;
  String get location => _location;
  String get photoUrl => _photoUrl;

  Future<bool> checkAuthStatus() async {
    final token = await ApiClient().secureStorage.read(key: 'accessToken');
    if (token != null) {
      _isLoggedIn = true;
      await fetchProfile();
      return true;
    }
    return false;
  }

  Future<void> fetchProfile() async {
    if (!_isLoggedIn) return;
    try {
      final response = await ApiClient().dio.get('/user/profile');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        _userId = data['id']?.toString() ?? '';
        _userName = data['username'] ?? '';
        _email = data['email'] ?? '';
        _fullName = data['fullname'] ?? '';
        _phone = data['phone'] ?? '';
        _dob = data['dateOfBirth'] ?? '';
        _location = data['location'] ?? '';
        _photoUrl = data['photoUrl'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      print('Fetch profile error: $e');
    }
  }

  Future<bool> updateProfile({
    required String fullNameVal,
    required String phoneVal,
    required String dobVal,
    required String locationVal,
    required String usernameVal,
    required String emailVal,
  }) async {
    try {
      // First check if profile exists (hasProfile)
      final profileCheckResponse = await ApiClient().dio.get('/user/profile');
      final bool hasProfile = profileCheckResponse.data['data']['hasProfile'] == 1 || 
                             profileCheckResponse.data['data']['hasProfile'] == true;

      // If profile does not exist, we must create it first via POST /user/create
      if (!hasProfile) {
        await ApiClient().dio.post('/user/create', data: {
          'fullname': fullNameVal,
          'phone': phoneVal,
          'dateOfBirth': dobVal,
          'location': locationVal,
        });
      }

      // Then update it via PUT /user/update (which updates both user and profile table fields)
      final response = await ApiClient().dio.put('/user/update', data: {
        'fullname': fullNameVal,
        'phone': phoneVal,
        'dateOfBirth': dobVal,
        'location': locationVal,
        'username': usernameVal,
        'email': emailVal,
      });

      if (response.statusCode == 200) {
        _fullName = fullNameVal;
        _phone = phoneVal;
        _dob = dobVal;
        _location = locationVal;
        _userName = usernameVal;
        _email = emailVal;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      print('Update profile error: ${e.response?.data}');
    } catch (e) {
      print('Unexpected error: $e');
    }
    return false;
  }

  Future<bool> uploadProfilePhoto(String localFilePath) async {
    try {
      MultipartFile multipartFile;
      if (localFilePath.startsWith('assets/')) {
        final byteData = await rootBundle.load(localFilePath);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${localFilePath.split('/').last}');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        multipartFile = await MultipartFile.fromFile(
          tempFile.path,
          filename: 'profile_photo.jpg',
        );
      } else {
        multipartFile = await MultipartFile.fromFile(
          localFilePath,
          filename: 'profile_photo.jpg',
        );
      }

      final formData = FormData.fromMap({
        'photo': multipartFile,
      });

      final response = await ApiClient().dio.put(
        '/user/profile/photo',
        data: formData,
      );

      if (response.statusCode == 200) {
        _photoUrl = response.data['data']['photoUrl'] ?? '';
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      print('Upload photo error: ${e.response?.data}');
    } catch (e) {
      print('Unexpected error: $e');
    }
    return false;
  }

  Future<bool> login(String emailInput, String password) async {
    try {
      final response = await ApiClient().dio.post('/auth/login', data: {
        'email': emailInput,
        'password': password,
      });

      if (response.statusCode == 200) {
        _isLoggedIn = true;
        _email = response.data['data']['email'];
        _userName = response.data['data']['username'];
        
        final accessToken = response.data['accessToken'];
        if (accessToken != null) {
          await ApiClient().saveToken(accessToken);
        }
        
        await fetchProfile();
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      print('Login error: ${e.response?.data}');
    } catch (e) {
      print('Unexpected error: $e');
    }
    return false;
  }

  Future<String?> register(String nameInput, String emailInput, String password) async {
    try {
      final response = await ApiClient().dio.post('/auth/register', data: {
        'username': nameInput,
        'email': emailInput,
        'password': password,
      });

      if (response.statusCode == 201) {
        // Registration successful, but user needs to verify OTP.
        return null; // Return null to indicate no errors
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response!.data['message']?.toString() ?? 'Pendaftaran gagal';
      }
      return 'Gagal terhubung ke server';
    } catch (e) {
      return 'Terjadi kesalahan tidak terduga';
    }
    return 'Gagal mendaftar';
  }

  Future<String?> verifyEmail(String emailInput, String otp) async {
    try {
      final response = await ApiClient().dio.post('/auth/verify-email', data: {
        'email': emailInput,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        return null; // Success
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response!.data['message']?.toString() ?? 'Verifikasi gagal';
      }
      return 'Gagal terhubung ke server';
    } catch (e) {
      return 'Terjadi kesalahan tidak terduga';
    }
    return 'Verifikasi gagal';
  }

  Future<String?> resendOTP(String emailInput) async {
    try {
      final response = await ApiClient().dio.post('/auth/resend-otp', data: {
        'email': emailInput,
      });

      if (response.statusCode == 200) {
        return null; // Success
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response!.data['message']?.toString() ?? 'Gagal mengirim ulang OTP';
      }
      return 'Gagal terhubung ke server';
    } catch (e) {
      return 'Terjadi kesalahan tidak terduga';
    }
    return 'Gagal mengirim ulang OTP';
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = '';
    _userName = 'Guest';
    _email = '';
    _fullName = '';
    _phone = '';
    _dob = '';
    _location = '';
    _photoUrl = '';
    await ApiClient().clearToken();
    notifyListeners();
  }
}
