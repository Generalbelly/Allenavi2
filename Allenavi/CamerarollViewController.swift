//
//  CamerarollViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/01/23.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit
import Photos
import AVKit

protocol CamerarollViewDelegate {
    func willClose()
    func photoSelected(asset: PHAsset)
}
class CamerarollViewController: UIViewController, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver, SubmittingFormVCDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var previewView: UIView!
    var forProfilePic = false
    var delegate: CamerarollViewDelegate?
    var authorized = false {
        didSet {
            if authorized {
                let allPhotosOptions = PHFetchOptions()
                allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
                allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                self.assetsFetchResults = PHAsset.fetchAssetsWithOptions(allPhotosOptions)
            }
        }
    }
    var buttonView = UIView()
    var gridThumbnailSize = CGSize()
    var imageManager: PHCachingImageManager?
    var assetsFetchResults = PHFetchResult()
    var previousPreheatRect: CGRect?
    let cameraButtonHeight: CGFloat = 120
    var cameraImage = UIImageView(frame: CGRectMake(0, 0, 50, 50))
    var defaultCameraImageCenterY: CGFloat?
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var selectedImageAsset: PHAsset?
    @IBAction func cancelTapped(sender: AnyObject) {
        self.delegate?.willClose()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBAction func selectTapped(sender: AnyObject) {
        if !self.forProfilePic {
            self.performSegueWithIdentifier("form", sender: self)
        } else {
            self.delegate?.photoSelected(self.selectedImageAsset!)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageManager = PHCachingImageManager()
        self.resetCachedAssets()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .Authorized:
            self.authorized = true
        default:
            self.requestAuth()
        }
        self.addCameraButton()
        self.getCameraReady()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.updateCachedAssets()
    }
    
    func submissionCompleted() {
        self.delegate?.willClose()
    }
    
    func requestAuth() {
        PHPhotoLibrary.requestAuthorization() { status in
            if status == PHAuthorizationStatus.Authorized {
                self.authorized = true
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession = nil
        self.stillImageOutput = nil
        self.previewLayer = nil
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    func getCameraReady() {
        self.captureSession = AVCaptureSession()
        self.captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let possibleCameraInput: AVCaptureDeviceInput?
        do {
            possibleCameraInput = try AVCaptureDeviceInput(device: backCamera)
        } catch _ as NSError {
            possibleCameraInput = nil
            return
        }
        if self.captureSession!.canAddInput(possibleCameraInput) {
            self.captureSession!.addInput(possibleCameraInput)
        }
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.previewLayer!.frame = self.previewView.frame
        self.previewView.layer.addSublayer(previewLayer!)

        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if self.captureSession!.canAddOutput(self.stillImageOutput) {
            self.captureSession!.addOutput(stillImageOutput)
        }
        let sessionQueue = dispatch_queue_create("camera_session", DISPATCH_QUEUE_SERIAL)
        dispatch_async(sessionQueue) {
            self.captureSession!.startRunning()
        }
    }
    
    func addCameraButton() {
        self.buttonView.backgroundColor = UIColor.clearColor()
        self.collectionView.backgroundColor = UIColor.clearColor()
        self.collectionView.backgroundView = self.buttonView
        let image = UIImage(named: "cameraIcon")
        self.cameraImage.contentMode = .ScaleAspectFit
        self.cameraImage.image = image
        self.buttonView.addSubview(self.cameraImage)
        self.cameraImage.center = CGPoint(x: self.view.frame.width / 2, y: self.cameraButtonHeight / 2)
        let tgr = UITapGestureRecognizer(target: self, action: #selector(CamerarollViewController.cameraButtonTapped(_:)))
        self.buttonView.addGestureRecognizer(tgr)
        self.defaultCameraImageCenterY = self.cameraImage.center.y
    }
    
    func cameraButtonTapped(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
            self.presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let sfvc = segue.destinationViewController as? SubmittingFormViewController else { return }
        sfvc.delegate = self
        sfvc.asset = self.selectedImageAsset
    }
    
    // UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assetsFetchResults.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let identifier = "photoCollectionCell"
        let asset = self.assetsFetchResults[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! CamerarollViewCell
        cell.representedAssetIdentifier = asset.localIdentifier
        let option = PHImageRequestOptions()
        option.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
        UIDevice.currentDevice()
        self.imageManager?.requestImageForAsset(asset as! PHAsset, targetSize: self.gridThumbnailSize, contentMode: .AspectFill, options: nil) { result, info in
            if cell.representedAssetIdentifier == asset.localIdentifier && result != nil {
                cell.thumbnailImage = result!
            }
        }
        if cell.selected {
            cell.selectedView.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        } else {
            cell.selectedView.backgroundColor = UIColor.clearColor()
        }
        return cell
    }
    
    // UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CamerarollViewCell
        cell.selectedView.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        if !self.selectButton.enabled {
            self.selectButton.enabled = true
        }
        self.selectedImageAsset = self.assetsFetchResults[indexPath.item] as? PHAsset
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CamerarollViewCell else { return }
        cell.selectedView.backgroundColor = UIColor.clearColor()
    }
    
    // UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = UIScreen.mainScreen().bounds.width / 3
        let itemSize = CGSize(width: width, height: width)
        self.gridThumbnailSize = itemSize
        return itemSize
    }
   
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(self.cameraButtonHeight, 0, 0, 0)
    }
    
    // UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.updateCachedAssets()
        let offsetY = abs(scrollView.contentOffset.y)
        if defaultCameraImageCenterY != nil {
            if offsetY > 64 {
                self.cameraImage.center.y = self.defaultCameraImageCenterY! + ((offsetY - 64) * 0.7)
            } else if offsetY == 64 {
                self.cameraImage.center.y = self.defaultCameraImageCenterY!
            }
        }
    }
    
    // UIImagePickerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if(picker.sourceType == UIImagePickerControllerSourceType.Camera) {
            guard let imageToSave: UIImage = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        guard let collectionChanges = changeInstance.changeDetailsForFetchResult(self.assetsFetchResults) else { return }
        dispatch_async(dispatch_get_main_queue()) {
            self.assetsFetchResults = collectionChanges.fetchResultAfterChanges
            if (!collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves) {
                // Reload the collection view if the incremental diffs are not available
                self.collectionView.reloadData()
            } else {
                let update = {
                    if let removedIndexes = collectionChanges.removedIndexes {
                        if removedIndexes.count > 0 {
                            self.collectionView.deleteItemsAtIndexPaths((removedIndexes.indexPathsFromIndexesWithSection(0)) as! [NSIndexPath])
                        }
                    }
                    if let insertedIndexes = collectionChanges.insertedIndexes {
                        if insertedIndexes.count > 0 {
                            self.collectionView.insertItemsAtIndexPaths((insertedIndexes.indexPathsFromIndexesWithSection(0)) as! [NSIndexPath])
                        }
                    }
                    if let changeIndexes = collectionChanges.changedIndexes {
                        if changeIndexes.count > 0 {
                            self.collectionView.reloadItemsAtIndexPaths((changeIndexes.indexPathsFromIndexesWithSection(0)) as! [NSIndexPath])
                        }
                    }
                }
                self.collectionView.performBatchUpdates(update, completion: nil)
            }
            self.resetCachedAssets()
        }
    }
    
    func resetCachedAssets() {
        self.imageManager?.stopCachingImagesForAllAssets()
        self.previousPreheatRect = CGRectZero
    }
    
    func updateCachedAssets() {
        if self.view != nil {
            var preheatRect = self.collectionView.bounds
            preheatRect = CGRectInset(preheatRect, 0, 0.5 * CGRectGetHeight(preheatRect))
            if self.previousPreheatRect != nil {
                let delata = abs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect!))
                if delata > CGRectGetHeight(self.collectionView.bounds) / 3 {
                    let addedIndexPath = NSMutableArray()
                    let removedIndexPaths = NSMutableArray()
                    self.computeDifferenceBetweenRect(self.previousPreheatRect!, newRect: preheatRect) { removedRect, addedRect in
                        if let indexPaths = self.collectionView.indexPathsForElementsInRect(removedRect) {
                            removedIndexPaths.addObjectsFromArray(indexPaths as [AnyObject])
                        }
                        if let indexPaths2 = self.collectionView.indexPathsForElementsInRect(addedRect) {
                            addedIndexPath.addObjectsFromArray(indexPaths2 as [AnyObject])
                        }
                    }
                    guard let assetsToStartCaching = self.assetsAtIndexPaths(addedIndexPath) else { return }
                    guard let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths) else { return }
                    
                    self.imageManager?.startCachingImagesForAssets(assetsToStartCaching as! [PHAsset], targetSize: self.gridThumbnailSize, contentMode: .AspectFill, options: nil)
                    self.imageManager?.stopCachingImagesForAssets(assetsToStopCaching as! [PHAsset], targetSize: self.gridThumbnailSize, contentMode: .AspectFill, options: nil)
                    
                    self.previousPreheatRect = preheatRect
                }
            }
        }
    }
    
    func computeDifferenceBetweenRect(oldRect: CGRect, newRect: CGRect, completionHandler: (oldRect: CGRect, newRect: CGRect) -> Void) {
        if (CGRectIntersectsRect(newRect, oldRect)) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinY(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinY(newRect)
            var rectToAdd = CGRectZero
            var rectToRemove = CGRectZero
            if (newMaxY > oldMaxY) {
                rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY))
            }
            if (oldMinY > newMinY) {
                rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY))
            }
            if (newMaxY < oldMaxY) {
                rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY))
            }
            if (oldMinY < newMinY) {
                rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY))
            }
            completionHandler(oldRect: rectToRemove, newRect: rectToAdd)
        } else {
            completionHandler(oldRect: oldRect, newRect: newRect)
        }
    }
    
    func assetsAtIndexPaths(indexPaths: NSArray) -> NSArray? {
        if indexPaths.count == 0 { return nil }
        let assets = NSMutableArray(capacity: indexPaths.count)
        for indexPath in indexPaths {
            let asset = self.assetsFetchResults[indexPath.item]
            assets.addObject(asset)
        }
        return assets
    }
}


