import Foundation

public enum ImageLoaderError: LocalizedError {
    case decodingError(Error)
    case badServerResponse
    
    public var errorDescription: String? {
        switch self {
        case .decodingError(let error):
            return "이미지 디코딩 실패: \(error.localizedDescription)"
        case .badServerResponse:
            return "서버 응답 오류"
        }
    }
}
