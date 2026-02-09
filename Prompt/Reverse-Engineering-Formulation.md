# Reverse-Engineering-Formulation.md
# 逆向工程規格萃取：從資料庫 Schema 與代碼產出規格模型

---
description: 針對遺留系統，從資料庫 Schema 與現有代碼逆向萃取 DDD 資料模型 (DBML) 與 BDD 功能模型 (Gherkin)，並產出事件風暴地圖
---

## 目標

從現有系統的**資料庫 Schema** 與**程式碼**中，逆向萃取並結構化為規格模型：
1. **資料模型 (Data Model)**：以 DBML 格式描述實體關係模型 (ERM)
2. **功能模型 (Functional Model)**：以 Gherkin Language 描述功能規格
3. **領域事件地圖 (Event Storming Map)**：識別領域邊界與聚合根

---

## 輸入來源

### 1. 資料庫 Schema SQL 檔案（必要）

- 路徑：專案指定的 Schema 目錄
- 提取內容：
  - `CREATE TABLE` 語句 → 表格結構
  - 欄位定義 → 屬性名稱、資料型別
  - `COMMENT` 註解 → 語義說明
  - `PRIMARY KEY` / `UNIQUE` → 唯一性約束
  - `INDEX` → 查詢最佳化線索
  - 外鍵欄位命名 (`xxx_id`) → 關聯推斷

### 2. 現有程式碼（輔助）

- 路徑：專案根目錄
- 分析內容：
  - PHP 檔案中的 SQL 查詢 → 業務邏輯推斷
  - 函數/方法名稱 → 功能識別
  - 條件判斷 → 業務規則萃取
  - 目錄結構 → 模組邊界識別

### 3. 現有文件（輔助）

- README.md、SDD 文件等
- 已有的 Feature 檔案
- 系統設定檔

---

## 執行步驟

### 階段一：資料庫 Schema 分析

#### 1.1 表格分類

掃描所有 `CREATE TABLE` 語句，依前綴或命名慣例分類：

**常見前綴對照表**：

| 前綴 | 領域 | 說明 |
|------|------|------|
| `WM_` | 核心平台 | 使用者、學校、系統設定 |
| `CO_` | 課程/MOOC | 課程、成員、擴充功能 |
| `APP_` | 行動應用 | APP 相關功能 |
| `QTI_` | 測驗系統 | 題庫、考試 |
| `BBS_` | 論壇系統 | 討論區、文章 |

**分類規則**：
1. 依前綴分組
2. 識別核心實體 vs 關聯表 vs 擴充表
3. 標記跨領域表格

#### 1.2 欄位語義萃取

針對每個欄位，從以下來源萃取語義（按優先順序）：

1. **COMMENT 註解**（最優先）
   ```sql
   `co_city` int(2) unsigned NOT NULL COMMENT '縣市代碼'
   ```

2. **欄位名稱推斷**
   - `xxx_id` → 外鍵或識別碼
   - `xxx_time` / `xxx_date` → 時間戳記
   - `is_xxx` / `can_xxx` → 布林值
   - `xxx_count` / `xxx_times` → 計數器

3. **資料型別推斷**
   - `enum('Y','N')` → 布林語義
   - `text` → 長文字內容
   - `datetime` → 時間戳記

4. **預設值推斷**
   - `DEFAULT '0'` → 計數器或狀態初始值
   - `DEFAULT 'N'` → 預設停用

#### 1.3 關係推斷

根據以下規則識別表格間關係：

**一對多 (1:N)**：
- 欄位名稱為 `xxx_id` 且對應其他表格主鍵
- 例如：`school_id` → 參照 `School.school_id`

**多對多 (M:N)**：
- 複合主鍵包含兩個外鍵欄位
- 例如：`PRIMARY KEY (username, course_id)`

**一對一 (1:1)**：
- 外鍵欄位同時為主鍵
- 或具有 `UNIQUE` 約束

#### 1.4 聚合根識別

識別聚合根的特徵：
1. 具有獨立主鍵（非複合）
2. 被其他表格參照
3. 代表核心業務概念
4. 具有生命週期管理需求

---

### 階段二：領域事件地圖產出

#### 2.1 領域邊界識別

根據表格分類結果，識別 Bounded Context：

```
【領域邊界範本】

┌─────────────────────────────────────────────────────────────────┐
│                     系統名稱 - 領域地圖                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐    ┌──────────────────┐                  │
│  │   領域 A         │    │    領域 B        │                  │
│  │  Context A       │    │  Context B       │                  │
│  ├──────────────────┤    ├──────────────────┤                  │
│  │ • Table_A1       │───▶│ • Table_B1       │                  │
│  │ • Table_A2       │    │ • Table_B2       │                  │
│  └──────────────────┘    └──────────────────┘                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 2.2 領域事件萃取

針對每個聚合根，識別可能的領域事件：

| 聚合根操作 | 對應事件 |
|------------|----------|
| 建立 (CREATE) | `XxxCreated` |
| 更新 (UPDATE) | `XxxUpdated` |
| 刪除 (DELETE) | `XxxDeleted` |
| 狀態變更 | `XxxStatusChanged` |
| 關聯建立 | `XxxAssociated` |

---

### 階段三：DBML 產出

依照 [`FormulationRules.md`](./FormulationRules.md) 的格式規範，將 Schema 轉換為 DBML。

#### 3.1 命名轉換規則

| SQL 命名 | DBML 命名 | 說明 |
|----------|-----------|------|
| `WM_all_account` | `Account` | 移除前綴，使用 PascalCase |
| `CO_all_course` | `Course` | 移除前綴，使用 PascalCase |
| `WM_sch4user` | `SchoolUser` | 語義化命名 |

#### 3.2 型別對應

| SQL 型別 | DBML 型別 |
|----------|-----------|
| `int`, `bigint`, `tinyint`, `smallint`, `mediumint` | `int` |
| `varchar`, `char`, `text`, `enum`, `set` | `string` |
| `float`, `double`, `decimal` | `float` |
| `date`, `datetime`, `timestamp` | `string` (備註格式) |
| `boolean`, `enum('Y','N')`, `tinyint(1)` | `bool` |

#### 3.3 DBML 輸出格式

```dbml
// spec/erm.dbml
// 系統名稱 - 資料模型
// 萃取來源：資料庫 Schema
// 萃取日期：YYYY-MM-DD

// ============================================
// 領域名稱 (Context Name)
// ============================================

Table EntityName [note: '''
實體說明（來自 COMMENT 或推斷）。
跨屬性不變條件：
- 條件 1
- 條件 2
'''] {
  field_name type [pk/unique, note: "欄位說明"]
  // ...
}

// 關聯定義
Ref: TableA.field > TableB.field
```

---

### 階段四：功能模型萃取

#### 4.1 從程式碼識別功能

掃描專案目錄結構，識別功能模組：

**目錄對應表（以 LMS 為例）**：

| 目錄 | 功能領域 | 使用者角色 |
|------|----------|------------|
| `learn/` | 學習功能 | 學生 |
| `teach/` | 教學功能 | 教師 |
| `academic/` | 學務管理 | 管理員 |
| `mooc/` | MOOC 平台 | 所有使用者 |
| `forum/` | 論壇討論 | 所有使用者 |
| `message/` | 訊息系統 | 所有使用者 |

#### 4.2 從 PHP 檔案萃取 Feature

針對每個 PHP 檔案，識別：

1. **功能名稱**：
   - 從檔案名稱推斷：`login.php` → 使用者登入
   - 從註解推斷
   - 從函數名稱推斷

2. **前置條件**：
   - Session 檢查 → 需登入
   - 權限驗證 → 需特定角色
   - 參數驗證 → 必填欄位

3. **後置條件**：
   - INSERT 語句 → 資料建立
   - UPDATE 語句 → 資料更新
   - DELETE 語句 → 資料刪除
   - Session 設定 → 狀態變更

#### 4.3 Feature 輸出格式

依照 [`FormulationRules.md`](./FormulationRules.md) 的 Gherkin 格式規範：

```gherkin
# spec/features/<中文功能簡稱>.feature

Feature: 功能名稱
  As a 使用者角色
  I want to 動作描述
  So that 目的說明

  Background:
    Given 共用前置條件

  Rule: 業務規則描述（原子化）

    Example: 正常情境
      Given 前置條件
      When 使用者操作
      Then 預期結果

    Example: 異常情境
      Given 前置條件
      When 使用者操作（違反規則）
      Then 操作失敗
```

---

## 輸出規格

### 檔案結構

```
spec/
├── erm.dbml                    # 完整資料模型
├── features/
│   ├── 使用者註冊.feature
│   ├── 使用者登入.feature
│   ├── 課程報名.feature
│   └── ...
└── event-storming/
    └── domain-map.md           # 領域事件地圖
```

### 命名規範

**DBML**：
- Table 名稱：PascalCase，移除前綴
- 欄位名稱：保留原始 snake_case
- Note：必須包含中文說明

**Feature**：
- 檔案名稱：`<中文功能簡稱>.feature`
- Feature 名稱：使用者視角的動作描述
- Rule：原子化的業務規則

---

## 核心原則

### 萃取原則

1. **只萃取 Schema 中存在的結構**
   - 不添加推測的欄位或關係
   - 不假設不存在的業務規則

2. **保留原始 COMMENT**
   - 將 SQL COMMENT 作為 note 的主要來源
   - COMMENT 不足時才進行推斷

3. **標記不確定項目**
   - 使用 `#TODO` 標記需進一步確認的規則
   - 在 note 中標註「推斷」來源

4. **逐步細化**
   - 先產出骨架結構
   - 透過 Discovery + Clarify 流程完善細節

### 與 Formulation 工具組整合

本 Prompt 產出的規格可無縫銜接：

1. **discovery.md**：掃描產出的 DBML + Feature，識別歧義與遺漏
2. **Clarify-and-translate.md**：互動式釐清，完善規格細節
3. **FormulationRules.md**：確保輸出格式符合規範

---

## 執行流程

```
┌─────────────────────────────────────────────────────────────────┐
│                        逆向工程執行流程                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  輸入                        處理                      輸出      │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐     │
│  │ 資料庫      │      │             │      │ spec/       │     │
│  │ Schema SQL  │ ───▶ │   本 Prompt  │ ───▶ │ erm.dbml    │     │
│  └─────────────┘      │             │      └─────────────┘     │
│  ┌─────────────┐      │             │      ┌─────────────┐     │
│  │ 程式碼      │ ───▶ │             │ ───▶ │ spec/       │     │
│  │ (PHP 等)    │      │             │      │ features/*  │     │
│  └─────────────┘      │             │      └─────────────┘     │
│  ┌─────────────┐      │             │      ┌─────────────┐     │
│  │ 現有文件    │ ───▶ │             │ ───▶ │ event-      │     │
│  │ (README等)  │      │             │      │ storming/   │     │
│  └─────────────┘      └─────────────┘      └─────────────┘     │
│                                                                 │
│  後續步驟                                                        │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐     │
│  │ spec/*      │ ───▶ │ discovery   │ ───▶ │ .clarify/   │     │
│  │             │      │ .md         │      │             │     │
│  └─────────────┘      └─────────────┘      └─────────────┘     │
│                              │                                  │
│                              ▼                                  │
│                       ┌─────────────┐      ┌─────────────┐     │
│                       │ Clarify-and │ ───▶ │ spec/       │     │
│                       │ -translate  │      │ (完善後)    │     │
│                       └─────────────┘      └─────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 範例：從 SQL 到 DBML

### 輸入（SQL Schema）

```sql
CREATE TABLE `WM_all_account` (
  `username` varchar(32) NOT NULL DEFAULT '',
  `password` varchar(32) NOT NULL DEFAULT '',
  `enable` enum('N','Y') NOT NULL DEFAULT 'N',
  `first_name` varchar(200) DEFAULT NULL,
  `last_name` varchar(200) DEFAULT NULL,
  `email` varchar(64) NOT NULL DEFAULT '',
  `co_city` int(2) unsigned NOT NULL COMMENT '縣市代碼',
  `co_isInd` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否是原住民',
  PRIMARY KEY (`username`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
```

### 輸出（DBML）

```dbml
Table Account [note: '''
使用者帳號，儲存個人資料與認證資訊。
'''] {
  username string [pk, note: "使用者名稱，唯一識別碼"]
  password string [note: "密碼，加密儲存"]
  enable string [note: "帳號狀態：'Y'=啟用, 'N'=停用，預設停用"]
  first_name string [note: "名字"]
  last_name string [note: "姓氏"]
  email string [note: "電子郵件"]
  co_city int [note: "縣市代碼"]
  co_isInd bool [note: "是否為原住民：0=否, 1=是"]
}
```

---

## 行為規則

1. **系統性掃描**：完整掃描所有表格，不遺漏
2. **一致性輸出**：所有 Table 使用相同格式
3. **語義優先**：優先使用 COMMENT，其次推斷
4. **標記未知**：不確定的語義使用 `#TODO` 標記
5. **保持精煉**：note 簡潔明確，避免冗長描述
6. **可追溯**：保留與原始 Schema 的對應關係
