# BÁO CÁO KỸ THUẬT: CẤU HÌNH TƯỜNG LỬA UFW TRÊN LINUX (SESSION 10 - BÀI 4)

## 1. Bản chất kỹ thuật của UFW (Uncomplicated Firewall)

### 1.1. UFW là gì?
- **UFW (Uncomplicated Firewall)** là một công cụ giao diện dòng lệnh cấp cao (CLI frontend) được phát triển bởi Canonical nhằm mục đích đơn giản hóa việc quản lý các quy tắc tường lửa trong Linux.
- Ở tầng dưới (under the hood), UFW không tự xử lý gói tin mà nó tạo ra các quy tắc và nạp vào **Netfilter / iptables (hoặc nftables)** - tầng xử lý gói tin sâu trong Linux Kernel.
- Nhờ UFW, quản trị viên không cần phải viết các câu lệnh `iptables` phức tạp dễ gây nhầm lẫn như:
  `iptables -A INPUT -p tcp --dport 22 -j ACCEPT`
  mà chỉ cần cú pháp trực quan: `ufw allow 22/tcp`.

### 1.2. Nguyên lý "Default Deny" (Chặn mặc định)
- Trong an toàn thông tin, triết lý xây dựng tường lửa chuẩn mực luôn là **Zero Trust & Default Deny**:
  - Mọi cổng mạng đi vào (Incoming Traffic) đều bị chặn toàn bộ theo mặc định (`default deny incoming`).
  - Chỉ những cổng có mục đích nghiệp vụ rõ ràng (Port 22 cho SSH, Port 8080 cho Backend) mới được cấp phép ngoại lệ (Whitelisting).
  - Nhờ đó, nếu một lập trình viên vô tình chạy một database (PostgreSQL 5432, Redis 6379, MongoDB 27017) không cài mật khẩu trên máy chủ, hacker từ Internet vẫn **không thể quét hoặc truy cập** vào database đó.

---

## 2. Vì sao bắt buộc phải mở cổng 22 trước khi kích hoạt UFW?

- Khi UFW được kích hoạt bằng lệnh `sudo ufw enable`, chính sách `default deny incoming` sẽ lập tức có hiệu lực tức thì trên toàn bộ giao diện mạng (`eth0`, `ens3`).
- Nếu bạn chưa thêm quy tắc `ufw allow 22/tcp`, Linux Kernel sẽ lập tức ngắt (DROP) toàn bộ các gói tin TCP hướng tới cổng 22.
- **Hậu quả nghiêm trọng:** Phiên làm việc SSH hiện tại của bạn sẽ bị đóng băng ngay lập tức, và bạn sẽ bị **khóa ngoài máy chủ (Lockout) vĩnh viễn** mà không thể đăng nhập lại từ xa. Cách duy nhất để khôi phục là phải truy cập qua bảng điều khiển Cloud Console (Serial Console / VNC / Web CLI).

$\rightarrow$ **Quy tắc an toàn bất biến:** Luôn thực hiện `sudo ufw allow 22/tcp` trước khi chạy `sudo ufw enable`.

---

## 3. Tương tác đặc thù giữa Docker và UFW

### 3.1. Vấn đề Docker bypass UFW
- Theo mặc định, Docker daemon khi khởi chạy sẽ tự động thao tác trực tiếp với các iptables chain (tạo ra chain `DOCKER` và can thiệp vào chain `PREROUTING`).
- Khi bạn chạy `docker run -p 8081:80`, Docker có thể chèn quy tắc NAT vào iptables trước khi UFW kiểm tra gói tin, dẫn đến việc container vẫn có thể truy cập được từ bên ngoài dù UFW chưa mở cổng 8081.

### 3.2. Giải pháp khắc phục chuẩn DevOps
1. **Liên kết với localhost:** Chạy container với port mapping dạng `-p 127.0.0.1:8081:80` (chỉ cho phép truy cập cục bộ từ máy chủ hoặc reverse proxy Nginx).
2. **Cấu hình UFW-Docker chain:** Thêm các rule lọc vào `/etc/ufw/after.rules` để buộc các gói tin đi qua chain `DOCKER-USER` phải chịu sự kiểm soát của UFW.
3. **Sử dụng Cloud Security Group:** Thiết lập tầng phòng vệ kép (Defense in Depth) bằng cách khóa cổng 8081 ở cấp Cloud Firewall (AWS Security Group / GCP Firewall), đảm bảo an ninh nhiều lớp.

---

## 4. Hướng dẫn nộp bài lên hệ thống Portal

1. **Link GitHub repository nộp bài:**
   ```text
   https://github.com/NguyenDuong1509/Session10-BTVN-Devops-B4
   ```
2. **File text nộp trực tiếp:**
   - File [commands.txt](file:///commands.txt) ghi lại toàn bộ danh sách lệnh cấu hình UFW và kiểm thử container.
3. **Hình ảnh minh chứng nộp kèm:**
   - `homework/session_10/exercise_04/ufw_status_verbose.png`: Ảnh chụp lệnh `sudo ufw status verbose` hiển thị cổng 22 và 8080 mở, còn lại chặn hết.
   - `homework/session_10/exercise_04/port_comparison_8080_8081_proof.png`: Ảnh minh chứng cổng 8080 kết nối HTTP 200 thành công còn cổng 8081 bị Timeout thất bại.
