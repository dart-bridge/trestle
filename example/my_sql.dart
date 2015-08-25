import 'package:trestle/src/gateway/gateway.dart';
import 'package:trestle/src/drivers/drivers.dart';
import 'package:sqljocky/sqljocky.dart' show ConnectionPool;

main() async {
  final Gateway gateway = new Gateway(
      new MySqlDriver(
          new ConnectionPool(
          user: 'root',
          password: '',
          db: 'test')));

  await gateway.connect();

  await for (var row in gateway.table('table').where((row) => row.id == 1).get()) {
    print(row);
  }
}