//
//  MarketAnnotation.swift
//  Nyangjoop
//
//  Created by Lee on 9/30/25.
//

import Foundation
import MapKit

final class MarketAnnotation: NSObject, MKAnnotation {
    let market: MarketModel

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: market.y, longitude: market.x)
    }

    var title: String? {
        return market.placeName
    }

    var subtitle: String? {
        return market.addressName
    }

    init(market: MarketModel) {
        self.market = market
        super.init()
    }
}

final class MarketAnnotationView: MKAnnotationView, IdentifierProtocol {
    
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        canShowCallout = true
        frame = CGRect(x: 0, y: 0, width: 50, height: 50)

        let imageView = UIImageView(frame: bounds)
        imageView.image = UIImage(named: "fish")
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
}
