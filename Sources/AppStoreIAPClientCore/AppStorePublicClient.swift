import Foundation

public struct AppStorePublicClient: Sendable {
    public init() {}

    public func search(term: String, countryCode: String = "US") async throws -> [AppSearchResult] {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "country", value: countryCode),
            URLQueryItem(name: "entity", value: "software"),
            URLQueryItem(name: "limit", value: "20")
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response.results.map { item in
            AppSearchResult(
                appId: String(item.trackId),
                name: item.trackName,
                developerName: item.artistName,
                bundleId: item.bundleId,
                primaryGenre: item.primaryGenreName,
                sourceCountry: countryCode
            )
        }
    }

    public func lookup(appId: String, countryCode: String) async throws -> AppSearchResult? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: appId),
            URLQueryItem(name: "country", value: countryCode)
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response.results.first.map { item in
            AppSearchResult(
                appId: String(item.trackId),
                name: item.trackName,
                developerName: item.artistName,
                bundleId: item.bundleId,
                primaryGenre: item.primaryGenreName,
                sourceCountry: countryCode
            )
        }
    }

    private struct SearchResponse: Decodable {
        let results: [SearchItem]
    }

    private struct SearchItem: Decodable {
        let trackId: Int
        let trackName: String
        let artistName: String
        let bundleId: String?
        let primaryGenreName: String?
    }
}
