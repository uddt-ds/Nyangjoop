# 🐱 냥냥 (Nyangnyang)

## 📚 목차
1. [프로젝트 소개](#project-intro)
2. [주요기능](#features)
3. [개발기간](#duration)
4. [기술스택](#tech-stack)
5. [기술적 의사결정](#tech-decision)
6. [프로젝트 구조](#project-structure)
7. [샘플이미지](#sample-images)



<a id="project-intro"></a>
## 🌤 프로젝트 소개

- 냥냥은 길고양이를 좋아하는 사람들을 위한 고양이 등록 및 기록 앱입니다.
- 길고양이를 발견한 위치, 사진, 성격 등을 기록하고 지도에서 쉽게 확인할 수 있습니다.
- 고양이별 방문 일지를 작성하여 같은 고양이를 다시 만났을 때의 추억을 기록할 수 있습니다.
- 업적 시스템을 통해 집사로서의 활동을 재미있게 추적할 수 있습니다.

<a id="features"></a>
## 🛠 주요기능

### 길고양이 등록 기능 (사진, 위치, 특징 등)
- **사진 촬영/선택**: 카메라 또는 앨범에서 고양이 사진 선택
- **EXIF 메타데이터 추출**: 사진의 촬영 날짜 자동 추출하여 발견 날짜로 설정
- **위치 정보 기록**: 지도에서 고양이를 발견한 위치 선택 및 주소 자동 변환
- **상세 정보 입력**: 이름, 성별, 성격, 발견 날짜 기록
- **지도 아이콘 설정**: 귀여운 고양이 아이콘으로 지도에 표시

### 현 위치 기반 고양이 위치, 간식가게 조회
- **MapKit 기반 실시간 지도**: 등록된 고양이 위치를 지도에 마커로 표시
- **클러스터링 기능**: 가까운 위치의 고양이들을 자동 그룹화하여 지도 가독성 향상
- **마커 터치 시 고양이 상세 정보**: 지도 마커 선택 시 고양이 이름, 사진, 특징 확인
- **현재 위치 기반 검색**: GPS를 활용한 주변 고양이 및 간식가게 위치 탐색

### 고양이 모아보기(갤러리)
- **사진 앨범**: 고양이별 방문 사진을 Waterfall 레이아웃으로 시각적으로 표시
- **방문 일지 작성**: 같은 고양이를 다시 만났을 때 사진과 메모 추가
- **시간순 정렬**: 최신 방문 기록부터 확인 가능
- **방문 횟수 추적**: 각 고양이별 만난 횟수 기록

### 커스텀 카메라
- **AVFoundation 기반 카메라**: 커스텀 카메라 UI 구현
- **실시간 프리뷰**: 촬영 전 실시간 카메라 프리뷰
- **사진 편집 기능**: 촬영 후 스티커 추가 및 편집
- **UIGraphicsImageRenderer를 통한 이미지 렌더링**: 편집된 이미지 고품질 렌더링

### 광고 (배너 / 전면 / 리워드)
- **전면 광고**: 고양이 등록 4회당 1번 표시
- **배너 광고**: 프로필 화면 하단 배너 표시
- **리워드 광고**: 광고 시청 후 보상 제공

### 인앱 결제
- **광고 제거**: StoreKit 2 기반 인앱 결제로 전면 광고 제거
- **구매 복원**: 재설치 시 구매 내역 복원 기능
- **영수증 검증**: 앱 스토어 영수증 검증으로 구매 안전성 확보

### 푸시 알림
- **FCM을 통한 원격 푸시 알림**: Firebase Cloud Messaging 기반 푸시 알림 수신
- **푸시 알림 타입별 처리**: PushNotificationManager로 푸시 처리 로직 중앙화
- **사용자 경험 개선**: 앱 실행 중이거나 Background/Foreground 상태별 푸시 알림 정책

<a id="duration"></a>
## 📅 개발기간

| 버전 | 기간 | 주요 변경 내용 |
| --- | --- | --- |
| V1.0 | 2025.09.25 ~ 2025.10.06 | • 고양이 등록 및 관리 기능 구현<br>• 지도 기반 탐색 기능 구현<br>• 방문 기록 관리 기능 구현<br>• 프로필 및 업적 시스템 구현<br>• AdMob 광고 연동 |
| V1.1 | 2025.10.06 ~ 진행중 | • 인앱 결제 (광고 제거) 기능 구현 |

<a id="tech-stack"></a>
## ⚙️ 기술스택

### 개발환경

| 구분 | 비고 |
|-------------|--------------------------------------|
| Swift 5.0 | iOS 앱 개발을 위한 프로그래밍 언어 |
| iOS 16.0+ | Minimum Deployment Target |
| Xcode 15.0+ | 통합 개발 환경 |

### 사용 패턴

| 구분 | 패턴 | 비고 |
|-------------|-------------------------------------|------|
| 아키텍처 | MVVM + Input/Output Pattern | • ViewModel의 transform 메서드를 통한 Input → Output 단방향 데이터 흐름<br>• RxSwift를 활용한 반응형 데이터 바인딩<br>• 비즈니스 로직과 UI 완전 분리 |
| 디자인 패턴 | Singleton Pattern | • 전역 매니저 클래스 (RealmManager, LocationManager, NetworkManager 등) |
| 프로토콜 지향 | ViewModelProtocol | • Input/Output 구조를 강제하는 프로토콜 기반 설계 |

### UI 구성

| 구분 | 비고 |
|---------|----------------------------------------------------|
| UIKit | iOS 기본 UI 프레임워크 |
| MapKit | 지도 표시 및 위치 기반 서비스 구현 |
| PhotosUI | 사진 선택 및 EXIF 메타데이터 추출 |
| [SnapKit 5.7.1](https://github.com/SnapKit/SnapKit) | Auto Layout을 간결하게 작성할 수 있는 DSL |

### 데이터 & 저장

| 구분 | 비고 |
|--------|-------------------------------------|
| [RealmSwift 10.0+](https://github.com/realm/realm-swift) | 로컬 데이터베이스 (고양이 정보, 방문 기록 저장) |
| UserDefaults | 간단한 설정 값 저장 (닉네임, 업적 카운터 등) |
| FileManager | 이미지 파일 로컬 저장 및 관리 |

### 네트워크

| 구분 | 비고 |
|--------|-------------------------------------|
| [Alamofire 5.0+](https://github.com/Alamofire/Alamofire) | HTTP 네트워크 통신 라이브러리 |

### 반응형 프로그래밍

| 구분 | 비고 |
|--------------------------------|---------------------------------------------------------------------|
| [RxSwift 6.0+](https://github.com/ReactiveX/RxSwift) | 반응형 프로그래밍을 통한 비동기 이벤트 처리 |
| [RxCocoa 6.0+](https://github.com/ReactiveX/RxSwift) | UIKit과 RxSwift 바인딩 |

### Third-Party SDKs

| 구분 | 비고 |
|--------------------------------|---------------------------------------------------------------------|
| **Firebase** | |
| FirebaseAnalytics | 사용자 행동 분석 및 이벤트 추적 |
| FirebaseCrashlytics | 크래시 리포팅 및 에러 추적 |
| FirebaseMessaging | 푸시 알림 |
| **Ad Networks** | |
| [Google Mobile Ads SDK](https://developers.google.com/admob/ios/quick-start) | AdMob 전면 광고 및 배너 광고 |
| **Utilities** | |
| [IQKeyboardManager](https://github.com/hackiftekhar/IQKeyboardManager) | 키보드 자동 관리 |
| [Toast-Swift](https://github.com/scalessec/Toast-Swift) | 토스트 메시지 UI |

### In-App Purchase

| 구분 | 비고 |
|--------|-------------------------------------|
| StoreKit 2 | 인앱 결제 처리 (광고 제거 구매) |
| Local StoreKit Configuration | 로컬 테스트 환경 구성 |

<a id="tech-decision"></a>
## 🧠 기술적 의사결정

### 1. 배너광고 로딩 지연 개선을 위한 광고 프리로딩

**문제점**
- 화면 진입 시 광고 로드로 인한 UI 지연 발생
- 사용자가 광고 로딩을 체감하여 UX 저하

**해결 방안**
```swift
// AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 앱 실행 시 광고 프리로드
    InterstitialAdManager.shared.loadInterstitialAd()
    return true
}

// AdTriggerService.swift
func hybridInterstitialDidDismiss(from source: InterstitialAdSource) {
    print("[AdTriggerService] 광고 닫힘 - source: \(source)")

    // 다음 광고 미리 로드
    adManager.loadAd()

    // completion 호출
    adCompletionHandler?()
    adCompletionHandler = nil
}
```

**효과**
- 화면 전환 시 광고 즉시 표시 가능
- 유저 인터랙션에 대한 지연 시간 최소화
- Background 진입 전 미리로드로 광고 준비 상태 유지

---

### 2. 사용자 경험을 고려한 전면 광고 표시 정책

**구현 이유**
- 과도한 광고 노출로 인한 사용자 이탈 방지
- 주요 기능 사용 시점에 광고 표시하여 자연스러운 UX 제공

**구현 방법**
```swift
// AdTriggerService.swift
func checkAndShowAdIfNeeded(from viewController: UIViewController, completion: @escaping () -> Void) {
    // 광고 제거 구매 확인
    if InAppPurchaseManager.shared.hasRemovedAds {
        completion()
        return
    }

    let currentCount = UserDefaults.standard.catRegistrationCount

    // 4회마다 광고 표시 (고정 간격)
    if currentCount > 0 && currentCount % 4 == 0 {
        if adManager.isReady() {
            adManager.show(from: viewController)
            self.adCompletionHandler = completion
        } else {
            adManager.loadAd()
            completion()
        }
    } else {
        completion()
    }
}
```

**효과**
- 사용자 경험과 수익의 균형 확보
- 예측 가능한 광고 노출로 사용자 불만 최소화
- 인앱 결제 유도 (광고 제거 상품)

---

### 3. StoreKit 2 기반 인앱 결제 및 앱 스토어 영수증 검증

**구현 이유**
- 광고 제거 기능을 통한 수익 다각화
- 앱 스토어 영수증 검증으로 구매 안전성 확보
- 소모성/비소모성 상품 분리 관리

**구현 방법**
```swift
// InAppPurchaseManager.swift
import StoreKit

final class InAppPurchaseManager {
    static let shared = InAppPurchaseManager()

    // 광고 제거 상품 (비소모성)
    var hasRemovedAds: Bool {
        UserDefaults.standard.bool(forKey: "hasRemovedAds")
    }

    // 구매 처리
    func purchase(productId: String) async throws {
        guard let product = try await Product.products(for: [productId]).first else {
            throw PurchaseError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // 영수증 검증
            let transaction = try checkVerified(verification)
            await transaction.finish()

            // 구매 완료 처리
            UserDefaults.standard.set(true, forKey: "hasRemovedAds")

        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    // 구매 복원
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            let transaction = try? checkVerified(result)
            // 구매 상태 복원
        }
    }
}
```

**효과**
- 사용자 선택권 제공 (광고 vs 유료 구매)
- 재설치 시 구매 복원 기능
- 앱 스토어 정책 준수 및 안전한 결제 처리

---

### 4. FirebaseAnalytics, Crashlytics를 통한 앱 지표 분석

**구현 이유**
- 사용자 행동 패턴 분석으로 UX 개선 방향 도출
- 크래시 발생 시 실시간 모니터링 및 디버깅
- 실시간 크래시 리포트 수신 및 빠른 대응

**구현 방법**
```swift
// AppDelegate.swift
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    return true
}

// 이벤트 로깅
Analytics.logEvent("cat_registered", parameters: [
    "gender": gender,
    "character": character ?? "unknown"
])

// 크래시 로그
Crashlytics.crashlytics().log("고양이 등록 시작")
```

**효과**
- 주요 기능 사용률 파악 (고양이 등록, 방문 기록 등)
- 앱 안정성 향상 (크래시 발생 빈도 및 위치 추적)
- 데이터 기반 의사 결정

---

### 5. Alamofire + RxSwift 기반 네트워킹 추상화

**구현 이유**
- Single Traits을 사용한 일회성 네트워킹 요청 처리
- 에러 핸들링 및 재시도 로직 통일
- 코드 재사용성 및 테스트 용이성 향상

**구현 방법**
```swift
// NetworkManager.swift
import Alamofire
import RxSwift

final class NetworkManager {
    static let shared = NetworkManager()

    func request<T: Decodable>(url: String, method: HTTPMethod = .get) -> Single<T> {
        return Single.create { single in
            AF.request(url, method: method)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let data):
                        single(.success(data))
                    case .failure(let error):
                        single(.failure(error))
                    }
                }

            return Disposables.create()
        }
    }
}
```

**효과**
- 네트워킹 로직 중앙화
- 에러 처리 일관성 확보
- RxSwift 스트림과 자연스러운 조합

---

### 6. Realm을 활용한 로컬 데이터베이스 구축

**선택 이유**
- 데이터 일관성 유지를 위한 1:N relationship 구현
- Realm DB를 활용한 사용자 데이터 CRUD
- 빠른 쿼리 속도 및 객체 지향적 API

**구현 방법**
```swift
// Cat 모델 정의
class Cat: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var gender: Int
    @Persisted var character: Int?
    @Persisted var drawImage: String
    @Persisted var lat: Double
    @Persisted var lon: Double
    @Persisted var address: String
    @Persisted var visitLogs: List<VisitLog>  // 1:N 관계
    @Persisted var createdAt: Date
}

class VisitLog: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var filePath: String
    @Persisted var memo: String?
    @Persisted var visitDate: Date
}

// CRUD 작업
func createCat(_ cat: Cat) {
    let realm = try! Realm()
    try! realm.write {
        realm.add(cat)
    }
}

func fetchAllCats() -> [Cat] {
    let realm = try! Realm()
    return Array(realm.objects(Cat.self))
}
```

**효과**
- 고양이와 방문 기록 간의 관계형 데이터 모델링
- 마이그레이션 지원으로 스키마 변경 용이

---

### 7. FileManager 커스텀 확장을 통한 이미지 저장소 구현

**구현 이유**
- Documents 디렉토리 기반 이미지 파일 관리
- 앱 내부 저장소를 활용한 데이터 영속성 확보

**구현 방법**
```swift
// FileManager+Extension.swift
extension FileManager {
    func saveImage(_ image: UIImage, fileName: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let documentsPath = urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent(fileName)

        do {
            try data.write(to: filePath)
            return fileName
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }

    func loadImage(fileName: String) -> UIImage? {
        let documentsPath = urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: filePath.path)
    }
}
```

**효과**
- 이미지 파일 로컬 저장 및 불러오기
- Realm에는 파일 경로만 저장하여 DB 용량 최적화

<a id="project-structure"></a>
## 📂 프로젝트 구조

```
Nyangjoop/
├── App/
│   ├── AppDelegate.swift              # 앱 생명주기, SDK 초기화
│   ├── SceneDelegate.swift            # Scene 관리
│   ├── Info.plist                     # 앱 설정 (API Key, SDK Key 등)
│   └── Ads/                           # 광고 관련
│       ├── AdConfig.swift             # 광고 Unit ID 관리
│       ├── InterstitialAdManager.swift
│       ├── BannerAdManager.swift
│       └── RewardAdManager.swift
│
├── Home/                              # 홈 화면
│   ├── HomeViewController.swift
│   ├── HomeViewModel.swift
│   ├── Map/                           # 지도 관련
│   └── ChurShop/                      # 인앱 결제 (츄르샵)
│
├── Register/                          # 고양이 등록
│   ├── CatRegisterViewController.swift
│   ├── CatRegisterViewModel.swift
│   ├── Location/                      # 위치 선택
│   │   └── LocationPickerViewController.swift
│   └── DefaultImage/                  # 아이콘 선택
│       └── DefaultImageViewController.swift
│
├── Log/                               # 방문 기록
│   ├── LogViewController.swift
│   ├── LogViewModel.swift
│   ├── LogDetailViewController.swift
│   └── Record/                        # 기록 추가
│       ├── LogRecordViewController.swift
│       └── LogRecordViewModel.swift
│
├── Profile/                           # 프로필
│   ├── ProfileViewController.swift
│   ├── ProfileViewModel.swift
│   └── AchievementManager.swift       # 업적 관리
│
├── Common/                            # 공통 모듈
│   ├── AdTriggerService.swift         # 광고 트리거 로직
│   ├── TabBar/                        # 탭바
│   └── Camera/                        # 카메라/앨범
│       └── PhotoPickerManager.swift
│
├── Data/                              # 데이터 모델
│   └── RealmModels/
│       ├── Cat.swift
│       └── VisitLog.swift
│
├── InAppPurchase/                     # 인앱 결제
│   └── InAppPurchaseManager.swift
│
└── Base/                              # Base 클래스
    └── BaseViewController.swift
```

<a id="sample-images"></a>
## 📸 샘플 이미지

| 화면 | 주요 기능 |
|:---:|:---|
| **메인 화면 및 지도**<br><img src="https://github.com/user-attachments/assets/26d63630-fec2-4d94-8b39-5153c3ef07f3" width="300" alt="메인 화면 및 지도" /> | - 지도에서 고양이 위치 확인<br>- 클러스터링으로 그룹화된 마커 표시<br>- 고양이 간식 가게 조회  |
| **고양이 등록**<br><img src="https://github.com/user-attachments/assets/b6f15871-cb98-40d6-af54-b04472369349" width="300" alt="고양이 등록" /> | - 사진 선택 및 지도 아이콘 설정<br>- 위치, 이름, 성별, 성격 입력 |
| **방문 기록**<br><img src="https://github.com/user-attachments/assets/c553323c-8fe5-4478-8f04-1cccdaf076b0" width="300" alt="방문 기록" /> | - 고양이별 방문 일지<br>- 사진 앨범 및 타임라인 |
| **프로필 및 업적**<br><img src="https://github.com/user-attachments/assets/dfacd3f3-708d-42bd-b19f-785effb26411" width="300" alt="프로필 및 업적" /> | - 업적 달성 현황<br>- 배너 광고 |
| **츄르샵**<br><img src="https://github.com/user-attachments/assets/56833cfa-dc4f-41c8-86ee-e7ce04633e16" width="300" alt="츄르샵" /> | - 소모성 / 비소모성 아이템 구매 |

---

## 🚀 시작하기

### 요구사항
- iOS 16.0+
- Xcode 15.0+
- Swift 5.0+

### 설치

1. **레포지토리 클론**
```bash
git clone https://github.com/yourusername/Nyangjoop.git
cd Nyangjoop
```

2. **Config 파일 설정**

`Config/Debug.xcconfig` 및 `Config/Release.xcconfig` 파일에 다음 값을 설정하세요:

```
// AdMob
AD_BANNER_UNIT_ID = ca-app-pub-xxxxx
AD_INTERSTITIAL_UNIT_ID = ca-app-pub-xxxxx
AD_REWARD_INTERSTITIAL_UNIT_ID = ca-app-pub-xxxxx

// API (선택)
API_BASE_URL = https://your-api-url.com
apiKey = your-api-key
```

3. **Firebase 설정**
- [Firebase Console](https://console.firebase.google.com/)에서 프로젝트 생성
- `GoogleService-Info.plist` 다운로드
- `Nyangjoop/App/Debug/` 및 `Nyangjoop/App/Release/`에 각각 추가

4. **빌드 및 실행**
```bash
# Xcode에서 프로젝트 열기
open Nyangjoop.xcodeproj

# 시뮬레이터 또는 실제 기기에서 실행
```

---

## 📝 라이센스

이 프로젝트는 개인 프로젝트이며, 상업적 사용을 금지합니다.

---

## 👤 개발자

**이다성**
- GitHub: [@udtt-ds](https://github.com/uddt-ds/)

---
