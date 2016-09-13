## 0.10.0

**Additions**
* Added back SQLite support via the newly updated `sqlite` package.

```dart
final gateway = new Gateway(
  // driver: new SqliteDriver.inMemory()
  driver: new SqliteDriver('path/to/database.db')
)
```

## 0.9.0

**Bug fixes**
* The `.unique()` constraint on a schema column now correctly outputs `UNIQUE` in `SQLDriver`.

## 0.7.0

**Breaking!**
* Removing SQLite implementation because it is simply not working well. Apps depending on the
  SQLite driver must stay `<0.7.0`.

**Additions**
* Added a JSON data type (#5)
