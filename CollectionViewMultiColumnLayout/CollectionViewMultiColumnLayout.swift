//
//  CollectionViewMultiColumnLayout.swift
//  CollectionViewMultiColumnLayout
//
//  Created by Vincent Esche on 5/18/17.
//  Copyright © 2017 Vincent Esche. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Based on https://github.com/chiahsien/CHTCollectionViewWaterfallLayout (MIT License)

import UIKit

public protocol CollectionViewMultiColumnLayoutDataSource: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfColumnsInSection section: Int
    ) -> Int

    func collectionView(
        _ collectionView: UICollectionView,
        columnForItemAt indexPath: NSIndexPath
    ) -> Int?
}

@objc public protocol CollectionViewMultiColumnLayoutDelegate: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        layout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath
    ) -> CGSize

    @objc optional func collectionView(
        _ collectionView: UICollectionView,
        layout: UICollectionViewLayout,
        heightForHeaderInSection section: Int
    ) -> CGFloat

    @objc optional func collectionView(
        _ collectionView: UICollectionView,
        layout: UICollectionViewLayout,
        heightForFooterInSection section: Int
    ) -> CGFloat

    @objc optional func collectionView(
        _ collectionView: UICollectionView,
        layout: UICollectionViewLayout,
        minimumInteritemSpacingForSection section: Int
    ) -> CGFloat

    @objc optional func collectionView(
        _ collectionView: UICollectionView,
        layout: UICollectionViewLayout,
        insetForSection section: Int
    ) -> UIEdgeInsets

    @objc optional func collectionView(
        _ collectionView: UICollectionView,
        layout: UICollectionViewLayout,
        insetForHeaderInSection section: Int
    ) -> UIEdgeInsets

    @objc optional func collectionView(
        _ collectionView: UICollectionView,
        layout: UICollectionViewLayout,
        insetForFooterInSection section: Int
    ) -> UIEdgeInsets
}

public class CollectionViewMultiColumnLayout: UICollectionViewLayout {

    /// How many items to be union into a single rectangle
    private let unionSize = 20;

    public var minimumColumnSpacing: CGFloat = 10.0 {
        didSet {
            self.invalidateIfNecessary(old: oldValue, new: self.minimumColumnSpacing)
        }
    }

    public var minimumInteritemSpacing: CGFloat = 10.0 {
        didSet {
            self.invalidateIfNecessary(old: oldValue, new: self.minimumInteritemSpacing)
        }
    }

    public var headerHeight: CGFloat = 0.0 {
        didSet {
            self.invalidateIfNecessary(old: oldValue, new: self.headerHeight)
        }
    }

    public var footerHeight: CGFloat = 0.0 {
        didSet {
            self.invalidateIfNecessary(old: oldValue, new: self.footerHeight)
        }
    }

    public var headerInsets: UIEdgeInsets = .zero {
        didSet {
            self.invalidateIfNecessary(old: oldValue, new: self.headerInsets)
        }
    }

    public var footerInsets: UIEdgeInsets = .zero {
        didSet {
            self.invalidateIfNecessary(old: oldValue, new: self.footerInsets)
        }
    }

    public var sectionInsets: UIEdgeInsets = .zero {
        didSet {
            self.invalidateIfNecessary(old: oldValue, new: self.sectionInsets)
        }
    }

    private var dataSource: CollectionViewMultiColumnLayoutDataSource? {
        guard let defaultDataSource = self.collectionView?.delegate else {
            return nil
        }
        guard let dataSource = defaultDataSource as? CollectionViewMultiColumnLayoutDataSource else {
            let name = String(describing: CollectionViewMultiColumnLayoutDataSource.self)
            print("UICollectionView's dataSource should conform to \(name) protocol")
            return nil
        }
        return dataSource
    }

    private var delegate: CollectionViewMultiColumnLayoutDelegate? {
        guard let defaultDelegate = self.collectionView?.delegate else {
            return nil
        }
        guard let delegate = defaultDelegate as? CollectionViewMultiColumnLayoutDelegate else {
            let name = String(describing: CollectionViewMultiColumnLayoutDelegate.self)
            print("UICollectionView's delegate should conform to \(name) protocol")
            return nil
        }
        return delegate
    }

    private var sectionItemAttributes: [[UICollectionViewLayoutAttributes]] = []
    private var allItemAttributes: [UICollectionViewLayoutAttributes] = []
    private var headersAttribute: [Int : UICollectionViewLayoutAttributes] = [:]
    private var footersAttribute: [Int : UICollectionViewLayoutAttributes] = [:]
    private var sectionRects: [Int : CGRect] = [:]
    private var contentHeight: CGFloat = 0.0

    override public func prepare() {
        super.prepare()

        guard let collectionView = self.collectionView else {
            return
        }

        guard let delegate = self.delegate else {
            return
        }

        guard let dataSource = self.dataSource else {
            return
        }

        self.headersAttribute.removeAll(keepingCapacity: false)
        self.footersAttribute.removeAll(keepingCapacity: false)
        self.sectionRects.removeAll(keepingCapacity: false)
        self.allItemAttributes.removeAll(keepingCapacity: false)
        self.sectionItemAttributes.removeAll(keepingCapacity: false)

        let numberOfSections = collectionView.numberOfSections
        guard numberOfSections > 0 else {
            return;
        }

        var top: CGFloat = 0.0
        var attributes: UICollectionViewLayoutAttributes

        var contentHeight: CGFloat = 0.0

        for section in 0..<numberOfSections {
            let numberOfColumns = dataSource.collectionView(
                collectionView,
                numberOfColumnsInSection: section
            )
            assert(numberOfColumns > 0, "Number of columns should be greater than 0.")

            var columnHeights: [CGFloat] = Array(repeating: 0.0, count: numberOfColumns)

            var sectionRect: CGRect = .null

            // MARK: Section metrics

            let minimumInteritemSpacing = delegate.collectionView?(
                collectionView,
                layout: self,
                minimumInteritemSpacingForSection: section
            ) ?? self.minimumInteritemSpacing

            let sectionInsets = delegate.collectionView?(
                collectionView,
                layout: self,
                insetForSection: section
            ) ?? self.sectionInsets

            let width = collectionView.frame.width - sectionInsets.left - sectionInsets.right
            let columnSpacing = (CGFloat(numberOfColumns) - 1.0) * self.minimumColumnSpacing
            let itemWidth = floor((width - columnSpacing) / CGFloat(numberOfColumns))

            // MARK: Section header

            let headerHeight = delegate.collectionView?(
                collectionView,
                layout: self,
                heightForHeaderInSection: section
            ) ?? self.headerHeight

            let headerInsets = delegate.collectionView?(
                collectionView,
                layout: self,
                insetForHeaderInSection: section
            ) ?? self.headerInsets

            top += headerInsets.top

            if headerHeight > 0 {
                let indexPath = IndexPath(item: 0, section: section)
                attributes = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                    with: indexPath
                )
                attributes.frame = CGRect(
                    x: headerInsets.left,
                    y: top,
                    width: collectionView.frame.width - (headerInsets.left + headerInsets.right),
                    height: headerHeight
                )
                self.headersAttribute[section] = attributes
                sectionRect = sectionRect.union(attributes.frame)
                top = attributes.frame.maxY + headerInsets.bottom
            }

            top += sectionInsets.top
            for idx in 0..<numberOfColumns {
                columnHeights[idx] = top
            }

            // MARK: Section items

            let itemCount = collectionView.numberOfItems(inSection: section)
            var itemAttributes = [UICollectionViewLayoutAttributes]()

            // Item will be put into shortest column.
            for idx in 0..<itemCount {
                let indexPath = IndexPath(item: idx, section: section)
                let column = dataSource.collectionView(
                    collectionView,
                    columnForItemAt: indexPath as NSIndexPath
                    ) ?? shortestColumnIndex(columnHeights)

                let itemWidthAndSpacing = itemWidth + self.minimumColumnSpacing
                let xOffset = sectionInsets.left + itemWidthAndSpacing * CGFloat(column)
                let yOffset = columnHeights[column]
                let itemSize = delegate.collectionView(
                    collectionView,
                    layout: self,
                    sizeForItemAtIndexPath: indexPath as NSIndexPath
                )
                var itemHeight: CGFloat = 0.0
                if itemSize.height > 0 && itemSize.width > 0 {
                    itemHeight = itemSize.height * itemWidth / itemSize.width
                }

                attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(
                    origin: CGPoint(x: xOffset, y: yOffset),
                    size: CGSize(width: itemWidth, height: itemHeight)
                )
                itemAttributes.append(attributes)
                self.allItemAttributes.append(attributes)
                sectionRect = sectionRect.union(attributes.frame)
                columnHeights[column] = attributes.frame.maxY + minimumInteritemSpacing
            }

            self.sectionItemAttributes.append(itemAttributes)

            // MARK: Section footer

            let columnIndex = longestColumnIndex(columnHeights)
            top = columnHeights[columnIndex] - minimumInteritemSpacing + sectionInsets.bottom

            let footerHeight = delegate.collectionView?(
                collectionView,
                layout: self,
                heightForFooterInSection: section
            ) ?? self.footerHeight

            let footerInsets = delegate.collectionView?(
                collectionView,
                layout: self,
                insetForFooterInSection: section
            ) ?? self.footerInsets

            top += footerInsets.top

            if footerHeight > 0 {
                let indexPath = IndexPath(item: 0, section: section)
                attributes = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                    with: indexPath
                )
                attributes.frame = CGRect(
                    x: footerInsets.left,
                    y: top,
                    width: collectionView.frame.width - (footerInsets.left + footerInsets.right),
                    height: footerHeight
                )
                self.footersAttribute[section] = attributes
                self.allItemAttributes.append(attributes)
                sectionRect = sectionRect.union(attributes.frame)
                top = attributes.frame.maxY + footerInsets.bottom
            }

            contentHeight = top
            self.sectionRects[section] = sectionRect
        }

        self.contentHeight = contentHeight
    }

    override public var collectionViewContentSize: CGSize {
        guard let collectionView = self.collectionView else {
            return .zero
        }
        guard collectionView.numberOfSections > 0 else {
            return .zero
        }
        var contentSize = collectionView.bounds.size
        contentSize.height = self.contentHeight
        return contentSize
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < self.sectionItemAttributes.count else {
            return nil
        }
        guard indexPath.item < self.sectionItemAttributes[indexPath.section].count else {
            return nil
        }
        return self.sectionItemAttributes[indexPath.section][indexPath.item]
    }

    override public func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case UICollectionElementKindSectionHeader:
            return self.headersAttribute[indexPath.section]
        case UICollectionElementKindSectionFooter:
            return self.footersAttribute[indexPath.section]
        case _:
            return nil
        }
    }

    override public func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes] {
        return Array(self.sectionRects.lazy.flatMap { section, sectionRect in
            sectionRect.intersects(rect) ? self.sectionItemAttributes[section] : nil
            }.joined())
    }

    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else {
            return false
        }
        let oldBounds = collectionView.bounds
        if newBounds.width != oldBounds.width {
            return true
        }
        return false
    }

    private func shortestColumnIndex(_ columnHeights: [CGFloat]) -> Int {
        return columnHeights.enumerated().min { $0.1 < $1.1 }!.0
    }

    private func longestColumnIndex(_ columnHeights: [CGFloat]) -> Int {
        return columnHeights.enumerated().max { $0.1 < $1.1 }!.0
    }
    
    private func invalidateIfNecessary<T>(old: T, new: T) where T: Equatable {
        if old != new {
            self.invalidateLayout()
        }
    }
}
