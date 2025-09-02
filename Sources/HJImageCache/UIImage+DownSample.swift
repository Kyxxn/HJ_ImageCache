import UIKit
import ImageIO

extension UIImage {
    /// 이미지 데이터를 지정된 크기로 다운샘플링하여 새로운 UIImage를 생성합니다.
    /// - Parameters:
    ///   - imageData: 원본 이미지 데이터
    ///   - pointSize: 다운샘플링할 목표 크기 (포인트 단위)
    ///   - scale: 화면 스케일 (예: 2.0 또는 3.0)
    /// - Returns: 다운샘플링된 UIImage, 실패 시 nil
    static func downsampleImage(at imageData: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
}
