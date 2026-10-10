# Ký APK release

APK cài được lên điện thoại phải được **ký**. Dự án dùng một keystore riêng, nằm **ngoài repo**; mật khẩu nằm trong `android/key.properties` (đã `.gitignore`). Không commit, không gửi cho ai hai thứ này.

## Có gì ở đâu

| Thứ | Vị trí | Trong git? |
|---|---|---|
| Keystore (PKCS12) | `%USERPROFILE%\vku-keys\upload-keystore.jks` | ❌ (ngoài repo, `*.jks` bị bỏ qua) |
| Mật khẩu, đường dẫn keystore | `android/key.properties` | ❌ (`android/key.properties` bị bỏ qua) |
| Cách đọc `key.properties` | `android/app/build.gradle.kts` | ✔ (không chứa mật khẩu) |

Alias khóa: `upload`. Chủ thể chứng chỉ: `CN=Le Duy Dat, OU=23SE1, O=VKU, L=Da Nang, C=VN`. Hiệu lực 10.000 ngày.

## ⚠ Sao lưu

**Mất keystore thì không thể cập nhật app đã phát hành bằng cùng chữ ký.** Hãy sao chép `upload-keystore.jks` và `key.properties` vào nơi an toàn ngoài máy này (USB, trình quản lý mật khẩu). Không đưa lên GitHub, kể cả repo private.

## Tạo lại keystore (khi mất máy hoặc làm máy mới)

Cần JDK có `keytool` (JDK 21 đã cài theo `docs/SETUP_ENV.md`). PowerShell:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\vku-keys" | Out-Null
keytool -genkeypair -v `
  -keystore "$env:USERPROFILE\vku-keys\upload-keystore.jks" `
  -storetype PKCS12 -alias upload -keyalg RSA -keysize 2048 -validity 10000 `
  -dname "CN=<Ho Ten>, OU=<Lop>, O=VKU, L=Da Nang, C=VN"
```

`keytool` hỏi mật khẩu; chọn mật khẩu dài, ngẫu nhiên, chỉ gồm chữ và số (tránh ký tự đặc biệt cho dễ ghi vào file `.properties`). Với PKCS12, mật khẩu khóa trùng mật khẩu kho.

Sau đó tạo `android/key.properties` (đường dẫn dùng dấu `/`):

```properties
storePassword=<mật khẩu>
keyPassword=<mật khẩu>
keyAlias=upload
storeFile=C:/Users/<ban>/vku-keys/upload-keystore.jks
```

> Keystore mới có **chữ ký khác** keystore cũ. APK ký bằng khóa khác không cài đè lên bản đã cài được; phải gỡ bản cũ trước (mất dữ liệu cục bộ của app).

## Build và kiểm tra chữ ký

```powershell
flutter build apk --release
# Kết quả: build\app\outputs\flutter-apk\app-release.apk

& "$env:ANDROID_HOME\build-tools\37.0.0\apksigner.bat" verify --print-certs `
  build\app\outputs\flutter-apk\app-release.apk
```

`apksigner` in ra chủ thể chứng chỉ (`CN=Le Duy Dat …`) và dấu vân tay SHA-256. **Dấu vân tay phải trùng** với của keystore:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\vku-keys\upload-keystore.jks" -alias upload
```

Nếu chủ thể là `CN=Android Debug` thì APK đang bị ký bằng khóa debug (xem mục dưới).

## Khi không có `key.properties`

Người clone repo không có keystore. Khi đó `flutter build apk --release` **vẫn chạy** nhưng ký bằng khóa **debug** và in dòng `WARNING: android/key.properties not found…`. APK này chỉ để thử, **không phát hành**. Muốn APK ký đúng, tạo keystore theo mục trên.

## Kiểm tra repo sạch trước khi push

```powershell
git status --short                      # không được có *.jks, key.properties, *.apk
git ls-files | Select-String "jks|keystore|key.properties|\.apk|\.aab"   # phải rỗng
```

`test/core/release_config_test.dart` kiểm tra tự động các điều trên.
