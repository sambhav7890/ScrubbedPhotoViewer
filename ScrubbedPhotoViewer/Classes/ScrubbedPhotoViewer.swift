//
//  ScrubbedPhotoViewer.swift
//  ScrubbedPhotoViewer
//
//  Created by Sambhav Shah on 22/12/17.
//

import UIKit

@objc public enum ScrubThumbnailStripPosition: Int {
	case top
	case bottom
}

@objc public protocol ScrubbedPhotoViewerDatasource: class {
	var dataCount: Int { get }

	func populateData(at index: Int, forCell: SCImageCell)
}

/** Collection Cell For PhotoViewer. */
@objc public class SCImageCell: UICollectionViewCell {

	var sCImageView: UIImageView = UIImageView()

	public override init(frame: CGRect) {
		super.init(frame: frame)
		self.addImage()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.addImage()
	}

	func addImage() {
		self.sCImageView.frame = self.bounds
		self.contentView.addSubview(self.sCImageView)
	}

	public override func prepareForReuse() {
		super.prepareForReuse()
		self.sCImageView.image = nil
	}
}

@objc public class ScrubbedPhotoViewer: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

	/**
		Data source list of (String) URLs to images (or UIImage objects).
	*/

	@objc public var imageDataSource: ScrubbedPhotoViewerDatasource?

	/**
		Background color of image browser.
	*/
	@objc public var sCBackgroundColor: UIColor = UIColor.black {
		didSet {
			self.view?.backgroundColor = sCBackgroundColor
		}
	}

	/**
		Padding around the images
	*/
	@objc public var sCImagePadding: CGFloat = 20.0

	/**
		Width of the main image being displayed
	*/
	@objc public var sCImageWidth: CGFloat = 0.0

	/**
		Height of thumnmail strip (optional). The default is 100.
	*/
	@objc public var sCThumbnailStripHeight: CGFloat = 100.0

	/**
		Position of the thumbnail strip
	*/
	@objc public var sCThumbnailStripPosition: ScrubThumbnailStripPosition = ScrubThumbnailStripPosition.bottom

	/**
		Starting image index. The default is 0 (first image).
	*/
	@objc public var sCStartIndex: Int = 0

	/**
		Internal Properties
	*/
	var scImageCollectionView: UICollectionView!
	var scThumbnailCollectionView: UICollectionView!

	var mainContainer: UIView?
	var currentPage: Int = 0

	let SCBottomCellIdentifer = "SCBottomCellIdentifer"

	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		self.initialize()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.initialize()
	}

	func initialize() {
		sCImageWidth = view.bounds.size.width - 100
		view.backgroundColor = sCBackgroundColor
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.setupMainCollection()
		self.setupThumbnailCollection()
		self.loadCollections()
	}

	func setupMainCollection() {
		var frame: CGRect
		frame = view.bounds
		// Image collection view
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = sCImagePadding

		//TODO: account for nav bar
		frame.origin = CGPoint(x: 0, y: sCImagePadding)
		frame.size.width = view.frame.size.width
		frame.size.height = view.frame.size.height - frame.origin.y - sCThumbnailStripHeight - sCImagePadding

		self.scImageCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
		self.scImageCollectionView.showsHorizontalScrollIndicator = false
		self.scImageCollectionView.delegate = self
		self.scImageCollectionView.dataSource = self
		self.scImageCollectionView.backgroundColor = sCBackgroundColor
		self.scImageCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
		self.scImageCollectionView.register(SCImageCell.self, forCellWithReuseIdentifier: SCBottomCellIdentifer)
		view.addSubview(self.scImageCollectionView)
	}

	func setupThumbnailCollection() {
		// Thumbnail collection view
		let bottomLayout = UICollectionViewFlowLayout()
		bottomLayout.scrollDirection = .horizontal
		bottomLayout.minimumInteritemSpacing = 0
		bottomLayout.minimumLineSpacing = sCImagePadding
		frame.origin = CGPoint(x: 0, y: self.scImageCollectionView.frame.size.height + self.scImageCollectionView.frame.origin.y + sCImagePadding)
		frame.size.width = view.frame.size.width
		frame.size.height = sCThumbnailStripHeight - sCImagePadding
		self.scThumbnailCollectionView = UICollectionView(frame: frame, collectionViewLayout: bottomLayout)
		self.scThumbnailCollectionView.showsHorizontalScrollIndicator = false
		self.scThumbnailCollectionView.allowsMultipleSelection = true
		self.scThumbnailCollectionView.delegate = self
		self.scThumbnailCollectionView.dataSource = self
		self.scThumbnailCollectionView.backgroundColor = sCBackgroundColor
		self.scThumbnailCollectionView.register(SCImageCell.self, forCellWithReuseIdentifier: SCBottomCellIdentifer)
		view.addSubview(self.scThumbnailCollectionView)

		// Reposition
		switch self.sCThumbnailStripPosition {
		case .top:
			var frame: CGRect = self.scThumbnailCollectionView.frame
			frame.origin.y = 32 + sCImagePadding * 2
			self.scThumbnailCollectionView.frame = frame
			frame = self.scImageCollectionView.frame
			frame.origin.y = self.scThumbnailCollectionView.frame.size.height + self.scThumbnailCollectionView.frame.origin.y - sCImagePadding
			self.scImageCollectionView.frame = frame
		case .bottom:
			break
		default:
			print("Strip position for \(sCThumbnailStripPosition)")
		}
	}

	func loadCollections() {
		// load collection views
		self.scImageCollectionView.reloadData()
		self.scThumbnailCollectionView.reloadData()
		if self.sCStartIndex > 0 {
			let indexPath = IndexPath(item: self.sCStartIndex, section: 0)
			self.scThumbnailCollectionView.scrollToItem(at: indexPath, at: [], animated: true)
			self.scImageCollectionView.scrollToItem(at: indexPath, at: [], animated: true)
		}
	}

}

//Mark: - UICollectionView Datasource
extension ScrubbedPhotoViewer {

	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.imageDataSource?.dataCount ?? 0
	}

	public func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		if (collectionView == scImageCollectionView) && (indexPath.item > 1) {
			scThumbnailCollectionView.scrollToItem(at: IndexPath(item: indexPath.item - 1, section: 0), at: .centeredHorizontally, animated: true)
		}

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SCBottomCellIdentifer, for: indexPath) as! SCImageCell

		self.imageDataSource?.populateData(at: indexPath.row, forCell: cell)

		return cell
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: false)
		currentPage = indexPath.item
		scImageCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
	}
}

//Mark: - UICollectionViewDelegateFlowLayout
extension ScrubbedPhotoViewer {

	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		guard collectionView == scThumbnailCollectionView else {
			return CGSize(width: sCImageWidth, height: collectionView.frame.size.height)
		}
		var size: CGSize = CGSize(width: 0, height: 0)
		size.height = collectionView.frame.size.height
		size.width = size.height * self.sCImageWidth / self.scImageCollectionView.frame.size.height
		return size
	}

	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		if collectionView == scImageCollectionView {
			return UIEdgeInsetsMake(0, (view.frame.size.width - sCImageWidth) / 2, 0, (view.frame.size.width - sCImageWidth) / 2)
		} else {
			return UIEdgeInsetsMake(0, sCImagePadding, 0, sCImagePadding)
		}
	}
}

//Mark: - UIScrollViewDelegate
extension ScrubbedPhotoViewer {
	public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
		guard scrollView == scImageCollectionView else { return }
		scrollView.isUserInteractionEnabled = false
	}

	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		guard scrollView == scImageCollectionView else { return }
		guard !scrollView.isDecelerating else { return }

		let item: Int = Int((scrollView.contentOffset.x - sCImageWidth / 2) / sCImageWidth) + 1

		let lastItem: Int = (self.imageDataSource?.dataCount ?? 1) - 1

		if item > currentPage {
			currentPage += 1
		} else {
			currentPage -= 1
		}

		if currentPage < 0 {
			currentPage = 0
		} else if currentPage > lastItem {
			currentPage = lastItem
		}
		self.scImageCollectionView?.scrollToItem(at: IndexPath(item: currentPage, section: 0), at: .centeredHorizontally, animated: true)
	}

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		guard scrollView == scImageCollectionView else { return }
		self.scImageCollectionView?.scrollToItem(at: IndexPath(item: currentPage, section: 0), at: .centeredHorizontally, animated: true)
		scrollView.isUserInteractionEnabled = true
	}
}

/** Nav Controller For PhotoViewer. */
@objc public class ScrubbedPhotoViewerNav: UINavigationController {
	@objc public var imageBrowser: ScrubbedPhotoViewer!

	@objc public init() {
		imageBrowser = ScrubbedPhotoViewer()
		super.init(rootViewController: imageBrowser)
	}

	@objc public required init?(coder aDecoder: NSCoder) {
		imageBrowser = ScrubbedPhotoViewer()
		super.init(coder: aDecoder)
	}

	@objc public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(false)
		imageBrowser.title = title
	}
}

