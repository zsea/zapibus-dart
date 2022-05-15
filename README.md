# 介绍
此包是```zApibus```的Dart语言的客户端SDK。

# 使用
```dart
zApibus bus=zApibus(String appkey, String secret, String url,
      {String httpMethod = "POST",
      Map<String,dynamic> headers,
      int connectTimeout = 5000,
      int receiveTimeout = 3000});
```

## 参数说明
* appkey - 调用的授权appkey，即调用者身份
* secret - 调用的安全字符串
* url - zApibus服务器的地址
* httpMethod - 请求的方法，默认为：POST
* headers - 请求时添加的自定义http header
* connectTimeout - 连接服务器超时时间，单位是毫秒。
* receiveTimeout - 接收数据的最长时限，单位是毫秒。
* onResponse - 响应拦截函数，函数签名为：```Future Function(zApibusResponse response)?```

> 增加```onResponse```的目的是为了拦截请求结果，判断用户是否是未登录，未登录时可统一跳转到登录页面。

## 调用方法

```dart
zApibusResponse<LoginResponse> response = await bus.execute<LoginResponse>(
      "zsea.admin.login", login,
      deserializer: Deserializer);
```
或者
```dart
  zApibusResponse<LoginResponse> response = await bus.request<LoginResponse>(
      LoginRequest("admin", "admin", "127.0.0.1"),
      deserializer: Deserializer);
```

execute方法通过api名称与```Map<String, dynamic>?```传递参数。
request方法通过继承自```zApibusRequest```类的子类传递参数。

### 其它参数说明

* authenticate - 用户认证信息。
* session - 用户的会话信息，与```authenticate```传入一个即可。
* httpMethod - 调用HTTP接口时的方法，可选值：POST/GET。
* deserializer - 调用成功时，将返回的```data```字段实例化为方法的泛型参数的回调方法。函数签名为：```T Function(dynamic d)```
* headers - 自定义的http头，与实例化时传入的进行合并。
* connectTimeout - 连接走超时时间
* receiveTimeout - 接收数据超时时间


### 返回值

两个方法均返回一个```zApibusResponse<T>```对象，其中泛型为实例化后的具体对象。

#### zApibusResponse

该对象为调用的返回结果：
* id - 当前请求的ID，一般用于日志检查
* code - 响应代码，为0时表示成功。
* message - 请求代码的描述。
* sub_code - 子错误码，一般为更详细的错误代码。
* sub_message - 子错误描述。
* data - 请求的响应结果
* origin - 请求成功的原始数据
