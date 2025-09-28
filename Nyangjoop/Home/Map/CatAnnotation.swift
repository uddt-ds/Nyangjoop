//
//  CatAnnotation.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import Foundation
import MapKit

final class CatAnnotation: NSObject, MKAnnotation {
    let cat: Cat

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: cat.lat, longitude: cat.lon)
    }

    var title: String? {
        return cat.name
    }

    var subtitle: String? {
        let lastVisit = cat.lastVisitDate?.formatted(date: .abbreviated, time:  .omitted) ?? "첫 만남"
        return "방문 횟수: \(cat.visitCount)회 | 최근: \(lastVisit)"
    }

    init(cat: Cat) {
        self.cat = cat
        super.init()
    }
}

final class CatAnnotationView: MKAnnotationView, IdentifierProtocol {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let catImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setupView() {
        canShowCallout = true
        addSubview(containerView)
        containerView.addSubview(catImageView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.size.equalTo(50)
        }

        catImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(44)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 50, height: 50)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        catImageView.image = nil
    }

    func configure(with cat: Cat, showGalleryImage: Bool) {
        if showGalleryImage {
            // 갤러리 모드: 실제 사진이 있으면 사진, 없으면 noImage
            if !cat.visitLogs.isEmpty, let filePath = cat.visitLogs.first?.filePath, !filePath.isEmpty {
                loadCatImage(from: filePath)
            } else {
                catImageView.image = UIImage(named: "noImage")
            }
        } else {
            // 기본 모드: 저장된 drawImage 사용
            catImageView.image = UIImage(named: cat.drawImage)
        }
    }

    private func loadCatImage(from imagePath: String) {
        // Documents 디렉토리 경로 가져오기
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appendingPathComponent(imagePath).path

        if let localImage = UIImage(contentsOfFile: fullPath) {
            catImageView.image = localImage
        } else {
            catImageView.image = UIImage(named: "noImage")
        }
    }

}


