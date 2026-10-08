# Cài đặt môi trường phát triển (Windows)

> Ghi lại **chính xác** các bước đã làm trên máy này ngày 2026-10-08 để bạn hiểu và tự làm lại được trên máy khác.
> Tất cả lệnh bên dưới chạy trong **PowerShell** (trừ khi ghi khác).

## 0. Tình trạng ban đầu

| Thành phần | Trạng thái trước khi cài |
|---|---|
| Flutter / Dart | ❌ chưa có (blocker B-001) |
| Android SDK | ✔ `D:\Android\SDK` |
| JDK | `java` trên PATH là **1.8** (quá cũ cho Gradle 9); có **Temurin 21** tại `C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot`; JBR của Android Studio là Java 25 |
| git | ✔ 2.43.0 |
| Dung lượng trống | `C:` ~9.5 GB (ít) · `D:` ~48 GB |

**Nguyên tắc chính:** mọi thứ nặng (Flutter SDK, cache pub, cache Gradle, Android SDK, NDK) phải nằm trên ổ **D:**.

---

## 1. Đặt thư mục cache ra ổ D: (làm TRƯỚC mọi lệnh `flutter`)

Lý do: lần chạy `flutter` đầu tiên sẽ chạy `pub get` cho chính bộ công cụ Flutter. Nếu chưa đặt `PUB_CACHE` thì cache sẽ rơi vào `C:\Users\<bạn>\AppData\Local\Pub\Cache`. Tương tự, Gradle mặc định để cache (vài GB) ở `C:\Users\<bạn>\.gradle`.

```powershell
New-Item -ItemType Directory -Force 'D:\dev-cache\gradle', 'D:\dev-cache\pub'
[Environment]::SetEnvironmentVariable('GRADLE_USER_HOME', 'D:\dev-cache\gradle', 'User')
[Environment]::SetEnvironmentVariable('PUB_CACHE', 'D:\dev-cache\pub', 'User')
```

| Biến (cấp User) | Giá trị | Ai dùng |
|---|---|---|
| `GRADLE_USER_HOME` | `D:\dev-cache\gradle` | Gradle: bản phân phối Gradle (wrapper), cache thư viện Maven, daemon |
| `PUB_CACHE` | `D:\dev-cache\pub` | `flutter pub get`: mã nguồn các package Dart |

## 2. Thêm vào PATH của User

Cần thêm `D:\flutter\bin` (lệnh `flutter`, `dart`) và `D:\dev-cache\pub\bin` (các công cụ cài bằng `dart pub global activate`).

> ⚠️ PATH của User trong registry có kiểu `REG_EXPAND_SZ` (chứa được `%USERPROFILE%`…). Cách hay gặp trên mạng là `[Environment]::SetEnvironmentVariable("Path", ... , "User")`. Cách này **đọc ra giá trị đã bung biến** và **ghi lại thành `REG_SZ`**, nên sẽ làm mất các tham chiếu `%...%`. Vì vậy dùng registry API trực tiếp:

```powershell
# (Tùy chọn) sao lưu PATH cũ trước khi sửa
$key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
$raw = $key.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
$raw | Out-File -Encoding utf8 "$HOME\user_path_backup.txt"

$parts = $raw.TrimEnd(';').Split(';')
foreach ($p in @('D:\flutter\bin', 'D:\dev-cache\pub\bin')) { if ($parts -notcontains $p) { $parts += $p } }
$key.SetValue('Path', ($parts -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString)
$key.Close()

# Gọi lại một lệnh SetEnvironmentVariable để Windows phát thông báo "biến môi trường đã đổi"
[Environment]::SetEnvironmentVariable('PUB_CACHE', 'D:\dev-cache\pub', 'User')
```

> 🔁 **Phải đóng hẳn VS Code (và mọi terminal) rồi mở lại** thì các chương trình mới nhận PATH và biến mới. Terminal đang mở từ trước sẽ không thấy lệnh `flutter`.
> (Trong phiên cài đặt, Claude Code gọi Flutter bằng đường dẫn đầy đủ `D:\flutter\bin\flutter` và tự `export` hai biến cache cho từng lệnh.)

## 3. Clone Flutter SDK (đầy đủ lịch sử, kênh stable)

```powershell
git clone https://github.com/flutter/flutter.git -b stable D:\flutter
```

- **Không** dùng `--depth 1`: bản clone nông (shallow) làm hỏng `flutter --version`, `flutter upgrade` và việc chuyển sang một tag cụ thể.
- Kích thước thư mục `.git` sau khi clone: khoảng **457 MB**.
- Đường dẫn `D:\flutter` **không có dấu cách** (Flutter SDK không chạy ổn định nếu đường dẫn SDK có dấu cách).
- `D:\` có sẵn một repo git ở gốc. Clone vào `D:\flutter` tạo một repo **riêng** (có `.git` riêng) nên **không đụng** tới repo ở gốc `D:\`.

## 4. Lần chạy đầu & kiểm tra phiên bản

```powershell
flutter --version
```

Lần đầu Flutter tự tải Dart SDK vào `D:\flutter\bin\cache` và build công cụ (pub vào `D:\dev-cache\pub`). Kết quả trên máy này:

```
Flutter 3.47.6 • channel stable
Framework • revision 5fc346839b • 2026-09-30
Tools • Dart 3.13.5 • DevTools 2.60.0
```

→ Là **3.x** nên giữ nguyên nhánh `stable`, không cần `git checkout` tag khác (yêu cầu: Flutter 3.x, Dart 3).

Kiểm tra cache đúng chỗ: `D:\dev-cache\pub` có ~140 MB; thư mục `C:\Users\<bạn>\AppData\Local\Pub\Cache` **không** được tạo.

## 5. Trỏ Flutter tới Android SDK và JDK 21

```powershell
Test-Path 'C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot\bin\java.exe'   # phải True
flutter config --android-sdk "D:\Android\SDK"
flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot"
```

- `--jdk-dir` chỉ ảnh hưởng tới **Flutter/Gradle**. `java` 1.8 trên PATH hệ thống được **giữ nguyên** (các phần mềm khác của bạn có thể cần nó).
- Vì sao JDK 21 mà không dùng JBR 25 của Android Studio: template Flutter 3.47 dùng **AGP 9.1 + Gradle 9.3.1**, chạy ổn định trên JDK 17/21 (LTS). JDK 21 là lựa chọn an toàn nhất.

## 6. Android SDK: kiểm tra gói & license

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot'
D:\Android\SDK\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=D:\Android\SDK --list_installed
```

Các gói đã có sẵn, **không cần cài thêm**:

| Gói | Phiên bản |
|---|---|
| `cmdline-tools;latest` | 23.0.0 |
| `platform-tools` | 37.0.1 |
| `build-tools` | 30.0.3, 34.0.0, 35.0.0, 35.0.1, 36.0.0, 37.0.0 |
| `platforms` | android-24, 33, 34, 35, 36 |
| `emulator` + system image API 33/36 | có (AVD `vku_test_api33` đã tồn tại) |

Nếu thiếu, cài bằng: `sdkmanager --sdk_root=D:\Android\SDK "platform-tools" "build-tools;36.0.0" "platforms;android-36" "cmdline-tools;latest"`.

**Ghi chú về `sdkmanager` bản 2026:** công cụ báo *deprecated* và tự tải **Android CLI** (lệnh mới: `android sdk ...`). Android CLI nằm ở `C:\Users\<bạn>\.android\bin` và `...\.android\cli`, tổng **~233 MB trên ổ C:**. Vị trí này do công cụ tự chọn, không đổi được, và sẽ được tải lại nếu xóa.

Chấp nhận license:

```powershell
flutter doctor --android-licenses     # trả lời y cho từng license
```

Trên máy này Android CLI trả lời *"The --licenses option is no longer needed"* và `flutter doctor` xác nhận **"All Android licenses accepted."**

## 7. `flutter doctor -v`

| Mục | Kết quả | Xử lý |
|---|---|---|
| Flutter | ✔ 3.47.6 (cảnh báo "not on your path" chỉ xuất hiện trong terminal mở **trước** khi sửa PATH) | Mở lại VS Code |
| Windows Version | ✔ | — |
| **Android toolchain** | ✔ **xanh**: SDK 36.0.0, Java 21 từ cấu hình Flutter, all licenses accepted | — |
| Chrome | ✔ (có sẵn) | Không dùng (dự án chỉ build Android) |
| Visual Studio | ✘ chưa cài | **Bỏ qua**: chỉ cần khi build ứng dụng Windows desktop |
| Android Studio | không hiện trong báo cáo | **Bỏ qua**: không bắt buộc, SDK + JDK đã cấu hình trực tiếp |
| Connected device | chỉ có Windows/Chrome/Edge | Cắm điện thoại Android (bật USB debugging) trước Phase 3 |

## 8. Build lần đầu: NDK và bộ nhớ Gradle

### 8.1. Lỗi tự cài NDK → cài tay bằng Android CLI

Template Flutter 3.47 khai báo `ndkVersion = flutter.ndkVersion` = **28.2.13676358**. Lần build đầu, Gradle (AGP) cố tự cài NDK bằng `sdkmanager` và thất bại:

```
Package ndk not found.
Package 28.2.13676358 not found.
> Android sdkmanager did not install NDK 28.2.13676358 into D:\Android\SDK.
```

**Nguyên nhân:** `sdkmanager.bat` bản 2026 chỉ còn là một *shim* (lớp vỏ) chuyển lệnh sang **Android CLI**. Khi chạy qua `cmd`, dấu `;` trong tên gói `ndk;28.2.13676358` bị coi là dấu phân cách tham số, nên lệnh nhận thành hai gói `ndk` và `28.2.13676358`. Bọc tên gói trong ngoặc kép cũng không ăn thua vì shim báo lỗi cú pháp.

**Cách sửa:** gọi thẳng `android.exe` (không qua `cmd`), dùng tên gói dạng `/` như shim vẫn tự đổi:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot'
D:\Android\SDK\cmdline-tools\latest\bin\android.exe --sdk=D:\Android\SDK sdk install ndk/28.2.13676358
```

Kết quả: tải `android-ndk-r28c-windows.zip`, giải nén vào `D:\Android\SDK\ndk\28.2.13676358` (**2.2 GB, trên ổ D:**).

Sau đó `flutter build apk --debug` thành công (lần đầu mất ~9.5 phút vì phải tải Gradle 9.3.1 và các thư viện Maven vào `D:\dev-cache\gradle`).

Cảnh báo `This version only understands SDK XML versions up to 3 but an SDK XML file of version 4 was encountered` là do AGP và cmdline-tools phát hành ở hai thời điểm khác nhau. Cảnh báo này **vô hại**.

### 8.2. Ổ C: bị hụt ~1.8 GB trong lúc build: do pagefile

Sau build đầu, ổ C: giảm từ 9.5 GB còn 7.7 GB. Đã kiểm tra:

- Thư mục người dùng trên C: chỉ tăng ~240 MB (Android CLI 232 MB + cache analyzer 5 MB). `C:\Users\<bạn>\.gradle` **không** bị ghi thêm.
- Thủ phạm chính: **`C:\pagefile.sys`** (bộ nhớ ảo do Windows tự quản lý) phình lên **7.8 GB**. Máy có **8 GB RAM**, trong khi template Flutter đặt heap cho Gradle là `-Xmx8G`, nên Windows phải đẩy bớt RAM ra đĩa.

**Cách sửa (đã commit trong `android/gradle.properties`):**

```properties
org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=256m
kotlin.daemon.jvmargs=-Xmx1G
```

Build lại với cấu hình mới vẫn thành công (63.7 giây, có cache). Pagefile do Windows quản lý: nó sẽ tự co lại sau khi khởi động lại máy. Nếu muốn giữ chỗ trên C: lâu dài, bạn có thể chuyển pagefile sang ổ D: (System Properties → Advanced → Performance → Virtual memory). Việc này là thiết lập hệ thống nên Claude **không** tự làm.

Mẹo: sau khi build xong, chạy `cd android; .\gradlew --stop` để tắt Gradle daemon và giải phóng RAM.

## 9. Những gì vẫn nằm trên ổ C: (nhỏ, chấp nhận được)

| Thư mục | Nội dung | Ước lượng |
|---|---|---|
| `C:\Users\<bạn>\.android\` | debug keystore, Android CLI (~233 MB), AVD emulator | AVD có thể lớn nếu chạy emulator |
| `C:\Users\<bạn>\AppData\Local\.dartServer` | cache của Dart analysis server (VS Code) | vài MB → vài trăm MB |
| `C:\Users\<bạn>\AppData\Roaming\.flutter*`, `.dart-tool` | cấu hình Flutter (`flutter config`), analytics | < 1 MB |
| `%TEMP%` | file tạm khi build | dọn được |
| `C:\pagefile.sys` | bộ nhớ ảo của Windows | xem mục 8.2 |

Thành phần lớn đều nằm trên D:: `D:\flutter` (SDK), `D:\dev-cache\pub`, `D:\dev-cache\gradle`, `D:\Android\SDK` (kể cả NDK 2.2 GB).

## 10. Kiểm tra lại sau khi mở terminal mới

```powershell
flutter --version          # Flutter 3.47.6, Dart 3.13.5
$env:PUB_CACHE             # D:\dev-cache\pub
$env:GRADLE_USER_HOME      # D:\dev-cache\gradle
flutter doctor -v          # Android toolchain [√]
cd "D:\Start Github\Projects\vku-ocr-expense"
flutter pub get
flutter build apk --debug
```

## 11. Gỡ cài đặt / hoàn tác

1. Xóa `D:\flutter`, `D:\dev-cache` và (nếu muốn) `D:\Android\SDK\ndk\28.2.13676358`.
2. Xóa hai biến: `[Environment]::SetEnvironmentVariable('PUB_CACHE', $null, 'User')`, tương tự với `GRADLE_USER_HOME`.
3. Gỡ `D:\flutter\bin;D:\dev-cache\pub\bin` khỏi PATH của User (System Properties → Environment Variables) hoặc khôi phục từ bản sao lưu ở bước 2.
