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
	@objc public var backgroundColor: UIColor = UIColor.black {
		didSet {
			self.view?.backgroundColor = backgroundColor
		}
	}

	/**
		Padding around the images
	*/
	@objc public var imagePadding: CGFloat = 20.0

	/**
		Width of the main image being displayed
	*/
	@objc public var imageWidth: CGFloat = 0.0

	/**
		Height of thumnmail strip (optional). The default is 100.
	*/
	@objc public var thumbnailStripHeight: CGFloat = 100.0

	/**
		Position of the thumbnail strip
	*/
	@objc public var thumbnailStripPosition: ScrubThumbnailStripPosition = ScrubThumbnailStripPosition.bottom

	/**
		Starting image index. The default is 0 (first image).
	*/
	@objc public var startIndex: Int = 0

	/**
		Internal Properties
	*/
	var imageCollectionView: UICollectionView!
	var thumbnailCollectionView: UICollectionView!

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
		imageWidth = view.bounds.size.width - 100
		view.backgroundColor = backgroundColor
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.setupMainCollection()
		self.setupThumbnailCollection()
		self.loadCollections()
	}

	func setupMainCollection() {

		// Image collection view
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = imagePadding

		//TODO: account for nav bar
		var frame: CGRect = CGRect.zero
		frame.origin = CGPoint(x: 0, y: imagePadding)
		frame.size.width = view.frame.size.width
		frame.size.height = view.frame.size.height - frame.origin.y - thumbnailStripHeight - imagePadding

		self.imageCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
		self.imageCollectionView.showsHorizontalScrollIndicator = false
		self.imageCollectionView.delegate = self
		self.imageCollectionView.dataSource = self
		self.imageCollectionView.backgroundColor = backgroundColor
		self.imageCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
		self.imageCollectionView.register(SCImageCell.self, forCellWithReuseIdentifier: SCBottomCellIdentifer)
		view.addSubview(self.imageCollectionView)
	}

	func setupThumbnailCollection() {

		// Thumbnail collection view
		let bottomLayout = UICollectionViewFlowLayout()
		bottomLayout.scrollDirection = .horizontal
		bottomLayout.minimumInteritemSpacing = 0
		bottomLayout.minimumLineSpacing = imagePadding

		var frame: CGRect = CGRect.zero
		frame.origin = CGPoint(x: 0, y: self.imageCollectionView.frame.size.height + self.imageCollectionView.frame.origin.y + imagePadding)
		frame.size.width = view.frame.size.width
		frame.size.height = thumbnailStripHeight - imagePadding
		self.thumbnailCollectionView = UICollectionView(frame: frame, collectionViewLayout: bottomLayout)
		self.thumbnailCollectionView.showsHorizontalScrollIndicator = false
		self.thumbnailCollectionView.allowsMultipleSelection = true
		self.thumbnailCollectionView.delegate = self
		self.thumbnailCollectionView.dataSource = self
		self.thumbnailCollectionView.backgroundColor = self.backgroundColor
		self.thumbnailCollectionView.register(SCImageCell.self, forCellWithReuseIdentifier: SCBottomCellIdentifer)
		view.addSubview(self.thumbnailCollectionView)

		// Reposition
		switch self.thumbnailStripPosition {
		case .top:
			var frame: CGRect = self.thumbnailCollectionView.frame
			frame.origin.y = 32 + imagePadding * 2
			self.thumbnailCollectionView.frame = frame
			frame = self.imageCollectionView.frame
			frame.origin.y = self.thumbnailCollectionView.frame.size.height + self.thumbnailCollectionView.frame.origin.y - imagePadding
			self.imageCollectionView.frame = frame
		case .bottom:
			break
		default:
			print("Strip position for \(thumbnailStripPosition)")
		}
	}

	func loadCollections() {
		// load collection views
		self.imageCollectionView.reloadData()
		self.thumbnailCollectionView.reloadData()
		if self.startIndex > 0 {
			let indexPath = IndexPath(item: self.startIndex, section: 0)
			self.thumbnailCollectionView.scrollToItem(at: indexPath, at: [], animated: true)
			self.imageCollectionView.scrollToItem(at: indexPath, at: [], animated: true)
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

		if collectionView == self.imageCollectionView && indexPath.item > 1 {
			self.thumbnailCollectionView.scrollToItem(at: IndexPath(item: indexPath.item - 1, section: 0), at: .centeredHorizontally, animated: true)
		}

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SCBottomCellIdentifer, for: indexPath) as! SCImageCell

		self.imageDataSource?.populateData(at: indexPath.item, forCell: cell)

		return cell
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: false)
		currentPage = indexPath.item
		self.imageCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
	}
}

//Mark: - UICollectionViewDelegateFlowLayout
extension ScrubbedPhotoViewer {

	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		guard collectionView == thumbnailCollectionView else {
			return CGSize(width: imageWidth, height: self.imageCollectionView.frame.size.height)
		}

		var size: CGSize = CGSize(width: 0, height: 0)
		size.height = collectionView.frame.size.height
		size.width = size.height * imageWidth / self.imageCollectionView.frame.size.height

		return size
	}

	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		if collectionView == self.imageCollectionView {
			return UIEdgeInsetsMake(0, (view.frame.size.width - imageWidth) / 2, 0, (view.frame.size.width - imageWidth) / 2)
		} else {
			return UIEdgeInsetsMake(0, imagePadding, 0, imagePadding)
		}
	}
}

//Mark: - UIScrollViewDelegate
extension ScrubbedPhotoViewer {
	public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
		guard scrollView == self.imageCollectionView else { return }
		scrollView.isUserInteractionEnabled = false
	}

	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		guard scrollView == self.imageCollectionView else { return }
		guard !scrollView.isDecelerating else { return }

		let item: Int = Int((scrollView.contentOffset.x - imageWidth / 2) / imageWidth) + 1

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

		self.imageCollectionView?.scrollToItem(at: IndexPath(item: currentPage, section: 0), at: .centeredHorizontally, animated: true)
	}

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		guard scrollView == self.imageCollectionView else { return }
		self.imageCollectionView?.scrollToItem(at: IndexPath(item: currentPage, section: 0), at: .centeredHorizontally, animated: true)
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

