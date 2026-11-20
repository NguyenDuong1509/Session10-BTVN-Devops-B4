# QuickBite Microservices - Infrastructure Security
## Session 10 - Bài tập 4: Cấu hình Firewall UFW (Vận dụng chuyên sâu)

---

## 📌 1. Bối cảnh & Tình huống nghiệp vụ
- **Vấn đề an ninh:** Một máy chủ VPS vừa khởi tạo thường chưa được kích hoạt tường lửa nội bộ (UFW inactive), dẫn đến nguy cơ các cổng mạng phụ (như cổng database 5432, 3306, redis 6379, microservices nội bộ) bị lộ ra ngoài Internet.
- **Yêu cầu triển khai:**
  1. Kích hoạt tường lửa **UFW (Uncomplicated Firewall)** trên Ubuntu 22.04 LTS.
  2. Áp dụng chính sách **Default Deny Incoming** (Chặn toàn bộ lưu lượng vào mặc định).
  3. **Chỉ mở duy nhất 2 cổng:**
     - **Cổng 22 (SSH):** Phục vụ quản trị máy chủ từ xa (*Phải mở trước khi bật UFW để tránh lockout*).
     - **Cổng 8080 (TCP):** Phục vụ người dùng truy cập microservice.
  4. Thực nghiệm so sánh: Chạy 2 container Nginx trên cổng **8080** và **8081** để chứng minh cổng 8080 truy cập thành công còn cổng 8081 bị tường lửa chặn đứng.

---

## 🛡️ 2. Bảng cấu hình quy tắc Firewall UFW

| Chiều lưu lượng | Chính sách / Cổng | Hành động (Action) | Ghi chú kỹ thuật |
| :--- | :--- | :--- | :--- |
| **Incoming** | Mọi cổng mặc định | **`DENY` (Chặn toàn bộ)** | Chính sách an ninh cơ bản (Default Deny) |
| **Outgoing** | Mọi cổng mặc định | **`ALLOW` (Cho phép toàn bộ)**| Cho phép máy chủ tải gói apt, pull docker image |
| **Cổng 22/tcp** | SSH Port | **`ALLOW IN`** | Duy trì kết nối quản trị từ xa |
| **Cổng 8080/tcp** | Web App (nginx-allowed) | **`ALLOW IN`** | Mở cho Internet truy cập dịch vụ chính |
| **Cổng 8081/tcp** | Test App (nginx-blocked) | **`BLOCKED / DENIED`** | Bị chính sách Default Deny chặn hoàn toàn |

---

## 🛠️ 3. Quy trình thực hiện chi tiết

### Bước 1: Cấu hình chính sách mặc định & mở cổng
```bash
# Đóng tất cả kết nối đến mặc định
sudo ufw default deny incoming

# Cho phép tất cả kết nối ra ngoài
sudo ufw default allow outgoing

# BẮT BUỘC: Mở cổng 22 trước khi bật UFW
sudo ufw allow 22/tcp comment 'SSH Port'

# Mở cổng ứng dụng 8080
sudo ufw allow 8080/tcp comment 'Application Port'
```

### Bước 2: Kích hoạt UFW và kiểm tra trạng thái
```bash
# Kích hoạt UFW
sudo ufw --force enable

# Kiểm tra trạng thái chi tiết
sudo ufw status verbose
```

### Bước 3: Khởi chạy 2 container Nginx để so sánh
```bash
# Chạy container 1 tại cổng 8080
docker run -d --name nginx-allowed -p 8080:80 nginx:alpine

# Chạy container 2 tại cổng 8081
docker run -d --name nginx-blocked -p 8081:80 nginx:alpine
```

### Bước 4: Kiểm tra kết nối từ máy cá nhân (Client)
```bash
# 1. Kiểm tra cổng 8080 (THÀNH CÔNG -> HTTP 200 OK):
curl -I http://54.254.198.85:8080

# 2. Kiểm tra cổng 8081 (THẤT BẠI -> CONNECTION TIMED OUT):
curl -I http://54.254.198.85:8081 --connect-timeout 5
```

---

## 📸 4. Hai hình ảnh minh chứng đạt chuẩn theo yêu cầu đề bài

1. 🖼️ **Ảnh chụp lệnh `sudo ufw status verbose`:**
   * [ufw_status_verbose.png](file:///homework/session_10/exercise_04/ufw_status_verbose.png)
   * *Nội dung:* Hiển thị trạng thái `Status: active`, `Default: deny (incoming), allow (outgoing)`, và bảng rules cho phép `22/tcp (SSH Port)` và `8080/tcp (QuickBite App)`.

2. 🖼️ **Ảnh truy cập thành công cổng 8080 và thất bại ở cổng 8081:**
   * [port_comparison_8080_8081_proof.png](file:///homework/session_10/exercise_04/port_comparison_8080_8081_proof.png)
   * *Nội dung:* Hiển thị so sánh trực quan song song:
     - **Cổng 8080:** `HTTP/1.1 200 OK`, trả về trang web "Welcome to nginx!" thành công mỹ mãn.
     - **Cổng 8081:** `curl: (28) Failed to connect to 54.254.198.85 port 8081: Connection timed out` do bị UFW lọc bỏ.

---

## 📁 5. Cấu trúc thư mục Repository
```text
.
├── .gitignore
├── README.md                      # Tài liệu hướng dẫn chi tiết bài tập
├── EXPLANATION.md                 # Báo cáo chuyên sâu về UFW, Iptables và Docker
├── commands.txt                   # Danh sách toàn bộ lệnh Linux đã thực thi
├── docker-compose.yml             # File compose khởi chạy 2 container so sánh
├── homework/
│   └── session_10/
│       └── exercise_04/
│           ├── ufw_status_verbose.png               # Ảnh lệnh sudo ufw status verbose
│           └── port_comparison_8080_8081_proof.png  # Ảnh so sánh kết nối 8080 vs 8081
└── scripts/
    └── setup-ufw-firewall.sh      # Script bash tự động cấu hình UFW và test
```
