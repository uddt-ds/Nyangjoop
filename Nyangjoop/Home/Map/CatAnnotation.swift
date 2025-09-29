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

    private let bubbleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.isHidden = true
        return view
    }()

    private let bubbleTailView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private let catImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let bubbleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.isHidden = true
        return imageView
    }()

    private var isShowingPhoto = false

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configureHierarchy()
        configureLayout()
        setupBubbleTail()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func configureHierarchy() {
        canShowCallout = false

        [bubbleContainerView, bubbleTailView, catImageView].forEach { addSubview($0) }
        bubbleContainerView.addSubview(bubbleImageView)
    }

    private func configureLayout() {
        catImageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(50)
        }

        // 말풍선 컨테이너 (갤러리 모드)
        bubbleContainerView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 65))
        }

        bubbleImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 70, height: 45))
        }

        // 말풍선 꼬리
        bubbleTailView.snp.makeConstraints { make in
            make.top.equalTo(bubbleContainerView.snp.bottom)
            make.centerX.equalTo(bubbleContainerView)
            make.size.equalTo(CGSize(width: 20, height: 15))
        }
    }

    private func setupBubbleTail() {
        bubbleTailView.layer.sublayers?.removeAll()

        let tailLayer = CAShapeLayer()
        let tailPath = UIBezierPath()

        tailPath.move(to: CGPoint(x: 6, y: 0))
        tailPath.addLine(to: CGPoint(x: 14, y: 0))
        tailPath.addLine(to: CGPoint(x: 10, y: 12))
        tailPath.close()

        tailLayer.path = tailPath.cgPath
        tailLayer.fillColor = UIColor.white.cgColor
        tailLayer.strokeColor = UIColor.clear.cgColor

        bubbleTailView.layer.addSublayer(tailLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if isShowingPhoto {
            self.frame = CGRect(x: 0, y: 0, width: 80, height: 65)
        } else {
            self.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        }

        self.centerOffset = CGPoint(x: 0, y: -self.frame.height / 2)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        catImageView.image = nil
        bubbleImageView.image = nil
    }

    func configure(with cat: Cat, showGalleryImage: Bool) {
        if showGalleryImage {
            // 갤러리 모드: 실제 사진이 있으면 사진, 없으면 noImage
            isShowingPhoto = true
            bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
            if !cat.visitLogs.isEmpty, let filePath = cat.visitLogs.first?.filePath, !filePath.isEmpty {
                showBubbleMode()
                loadCatImage(from: filePath, into: bubbleImageView)
            } else {
                showBubbleMode()
                bubbleImageView.image = UIImage(named: "noImage")
            }
        } else {
            // 기본 모드: 저장된 drawImage 사용
            isShowingPhoto = false
            bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
            showDirectImageMode()
            catImageView.image = UIImage(named: cat.drawImage)
        }

        setNeedsLayout()
    }

    private func loadCatImage(from imagePath: String, into imageView: UIImageView) {
        // Documents 디렉토리 경로 가져오기
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appendingPathComponent(imagePath).path

        if let localImage = UIImage(contentsOfFile: fullPath) {
            imageView.image = localImage
        } else {
            imageView.image = UIImage(named: "noImage")
        }
    }

    private func showBubbleMode() {
        catImageView.isHidden = true
        bubbleContainerView.isHidden = false
        bubbleTailView.isHidden = false
        bubbleImageView.isHidden = false
    }

    private func showDirectImageMode() {
        catImageView.isHidden = false
        bubbleContainerView.isHidden = true
        bubbleTailView.isHidden = true
        bubbleImageView.isHidden = true
    }
}


