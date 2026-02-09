# 網站專案技術選型

## 系統架構

本專案採用現代化的 Web 應用程式技術棧，基於容器化部署架構。

## 技術棧詳細規格

### 容器化與基礎設施
- **Docker**: 容器化部署平台
- **Nginx**: 1.28 - Web 伺服器與反向代理

### 資料庫與快取
- **MariaDB**: 10.11 - 關聯式資料庫管理系統
- **Redis**: 7 - 記憶體快取與資料結構儲存

### 後端技術
- **PHP**: 8.4.15 - 伺服器端程式語言
- **Laravel**: 12 - PHP Web 應用程式框架

### 前端技術
- **Bootstrap**: 5.3.8 - CSS 框架與 UI 元件庫
- **jQuery**: 3.7.1 - JavaScript 函式庫

## 版本相容性說明

### PHP 8.4.15
- 支援最新的 PHP 語法與效能優化
- 完整支援 Laravel 12 框架
- 提供更好的型別系統與錯誤處理

### Laravel 12
- 最新版本的 Laravel 框架
- 支援 PHP 8.4 新特性
- 提供現代化的 MVC 架構與豐富的生態系統

### Bootstrap 5.3.8
- 不依賴 jQuery（但本專案仍保留 jQuery 支援）
- 提供響應式網格系統與 UI 元件
- 支援深色模式與自訂主題

### MariaDB 10.11
- MySQL 的分支，提供更好的效能與相容性
- 支援完整的 ACID 事務
- 與 Laravel Eloquent ORM 完美整合

### Redis 7
- 高效能記憶體資料庫
- 用於 Session 儲存、快取與佇列管理
- 支援 Laravel Cache 與 Queue 驅動

## 部署架構

```
┌─────────────────────────────────────────┐
│            Docker Container             │
├─────────────────────────────────────────┤
│  Nginx 1.28 (Web Server)                │
│  ├── PHP 8.4.15 (FPM)                   │
│  │   └── Laravel 12 Application         │
│  │       ├── Bootstrap 5.3.8 (Frontend) │
│  │       └── jQuery 3.7.1 (Frontend)    │
│  │                                       │
│  ├── MariaDB 10.11 (Database)           │
│  └── Redis 7 (Cache/Queue/Session)      │
└─────────────────────────────────────────┘
```

## 開發環境需求

### 必要軟體
- Docker Desktop (或 Docker Engine + Docker Compose)
- Git
- 任何現代化的程式碼編輯器（推薦 VS Code 或 PhpStorm）

### 推薦工具
- Composer (PHP 套件管理)
- npm 或 yarn (前端套件管理)
- Laravel Sail (Laravel 官方 Docker 開發環境)

## 相依套件版本管理

### Composer (PHP 套件)
```json
{
  "require": {
    "php": "^8.4",
    "laravel/framework": "^12.0"
  }
}
```

### NPM (前端套件)
```json
{
  "dependencies": {
    "bootstrap": "^5.3.8",
    "jquery": "^3.7.1"
  }
}
```

## 安全性考量

### PHP 8.4.15
- 定期更新以修補安全漏洞
- 啟用 OPcache 以提升效能
- 適當設定 php.ini 安全參數

### Laravel 12
- 內建 CSRF 保護機制
- 支援 bcrypt/Argon2 密碼雜湊
- SQL 注入防護（Eloquent ORM）
- XSS 防護（Blade 模板引擎）

### Nginx 1.28
- 設定 HTTPS/SSL 證書
- 設定安全標頭（CSP, HSTS 等）
- 限流與防 DDoS 配置

### MariaDB 10.11
- 使用強密碼與限制遠端存取
- 定期備份資料庫
- 使用預備陳述式（Prepared Statements）

### Redis 7
- 設定密碼驗證
- 限制綁定 IP 位址
- 禁用危險指令（FLUSHALL, FLUSHDB 等）

## 效能優化建議

### 後端優化
- 啟用 Laravel 快取（Config, Route, View Cache）
- 使用 Redis 作為 Session 與 Cache 驅動
- 啟用 OPcache 與 JIT 編譯器
- 資料庫查詢優化（Eager Loading, 索引）

### 前端優化
- 壓縮 CSS 與 JavaScript 檔案
- 使用 CDN 載入 Bootstrap 與 jQuery（生產環境）
- 圖片優化與延遲載入
- 啟用瀏覽器快取

### Docker 優化
- 使用多階段建構（Multi-stage Build）
- 優化映像檔大小
- 使用 Docker Compose 管理多容器服務

## 測試框架

### 後端測試
- **Pest**: Laravel 推薦的測試框架
- **PHPUnit**: 傳統的 PHP 測試框架（Pest 基於此）

### 前端測試
- **Jest**: JavaScript 單元測試
- **Laravel Dusk**: 瀏覽器自動化測試

## 持續整合/持續部署 (CI/CD)

### 推薦工具
- GitHub Actions
- GitLab CI/CD
- Jenkins
- Docker Hub / GitHub Container Registry

### 部署流程
1. 程式碼推送至 Git 倉庫
2. 自動執行測試套件
3. 建構 Docker 映像檔
4. 推送至容器註冊中心
5. 部署至生產環境（使用 Docker Compose 或 Kubernetes）

## 文件版本

- **建立日期**: 2025-12-08
- **最後更新**: 2025-12-08
- **文件版本**: 1.0

## 參考資源

### 官方文件
- [Laravel 12 Documentation](https://laravel.com/docs/12.x)
- [PHP 8.4 Documentation](https://www.php.net/manual/en/)
- [Bootstrap 5.3 Documentation](https://getbootstrap.com/docs/5.3/)
- [jQuery 3.7 Documentation](https://api.jquery.com/)
- [MariaDB 10.11 Documentation](https://mariadb.com/kb/en/mariadb-10-11/)
- [Redis 7 Documentation](https://redis.io/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Documentation](https://docs.docker.com/)

### 生態系統資源
- [Laravel News](https://laravel-news.com/)
- [Laracasts](https://laracasts.com/)
- [Packagist](https://packagist.org/) - Composer 套件倉庫
- [npm Registry](https://www.npmjs.com/) - Node.js 套件倉庫

---

**注意**: 所有版本號碼應定期檢查更新，以確保安全性與相容性。建議訂閱各官方發布通知，以即時獲取安全性更新資訊。
