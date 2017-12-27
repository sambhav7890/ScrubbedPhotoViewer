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
	func dataCount() -> Int
	func updatedCurrentPhotoIndex(_ controller: ScrubbedPhotoViewer)
	func populateData(at index: Int, forCell: SCImageCell)
}

/** Collection Cell For PhotoViewer. */
@objc public class SCImageCell: UICollectionViewCell {

	@objc public var imageView: UIImageView = UIImageView()

	public override init(frame: CGRect) {
		super.init(frame: frame)
		self.addImage()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.addImage()
	}

	func addImage() {
		self.imageView.frame = self.bounds
		self.contentView.addSubview(self.imageView)
	}

	public override func prepareForReuse() {
		super.prepareForReuse()
		self.imageView.image = nil
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

	@objc public private (set) var currentPage: Int = 0 {
		didSet {
			self.scrollToCurrentPage()
			self.imageDataSource?.updatedCurrentPhotoIndex(self)
		}
	}

	/**
		Internal Properties
	*/
	var imageCollectionView: UICollectionView!
	var thumbnailCollectionView: UICollectionView!

	var mainContainer: UIView?

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
		imageWidth = view.bounds.size.width
		view.backgroundColor = backgroundColor
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.setupMainCollection()
		self.setupThumbnailCollection()
		self.addConstraints()
		self.loadCollections()
	}


	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.imageCollectionView.removeFromSuperview()
		self.imageCollectionView = nil
		self.thumbnailCollectionView.removeFromSuperview()
		self.thumbnailCollectionView = nil
	}

	func setupMainCollection() {

		// Image collection view
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = imagePadding

		//TODO: account for nav bar
		var frame: CGRect = CGRect.zero
		frame.size.width = view.frame.size.width
		frame.size.height = view.frame.size.height - thumbnailStripHeight

		self.imageCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
		self.imageCollectionView.showsHorizontalScrollIndicator = false
		self.imageCollectionView.delegate = self
		self.imageCollectionView.dataSource = self
		if #available(iOS 10.0, *) {
			self.imageCollectionView.prefetchDataSource = self
		}
		self.imageCollectionView.backgroundColor = backgroundColor
		self.imageCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
		self.imageCollectionView.register(SCImageCell.self, forCellWithReuseIdentifier: SCBottomCellIdentifer)
	}

	func setupThumbnailCollection() {

		// Thumbnail collection view
		let bottomLayout = UICollectionViewFlowLayout()
		bottomLayout.scrollDirection = .horizontal
		bottomLayout.minimumInteritemSpacing = 0
		bottomLayout.minimumLineSpacing = imagePadding

		var frame: CGRect = CGRect.zero
		frame.size.width = view.frame.size.width
		frame.size.height = thumbnailStripHeight
		self.thumbnailCollectionView = UICollectionView(frame: frame, collectionViewLayout: bottomLayout)
		self.thumbnailCollectionView.showsHorizontalScrollIndicator = false
		self.thumbnailCollectionView.allowsMultipleSelection = true
		self.thumbnailCollectionView.delegate = self
		self.thumbnailCollectionView.dataSource = self
		if #available(iOS 10.0, *) {
			self.thumbnailCollectionView.prefetchDataSource = self
		}
		self.thumbnailCollectionView.backgroundColor = self.backgroundColor
		self.thumbnailCollectionView.register(SCImageCell.self, forCellWithReuseIdentifier: SCBottomCellIdentifer)

	}

	func addConstraints() {
		self.imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
		self.thumbnailCollectionView.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(self.imageCollectionView)
		view.addSubview(self.thumbnailCollectionView)

		let metrics = ["scrubberHeight": thumbnailStripHeight, "imagePadding": imagePadding]
		let views = ["view1": self.imageCollectionView, "view2": self.thumbnailCollectionView]

		// align collectionViews from the left and right
		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view1]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views));

		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view2]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views));


		// Reposition
		switch self.thumbnailStripPosition {
		case .top:
			// align collectionView from the top and bottom
			self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view2(==scrubberHeight)]-imagePadding-[view1]-imagePadding-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views));
		case .bottom:
			// align collectionView from the top and bottom
			self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-imagePadding-[view1]-imagePadding-[view2(==scrubberHeight)]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views));
			break
		}
		// align collectionView from the left and right
	}

	func loadCollections() {

		// load collection views
		self.imageCollectionView.reloadData()
		self.thumbnailCollectionView.reloadData()
		if self.startIndex > 0 {
			self.currentPage = self.startIndex
		}

		self.view.setNeedsLayout()
	}

	func scrollToCurrentPage() {
		guard self.isViewLoaded else { return }
		let indexPath = IndexPath(item: currentPage, section: 0)
		self.imageCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
		self.thumbnailCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
	}

}

//Mark: - UICollectionView Datasource
extension ScrubbedPhotoViewer {

	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.imageDataSource?.dataCount() ?? 0
	}

	public func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SCBottomCellIdentifer, for: indexPath) as! SCImageCell

		self.imageDataSource?.populateData(at: indexPath.item, forCell: cell)

		return cell
	}

	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: false)
		guard collectionView == self.thumbnailCollectionView else { return }
		self.currentPage = indexPath.item
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

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		guard scrollView == self.imageCollectionView else { return }
		self.scrollToCurrentPage()
		scrollView.isUserInteractionEnabled = true
	}


	public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		guard scrollView == self.imageCollectionView else { return }
		guard !scrollView.isDecelerating else { return }

		let visualScrollCenter = (scrollView.contentOffset.x + scrollView.bounds.width / 2)
		let imagesScrolled = ((visualScrollCenter - imageWidth) / imageWidth) + 1
		var item = Int(imagesScrolled)

		let lastItem: Int = (self.imageDataSource?.dataCount() ?? 1) - 1

		if item < 0 {
			item = 0
		} else if item > lastItem {
			item = lastItem
		}

		self.currentPage = item
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


@available (iOS 10.0, *)
protocol ScrubbedPhotoViewerDatasourcePrefetch: ScrubbedPhotoViewerDatasource {
	func prefetchData(for: ScrubbedPhotoViewer, at: [Int])
	func cancelPrefetchData(for: ScrubbedPhotoViewer, at: [Int])
}

@available (iOS 10.0, *)
extension ScrubbedPhotoViewer: UICollectionViewDataSourcePrefetching {

	public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		let rows = indexPaths.map { $0.item }
		(self.imageDataSource as? ScrubbedPhotoViewerDatasourcePrefetch)?.prefetchData(for: self, at: rows)
	}

	public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		let rows = indexPaths.map { $0.item }
		(self.imageDataSource as? ScrubbedPhotoViewerDatasourcePrefetch)?.cancelPrefetchData(for: self, at: rows)
	}
}
