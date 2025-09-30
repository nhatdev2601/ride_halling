# RideApp - Ứng dụng đặt xe công nghệ

Ứng dụng đặt xe công nghệ được thiết kế với giao diện hiện đại, tối giản, lấy cảm hứng từ Grab với màu xanh lá cây chủ đạo (#00B14F).

##  Tính năng chính

###  Các màn hình chính:

1. **Màn hình chính (Home Screen)**
   - Bản đồ toàn màn hình với Google Maps
   - Ô nhập điểm đi và điểm đến ở trên cùng
   - Nút đặt xe lớn nổi bật ở dưới cùng
   - Các dịch vụ nhanh (Bike, Car, Delivery, Food)

2. **Màn hình chọn loại xe (Vehicle Selection)**
   - Hiển thị các lựa chọn: RideBike, RideCar, RidePremium
   - Thông tin giá cước và thời gian dự kiến
   - Chọn phương thức thanh toán
   - UI Material Design với animation mượt mà

3. **Màn hình theo dõi chuyến đi (Trip Tracking)**
   - Bản đồ với lộ trình di chuyển
   - Thông tin tài xế (ảnh, tên, biển số xe, đánh giá)
   - Trạng thái chuyến đi real-time
   - Nút liên hệ tài xế

4. **Màn hình thanh toán (Payment)**
   - Hỗ trợ nhiều hình thức: Tiền mặt, Ví điện tử, Thẻ tín dụng
   - Thêm/xóa phương thức thanh toán
   - UI thân thiện và bảo mật

5. **Màn hình lịch sử chuyến đi (Trip History)**
   - Danh sách chuyến đi đã hoàn thành
   - Chi tiết từng chuyến đi
   - Đánh giá và feedback

6. **Màn hình đánh giá (Rating)**
   - Đánh giá tài xế với sao
   - Feedback nhanh với tags
   - Nhập ý kiến chi tiết

##  Thiết kế UI/UX

### Màu sắc chủ đạo:
- **Primary Green**: #00B14F (màu xanh lá Grab)
- **White**: #FFFFFF (nền chính)
- **Light Grey**: #F5F5F5 (nền phụ)
- **Dark Grey**: #424242 (text)

### Đặc điểm thiết kế:
-  Material Design 3.0
-  Tối giản, hiện đại
-  Dễ thao tác bằng một tay
-  Icon đơn giản, rõ ràng
-  Animation mượt mà
-  Responsive design

##  Công nghệ sử dụng

- **Framework**: Flutter 3.8.1+
- **Language**: Dart
- **Maps**: Google Maps Flutter
- **Location**: Geolocator
- **Permissions**: Permission Handler
- **UI Components**: Material Design 3
- **Rating**: Flutter Rating Bar

##  Cài đặt và chạy

### Yêu cầu:
- Flutter SDK 3.8.1 trở lên
- Dart SDK
- Android Studio / VS Code
- Google Maps API Key

### Các bước cài đặt:

1. Clone repository:
```bash
git clone <repository-url>
cd ride_hailing
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Cấu hình Google Maps API:
   - Tạo API key tại [Google Cloud Console](https://console.cloud.google.com/)
   - Thêm API key vào `android/app/src/main/AndroidManifest.xml`
   - Thêm API key vào `ios/Runner/AppDelegate.swift`

4. Chạy ứng dụng:
```bash
flutter run
```

##  Cấu trúc thư mục

```
lib/
├── main.dart                 # Entry point
├── theme/
│   └── app_theme.dart       # Theme và màu sắc
├── models/
│   └── models.dart          # Data models
├── screens/
│   ├── splash_screen.dart   # Màn hình khởi động
│   ├── main_screen.dart     # Navigation chính
│   ├── home_screen.dart     # Màn hình chính
│   ├── vehicle_selection_screen.dart
│   ├── trip_tracking_screen.dart
│   ├── trip_rating_screen.dart
│   ├── trip_history_screen.dart
│   └── payment_screen.dart
└── widgets/
    ├── location_input.dart  # Widget nhập địa chỉ
    └── bottom_book_button.dart
```

##  Tính năng nổi bật

### 1. Giao diện người dùng
- **Clean & Modern**: Thiết kế tối giản, tập trung vào trải nghiệm người dùng
- **Consistent Colors**: Màu sắc nhất quán theo brand identity
- **Smooth Animations**: Animation mượt mà cho mọi tương tác

### 2. Trải nghiệm đặt xe
- **Quick Booking**: Đặt xe nhanh chóng với vài thao tác
- **Real-time Tracking**: Theo dõi tài xế và chuyến đi real-time
- **Multiple Payment**: Nhiều phương thức thanh toán linh hoạt

### 3. Tương tác tài xế
- **Driver Info**: Thông tin chi tiết về tài xế và xe
- **Communication**: Gọi điện, nhắn tin trực tiếp
- **Rating System**: Hệ thống đánh giá hai chiều

##  Roadmap

### Version 1.1
- [ ] Thêm Dark Theme
- [ ] Push Notifications
- [ ] Offline Maps
- [ ] Multiple Languages

### Version 1.2
- [ ] Voice Commands
- [ ] Share Trip
- [ ] Emergency Features
- [ ] Advanced Filters

##  Đóng góp

Chúng tôi chào đón mọi đóng góp! Vui lòng:

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

##  License

Dự án này được phân phối dưới MIT License. Xem `LICENSE` file để biết thêm chi tiết.

##  Liên hệ

- **Email**: contact@rideapp.com
- **Website**: https://rideapp.com
- **Support**: https://support.rideapp.com

---

*Được phát triển với  bởi RideApp Team*
