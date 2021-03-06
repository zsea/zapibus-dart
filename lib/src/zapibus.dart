import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';

String _md5(String s) {
  var content = const Utf8Encoder().convert(s);
  var md5 = crypto.md5;
  var digest = md5.convert(content);
  return digest.toString();
}

void _appendTosortByArray(
    List data, List<String> sort, String parent, String key) {
  if (data == null || data.length == 0) return;

  for (int i = 0; i < data.length; i++) {
    var value = data[i];
    if (value == null || value == "") continue;
    if (value is List) {
      _appendTosortByArray(value, sort, "$parent$key[$i]", "");
    } else if (value is Map<String, dynamic>) {
      _appendTosortByObject(value, sort, "$parent$key[$i]");
    } else {
      sort.add("$parent$key[$i]=$value");
    }
  }
}

void _appendTosortByObject(
    Map<String, dynamic> data, List<String> sort, String parent) {
  if (data == null) return;
  data.forEach((key, value) {
    if (value == null || value == "") return;
    if (value is List) {
      _appendTosortByArray(value, sort, parent, key);
    } else if (value is Map<String, dynamic>) {
      _appendTosortByObject(value, sort, parent + key + ".");
    } else {
      sort.add(parent + key + "=" + value.toString());
    }
  });
}

String _GetSignature(Map<String, dynamic> reqData, String secret) {
  List<String> s = [];
  reqData.forEach((key, value) {
    if (key == "signature" || value == null || value == "") return;
    if (key == "request") {
      if (value is Map<String, dynamic>) {
        _appendTosortByObject(value, s, "request.");
      }
      return;
    }
    s.add("$key=$value");
  });
  s.add("secret=" + secret);
  s.sort();
  var plain = s.join("&");
  var signature = _md5(plain);
  return signature;
}

abstract class zApibusRequest {
  String method = "";
  zApibusRequest(this.method);
  Map<String, dynamic> toParams();
}

class zApibusAuthenticate {
  String token;
  String secret;
  zApibusAuthenticate(this.token, this.secret);
}

class zApibusResponse<T> {
  String id = "";
  int code = 0;
  String? sub_code = "";
  String message = "";
  String? sub_message = "";
  T? data;
  dynamic origin;
  zApibusResponse(
      this.id, this.code, this.message, this.sub_code, this.sub_message);
  factory zApibusResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic d)? deserializer) {
    zApibusResponse<T> response = zApibusResponse(json['id'], json['code'],
        json['message'], json['sub_code'], json['sub_message']);
    if (deserializer != null && json["data"] != null) {
      response.data = deserializer(json["data"]);
    }
    response.origin = json["data"];
    return response;
  }
}

class zApibusRequestResponse<T> {
  Map<String, dynamic> request;
  zApibusResponse<T> response;
  String httpMethod;
  Map<String, dynamic> reqHeader;
  String url;
  int httpStatusCode;
  String? httpResponseBody;
  Object? error;
  StackTrace? stack;
  zApibusRequestResponse(
      {required this.request,
      required this.response,
      required this.httpMethod,
      required this.reqHeader,
      required this.url,
      required this.httpStatusCode,
      this.httpResponseBody,
      this.error,
      this.stack});
}

class zApibus {
  String appkey, secret, url, httpMethod = "POST";
  Map<String, String>? headers;
  Future Function(zApibusRequestResponse response)? onResponse;
  Future<Map<String, String>> Function(Map<String, dynamic> reqData)? onHeaders;
  final Dio _dio = Dio();
  zApibus(this.appkey, this.secret, this.url,
      {this.httpMethod = "POST",
      this.headers,
      int connectTimeout = 5000,
      int receiveTimeout = 3000,
      this.onResponse,
      this.onHeaders}) {
    _dio.options.connectTimeout = connectTimeout;
    _dio.options.receiveTimeout = receiveTimeout;
  }
  Future<zApibusResponse<T>> execute<T>(
      String method, Map<String, dynamic>? params,
      {zApibusAuthenticate? authenticate,
      String? session,
      String? httpMethod,
      T Function(dynamic d)? deserializer,
      Map<String, dynamic>? headers,
      int? connectTimeout,
      int? receiveTimeout}) async {
    zApibusRequestResponse<T> response = await _execute<T>(method, params,
        authenticate: authenticate,
        session: session,
        httpMethod: httpMethod,
        deserializer: deserializer,
        headers: headers,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout);
    if (onResponse != null) {
      await onResponse!(response);
    }
    return response.response;
  }

  Future<zApibusRequestResponse<T>> _execute<T>(
      String method, Map<String, dynamic>? params,
      {zApibusAuthenticate? authenticate,
      String? session,
      String? httpMethod,
      T Function(dynamic d)? deserializer,
      Map<String, dynamic>? headers,
      int? connectTimeout,
      int? receiveTimeout}) async {
    //options.noSuchMethod(invocation)
    Map<String, dynamic> reqData = {
      'appkey': appkey,
      'time': DateTime.now().microsecondsSinceEpoch ~/ (1000 * 1000),
      'method': method,
      'request': params,
      'session': session,
      'token': authenticate?.token
    };
    String signature = _GetSignature(
        reqData, authenticate == null ? secret : authenticate.secret);
    reqData.addAll({"signature": signature});
    Response<dynamic> response;
    String http_method = httpMethod ?? this.httpMethod;
    Map<String, dynamic> __headers = {};
    if (this.headers != null) {
      __headers.addAll(this.headers!);
    }
    if (headers != null) {
      __headers.addAll(headers);
    }
    if (onHeaders != null) {
      var _xHeaders = await onHeaders!(reqData);
      __headers.addAll(_xHeaders);
    }
    try {
      if (http_method == "GET") {
        response = await _dio.get(
          url,
          queryParameters: {
            "body": reqData,
            "_": DateTime.now().microsecondsSinceEpoch
          },
          options: Options(
            headers: __headers,
          ),
        );
      } else {
        response = await _dio.post(
          url,
          data: reqData,
          options: Options(
            headers: __headers,
          ),
        );
      }
    } catch (e, stack) {
      return zApibusRequestResponse(
          request: reqData,
          response: zApibusResponse("", 10, "Service Currently Unavailable",
              "isp.apibus-unknown-error", "??????zApibus?????????????????????"),
          httpMethod: http_method,
          reqHeader: __headers,
          url: url,
          httpStatusCode: 0,
          error: e,
          stack: stack);
    }
    if (response.statusCode != 200) {
      return zApibusRequestResponse(
          request: reqData,
          response: zApibusResponse(
              "",
              10,
              "Service Currently Unavailable",
              "isp.apibus-net-error:httpcode:" + response.statusCode.toString(),
              "zApibus???????????????"),
          httpMethod: http_method,
          reqHeader: __headers,
          url: url,
          httpStatusCode: response.statusCode ?? 0,
          httpResponseBody: response.data);
    }
    //print(response.data.runtimeType);
    JsonCodec JSON = const JsonCodec();
    try {
      zApibusResponse<T> zResponse =
          zApibusResponse.fromJson(JSON.decode(response.data), deserializer);

      return zApibusRequestResponse(
        request: reqData,
        response: zResponse,
        httpMethod: http_method,
        reqHeader: __headers,
        url: url,
        httpStatusCode: response.statusCode ?? 0,
        httpResponseBody: response.data,
      );
    } catch (e, stack) {
      return zApibusRequestResponse(
          request: reqData,
          response: zApibusResponse("", 10, "Service Currently Unavailable",
              "isp.apibus-response-format-error", "zApibus?????????????????????????????????"),
          httpMethod: http_method,
          reqHeader: __headers,
          url: url,
          httpStatusCode: 0,
          httpResponseBody: response.data,
          error: e,
          stack: stack);
    }
  }

  Future<zApibusResponse<T>> request<T>(zApibusRequest request,
      {zApibusAuthenticate? authenticate,
      String? session,
      String? httpMethod,
      T Function(dynamic d)? deserializer,
      Map<String, dynamic>? headers,
      int? connectTimeout,
      int? receiveTimeout}) async {
    return execute<T>(request.method, request.toParams(),
        authenticate: authenticate,
        session: session,
        httpMethod: httpMethod,
        deserializer: deserializer,
        headers: headers,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout);
  }
}
