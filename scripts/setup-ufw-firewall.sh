#!/usr/bin/env bash
# ==============================================================================
# Script tự động cấu hình UFW Firewall & Triển khai 2 container kiểm thử
# QuickBite Platform - Session 10 Bài tập 4
# ==============================================================================

set -e

echo "=========================================================="
echo "  [1/4] Cấu hình chính sách mặc định cho UFW Firewall..."
echo "=========================================================="
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "=========================================================="
echo "  [2/4] Mở cổng SSH 22 và Cổng ứng dụng 8080..."
echo "=========================================================="
sudo ufw allow 22/tcp comment 'SSH Port'
sudo ufw allow 8080/tcp comment 'QuickBite Web Application Port'

echo "=========================================================="
echo "  [3/4] Kích hoạt tường lửa UFW..."
echo "=========================================================="
sudo ufw --force enable
sudo ufw status verbose

echo "=========================================================="
echo "  [4/4] Khởi chạy 2 Container Nginx ở cổng 8080 và 8081..."
echo "=========================================================="
# Dọn dẹp container cũ nếu có
docker rm -f nginx-allowed nginx-blocked 2>/dev/null || true

# Khởi chạy container mở tại 8080
docker run -d --name nginx-allowed -p 8080:80 nginx:alpine

# Khởi chạy container bị chặn tại 8081
docker run -d --name nginx-blocked -p 8081:80 nginx:alpine

echo ""
echo "[v] Danh sách container đang chạy:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=========================================================="
echo "  [HOÀN TẤT] Tường lửa UFW đã được cấu hình thành công!"
echo "  - Cổng 8080: Được mở (ALLOW) -> Truy cập bình thường."
echo "  - Cổng 8081: Bị chặn (DENY)  -> Bị ngắt kết nối (Timeout)."
echo "=========================================================="
