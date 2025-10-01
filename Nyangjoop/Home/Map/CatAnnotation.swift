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

// MARK: - CatAnnotationView
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
            make.size.equalTo(50)
        }

        bubbleContainerView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 65))
        }

        bubbleImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 70, height: 45))
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
            self.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        } else {
            self.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
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
        if showGalleryImage {
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
            isShowingPhoto = false
            bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
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
    
    // 배경 원형 컨테이너
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange
        return view
    }()
    
    // 발자국 아이콘 이미지뷰
    private let pawImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        imageView.image = UIImage(systemName: "pawprint.fill", withConfiguration: config)
        imageView.tintColor = .white
        return imageView
    }()
    
    // 숫자 표시 레이블
    private let countLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .heavy)
        label.textColor = .systemOrange
        label.backgroundColor = .white
        label.layer.cornerRadius = 10
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
        
        addSubview(containerView)
        containerView.addSubview(pawImageView)
        containerView.addSubview(countLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        pawImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(35)
        }
        
        countLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.width.greaterThanOrEqualTo(20)
            make.height.equalTo(20)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        countLabel.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = bounds.width / 2
    }
    
    func configure(with clusterAnnotation: MKClusterAnnotation) {
        let count = clusterAnnotation.memberAnnotations.count
        countLabel.text = "\(count)"
        
        // 개수에 따라 크기 조정
        let size: CGFloat
        let pawSize: CGFloat
        let fontSize: CGFloat
        
        switch count {
        case 2...9:
            size = 60
            pawSize = 30
            fontSize = 14
        case 10...99:
            size = 70
            pawSize = 35
            fontSize = 15
        default:
            size = 80
            pawSize = 40
            fontSize = 16
        }
        
        // 아이콘 크기 조정
        let config = UIImage.SymbolConfiguration(pointSize: pawSize, weight: .bold)
        pawImageView.image = UIImage(systemName: "pawprint.fill", withConfiguration: config)
        
        // 폰트 크기 조정
        countLabel.font = .systemFont(ofSize: fontSize, weight: .heavy)
        
        bounds = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = CGPoint(x: 0, y: -size / 2)
        
        setNeedsLayout()
    }
}
