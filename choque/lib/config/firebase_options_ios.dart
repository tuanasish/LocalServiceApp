import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase options cho iOS khi không dùng native FirebaseApp.configure()
/// (tránh crash do GoogleService-Info.plist thiếu CLIENT_ID).
///
/// NOTE: Giá trị này lấy từ GoogleService-Info.plist của project cho-que-c9752.
/// Firebase API keys được restrict bởi Bundle ID trong Firebase Console,
/// nên chúng không phải là secret nguy hiểm. Tuy nhiên, trong production bạn nên:
/// 1. Tải GoogleService-Info.plist đầy đủ từ Firebase Console (bao gồm CLIENT_ID)
/// 2. Sử dụng native FirebaseApp.configure() trong AppDelegate thay vì file này
/// 3. Xem xét dùng FlutterFire CLI để generate firebase_options.dart tự động
const FirebaseOptions iosFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCqeO6Am0Dokty_2c92KzLlfI7xRHBVA78',
  appId: '1:1013852381026:ios:62f2955555c3e95b3a163b',
  messagingSenderId: '1013852381026',
  projectId: 'cho-que-c9752',
  storageBucket: 'cho-que-c9752.firebasestorage.app',
);
