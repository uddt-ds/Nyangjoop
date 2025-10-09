//
//  WaterfallLayout.swift
//  Nyangjoop
//
//  Created by Lee on 10/6/25.
//

import UIKit

protocol WaterfallLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath) -> CGFloat
}

final class WaterfallLayout: UICollectionViewLayout {
    weak var delegate: WaterfallLayoutDelegate?
    
    private var numberOfColumns: Int = 2
    private var cellPadding: CGFloat = 6.0
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0.0
    
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0.0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        
        cache.removeAll()
        contentHeight = 0
        
        let columnWidth: CGFloat = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            let offset = CGFloat(column) * columnWidth
            xOffset.append(offset)
        }
        
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
        
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            
            let column = yOffset.firstIndex(of: yOffset.min() ?? 0) ?? 0
            
            let itemHeight = delegate?.collectionView(collectionView, heightForItemAt: indexPath) ?? 0
            let height = cellPadding * 2 + itemHeight
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { rect.intersects($0.frame) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
}
