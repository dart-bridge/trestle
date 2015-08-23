# Trestle
### Database Gateway and ORM for Dart

---

## ORM
`IN DEVELOPEMENT`

## Gateway
`IN DEVELOPEMENT`

#### Basic usage
```dart
Stream getAllUsersOlderThan18AndTheirAddresses(Gateway gateway) {
  return gateway.table('users')
    .where((user) => user.age > 18)
    .join('addresses', (user, address) => user.addressId == address.id)
    .get();
}

Future getAllRecentPosts(Gateway gateway) {
  return gateway.table('posts')
    .sortBy('created_at')
    .limit(10)
    .get();
}

Future<int> getTheCountOfUsersThatWasRegisteredDuring2014(Gateway gateway) {
  return gateway.table('users')
    .where((user) 
      => user.createdAt > '2014-01-01 00:00:00'
      && user.createdAt < '2015-01-01 00:00:00')
    .count();
}
```
