# luci-app-android-adb

Gói LuCI cho OpenWrt để đọc một số trạng thái Android qua ADB và gửi lệnh bật/tắt chế độ máy bay.

## Chức năng

- Pin và trạng thái đang sạc (đọc từ `dumpsys battery`).
- Trạng thái SIM và tên nhà mạng (Android `getprop`).
- Airplane mode thông qua `settings put global airplane_mode_on` và broadcast intent.
- Chỉ có hai thao tác từ giao diện; backend không nhận lệnh shell tùy ý từ trình duyệt.

## Cài đặt

Đặt thư mục này vào `package/feeds/luci/luci-app-android-adb` trong cây build OpenWrt đã có feed LuCI, chạy `make menuconfig`, chọn `LuCI > Applications > luci-app-android-adb`, sau đó build và cài gói `.ipk`. Tên/gói ADB phụ thuộc feed và phiên bản OpenWrt; cài tiện ích `adb` phù hợp riêng nếu bản build không cung cấp sẵn.

Sau khi cài, sửa `/etc/config/android_adb`:

```uci
config android_adb 'main'
    option host '192.168.1.100'
    option port '5555'
```

Thiết bị Android phải bật Developer options và Wireless debugging/ADB TCP-IP, được xác thực/ghép nối trước. Trên router, xác nhận thiết bị:

```sh
adb connect 192.168.1.100:5555
adb devices
```

Mở **Services → Android ADB** trong LuCI.

## Lưu ý an toàn và tương thích

- ADB TCP/IP là quyền truy cập rất nhạy cảm. Chỉ bật trong mạng tin cậy, xác thực thiết bị, không mở cổng ADB ra Internet và tắt Wireless debugging khi không dùng. Thiết bị Android đời mới thường dùng Wireless debugging với cổng ghép nối và cổng kết nối động; cổng 5555 có thể không dùng được.
- Không phải Android nào cũng cho ứng dụng shell ADB thay đổi trạng thái máy bay. Android/OEM mới có thể yêu cầu quyền hệ thống hoặc từ chối broadcast; giao diện sẽ báo trạng thái/lỗi nếu đọc được.
- Khi ADB đi qua Wi-Fi của chính điện thoại, airplane mode hoặc thay đổi mạng có thể ngắt phiên ADB. Dùng đường kết nối độc lập hoặc mạng điều khiển riêng để tránh mất kết nối.
- Airplane mode không đảm bảo IP công cộng thay đổi. Địa chỉ do nhà mạng cấp có thể giữ nguyên, và bật máy bay thường làm mất kết nối dữ liệu.
- `gsm.sim.state` và `gsm.operator.alpha` không được mọi ROM công khai giống nhau; dual-SIM có thể trả về giá trị tổng hợp. Không đọc IMEI hay dữ liệu định danh thiết bị.
- Mã nguồn là khung ứng dụng LuCI chưa được biên dịch/kiểm thử trên một target OpenWrt cụ thể. API LuCI và tên gói ADB có thể khác theo nhánh release.

## Tải gói IPK

Các gói cài đặt có trong GitHub Release `v1.0.0`:

- `luci-app-android-adb_1.0.0-1_all.ipk`: định dạng ar (dùng với các bản opkg mới).
- `luci-app-android-adb_1.0.0-1_all_legacy.ipk`: định dạng tar IPK kiểu cũ.

Cả hai gói đều có kiến trúc `all` và yêu cầu `luci-base`. Nếu cả hai đều bị báo *Malformed package file*, firmware có thể yêu cầu metadata/định dạng hoặc phiên bản ABI khác; cần build bằng SDK/Buildroot đúng phiên bản OpenWrt của thiết bị.
