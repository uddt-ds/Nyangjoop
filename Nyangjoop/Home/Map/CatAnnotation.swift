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

    private let defaultIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "pawprint.fill")
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
        containerView.addSubview(defaultIconView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.size.equalTo(50)
        }

        catImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(44)
        }

        defaultIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(26)
        }

        showDefaultIcon()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 50, height: 50)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        catImageView.image = nil
    }

    func configure(with cat: Cat, showGalleryImage: Bool) {
        if showGalleryImage && !cat.drawImage.isEmpty {
            loadCatImage(from: cat.drawImage)
        } else {
            showDefaultIcon()
        }
    }

    private func loadCatImage(from path: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagePath = documentsPath.appending(path: path)
        if let image = UIImage(contentsOfFile: imagePath.path()) {
            catImageView.image = image
            showGalleryImage()
        } else {
            showDefaultIcon()
        }
    }

    private func showDefaultIcon() {
        catImageView.isHidden = true
        defaultIconView.isHidden = false
    }

    private func showGalleryImage() {
        catImageView.isHidden = false
        defaultIconView.isHidden = true
    }
}


