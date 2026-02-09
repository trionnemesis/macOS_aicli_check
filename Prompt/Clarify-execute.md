---
description: 執行 WM5_NOU_LTC 專案釐清任務的 prompt，根據 Clarify-and-translate.md 的流程，優先嘗試自動解答，再進行互動式問答。
target_project: WM5_NOU_LTC
---

請依照 @Prompt/Clarify-and-translate.md 的流程，針對 **@WM5_NOU_LTC/** 專案執行以下釐清任務，**並在提問前先嘗試從現有資源自動解答**：

## 任務目標
根據 Discovery 階段產出的釐清項目，透過**自動解答**與**互動式問答**流程逐一釐清，並將釐清結果即時整合回規格檔案中。

## 目標專案

**WM5_NOU_LTC/**

## 輸入來源

1. **釐清策略檔案**：
   - `WM5_NOU_LTC/spec/.clarify/overview.md`

2. **釐清項目檔案**：
   - `WM5_NOU_LTC/spec/.clarify/data/*.md`（資料模型相關）
   - `WM5_NOU_LTC/spec/.clarify/features/*.md`（功能模型相關）

3. **已解決項目**（需排除）：
   - `WM5_NOU_LTC/spec/.clarify/resolved/data/*.md`
   - `WM5_NOU_LTC/spec/.clarify/resolved/features/*.md`

4. **現有規格檔案**（需更新）：
   - `WM5_NOU_LTC/spec/erm.dbml`
   - `WM5_NOU_LTC/spec/features/*.feature`

5. **自動解答來源**（依優先級排序）：
   - `WM5_NOU_LTC/spec/functional-map/module-database-mapping.md`（**最優先：資料模型映射表**）
   - `WM_schema/WM_10001.sql`（SQL Schema 的 COMMENT 註解）
   - `WM_schema/WM_MASTER.sql`（SQL Schema 的 COMMENT 註解）
   - `WM5_NOU_LTC/spec/erm.dbml`（現有規格中的相關說明）
   - `WM5_NOU_LTC/` 目錄下的 PHP 程式碼（註解、函數名稱、SQL 查詢）

## 執行步驟

### 階段 0：初始化載入

1. **讀取釐清策略**：載入 `WM5_NOU_LTC/spec/.clarify/overview.md`
2. **載入釐清項目**：依照建議順序讀取 `WM5_NOU_LTC/spec/.clarify/data/*.md` 和 `WM5_NOU_LTC/spec/.clarify/features/*.md`
3. **載入現有規格**：載入 `WM5_NOU_LTC/spec/erm.dbml` 和 `WM5_NOU_LTC/spec/features/*.feature`
4. **載入自動解答來源**：
   - **資料模型映射表**：載入 `WM5_NOU_LTC/spec/functional-map/module-database-mapping.md`（優先查詢來源）
   - **SQL Schema**：載入 `WM_schema/WM_10001.sql` 和 `WM_schema/WM_MASTER.sql`
   - **程式碼索引**：建立 `WM5_NOU_LTC/` 目錄下的表格名稱 → 關聯表對照索引

### 階段 1：自動解答（互動前執行）

**在提問前，先嘗試從現有資源自動解答每個釐清項目**：

#### 1.1 自動解答查詢順序

針對每個釐清項目，**依序**查詢以下來源：

1. **資料模型映射表**（最優先）：
   - 查詢 `WM5_NOU_LTC/spec/functional-map/module-database-mapping.md` 中的「關聯表」欄位
   - 若釐清項目為「XXX_field_關聯實體為何」，直接從映射表取得答案
   - **置信度：高**

2. **SQL Schema COMMENT**：
   - 查詢 `WM_schema/WM_10001.sql` 和 `WM_schema/WM_MASTER.sql`
   - 提取對應表格/欄位的 `COMMENT` 註解
   - **置信度：高**

3. **現有規格檔案**：
   - 查詢 `WM5_NOU_LTC/spec/erm.dbml` 中該實體的 note 說明
   - 查詢 `WM5_NOU_LTC/spec/features/*.feature` 中相關功能的說明
   - **置信度：高**

4. **推論規則**：
   - 套用命名慣例、欄位名稱自明規則（見 1.2 節）
   - **置信度：中-高**（依規則而定）

5. **程式碼分析**：
   - 搜尋 `WM5_NOU_LTC/` 目錄下程式碼中的 JOIN 查詢、函數名稱、註解
   - **置信度：中**（需有明確證據）

#### 1.2 增強推論規則

##### A. 命名慣例推論規則（適用於「XXX_field_關聯實體為何」）

| 欄位名稱模式 | 推論目標實體 | 置信度 |
|-------------|-------------|--------|
| `course_id` | `Course` / `TermCourse` | 高 |
| `class_id` | `ClassMain` | 高 |
| `board_id` | `BbsBoard` | 高 |
| `school_id` / `school` | `School` | 高 |
| `username` | `Account`（作為外鍵時） | 高 |
| `creator` | `Account` | 高 |
| `examinee` | `Account` | 高 |
| `poster` | `Account` | 高 |
| `exam_id` | `ExamTest` / `HomeworkTest` / `QuestionnaireTest` | 中 |
| `time_id` | 對應的 `*Test` 表 | 中 |
| `node` + `site` | `BbsPost`（複合外鍵） | 高 |
| `parent` + `child` | 自關聯或同類表關聯 | 中 |
| `xxx_id`（通用） | `Xxx` 或 `XxxMain` | 中 |

**驗證步驟**：使用 `grep` 搜尋 `WM5_NOU_LTC/` 程式碼中的 JOIN 或 WHERE 條件來驗證推論。

##### B. 欄位名稱自明規則（適用於「XXX_field_欄位用途為何」）

| 欄位名稱 | 直接答案 | 置信度 |
|---------|---------|--------|
| `birthday` | 生日 | 高 |
| `email` | 電子郵件 | 高 |
| `password` / `passwd` | 密碼 | 高 |
| `username` | 使用者帳號 | 高 |
| `first_name` | 名 | 高 |
| `last_name` | 姓 | 高 |
| `realname` | 真實姓名 | 高 |
| `cell_phone` | 手機號碼 | 高 |
| `home_tel` / `office_tel` | 住家電話 / 辦公電話 | 高 |
| `home_address` / `office_address` | 住家地址 / 辦公地址 | 高 |
| `content` | 內容 | 高 |
| `subject` / `title` / `caption` | 標題/名稱 | 高 |
| `create_time` / `add_time` / `reg_time` | 建立時間 | 高 |
| `update_time` / `upd_time` / `modify_time` | 更新時間 | 高 |
| `begin_time` / `open_time` / `start_time` | 開始時間 | 高 |
| `end_time` / `close_time` | 結束時間 | 高 |
| `enable` | 啟用狀態 | 高 |
| `status` / `state` | 狀態 | 高 |
| `score` | 分數 | 高 |
| `comment` | 評語/備註 | 高 |
| `permute` | 排序順序 | 高 |
| `hit` | 點閱次數 | 高 |
| `attach` | 附件 | 高 |
| `ip` / `ip_addr` / `remote_address` | IP 位址 | 高 |
| `lang` / `language` | 語言設定 | 高 |
| `gender` | 性別 | 高 |
| `role` | 角色 | 高 |
| `level` | 等級/層級 | 高 |
| `quota_*` | 配額相關 | 高 |
| `login_times` / `post_times` / `dsc_times` | 登入/發文/討論次數 | 高 |

##### C. 複合主鍵關聯規則

當表格有複合主鍵時：
- 複合主鍵中的 `xxx_id` 欄位通常是外鍵
- 範例：`ClassDirector` 主鍵為 `username + class_id`
  - `username` → 關聯 `Account`
  - `class_id` → 關聯 `ClassMain`
- **置信度：高**（若映射表有對應記錄）

##### D. 主鍵判斷規則

若欄位為該表的 PRIMARY KEY：
- 回答為「主鍵，不關聯其他實體，而是被其他實體關聯」
- 範例：`Account.username` 是主鍵
- **置信度：高**

#### 1.3 自動解答判斷標準

**可直接自動解答的情況**：
- `module-database-mapping.md` 中有明確的關聯表定義
- SQL Schema 中有明確的 `COMMENT` 註解
- 現有規格檔案中已有相關說明
- 程式碼中有明確的註解說明
- 欄位名稱符合「欄位名稱自明規則」表格
- 欄位名稱符合「命名慣例推論規則」且有程式碼使用模式驗證
- 複合主鍵中的欄位符合外鍵命名慣例

**需要互動式釐清的情況**：
- 程式碼中找不到相關使用 **且** 無法套用任何推論規則
- 有多種可能的解釋，無法從程式碼或命名慣例判斷
- 涉及業務規則的判斷（如「是否允許負值」「邊界條件」）
- 推論結果置信度為「低」的情況

#### 1.4 自動解答結果處理

對於可自動解答的項目：
1. **直接更新規格檔案**：
   - 資料模型問題 → 更新 `WM5_NOU_LTC/spec/erm.dbml` 的 note 或關聯定義
   - 功能模型問題 → 更新 `WM5_NOU_LTC/spec/features/*.feature` 的 Rule 或 Example
2. **標記為已解決**：
   - 將釐清項目移至 `WM5_NOU_LTC/spec/.clarify/resolved/` 目錄
   - 更新 `WM5_NOU_LTC/spec/.clarify/overview.md` 的統計數字
   - 在 resolved 檔案中註記解決記錄，格式如下：

```markdown
---
# 解決記錄

- **回答**：<自動推論的答案>
- **更新的規格檔**：<WM5_NOU_LTC/spec/erm.dbml 或 WM5_NOU_LTC/spec/features/*.feature>
- **變更內容**：<簡述規格檔的變更內容>
- **自動解答來源**：<映射表 / SQL COMMENT / 命名慣例 / 欄位名稱自明 / 程式碼 / 現有規格>
- **置信度**：<高 / 中>
```

對於無法自動解答的項目：
- 保留在待處理佇列中
- 進入階段 2 的互動式問答流程

### 階段 2：互動式問答（僅處理無法自動解答的項目）

僅對無法從現有資源自動解答的釐清項目進行互動式問答：

1. **建立釐清佇列**：僅包含無法自動解答的項目
2. **逐題提問**：按照原有流程進行互動式問答
3. **即時整合**：每個答案接受後立即更新 `WM5_NOU_LTC/` 專案的規格檔案

### 階段 3：驗證與報告

完成所有釐清後：
1. **統計報告**：
   - 自動解答項目數量（其中高置信度 H 項，中置信度 M 項）
   - 互動式解答項目數量
   - 跳過項目數量
2. **驗證完整性**：
   - 檢查 `WM5_NOU_LTC/spec/` 下所有規格檔案是否已更新
   - 確認所有釐清項目都已處理或歸檔

## 自動解答範例

### 範例 1：從映射表自動解答

**釐清項目**：`ClassDirector_class_id_關聯實體為何.md`

**自動解答流程**：
1. 查詢 `WM5_NOU_LTC/spec/functional-map/module-database-mapping.md`
2. 找到 `WM_class_director` 的關聯表為 `WM_class_main, WM_all_account`
3. 比對 `class_id` → 對應 `WM_class_main` → 實體為 `ClassMain`
4. **自動解答**：關聯 ClassMain，置信度：高
5. 更新 `WM5_NOU_LTC/spec/erm.dbml` 的 Ref 定義
6. 將釐清項目移至 `WM5_NOU_LTC/spec/.clarify/resolved/data/`，註記來源為「映射表」

### 範例 2：從欄位名稱自明規則解答

**釐清項目**：`Account_birthday_欄位用途為何.md`

**自動解答流程**：
1. 查詢欄位名稱自明規則表格
2. `birthday` 對應「生日」，置信度：高
3. **自動解答**：生日
4. 更新 `WM5_NOU_LTC/spec/erm.dbml` 的 note
5. 將釐清項目移至 `WM5_NOU_LTC/spec/.clarify/resolved/data/`，註記來源為「欄位名稱自明」

### 範例 3：從命名慣例 + 程式碼驗證

**釐清項目**：`BbsPost_board_id_關聯實體為何.md`

**自動解答流程**：
1. 套用命名慣例：`board_id` → 可能關聯 `BbsBoard`
2. 使用 `grep` 在 `WM5_NOU_LTC/` 驗證：搜尋 `bbs_post.*JOIN.*bbs_board` 或 `board_id = bbs_board`
3. 找到程式碼中的使用模式，確認關聯
4. **自動解答**：關聯 BbsBoard，置信度提升為高
5. 更新規格並歸檔

### 範例 4：主鍵判斷

**釐清項目**：`Account_username_關聯實體為何.md`

**自動解答流程**：
1. 查詢 `WM5_NOU_LTC/spec/erm.dbml`，發現 Account.username 是主鍵 `[pk]`
2. 查詢 SQL Schema，確認 `WM_all_account.username` 是 PRIMARY KEY
3. **自動解答**：主鍵，不關聯其他實體，而是被其他實體關聯
4. 將釐清項目移至 `WM5_NOU_LTC/spec/.clarify/resolved/data/`，註記來源為「主鍵判斷」

## 輸出要求

1. **自動解答報告**：
   - 列出所有自動解答的項目及來源
   - 標記自動解答的置信度（高/中）

2. **更新後的規格檔案**：
   - `WM5_NOU_LTC/spec/erm.dbml`
   - `WM5_NOU_LTC/spec/features/*.feature`

3. **已解決項目記錄**：
   - 自動解答的項目移至 `WM5_NOU_LTC/spec/.clarify/resolved/` 並註記來源與置信度
   - 互動式解答的項目移至 `WM5_NOU_LTC/spec/.clarify/resolved/`

4. **更新後的總覽**：
   - 更新 `WM5_NOU_LTC/spec/.clarify/overview.md` 的統計數字

## 注意事項

- **映射表最優先**：`WM5_NOU_LTC/spec/functional-map/module-database-mapping.md` 是最可靠的關聯來源
- **推論規則需驗證**：使用命名慣例時，須用 `grep` 搜尋 `WM5_NOU_LTC/` 程式碼驗證
- **置信度門檻**：僅當置信度為「高」或「中」時才可自動解答
- **保持術語一致**：自動解答時使用 `WM5_NOU_LTC/spec/` 規格檔案中已定義的繁體中文術語
- **記錄解答來源**：在 resolved 檔案中註記自動解答的來源與置信度
- **批量處理**：自動解答階段可一次處理多個項目，減少互動負擔
- **驗證答案正確性**：自動解答後，若發現矛盾或不明確，仍可進入互動式釐清
