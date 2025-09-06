import Foundation

public protocol NetworkServiceProtocol: Sendable {
    func request(from url: URL) async throws -> Data
}

public struct NetworkService: NetworkServiceProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func request(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw ImageLoaderError.badServerResponse
        }
        
        return data
    }
}
