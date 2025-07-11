# Burp-CLI
Instruction for using Burp in CLI
# Burp CLI & REST API Guide

> Hướng dẫn chạy Burp Suite Professional ở chế độ headless CLI (sử dụng `cli.sh`) và cách tương tác với REST API để khởi tạo & theo dõi một **scan**.

---

## 1. Giới thiệu

Burp Suite (Professional/Enterprise) hỗ trợ chế độ *headless* thông qua command‑line và REST API. Điều này cho phép bạn:

* Tự động hoá quét bảo mật (CI/CD, cron,…)
* Giới hạn tài nguyên, chạy song song nhiều job
* Tích hợp kết quả vào dashboard, SIEM hoặc ticket system

## 2. Yêu cầu hệ thống

| Thành phần              | Phiên bản tối thiểu                      |
| ----------------------- | ---------------------------------------- |
| Burp Suite Professional | 2025.x                                   |
| Java (JDK)              | 17+                                      |
| Quyền thực thi file     | `chmod +x cli.sh`                        |
| Cấu hình env            | `JAVA_HOME`, `BURP_JAR`, `BURP_LICENSE`… |

## 3. Cấu trúc repo

```
.
├── cli.sh                  # script khởi chạy Burp headless
├── burp_core_schema.json   # JSON‑Schema lý thuyết (mục 5)
├── example_flow.json       # JSON ví dụ end‑to‑end (mục 5)
└── README.md               # tài liệu này
```

## 4. Hướng dẫn chạy `cli.sh`

```bash
# 1) export biến cần thiết
export JAVA_HOME="/usr/lib/jvm/jdk-21"
export BURP_JAR="/opt/burp/burpsuite_pro_v2025.jar"

# 2) chạy Burp ở cổng API mặc định 1337
./cli.sh \
  --project-file project/juice-shop.burp \
  --config-file user-config.json \
  --user-option-file user-options.json \
  --headless                                    # quan trọng!
```

* **–project-file**: nơi Burp lưu tiến trình & kết quả.
* **–user-option-file**: xuất ra từ GUI (User options → Misc → Export).
* API server lắng nghe tại **`http://127.0.0.1:1337/v0.1`** khi Burp khởi chạy thành công.

## 5. Ba “viên gạch” API chính

### 5.1 JSON‑Schema tổng quát

File [`burp_core_schema.json`](./burp_core_schema.json) mô tả **đầy đủ** tuỳ chọn & kiểu dữ liệu cho 3 endpoint quan trọng: `POST /scan`, `GET /scan/{id}`, `GET /knowledge_base/issue_definitions`.

> Trích đoạn rút gọn phần **body** gửi tới `/scan` (xem file để lấy bản đầy đủ):

```jsonc
{
  "scan": {
    "urls": ["String"],        // required
    "name": "String",
    "scope": {                  // SimpleScope | AdvancedScope
      "type": "AdvancedScope",
      "include": [ { … } ],
      "exclude": [ { … } ]
    },
    "application_logins": [ { … } ],
    "scan_configurations": [ { … } ],
    "resource_pool": "String",
    "scan_callback": { "url": "String" },
    "protocol_option": "httpAndHttps"|"specified"
  }
}
```

### 5.2 Ví dụ JSON end‑to‑end

File [`example_flow.json`](./example_flow.json) minh hoạ luồng:

1. **POST** `/scan` → **201** & `Location` header.
2. **GET** `/scan/{id}` → nhận `scan_status`, `issue_events`.
3. **GET** `/knowledge_base/issue_definitions` → ánh xạ `issue_type_id`.

*Trích đoạn mẫu:*

```jsonc
{
  "request": {
    "POST /scan": {
      "urls": ["https://juice-shop.lab"],
      "name": "Juice-Shop SQLi + XSS",
      "scan_configurations": [
        { "type": "NamedConfiguration", "name": "Audit checks – SQLi & XSS" }
      ]
    }
  },
  "server_response": {
    "status": 201,
    "headers": { "Location": "/v0.1/scan/8b9e…" }
  }
}
```

## 6. Quy trình mẫu

1. **Start Burp CLI** (`cli.sh`).
2. Gửi request tạo scan:

   ```bash
   curl -X POST http://127.0.0.1:1337/v0.1/scan \
        -H "Content-Type: application/json" \
        -d @create_scan.json -i
   ```
3. Lưu `scan_id` từ header `Location`.
4. Poll trạng thái:

   ```bash
   curl http://127.0.0.1:1337/v0.1/scan/$scan_id | jq
   ```
5. Khi `scan_status` = **succeeded**, gọi endpoint knowledge\_base để render report.

## 7. Tips & Best Practices

* Giới hạn tốc độ crawl (`crawl_limit`) để tránh bị WAF chặn.
* Xuất cấu hình từ Burp GUI thay vì viết tay chuỗi JSON dài.
* Sử dụng webhook (`scan_callback.url`) để push kết quả về Slack / Discord.

## 8. Tài liệu tham khảo

* [PortSwigger Automation Integration API Docs](https://portswigger.net/burp/documentation/enterprise/automated-scans/integration-api)
* Burp Blog – *Running Burp headless in CI pipelines*

---

> **Maintainer:** Ray Tran  •  Version 1.0
