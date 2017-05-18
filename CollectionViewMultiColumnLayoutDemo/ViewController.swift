//
//  ViewController.swift
//  CollectionViewMultiColumnLayoutDemo
//
//  Created by Vincent Esche on 5/18/17.
//  Copyright © 2017 Vincent Esche. All rights reserved.
//

import UIKit

import CollectionViewMultiColumnLayout

class CollectionViewController: UICollectionViewController {

    enum ReuseIdentifier: String {
        case cell = "Cell"
        case headerReuseIdentifier = "Header"
        case footerReuseIdentifier = "Footer"
    }
    fileprivate static let cellReuseIdentifier = "Cell"
    fileprivate static let headerReuseIdentifier = "Header"
    fileprivate static let footerReuseIdentifier = "Footer"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        guard let collectionView = self.collectionView else {
            return
        }

        // Register cell classes
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: CollectionViewController.cellReuseIdentifier
        )
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
            withReuseIdentifier: CollectionViewController.headerReuseIdentifier
        )
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
            withReuseIdentifier: CollectionViewController.footerReuseIdentifier
        )

        let layout = CollectionViewMultiColumnLayout()
        collectionView.setCollectionViewLayout(layout, animated: false)

        // Do any additional setup after loading the view.
    }
}

extension CollectionViewController /*: UICollectionViewDataSource */ {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 4
        case 2: return 5
        case _: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CollectionViewController.cellReuseIdentifier,
            for: indexPath
        )

        let column = self.collectionView(collectionView, columnForItemAt: indexPath as NSIndexPath)!
        cell.backgroundColor = [.darkGray, .gray, .lightGray][column % 3]

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let reuseIdentifier: String = {
            switch kind {
            case UICollectionElementKindSectionHeader:
                return CollectionViewController.headerReuseIdentifier
            case UICollectionElementKindSectionFooter:
                return CollectionViewController.footerReuseIdentifier
            case _: fatalError("Unrecognized UICollectionElementKind: '\(kind)'")
            }
        }()

        let supplementaryView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        )

        // Configure the cell

        switch kind {
        case UICollectionElementKindSectionHeader:
            supplementaryView.backgroundColor = .blue
        case UICollectionElementKindSectionFooter:
            supplementaryView.backgroundColor = .green
        case _: break
        }

        return supplementaryView
    }

    // MARK: UICollectionViewDelegate

    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */

    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */

    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }

     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }

     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {

     }
     */

}

extension CollectionViewController: CollectionViewMultiColumnLayoutDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 2
        case 2: return 3
        case _: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, columnForItemAt indexPath: NSIndexPath) -> Int? {
        return indexPath.item % (indexPath.section + 1)
    }
}

extension CollectionViewController: CollectionViewMultiColumnLayoutDelegate {

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let height = CGFloat(arc4random_uniform(20)) + 10.0
        return CGSize(width: 30.0, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, insetForSection section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

    //    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, insetForHeaderInSection section: Int) -> UIEdgeInsets
    //    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, insetForFooterInSection section: Int) -> UIEdgeInsets
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, minimumInteritemSpacingForSection section: Int) -> CGFloat {
        return 10.0
    }
}
