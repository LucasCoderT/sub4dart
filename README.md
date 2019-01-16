A [subsonic] API wrapper written in Dart

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:sub4dart/sub4dart.dart';

main() async {
  var subsonic = new SubSonic("https://music.example.com","John","Doe");
  await subsonic.getPing(); // Returns a response if successfully authenticated
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/LucasCLuk/sub4dart/issues
[subsonic]: http://www.subsonic.org/pages/index.jsp