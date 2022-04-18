import 'package:flutter_test/flutter_test.dart';

import 'package:zapibus/zapibus.dart';

void main() async {
  // test('adds one to input values', () {
  //   final calculator = Calculator();
  //   expect(calculator.addOne(2), 3);
  //   expect(calculator.addOne(-7), -6);
  //   expect(calculator.addOne(0), 1);
  // });
  zApibus bus =
      new zApibus("1", "hmJ1Y7tyi7cM", "https://expert.zsea.app:8443/api");
  await bus.Execute("api.get", {"a": 1, "b": "b"});
}
