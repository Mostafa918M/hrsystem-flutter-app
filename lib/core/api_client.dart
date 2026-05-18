import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  // static final String baseUrl = "https://api-hr.fairdirection.com/api/v1/";
  static final String baseUrl = "http://192.168.1.15:3000/api/v1/";
  final Dio dio = Dio(BaseOptions(baseUrl: baseUrl));
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final Logger logger = Logger();

  ApiClient._internal() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          logger.d("Token found and added to headers");
        } else {
          logger.w("No token found in storage!");
        }
        options.headers['x-tenant-slug'] = 'fairdirection';
        logger.i("REQUEST[${options.method}] => ${options.baseUrl}${options.path}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        logger.i("RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}");
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        logger.e("ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}\nMESSAGE: ${e.message}\nDATA: ${e.response?.data}");
        return handler.next(e);
      },
    ));
  }
}
