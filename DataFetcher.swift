import Foundation

// MARK: - Data Models
struct MoodData: Decodable {
    let timeRange: String
    let emotion: String
    let icon: String
}

struct ThoughtData: Decodable {
    let thoughts: [String]
}

struct ForecastData: Codable {
    let day: String
    let emoji: String
    let label: String
    // Optional time-based fields for enhanced API
    let timeSegment: String?
    let hour: Int?
}

struct ForecastResponse: Codable {
    let forecasts: [ForecastData]
}

// MARK: - Network Error Type
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
}

// MARK: - DataFetcher
class DataFetcher: ObservableObject {
    static let shared = DataFetcher()
    
    private let baseURL = "http://44.202.137.205"
    
    @Published var moodData: [MoodData] = []
    @Published var thoughts: [String] = []
    
    func fetchData(for city: String) {
        fetchMoodData(for: city)
        fetchThoughts(for: city)
    }
    
    private func fetchMoodData(for city: String) {
        guard let url = URL(string: "\(baseURL)/mood?city=\(city)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([MoodData].self, from: data) {
                    DispatchQueue.main.async {
                        self.moodData = decoded
                    }
                }
            }
        }.resume()
    }
    
    private func fetchThoughts(for city: String) {
        guard let url = URL(string: "\(baseURL)/thoughts?city=\(city)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode(ThoughtData.self, from: data) {
                    DispatchQueue.main.async {
                        self.thoughts = decoded.thoughts
                    }
                }
            }
        }.resume()
    }
    
    // Generic fetch method to be used by other methods
    func fetch<T: Decodable>(endpoint: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decoded))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.decodingError))
                }
            }
        }.resume()
    }
    
    // Fetch mood forecast data with time segments
    func fetchMoodForecast(city: String, completion: @escaping (Result<[ForecastData], Error>) -> Void) {
        // Include current time to help server provide time-based forecasts
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        let currentHour = formatter.string(from: Date())
        
        let endpoint = "forecast?city=\(city)&hour=\(currentHour)"
        
        fetch(endpoint: endpoint) { (result: Result<ForecastResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.forecasts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
