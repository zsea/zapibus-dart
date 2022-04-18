library zapibus;

import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';

//import 'dart:convert';
//import 'package:convert/convert.dart';
//import 'package:crypto/crypto.dart';
/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

String _md5(String s) {
  var content = new Utf8Encoder().convert(s);
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

abstract class IzApibusRequest {
  String method = "";
  Map<String, dynamic> ToParams();
}

class zApibusAuthenticate {
  String token;
  String secret;
  zApibusAuthenticate(this.token, this.secret);
}

class zApibusResponse {}

class zApibus {
  String appkey, secret, url;
  zApibus(this.appkey, this.secret, this.url);

  Future<zApibusResponse> Execute(String method, Map<String, dynamic> params,
      {zApibusAuthenticate? authenticate,
      String? session,
      String httpMethod = "POST"}) async {
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
    //reqData.addAll({})
    var dio = Dio();
    //print(jsonEncode(reqData));
    //dio.request(path)
    Response<dynamic> response;
    if (httpMethod == "GET") {
      response = await dio.get(url, queryParameters: reqData);
    } else {
      response = await dio.post(url, data: reqData);
    }
    print(response.data);
    //print("请求完成");
    return zApibusResponse();
  }

  Future<zApibusResponse> Request(IzApibusRequest request,
      {zApibusAuthenticate? authenticate,
      String? session,
      String httpMethod = "POST"}) async {
    return this.Execute(request.method, request.ToParams(),
        authenticate: authenticate, session: session, httpMethod: httpMethod);
  }
}
