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
    private let cachedCoordinate: CLLocationCoordinate2D
    private let cachedTitle: String
    private let cachedSubtitle: String

    var coordinate: CLLocationCoordinate2D {
        return cachedCoordinate
    }

    var title: String? {
        return cachedTitle
    }

    var subtitle: String? {
        return cachedSubtitle
    }

    init(cat: Cat) {
        self.cat = cat
        self.cachedCoordinate = CLLocationCoordinate2D(latitude: cat.lat, longitude: cat.lon)
        self.cachedTitle = cat.name
        
        let lastVisit = cat.lastVisitDate?.formatted(date: .abbreviated, time:  .omitted) ?? "첫 만남"
        self.cachedSubtitle = "방문 횟수: \(cat.visitCount)회 | 최근: \(lastVisit)"
        
        super.init()
    }
}

// MARK: - CatAnnotationView
final class CatAnnotationView: MKAnnotationView, IdentifierProtocol {

    private let bubbleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
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
        setupView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupView() {
        // 클러스터링 식별자는 나중에 동적으로 설정
        // displayPriority와 collisionMode 설정
        displayPriority = .defaultHigh
        collisionMode = .circle
        
        configureHierarchy()
        configureLayout()
        setupBubbleTail()
    }

    private func configureHierarchy() {
        canShowCallout = false

        [bubbleContainerView, bubbleTailView, catImageView].forEach { addSubview($0) }
        bubbleContainerView.addSubview(bubbleImageView)
    }

    private func configureLayout() {
        catImageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(60)
        }

        bubbleContainerView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 90, height: 90))
        }

        bubbleImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 80))
        }

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
        tailPath.addLine(to: CGPoint(x: 10, y: 6))
        tailPath.close()

        tailLayer.path = tailPath.cgPath
        tailLayer.fillColor = UIColor.white.cgColor
        tailLayer.strokeColor = UIColor.clear.cgColor
        tailLayer.shadowColor = UIColor.black.cgColor
        tailLayer.shadowOpacity = 0.15
        tailLayer.shadowOffset = CGSize(width: 0, height: 2)
        tailLayer.shadowRadius = 4

        bubbleTailView.layer.addSublayer(tailLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if isShowingPhoto {
            self.frame = CGRect(x: 0, y: 0, width: 90, height: 90)
        } else {
            self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        }

        self.centerOffset = CGPoint(x: 0, y: -self.frame.height / 2)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        catImageView.image = nil
        bubbleImageView.image = nil
        // 클러스터링 식별자는 매번 새로 설정되므로 초기화 불필요
    }

    func configure(with cat: Cat, showGalleryImage: Bool) {
        guard !cat.isInvalidated else {
            isShowingPhoto = false
            showDirectImageMode()
            catImageView.image = UIImage(systemName: "exclamationmark.triangle")
            return
        }
        
        if showGalleryImage {
            isShowingPhoto = true
            bounds = CGRect(x: 0, y: 0, width: 90, height: 90)
            if !cat.visitLogs.isEmpty, let filePath = cat.visitLogs.first?.filePath, !filePath.isEmpty {
                showBubbleMode()
                loadCatImage(from: filePath, into: bubbleImageView)
            } else {
                showBubbleMode()
                bubbleImageView.image = UIImage(named: "noImage")
            }
        } else {
            isShowingPhoto = false
            bounds = CGRect(x: 0, y: 0, width: 60, height: 60)
            showDirectImageMode()
            catImageView.image = UIImage(named: cat.drawImage)
        }

        setNeedsLayout()
    }

    private func loadCatImage(from imagePath: String, into imageView: UIImageView) {
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

// MARK: - CatClusterAnnotationView
final class CatClusterAnnotationView: MKAnnotationView, IdentifierProtocol {
    
    private let towerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "catTower")
        return imageView
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .heavy)
        label.textColor = .white
        label.backgroundColor = .retroRed
        label.layer.cornerRadius = 14
        label.clipsToBounds = true
        return label
    }()
    
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupClusterView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupClusterView()
    }
    
    private func setupClusterView() {
        displayPriority = .defaultHigh
        collisionMode = .circle
        
        addSubview(towerImageView)
        addSubview(countLabel)
        
        towerImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        countLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.trailing.equalToSuperview().offset(-2)
            make.width.height.equalTo(32)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        countLabel.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func configure(with clusterAnnotation: MKClusterAnnotation) {
        let count = clusterAnnotation.memberAnnotations.count
        countLabel.text = "\(count)"
        
        let size: CGFloat
        let fontSize: CGFloat
        let labelSize: CGFloat
        
        switch count {
        case 2...9:
            size = 90
            fontSize = 16
            labelSize = 32
        case 10...99:
            size = 100
            fontSize = 14
            labelSize = 36
        default:
            size = 110
            fontSize = 13
            labelSize = 40
        }
        
        countLabel.font = .systemFont(ofSize: fontSize, weight: .heavy)
        
        countLabel.snp.updateConstraints { make in
            make.width.height.equalTo(labelSize)
        }
        
        countLabel.layer.cornerRadius = labelSize / 2
        
        bounds = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = CGPoint(x: 0, y: -size / 2)
        
        setNeedsLayout()
    }
}
