import Combine
import Foundation

/// Owns the dashboard's single refresh domain and visibility-aware scheduler.
@MainActor
final class DashboardViewModel: ObservableObject {
    typealias ToolFetcher = (Bool, Bool, Bool) async -> [ToolUsage]
    typealias MCPFetcher = () async -> [MCPConnection]
    typealias SchedulerSleep = (TimeInterval) async throws -> Void

    @Published private(set) var toolUsages: [ToolUsage] = []
    @Published private(set) var mcpConnections: [MCPConnection] = []
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private let defaults: UserDefaults
    private let toolFetcher: ToolFetcher
    private let mcpFetcher: MCPFetcher
    private let schedulerSleep: SchedulerSleep

    private var schedulerTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var refreshPending = false
    private var isWindowVisible = false
    private var settingsCancellable: AnyCancellable?

    init(
        defaults: UserDefaults = .standard,
        toolFetcher: @escaping ToolFetcher = { monitorGemini, monitorCodex, monitorClaude in
            await AICLIService.fetchSelected(
                monitorGemini: monitorGemini,
                monitorCodex: monitorCodex,
                monitorClaude: monitorClaude,
                runner: ProcessRunner.shared,
                locator: SystemExecutableLocator()
            )
        },
        mcpFetcher: @escaping MCPFetcher = {
            await MCPService.fetchAllConnections()
        },
        schedulerSleep: @escaping SchedulerSleep = { interval in
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    ) {
        self.defaults = defaults
        self.toolFetcher = toolFetcher
        self.mcpFetcher = mcpFetcher
        self.schedulerSleep = schedulerSleep

        settingsCancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification, object: defaults)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.settingsDidChange()
                }
            }
    }

    deinit {
        schedulerTask?.cancel()
        refreshTask?.cancel()
    }

    func setWindowVisible(_ visible: Bool) {
        guard visible != isWindowVisible else { return }
        isWindowVisible = visible

        if visible {
            requestRefresh()
            restartScheduler()
        } else {
            stopBackgroundWork()
        }
    }

    func requestRefresh() {
        guard isWindowVisible else { return }

        if refreshTask != nil {
            refreshPending = true
            return
        }

        isLoading = true
        lastError = nil
        let monitorGemini = defaults.object(forKey: "monitorGemini") as? Bool ?? true
        let monitorCodex = defaults.object(forKey: "monitorCodex") as? Bool ?? true
        let monitorClaude = defaults.object(forKey: "monitorClaude") as? Bool ?? true

        refreshTask = Task { [weak self] in
            guard let self else { return }

            async let tools = toolFetcher(monitorGemini, monitorCodex, monitorClaude)
            async let connections = mcpFetcher()
            let values = await (tools, connections)

            guard !Task.isCancelled else {
                refreshDidFinish(cancelled: true)
                return
            }

            if toolUsages != values.0 {
                toolUsages = values.0
            }
            if mcpConnections != values.1 {
                mcpConnections = values.1
            }

            lastUpdated = Date()
            if values.0.contains(where: { $0.status == "Error" || $0.status == "Timed Out" }) {
                lastError = "部分工具無法安全完成狀態檢查"
            }
            refreshDidFinish(cancelled: false)
        }
    }

    private var autoRefreshEnabled: Bool {
        defaults.object(forKey: "autoRefreshEnabled") as? Bool ?? false
    }

    private var refreshInterval: TimeInterval {
        let configured = defaults.object(forKey: "refreshInterval") as? Double ?? 120
        return min(600, max(60, configured))
    }

    private func settingsDidChange() {
        guard isWindowVisible else { return }
        requestRefresh()
        restartScheduler()
    }

    private func restartScheduler() {
        schedulerTask?.cancel()
        schedulerTask = nil

        guard isWindowVisible, autoRefreshEnabled else { return }
        let interval = refreshInterval

        schedulerTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await schedulerSleep(interval)
                } catch {
                    return
                }

                guard !Task.isCancelled, let self, self.isWindowVisible else { return }
                self.requestRefresh()
            }
        }
    }

    private func stopBackgroundWork() {
        schedulerTask?.cancel()
        schedulerTask = nil
        refreshPending = false
        refreshTask?.cancel()
    }

    private func refreshDidFinish(cancelled: Bool) {
        refreshTask = nil
        isLoading = false

        let shouldRunPendingRefresh = refreshPending && isWindowVisible
        refreshPending = false
        if shouldRunPendingRefresh {
            requestRefresh()
        } else if cancelled {
            lastError = nil
        }
    }
}
