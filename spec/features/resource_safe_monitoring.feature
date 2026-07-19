Feature: 資源安全的背景監控 (Resource-safe Monitoring)

  Rule: 自動更新必須是 opt-in 且 single-flight
    Example: 首次安裝預設不啟動自動輪詢
      Given 使用者尚未設定自動更新偏好
      When 應用程式啟動時
      Then 自動更新應為停用
      And 儀表板只能執行一次初始的安全狀態讀取

    Example: 上一輪尚未完成時不重疊執行
      Given CLI refresh 正在執行
      When timer 或手動 refresh 再次觸發
      Then 不得啟動第二個 CLI refresh
      And 系統最多只能合併一個待執行 refresh

    Example: 視窗隱藏時停止背景工作
      Given 儀表板視窗正在顯示且自動更新已啟用
      When 使用者隱藏或關閉儀表板視窗
      Then 所有 refresh timer 應停止
      And 執行中的 refresh 應收到取消要求
      And 隱藏期間不得啟動新的 child process

    Example: 視窗重新顯示時只更新一次
      Given 儀表板視窗目前隱藏
      When 使用者重新顯示儀表板視窗
      Then scheduler 應只啟動一次
      And 儀表板應執行一次立即 refresh

    Example: 更新頻率變更立即生效
      Given 自動更新已啟用
      When 使用者變更 refresh interval
      Then scheduler 應取消舊排程
      And 新 interval 應在不重新啟動應用程式下生效

  Rule: 每個外部程序都必須有明確資源邊界
    Example: 直接執行已解析的 executable
      Given adapter 需要啟動外部 CLI
      When process runner 執行 probe
      Then runner 應使用 executable URL 與 argument array
      And runner 不得為每次 probe 啟動 login shell

    Example: 超時會終止程序
      Given probe 在 5 秒內沒有完成
      When timeout 到期
      Then runner 應終止該 process
      And probe 應回傳 "Timed Out"
      And timeout 後不得留下可觀測的 child process

    Example: 限制輸出大小
      Given probe 輸出超過 65536 bytes
      When runner 讀取輸出
      Then runner 最多只能保留 65536 bytes
      And probe 應回傳輸出被截斷的 metadata

    Example: 取消會終止程序
      Given probe 正在執行
      When refresh task 被取消
      Then runner 應終止該 process
      And 不得將取消結果發布為成功資料

  Rule: UI 只在資料實際改變時更新
    Example: 相同資料不重建 rows
      Given 新資料與目前顯示資料相同
      When refresh 完成
      Then view model 不應重新發布該 collection
      And tool、limit 與 MCP row 應保留穩定 identity
