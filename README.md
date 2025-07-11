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

Script `cli.sh` (xem *scripts/cli.sh*) khởi động Burp Suite Professional ở chế độ headless.

```bash
#!/bin/bash
# ... rút gọn ...
JAVA_PATH="/usr/local/opt/openjdk@21/bin/java"
BURP_JAR="./burpsuite_pro_v2025.jar"
LOADER_JAR="./loader.jar"
PROJECT_FILE="./project/test.burp"
CONFIG_FILE="./user-config.json"
```

> **Lưu ý:** các biến môi trường ở đầu file (`JAVA_PATH`, `BURP_JAR`, `LOADER_JAR`, `PROJECT_FILE`, `CONFIG_FILE`) **phải chỉnh theo vị trí cài đặt thực tế** trên máy bạn. Ví dụ, nếu bạn cài OpenJDK qua `sdkman`, đường dẫn `JAVA_PATH` có thể là `/Users/you/.sdkman/candidates/java/current/bin/java`; hoặc nếu để file JAR trong thư mục khác, hãy sửa lại biến tương ứng.

### 4.1 Chạy script

```bash
chmod +x cli.sh
./cli.sh
```

Sau khi khởi chạy thành công, Burp sẽ hiển thị log tương tự:

```
Burp Suite Professional 2025.XX starting...
REST API listening on http://127.0.0.1:1337
```

### 4.2 Gọi API mẫu

Khi API server sẵn sàng (mặc định `http://127.0.0.1:1337/v0.1`), bạn có thể tạo một scan tối thiểu bằng cURL:

```bash
curl -X POST http://127.0.0.1:1337/v0.1/scan \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["http://testphp.vulnweb.com"]
  }'
```

Lệnh trên sẽ trả về **HTTP 201** cùng header `Location: /v0.1/scan/{scan_id}`—đó là ID của scan để bạn tiếp tục `GET /scan/{scan_id}` theo dõi tiến độ.

---

5. Ba “viên gạch” API chính

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
  }
}
```

### 5.3 CustomConfiguration & RecordedLogin

Burp hỗ trợ truyền **cấu hình quét tuỳ chỉnh** và **kịch bản đăng nhập đã ghi** theo hai trường dưới `POST /scan`:

| Trường                                                         | Kiểu                                      | Nguồn lấy file                                   |
| -------------------------------------------------------------- | ----------------------------------------- | ------------------------------------------------ |
| `scan_configurations[{ type: "CustomConfiguration", config }]` | **String** (nội dung JSON, XML hoặc YAML) | *Configuration Library → Export → Custom Scan*   |
| `application_logins[{ type: "RecordedLogin", label, script }]` | **String** (JSON)                         | Extension **Burp Recorder** → *Export Recording* |

> **Mẹo:** Burp yêu cầu **nội dung file** chứ không phải đường dẫn, vì vậy ta đọc file & chuyển thành chuỗi JSON an toàn bằng `jq`.

#### Ví dụ cURL full‑option

```bash
curl -vgw "
" -X POST "http://127.0.0.1:1337/v0.1/scan" \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["http://127.0.0.1:49222"],
    "scan_configurations": [
      {
        "type": "CustomConfiguration",
        "config": '"$(jq -c '.' SQLi.json | jq -Rs '.')"'
      }
    ],
    "application_logins": [
      {
        "type": "RecordedLogin",
        "label": "Login from record.json",
        "script": '"$(jq -c '.' record.json | jq -Rs '.')"'
      }
    ],
    "scope": {
      "type": "SimpleScope",
      "include": [{"rule": "http://127.0.0.1:49222/"}]
    }
  }'
```

##### Giải thích cú pháp `$(jq -c '.' file | jq -Rs '.')`

| Thành phần       | Chức năng                                                                                                                                                                                 |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `jq -c '.' file` | Đọc **file** rồi "compact" (`-c`) thành chuỗi JSON một dòng (loại bỏ khoảng trắng)                                                                                                        |
| `jq -Rs '.'`     | Đọc **stdin** ở dạng *raw string* (`-R`), sau đó bọc lại thành **JSON‑encoded string** (`-s '.'`). Điều này escape mọi ký tự đặc biệt (dấu nháy, xuống dòng) để chèn an toàn vào payload. |

Kết quả là biến shell `$( … )` trả về **chuỗi JSON hợp lệ** sẵn sàng ghép vào cURL mà không phải lo ký tự thoát.

---

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
