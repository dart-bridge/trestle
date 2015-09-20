import 'dart:async';
import 'package:trestle/gateway.dart';

Future session(Driver driver, session(Gateway gateway)) async {
    final gateway = new Gateway(driver);
    await gateway.connect();

    await session(gateway);

    await gateway.disconnect();
}