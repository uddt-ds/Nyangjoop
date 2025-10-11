import Foundation

enum AchievementType: String, CaseIterable {
    case firstMeet = "묘험가"
    case catRadar = "고양이 레이더"
    case catDetector = "고양이 탐지기"
    case catDetective = "고양이 탐정"
    case humanCatnip = "인간캣잎"
    case goyangCitizen = "고양시민"
    case photographer = "사진 작가"
    case catServant = "고양이 집사"
    
    var description: String {
        switch self {
        case .firstMeet:
            return "고양이를 처음 만남"
        case .catRadar:
            return "고양이 10마리 등록"
        case .catDetector:
            return "고양이 20마리 등록"
        case .catDetective:
            return "고양이 50마리 등록"
        case .humanCatnip:
            return "고양이 200마리 등록"
        case .goyangCitizen:
            return "설정한 주소지가 고양시인 사람"
        case .photographer:
            return "사진 100장 등록"
        case .catServant:
            return "사진 1000장 등록"
        }
    }
    
    var imageName: String {
        switch self {
        case .firstMeet:
            return "cat"
        case .catRadar:
            return "rd"
        case .catDetector:
            return "finder"
        case .catDetective:
            return "hat"
        case .humanCatnip:
            return "leaf"
        case .goyangCitizen:
            return "goyang"
        case .photographer:
            return "camera"
        case .catServant:
            return "suit"
        }
    }
    
    var requirement: AchievementRequirement {
        switch self {
        case .firstMeet:
            return .catCount(1)
        case .catRadar:
            return .catCount(10)
        case .catDetector:
            return .catCount(20)
        case .catDetective:
            return .catCount(50)
        case .humanCatnip:
            return .catCount(200)
        case .goyangCitizen:
            return .address("고양시")
        case .photographer:
            return .photoCount(100)
        case .catServant:
            return .photoCount(1000)
        }
    }
}

enum AchievementRequirement {
    case catCount(Int)
    case photoCount(Int)
    case address(String)
}

struct Achievement {
    let type: AchievementType
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    init(type: AchievementType, isUnlocked: Bool = false, unlockedDate: Date? = nil) {
        self.type = type
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
}
