//
//  FileManager+ImageStorage.swift
//  Nyangjoop
//
//  Created by Lee on 9/30/25.
//

import UIKit

extension FileManager {
    
    /// Documents 디렉토리 경로
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// 이미지를 Documents 디렉토리에 저장
    static func saveImage(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> String? {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        let fileName = "cat_\(UUID().uuidString).jpg"
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: filePath)
            return fileName
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }
    
    /// Documents 디렉토리에서 이미지 불러오기
    static func loadImage(fileName: String) -> UIImage? {
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: filePath.path)
    }
    
    /// Documents 디렉토리에서 이미지 삭제
    static func deleteImage(fileName: String) -> Bool {
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: filePath)
            return true
        } catch {
            print("이미지 삭제 실패: \(error)")
            return false
        }
    }
    
    /// 파일명에서 전체 경로 생성
    static func getImagePath(fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent(fileName)
    }
}
