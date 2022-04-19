library zapibus;

import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';

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

abstract class zApibusRequest {
  String method = "";
  Map<String, dynamic> ToParams();
}

class zApibusAuthenticate {
  String token;
  String secret;
  zApibusAuthenticate(this.token, this.secret);
}

class zApibusResponse<T> {
  String id="";
  int code=0;
  String? sub_code="";
  String message="";
  String? sub_message="";
  T? data;
  //Map<String, dynamic>? _data;
  zApibusResponse(this.id,this.code,this.message,this.sub_code,this.sub_message);
  factory zApibusResponse.fromJson(Map<String, dynamic> json,T Function(Map<String, dynamic> d)? deserializer){
    zApibusResponse<T> response=zApibusResponse(json['id'],json['code'],json['message'],json['sub_code'],json['sub_message']);
    if(deserializer!=null){
      response.data=deserializer(json["data"]);
    }
    return response;
  }
}

class zApibus {
  String appkey, secret, url,httpMethod="POST";
  Map<String,String>? headers;
  Dio _dio=Dio(BaseOptions(
    connectTimeout: 5000,
    receiveTimeout: 3000,
  ));
  zApibus(this.appkey, this.secret, this.url,{this.httpMethod="POST",this.headers});

  Future<zApibusResponse<T>> Execute<T>(String method, Map<String, dynamic> params,
      {zApibusAuthenticate? authenticate,
      String? session,
      String? httpMethod,
      T Function(Map<String, dynamic> d)? deserializer
      }) async {
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
    String http_method=httpMethod??this.httpMethod;
    try{
      if (http_method == "GET") {
        response = await _dio.get(url, queryParameters: reqData);
      } else {
        response = await _dio.post(url, data: reqData);
      }
    }
    catch(e){
      //print(e);
      return zApibusResponse("",10,"Service Currently Unavailable","isp.apibus-unknown-error","请求zApibus时发生未知错误");

    }
    if(response.statusCode!=200){
      return zApibusResponse("",10,"Service Currently Unavailable","isp.apibus-net-error:httpcode:"+response.statusCode.toString(),"zApibus服务器错误");
    }
    JsonCodec JSON = const JsonCodec();
    try{
      zApibusResponse<T> zResponse=zApibusResponse.fromJson(JSON.decode(response.data),deserializer);
      return zResponse;
    }
    catch(e){
      return zApibusResponse("",10,"Service Currently Unavailable","isp.apibus-response-format-error","zApibus服务器响应数据格式错误");
    }
  }

  Future<zApibusResponse<T>> Request<T>(
      zApibusRequest request,
      {zApibusAuthenticate? authenticate,
      String? session,
      String? httpMethod,
      T Function(Map<String, dynamic> d)? deserializer
      }) async {
    return Execute<T>(request.method, request.ToParams(),
        authenticate: authenticate, session: session, httpMethod: httpMethod,deserializer: deserializer);
  }
}
