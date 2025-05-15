import HealthKit
import Foundation

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var error: String?
    
    private init() {}
    
    // Request HealthKit authorization
    func requestAuthorization() {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.error = "HealthKit is not available on this device"
                print("HealthKit not available - running on simulator")
            }
            return
        }
        
        // Create the types we want to read
        var readTypes = Set<HKObjectType>()
        
        if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            readTypes.insert(stepCount)
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            readTypes.insert(heartRate)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            readTypes.insert(activeEnergy)
        }
        if let sleepAnalysis = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            readTypes.insert(sleepAnalysis)
        }
        
        // Request authorization
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    self?.error = error.localizedDescription
                    print("HealthKit authorization error: \(error)")
                }
                
                if success {
                    print("HealthKit authorized - starting data sync")
                    // Start fetching and sending data to backend
                    self?.startHealthDataSync()
                }
            }
        }
    }
    
    // Start syncing health data to backend
    private func startHealthDataSync() {
        // Fetch health data every hour and send to backend
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.fetchAndSendHealthData()
        }
        
        // Initial fetch
        fetchAndSendHealthData()
    }
    
    private func fetchAndSendHealthData() {
        var healthData: [String: Any] = [:]
        let group = DispatchGroup()
        
        // Fetch steps
        group.enter()
        fetchTodaySteps { steps in
            healthData["steps"] = steps
            group.leave()
        }
        
        // Fetch heart rate
        group.enter()
        fetchLatestHeartRate { heartRate in
            healthData["heartRate"] = heartRate
            group.leave()
        }
        
        // Fetch sleep
        group.enter()
        fetchLastNightSleep { hours in
            healthData["sleepHours"] = hours
            group.leave()
        }
        
        // When all data is fetched, send to backend
        group.notify(queue: .main) {
            self.sendToBackend(healthData)
        }
    }
    
    private func fetchTodaySteps(completion: @escaping (Int) -> Void) {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async {
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                completion(Int(steps))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHeartRate(completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            DispatchQueue.main.async {
                guard let sample = results?.first as? HKQuantitySample else {
                    completion(0)
                    return
                }
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                completion(heartRate)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLastNightSleep(completion: @escaping (Double) -> Void) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(0)
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            var totalSleep: TimeInterval = 0
            
            results?.forEach { sample in
                if let categorySample = sample as? HKCategorySample,
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSleep += categorySample.endDate.timeIntervalSince(categorySample.startDate)
                }
            }
            
            DispatchQueue.main.async {
                completion(totalSleep / 3600) // Convert to hours
            }
        }
        
        healthStore.execute(query)
    }
    
    private func sendToBackend(_ data: [String: Any]) {
        let username = UserDefaults.standard.string(forKey: "moodgpt_username") ?? "anonymous_user"
        
        // Add timestamp and username
        var healthActivity = data
        healthActivity["timestamp"] = ISO8601DateFormatter().string(from: Date())
        healthActivity["isSimulator"] = !HKHealthStore.isHealthDataAvailable()
        
        // Send to your activity API
        ActivityAPIClient.shared.logActivity(
            email: username,
            action: "healthDataSync",
            details: ["healthData": healthActivity]
        )
        
        print("Health data sent to backend: \(healthActivity)")
    }
}
