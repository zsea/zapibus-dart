import 'package:zapibus/src/zapibus.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';

String _md5(String s) {
  var content = new Utf8Encoder().convert(s);
  var md5 = crypto.md5;
  var digest = md5.convert(content);
  return digest.toString();
}

class Token {
  String? token;
  String? secret;
}

class LoginResponse {
  Token? token;
  Token? refresh;
}

LoginResponse Deserializer(Map<String, dynamic> json) {
  LoginResponse response = LoginResponse();
  response.token = Token();
  response.token!.token = json["token"]["token"];
  response.token!.secret = json["token"]["secret"];
  response.refresh = Token();
  response.refresh!.token = json["refresh"]["token"];
  response.refresh!.secret = json["refresh"]["secret"];
  return response;
}

class LoginRequest extends zApibusRequest {
  String username, password, domain;
  LoginRequest(this.username, this.password, this.domain)
      : super("zsea.admin.login");
  @override
  Map<String, dynamic> toParams() {
    var timestamp = DateTime.now().microsecondsSinceEpoch ~/ 1000;
    return {
      "username": "admin",
      "timestamp": timestamp,
      "domain": "",
      "password": _md5(_md5("admin#admin") + "#" + timestamp.toString())
    };
  }
}

class MessageListResponse {
  static MessageListResponse deserializer(dynamic json) {
    MessageListResponse response = MessageListResponse();
    //response.count=json["count"];
    List<dynamic> _json = json;
    print("打印数据");
    print(_json.length);
    return response;
  }
}

void main() async {
  // test('adds one to input values', () {
  //   final calculator = Calculator();
  //   expect(calculator.addOne(2), 3);
  //   expect(calculator.addOne(-7), -6);
  //   expect(calculator.addOne(0), 1);
  // });
  var timestamp = DateTime.now().microsecondsSinceEpoch ~/ 1000;
  print("时间：$timestamp");
  Map<String, dynamic> login = {
    "username": "admin",
    "timestamp": timestamp,
    "domain": "expert.zsea.app",
    "password": _md5(_md5("admin#admin") + "#" + timestamp.toString())
  };
  zApibus bus = new zApibus("1", "hmJ1Y7tyi7cM", "http://127.0.0.1:8080/api",
      headers: {"x-token": "aaaa"});
  bus.onResponse = (response) async {
    print(response.httpResponseBody);
    //print(response.response.message);
  };
  //bus.url="";
  // zApibusResponse<LoginResponse> response = await bus.Execute<LoginResponse>(
  //     "zsea.admin.login", login,
  //     deserializer: Deserializer);
  zApibusResponse<MessageListResponse> response =
      await bus.execute<MessageListResponse>(
          "charge.user.messages.get", {"laster": 999999},
          deserializer: MessageListResponse.deserializer,
          session: "JSt7C6hmnGyM4iNArSn6JkktHBRMd96a");
  print(response);
}
