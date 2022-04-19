import 'package:flutter_test/flutter_test.dart';

import 'package:zapibus/zapibus.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';
String _md5(String s) {
  var content = new Utf8Encoder().convert(s);
  var md5 = crypto.md5;
  var digest = md5.convert(content);
  return digest.toString();
}
class Token{
  String? token;
  String? secret;
}
class LoginResponse{
  Token? token;
  Token? refresh;
}
LoginResponse Deserializer(Map<String, dynamic> json){
  LoginResponse response=LoginResponse();
  response.token=Token();
  response.token!.token=json["token"]["token"];
  response.token!.secret=json["token"]["secret"];
  response.refresh=Token();
  response.refresh!.token=json["refresh"]["token"];
  response.refresh!.secret=json["refresh"]["secret"];
  return response;
}
void main() async {
  // test('adds one to input values', () {
  //   final calculator = Calculator();
  //   expect(calculator.addOne(2), 3);
  //   expect(calculator.addOne(-7), -6);
  //   expect(calculator.addOne(0), 1);
  // });
  var timestamp=DateTime.now().microsecondsSinceEpoch~/1000;
  print("时间：$timestamp");
  Map<String,dynamic> login={
"username":"admin",
"timestamp":timestamp,
"domain":"expert.zsea.app",
"password":_md5(_md5("admin#admin")+"#"+timestamp.toString())
  };
  zApibus bus =
      new zApibus("1", "hmJ1Y7tyi7cM", "https://expert.zsea.app:8443/api");
  //bus.url="";
  zApibusResponse<LoginResponse> response=await bus.Execute<LoginResponse>("zsea.admin.login", login,deserializer: Deserializer);
  if(response.code==0){
    print("登录成功 Token="+response.data!.token!.token!);
    //print(response.data!.token!.token);
  }
  else{
    print("登录失败："+response.message);
  }
}
