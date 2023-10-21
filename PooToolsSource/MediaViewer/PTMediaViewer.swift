//
//  PTMediaViewer.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/25.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SceneKit
import CoreMotion
import AVFoundation
import AVKit
import Kingfisher

public let PTViewerBaseTag = 9999
public let PTSubViewBasicsIndex = 888
public let PTViewerTitleHeight:CGFloat = 34
public typealias PTViewerSaveBlock = (_ finish:Bool) -> Void
public typealias PTViewerIndexBlock = (_ dataIndex:Int) -> Void

@objc public enum PTViewerDataType:Int {
    case Normal
    case GIF
    case Video
    case FullView
    case ThreeD
}

@objc public enum PTViewerActionType:Int {
    case All
    case Save
    case Delete
    case DIY
    case Empty
}

@objcMembers
public class PTViewerModel: NSObject {
    public var imageInfo:String = ""
    public var imageShowType:PTViewerDataType = .Normal
    public var imageURL:Any!
}

@objc public enum PTLoadingViewMode:Int {
    case LoopDiagram
    case PieDiagram
}

public let PTLoadingBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
public let PTLoadingItemSpace :CGFloat = 10
@objcMembers
public class PTLoadingView: UIView {
    
    public var progress:CGFloat = 0 {
        didSet {
            self.setNeedsDisplay()
            if progress >= 1 {
                removeFromSuperview()
            }
        }
    }
    
    fileprivate var progressMode:PTLoadingViewMode = .LoopDiagram
    
    public init(type:PTLoadingViewMode) {
        super.init(frame: .zero)
        progressMode = type
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PTLoadingBackgroundColor
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        let xCenter = rect.size.width * 0.5
        let yCenter = rect.size.height * 0.5
        UIColor.white.set()
        
        switch progressMode {
        case .PieDiagram:
            let radius = min(xCenter, yCenter) - PTLoadingItemSpace
            let w = radius * 2 - PTLoadingItemSpace
            let h = w
            let x = (rect.size.width - 2) * 0.5
            let y = (rect.size.height - 2) * 0.5
            ctx!.addEllipse(in: CGRect.init(x: x, y: y, width: w, height: h))
            ctx!.fillPath()
            
            PTLoadingBackgroundColor.set()
            ctx!.move(to: CGPoint.init(x: xCenter, y: yCenter))
            ctx?.addLine(to: CGPoint.init(x: xCenter, y: 0))
            let piFloat :CGFloat = -.pi
            let to = (piFloat * 0.5 + progress * .pi * 2 + 0.01)
            ctx!.addArc(center: CGPoint.init(x: xCenter, y: yCenter), radius: yCenter / 2, startAngle: (piFloat * 0.5), endAngle: to, clockwise: true)
            ctx!.closePath()
            ctx!.fillPath()
        case .LoopDiagram:
            ctx!.setLineWidth(4)
            ctx!.setLineCap(.round)
            let piFloat :CGFloat = -.pi
            let to = (piFloat * 0.5 + progress * .pi * 2 + 0.05)
            let radius = min(rect.size.width, rect.self.size.height) * 0.5 - PTLoadingItemSpace
            ctx!.addArc(center: CGPoint.init(x: xCenter, y: yCenter), radius: radius, startAngle: (piFloat * 0.5), endAngle: to, clockwise: false)
            ctx!.strokePath()
        }
    }
}

@objcMembers
public class PTViewerConfig: NSObject {
    ///默认到哪一页,默认0
    public var defultIndex:Int = PTViewerBaseTag
    ///数据源
    public var mediaData:[PTViewerModel]!
    ///内容的文字颜色
    public var titleColor:UIColor = UIColor.white
    ///内容字体
    public var viewerFont:UIFont = UIFont.systemFont(ofSize: 18)
    ///内容的容器背景颜色
    public var viewerContentBackgroundColor:UIColor = UIColor.black
    ///操作方式
    public var actionType:PTViewerActionType = .All
    ///关闭页面按钮图片连接/名字
    public var closeViewerImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 24))
    ///更多操作按钮图片连接/名字
    public var moreActionImage:UIImage = "🗃️".emojiToImage(emojiFont: .appfont(size: 24))
    ///更多功能扩展,如果选择全部,则默认保存0删除1........
    public var moreActionEX:[String] = []
    ///是否显示Nav右边媒体的名字
    public var showMediaTypeLabel:Bool = true
    ///iCloudDocumentName
    public var iCloudDocumentName:String = ""
}

public class PTMediaMediaView:UIView {
    let maxZoomSale:CGFloat = 2
    let minZoomSale:CGFloat = 0.6

    var isFullWidthForLandScape:Bool = false
    
    fileprivate lazy var contentScrolView:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.clipsToBounds = true
        return view
    }()
    
    fileprivate var viewConfig:PTViewerConfig!
    fileprivate var dataModel:PTViewerModel!

    //MARK: 全景相关
    fileprivate var lastPoint_x:CGFloat = 0
    fileprivate var lastPoint_y:CGFloat = 0
    fileprivate var fingerRotationX:CGFloat = 0
    fileprivate var fingerRotationY:CGFloat = 0
    fileprivate var currentScale:CGFloat = 0.0
    fileprivate var prevScale:CGFloat = 0
    fileprivate var gestureDuring:Bool? = false
    fileprivate var cameraNode:SCNNode?
    fileprivate var sceneView:SCNView?
    fileprivate var panoramaNode:SCNNode?
    fileprivate lazy var motionManager : CMMotionManager = {
        let view = CMMotionManager()
        view.deviceMotionUpdateInterval = 1/6
        return view
    }()

    //MARK: 图片相关
    fileprivate var scrollOffset:CGPoint? = CGPoint.zero
    public lazy var zoomImageSize:CGSize? = CGSize.init(width: frame.size.width, height: frame.size.height)
    var hasLoadedImage:Bool? = false
    fileprivate lazy var reloadButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.viewCorner(radius: 2,borderWidth:1,borderColor: .white)
        view.titleLabel?.font = UIFont.init(name: self.viewConfig.viewerFont.familyName, size: self.viewConfig.viewerFont.pointSize * 0.7)
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        view.setTitle("图片加载失败,点击重试", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.addActionHandlers { sender in
            self.reloadButton.removeFromSuperview()
            self.setMediaData(dataModel: self.dataModel)
        }
        return view
    }()
    
    fileprivate lazy var imageView:UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    fileprivate var gifImage:UIImage? = nil

    //MARK: 视频相关
    var playedVideo:Bool? = false
    fileprivate var playedFull:Bool? = false
    
    fileprivate lazy var player:AVPlayerViewController = {
        let view = AVPlayerViewController()
        return view
    }()
    
    fileprivate lazy var videoSlider:UISlider = {
        let view = UISlider()
        view.addSliderAction { sender in
            self.player.player!.pause()
            self.playInSomeTime(someTime: sender.value)
        }
        let sliderTap = UITapGestureRecognizer.init { sender in
            self.player.player!.pause()
            let touchPoint = (sender as! UITapGestureRecognizer).location(in: self.videoSlider)
            let value = CGFloat(self.videoSlider.maximumValue - self.videoSlider.minimumValue) / (touchPoint.x / self.videoSlider.frame.size.width)
            self.videoSlider.setValue(Float(value), animated: true)
            self.playInSomeTime(someTime: Float(value))
        }
        view.addGestureRecognizer(sliderTap)
        return view
    }()
    
    let bundlePath = Bundle.init(path: PTUtils.cgBaseBundle().path(forResource: "PooTools", ofType: "bundle")!)

    fileprivate lazy var playBtn:UIButton = {
        
        let playImage = UIImage.init(contentsOfFile: bundlePath!.path(forResource: "p_play", ofType: "png")!)

        let view = UIButton.init(type: .custom)
        view.setImage(playImage, for: .normal)
        view.addActionHandlers { sender in
            self.stopBtn.isHidden = false
            self.videoSlider.isHidden = false
            sender.isHidden = true
            if self.playedFull! {
                self.playInSomeTime(someTime: 0)
            } else {
                self.player.player!.play()
            }
            self.playBtn.isHidden = true
        }
        return view
    }()
    
    fileprivate lazy var stopBtn:UIButton = {
        let playImage = UIImage.init(contentsOfFile: bundlePath!.path(forResource: "p_play", ofType: "png")!)
        let stopImage = UIImage.init(contentsOfFile: bundlePath!.path(forResource: "p_pause", ofType: "png")!)

        let view = UIButton.init(type: .custom)
        view.setImage(playImage, for: .selected)
        view.setImage(stopImage, for: .normal)
        view.addActionHandlers { sender in
            sender.isSelected = !sender.isSelected
            if sender.isSelected {
                self.player.player!.pause()
            } else {
                self.stopBtn.isHidden = false
                self.videoSlider.isHidden = false
                if self.playedFull! {
                    self.playInSomeTime(someTime: 0)
                } else {
                    self.player.player!.play()
                }
            }
        }
        return view
    }()
    
    init(viewConfig:PTViewerConfig) {
        super.init(frame: .zero)
        
        self.viewConfig = viewConfig
        
        addSubview(contentScrolView)
        contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func adjustFrame() {
        switch dataModel.imageShowType {
        case .GIF,.Normal:
            if gifImage != nil {
                let imageSize = gifImage!.size
                var imageFrame = CGRect.init(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
                if isFullWidthForLandScape {
                    let ratio = frame.size.width / imageFrame.size.width
                    imageFrame.size.height = imageFrame.size.height * ratio
                    imageFrame.size.width = frame.size.width
                } else {
                    if frame.size.width <= frame.size.height {
                        let ratio = frame.size.width / imageFrame.size.width
                        imageFrame.size.height = imageFrame.size.height * ratio
                        imageFrame.size.width = frame.size.width
                    } else {
                        let ratio = frame.size.height / imageFrame.size.height
                        imageFrame.size.width = imageFrame.size.width * ratio
                        imageFrame.size.height = frame.size.height
                    }
                }
                imageView.frame = imageFrame
                contentScrolView.contentSize = imageView.frame.size
                imageView.center = PTMediaMediaView.centerOfScrollVIewContent(scrollView: contentScrolView)
                
                var maxScale = frame.size.height / imageFrame.size.height
                maxScale = frame.size.width / imageFrame.self.width > maxScale ? frame.self.width / imageFrame.self.width : maxScale
                maxScale = maxScale > maxZoomSale ? maxScale : maxZoomSale
                contentScrolView.minimumZoomScale = minZoomSale
                contentScrolView.maximumZoomScale = maxScale
                contentScrolView.zoomScale = 1
            } else {
                frame.origin = .zero
                imageView.frame = frame
                contentScrolView.contentSize = imageView.frame.size
            }
            contentScrolView.contentOffset = .zero
            zoomImageSize = imageView.frame.size
        default:
            break
        }
    }
    
    func setMediaData(dataModel:PTViewerModel) {
        self.dataModel = dataModel
        
        let loading = PTLoadingView.init(type: .LoopDiagram)
        addSubview(loading)
        loading.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.centerX.centerY.equalToSuperview()
        }
        
        PTGCDManager.gcdAfter(time: 0.1) {
            switch dataModel.imageShowType {
            case .ThreeD,.FullView:
                if dataModel.imageURL is String {
                    let urlString = dataModel.imageURL as! String
                    if urlString.isValidUrl {
                        ImageDownloader.default.downloadImage(with: URL(string: urlString)!,options: PTAppBaseConfig.share.gobalWebImageLoadOption(), progressBlock: { receivedSize, totalSize in
                            PTGCDManager.gcdMain {
                                loading.progress = CGFloat(receivedSize / totalSize)
                            }
                        }) { result in
                            switch result {
                            case .success(let value):
                                loading.removeFromSuperview()
                                self.createThreeDView(image: value.image)
                            case .failure(let error):
                                loading.removeFromSuperview()
                                PTNSLogConsole(error)
                                self.createReloadButton()
                            }
                        }
                    }
                } else if dataModel.imageURL is UIImage {
                    loading.removeFromSuperview()
                    self.createThreeDView(image: dataModel.imageURL as! UIImage)
                }
            case .Video:
                loading.removeFromSuperview()
                self.contentScrolView.delaysContentTouches = false
                if dataModel.imageURL is String {
                    self.playedVideo = false

                    var videoUrl:NSURL?
                    let urlString = dataModel.imageURL as! String
                    if FileManager.pt.judgeFileOrFolderExists(filePath: urlString) {
                        videoUrl = NSURL.init(fileURLWithPath: urlString)
                    } else {
                        videoUrl = NSURL.init(string: urlString.nsString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
                    }
                    
                    let opts = NSDictionary.init(object: NSNumber.init(booleanLiteral: false), forKey: AVURLAssetPreferPreciseDurationAndTimingKey as NSCopying)
                    let urlAsset = AVURLAsset.init(url: videoUrl! as URL,options: (opts as! [String : Any]))
                    let playerItem = AVPlayerItem.init(asset: urlAsset)
                    self.player.player = AVPlayer.init(playerItem: playerItem)
                    self.player.showsPlaybackControls = false
                    self.contentScrolView.addSubview(self.player.view)
                    PTGCDManager.gcdAfter(time: 0.1) {
                        self.player.view.snp.makeConstraints { make in
                            make.width.equalTo(self.frame.size.width)
                            make.top.equalTo(CGFloat.kNavBarHeight)
                            make.left.equalTo(0)
                            make.height.equalTo(self.frame.size.height - CGFloat.kNavBarHeight - 80)
                        }
                    }
                    
                    self.player.player!.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: nil, using: { time in
                        
                        let duration = Float(CMTimeGetSeconds(self.player.player?.currentItem?.duration ?? .zero))
                        
                        self.videoSlider.maximumValue = duration
                        self.videoSlider.minimumValue = 0
                        
                        let progress = Float(CMTimeGetSeconds(self.player.player!.currentItem!.currentTime())) / duration
                        
                        let sliderCurrentValue = Float(CMTimeGetSeconds(self.player.player!.currentItem!.currentTime()))
                        
                        self.videoSlider.setValue(sliderCurrentValue, animated: true)
                        
                        if progress >= 1 {
                            self.playedFull = true
                            if !self.playedVideo! {
                                self.playBtn.isHidden = false
                            }
                            self.videoSlider.isHidden = true
                            self.videoSlider.setValue(0, animated: true)
                            self.stopBtn.isHidden = true
                        }
                    })
                    
                    self.contentScrolView.addSubviews([self.playBtn,self.stopBtn,self.videoSlider])
                    self.playBtn.snp.makeConstraints { make in
                        make.width.height.equalTo(44)
                        make.centerX.centerY.equalToSuperview()
                    }
                    
                    self.stopBtn.snp.makeConstraints { make in
                        make.width.height.equalTo(44)
                        make.left.equalTo(self.player.view).offset(10)
                        make.bottom.equalTo(self.player.view).offset(-10)
                    }
                    self.stopBtn.isHidden = true
                    
                    self.videoSlider.snp.makeConstraints { make in
                        make.left.equalTo(self.stopBtn.snp.right).offset(10)
                        make.right.equalTo(self.player.view).offset(-10)
                        make.height.equalTo(20)
                        make.centerY.equalTo(self.stopBtn)
                    }
                    self.videoSlider.isHidden = true
                    self.hasLoadedImage = true
                }
            case .GIF,.Normal:
                self.imageView.contentMode = .scaleAspectFit
                self.contentScrolView.addSubview(self.imageView)
                
                PTLoadImageFunction.loadImage(contentData: dataModel.imageURL as Any,iCloudDocumentName: self.viewConfig.iCloudDocumentName) { receivedSize, totalSize in
                    loading.progress = CGFloat(receivedSize / totalSize)
                } taskHandle: { images in
                    if images.count > 1 {
                        self.gifImage = images.first
                        self.imageView.animationImages = images
                        self.imageView.animationDuration = 2
                        self.imageView.startAnimating()
                        self.adjustFrame()
                        self.hasLoadedImage = true
                        loading.removeFromSuperview()
                    } else if images.count == 1 {
                        self.gifImage = images.first
                        self.imageView.image = images.first
                        self.adjustFrame()
                        self.hasLoadedImage = true
                        loading.removeFromSuperview()
                    } else {
                        loading.removeFromSuperview()
                        self.createReloadButton()
                        self.adjustFrame()
                    }
                }                
            default:
                break
            }
        }
    }
    
    func createThreeDView(image:UIImage) {
        let camera = SCNCamera()
        cameraNode = SCNNode()
        
        sceneView = SCNView()
        sceneView?.scene = SCNScene()
        contentScrolView.addSubview(sceneView!)
        sceneView?.snp.makeConstraints({ make in
            make.left.right.equalToSuperview()
            make.height.equalTo(self.frame.size.height - CGFloat.kNavBarHeight - 80)
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight)
        })
        sceneView?.allowsCameraControl = true
        
        cameraNode?.camera = camera
        cameraNode?.camera?.automaticallyAdjustsZRange = true
        cameraNode?.position = SCNVector3.init(x: 0, y: 0, z: 0)
        cameraNode?.camera?.fieldOfView = 60
        cameraNode?.camera?.focalLength = 60
        sceneView?.scene?.rootNode.addChildNode(cameraNode!)
        
        panoramaNode = SCNNode()
        panoramaNode?.geometry = SCNSphere.init(radius: 150)
        panoramaNode?.geometry?.firstMaterial?.cullMode = .front
        panoramaNode?.geometry?.firstMaterial?.isDoubleSided = true
        panoramaNode?.position = SCNVector3.init(x: 0, y: 0, z: 0)
        sceneView?.scene?.rootNode.addChildNode(panoramaNode!)
        
        panoramaNode?.geometry?.firstMaterial?.diffuse.contents = image
        
        let pan = UIPanGestureRecognizer.init { sender in
            let ges = sender as! UIPanGestureRecognizer
            if ges.delaysTouchesBegan {
                self.gestureDuring = true
                let currentPoint = ges.location(in: self.sceneView)
                self.lastPoint_x = currentPoint.x
                self.lastPoint_y = currentPoint.y
            } else if ges.delaysTouchesEnded {
                self.gestureDuring = false
            } else {
                let currentPoint = ges.location(in: self.sceneView)
                var distX = currentPoint.x - self.lastPoint_x
                var distY = currentPoint.y - self.lastPoint_y
                self.lastPoint_x = currentPoint.x
                self.lastPoint_y = currentPoint.y
                distX *= -0.003
                distY *= -0.003
                self.fingerRotationX += distX
                self.fingerRotationY += distY
                var modelMatrix = SCNMatrix4MakeRotation(0, 0, 0, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, Float(self.fingerRotationX), 0, 1, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, Float(self.fingerRotationY), 1, 0, 0)
                self.cameraNode?.pivot = modelMatrix
            }
        }
        sceneView?.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer.init { sender in
            //TODO: pinch
            let ges = sender as! UIPinchGestureRecognizer
            if ges.state != .ended && ges.state != .failed {
                if ges.scale != 0.0 {
                    var scale = ges.scale - 1
                    if scale < 0 {
                        scale *= (5 - 0.5)
                    }
                    self.currentScale = scale + self.prevScale
                    self.currentScale = self.validateScale(scale: self.currentScale)
                    
                    let valScale = self.validateScale(scale: self.currentScale)
                    let scaleRatio = 1 - (valScale - 1) * 0.15
                    let xFov = 60 * scaleRatio
                    let yFov = 60 * scaleRatio
                    
                    self.cameraNode?.camera?.fieldOfView = xFov
                    self.cameraNode?.camera?.focalLength = yFov
                }
            } else if ges.state == .ended {
                self.prevScale = self.currentScale
            }
        }
        sceneView?.addGestureRecognizer(pinch)
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates()
        } else {
            PTNSLogConsole("该设备的deviceMotion不可用")
        }
        
        motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue.current!) { motion, error in
            
            var orientation:UIInterfaceOrientation = .unknown
            orientation = PTUtils.getCurrentVC().view.window!.windowScene!.interfaceOrientation

            if orientation == .portrait && !self.gestureDuring! {
                var modelMatrix = SCNMatrix4MakeRotation(0, 0, 0, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, -Float(motion!.attitude.roll), 0, 1, 0)
                modelMatrix = SCNMatrix4Rotate(modelMatrix, -Float(motion!.attitude.pitch), 1, 0, 0)
                self.cameraNode?.pivot = modelMatrix
            }
        }
        
        hasLoadedImage = true
        contentScrolView.contentSize = CGSize.init(width: frame.size.width, height: frame.size.height)
    }
    
    func validateScale(scale:CGFloat)->CGFloat {
        var validateScale = scale
        if scale < 0.5 {
            validateScale = 0.5
        } else if scale > 5 {
            validateScale = 5
        }
        return validateScale
    }
    
    func createReloadButton() {
        hasLoadedImage = false
        addSubview(reloadButton)
        reloadButton.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.height.equalTo(40)
            make.centerY.centerX.equalToSuperview()
        }
        bringSubviewToFront(reloadButton)
    }
    
    func playInSomeTime(someTime:Float) {
        let fps = player.player!.currentItem!.asset.tracks(withMediaType: .video)[0].nominalFrameRate
        let time = CMTimeMakeWithSeconds(Float64(someTime), preferredTimescale: Int32(fps))
        self.player.player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { finish in
            self.player.player!.play()
        })
    }
    
    open class func centerOfScrollVIewContent(scrollView:UIScrollView) ->CGPoint {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? ((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5) : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? ((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5) : 0
        let actualCenter = CGPoint.init(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
}

extension PTMediaMediaView:UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        zoomImageSize = view?.frame.size
        scrollOffset = scrollView.contentOffset
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = PTMediaMediaView.centerOfScrollVIewContent(scrollView: scrollView)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollOffset = scrollView.contentOffset
    }
}

@objcMembers
public class PTMediaViewer: UIView {

    public var viewerDismissBlock:PTActionTask?
    public var viewSaveImageBlock:PTViewerSaveBlock?
    public var viewDeleteImageBlock:PTViewerIndexBlock?
    public var viewMoreActionBlock:PTViewerIndexBlock?

    fileprivate var actionSheetTitle:[String] = []
    fileprivate var viewConfig:PTViewerConfig!
    fileprivate var imagesScrollViews = [UIView]()
    fileprivate var page:Int = 0
    fileprivate var showLabel:Bool? = false
    fileprivate lazy var fullViewLabel:UIButton = {
        let view = UIButton.init(type: .custom)
        view.titleLabel?.font = self.viewConfig.viewerFont
        view.setTitleColor(self.viewConfig.titleColor, for: .normal)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    fileprivate lazy var pageView_label:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.textColor = self.viewConfig.titleColor
        view.font = self.viewConfig.viewerFont
        return view
    }()
    
    fileprivate lazy var pageView:UIPageControl = {
        let view = UIPageControl()
        view.backgroundColor = .clear
        view.pageIndicatorTintColor = .lightGray
        view.currentPageIndicatorTintColor = .white
        return view
    }()

    fileprivate lazy var backgroundView:UIView = {
        let view = UIView()
        view.backgroundColor = self.viewConfig.viewerContentBackgroundColor
        return view
    }()
    
    fileprivate lazy var contentScrolView:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    fileprivate var hideNavAndBottom:Bool? = false
    
    fileprivate lazy var fakeNav:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)
        return view
    }()
    
    fileprivate lazy var bottomView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)
        return view
    }()
    
    fileprivate lazy var moreActionButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.setImage(self.viewConfig.moreActionImage, for: .normal)
        view.addActionHandlers { sender in
            UIAlertController.baseActionSheet(title: "更多操作", cancelButtonName: "取消",titles: self.actionSheetTitle) { sheet in
                
            } cancelBlock: { sheet in
                
            } otherBlock: { sheet, index in
                switch self.viewConfig.actionType {
                case .Save:
                    switch index {
                    case 0:
                        self.saveImage()
                    default:
                        if self.viewMoreActionBlock != nil {
                            self.viewMoreActionBlock!(index - 1)
                        }
                        self.viewDismissAction()
                    }
                case .Delete:
                    switch index {
                    case 0:
                        self.deleteImage()
                    default:
                        if self.viewMoreActionBlock != nil {
                            self.viewMoreActionBlock!(index - 1)
                        }
                        self.viewDismissAction()
                    }
                case .All:
                    switch index {
                    case 0:
                        self.saveImage()
                    case 1:
                        self.deleteImage()
                    default:
                        if self.viewMoreActionBlock != nil {
                            self.viewMoreActionBlock!(index - 2)
                        }
                        self.viewDismissAction()
                    }
                case .DIY:
                    if self.viewMoreActionBlock != nil {
                        self.viewMoreActionBlock!(index)
                    }
                    self.viewDismissAction()
                default:
                    break
                }

            } tapBackgroundBlock: { sheet in
                
            }
        }
        return view
    }()

    fileprivate lazy var labelScroller:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    fileprivate lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.textColor = self.viewConfig.titleColor
        view.textAlignment = .left
        view.font = UIFont.init(name: self.viewConfig.viewerFont.familyName, size: self.viewConfig.viewerFont.pointSize * 0.8)
        view.numberOfLines = 0
        view.lineBreakMode = .byTruncatingTail
        view.textColor = self.viewConfig.titleColor
        return view
    }()

    fileprivate lazy var indexLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = self.viewConfig.viewerFont
        view.textColor = self.viewConfig.titleColor
        return view
    }()
    
    fileprivate lazy var backButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.imageView?.contentMode = .scaleAspectFit
        view.setImage(self.viewConfig.closeViewerImage, for: .normal)
        view.addActionHandlers { sender in
            self.viewDismissAction()
            if self.viewerDismissBlock != nil {
                self.viewerDismissBlock!()
            }
        }
        return view
    }()
    
    fileprivate lazy var tempView:UIImageView = {
        let view = UIImageView()
        
        let currentView = self.contentScrolView.subviews[self.page] as! PTMediaMediaView
        
        let currentImageView = currentView.imageView
        let tempImageX = currentImageView.frame.origin.x - currentView.scrollOffset!.x
        var tempImageY = currentImageView.frame.origin.y - currentView.scrollOffset!.y

        let tempImageW = currentView.zoomImageSize!.width
        var tempImageH = currentView.zoomImageSize!.height
        
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape {
            if tempImageH > self.frame.size.height {
                tempImageH = tempImageH > (tempImageW * 1.5) ? (tempImageW * 1.5) : tempImageH
                if abs(tempImageY) > tempImageH {
                    tempImageY = 0
                }
            }
        }
        
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.frame = CGRect.init(x: tempImageX, y: tempImageY, width: tempImageW, height: tempImageH)
        view.image = currentImageView.image
        return view
    }()
    
    fileprivate lazy var coverView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
        return view
    }()

    public init(viewConfig:PTViewerConfig!) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
        switch self.viewConfig.actionType {
        case .All:
            actionSheetTitle = ["保存媒体","删除图片"]
            self.viewConfig.moreActionEX.enumerated().forEach { index,value in
                actionSheetTitle.append(value)
            }
        case .Save:
            actionSheetTitle = ["保存媒体"]
            self.viewConfig.moreActionEX.enumerated().forEach { index,value in
                actionSheetTitle.append(value)
            }
        case .Delete:
            actionSheetTitle = ["删除图片"]
            self.viewConfig.moreActionEX.enumerated().forEach { index,value in
                actionSheetTitle.append(value)
            }
        case .DIY:
            self.viewConfig.moreActionEX.enumerated().forEach { index,value in
                actionSheetTitle.append(value)
            }
        default:
            break
        }
        
        addSubview(contentScrolView)
        contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(fakeNav)
        fakeNav.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight_Total)
        }
        
        addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kTabbarHeight)
        }

        if self.viewConfig.mediaData.count > 1 {
            fakeNav.addSubview(indexLabel)
            indexLabel.text = "1/\(self.viewConfig.mediaData.count)"
            indexLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + (CGFloat.kNavBarHeight - PTViewerTitleHeight) / 2)
                make.height.equalTo(PTViewerTitleHeight)
            }
        }
        
        fakeNav.addSubview(fullViewLabel)
        fullViewLabel.snp.makeConstraints { make in
            make.height.equalTo(PTViewerTitleHeight)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + (CGFloat.kNavBarHeight - PTViewerTitleHeight) / 2)
            make.right.equalToSuperview().inset(20)
        }
        fullViewLabel.isHidden = self.viewConfig.showMediaTypeLabel
        
        fakeNav.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.width.height.equalTo(PTViewerTitleHeight)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + (CGFloat.kNavBarHeight - PTViewerTitleHeight) / 2)
            make.left.equalToSuperview().inset(10)
        }

        if self.viewConfig.mediaData.count > 10 {
            showLabel = true
            pageView_label.text = "1/\(self.viewConfig.mediaData.count)"
            addSubview(pageView_label)
            pageView_label.snp.makeConstraints { make in
                make.height.equalTo(PTViewerTitleHeight)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(20)
            }
        } else {
            showLabel = false
            addSubview(pageView)
            pageView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(20)
                make.height.equalTo(20)
            }
            if self.viewConfig.mediaData.count > 1 {
                pageView.isHidden = false
            } else {
                pageView.isHidden = true
            }
        }
        
        isUserInteractionEnabled = true
        
        bottomView.addSubview(labelScroller)
        labelScroller.addSubview(titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func touchAction() {
        let doubleTap = UITapGestureRecognizer.init { sender in
            let currentView = self.contentScrolView.subviews[self.page] as! PTMediaMediaView
            let touchPoint = (sender as! UITapGestureRecognizer).location(in: self)
            if currentView.contentScrolView.zoomScale <= 1 {
                let scaleX = touchPoint.x + currentView.contentScrolView.contentOffset.x
                let scaleY = touchPoint.y + currentView.contentScrolView.contentOffset.y
                currentView.contentScrolView.zoom(to: CGRect.init(x: scaleX, y: scaleY, width: 10, height: 10), animated: true)
            } else {
                currentView.contentScrolView.setZoomScale(1, animated: true)
            }
        }
        doubleTap.numberOfTapsRequired = 2

        let singleTap = UITapGestureRecognizer.init { sender in
            UIView.animate(withDuration: 0.4) {
                self.fakeNav.alpha = self.hideNavAndBottom! ? 1 : 0
                self.bottomView.alpha = self.fakeNav.alpha
                if self.showLabel! {
                    self.pageView_label.alpha = self.hideNavAndBottom! ? 0 : 1
                } else {
                    self.pageView.alpha = self.hideNavAndBottom! ? 0 : 1
                }
                self.hideNavAndBottom = !self.hideNavAndBottom!
            } completion: { finish in
                
            }
        }
        singleTap.numberOfTapsRequired = 1
        singleTap.delaysTouchesBegan = true
        singleTap.require(toFail: doubleTap)
        
        let pan = UIPanGestureRecognizer.init { sender in
            let panGes = sender as! UIPanGestureRecognizer
            
            self.contentScrolView.isScrollEnabled = false
            let orientation = UIDevice.current.orientation
            if orientation.isLandscape {
                return
            }
            
            let transPoint = panGes.translation(in: self)
            let veloctiy = panGes.velocity(in: self)
            
            PTNSLogConsole(">>>>>>>>>>>>>>>>>>.\(panGes.state)")
            
            switch panGes.state {
            case .began:
                self.prepareForHide()
            case .changed:
                self.fakeNav.alpha = 0
                self.bottomView.alpha = 0
                var delt = 1 - abs(transPoint.y) / self.frame.size.height
                delt = max(delt, 0)
                let s = max(delt, 0.5)
                let translation = CGAffineTransform(translationX: transPoint.x / s, y: transPoint.y / s)
                let scale = CGAffineTransform(scaleX: s, y: s)
                self.tempView.transform = translation.concatenating(scale)
                PTNSLogConsole(">>>>>>>>>>>>>>>>>>.\(delt)")
                self.coverView.alpha = delt
            case .ended:
                if abs(transPoint.y) > 220 || abs(veloctiy.y) > 500 {
                    self.hideAnimation()
                } else {
                    self.bounceToOriginal()
                }
                self.contentScrolView.isScrollEnabled = true
            default:break
            }
        }
        
//        let current = self.contentScrolView.subviews[self.page] as! PTMediaMediaView
        addGestureRecognizers([singleTap,doubleTap,pan])
    }
    
    public func showImageViewer() {
        let windows = AppWindows!
        windows.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        show(content: backgroundView) {
            UIView.animate(withDuration: 0.5) {
                self.alpha = 1
                self.backgroundView.alpha = 1
            } completion: { finish in
            }
        }
    }
    
    func show(content:UIView,loadFinishBlock:@escaping PTActionTask) {
        content.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        PTGCDManager.gcdAfter(time: 0.1) {
            self.contentScrolView.contentSize = CGSize.init(width: self.frame.size.width * CGFloat(self.viewConfig.mediaData.count), height: self.frame.size.height)
            let w = self.frame.size.width
            self.viewConfig.mediaData.enumerated().forEach { index,value in
                let imageScroll = PTMediaMediaView.init(viewConfig: self.viewConfig)
                imageScroll.isFullWidthForLandScape = false
                imageScroll.tag = PTSubViewBasicsIndex + index
                imageScroll.setMediaData(dataModel: value)
                self.contentScrolView.addSubview(imageScroll)
                imageScroll.snp.makeConstraints { make in
                    make.left.equalTo(w * CGFloat(index))
                    make.top.equalTo(0)
                    make.width.equalTo(w)
                    make.height.equalTo(self.frame.size.height)
                }
                self.imagesScrollViews.append(imageScroll)
            }
            self.contentScrolView.setContentOffset(CGPoint.init(x: w * CGFloat(self.viewConfig.defultIndex - PTViewerBaseTag), y: 0), animated: false)
            if self.fullImageHidden() == "全景" {
                self.fullViewLabel.isUserInteractionEnabled = true
            } else {
                self.fullViewLabel.isUserInteractionEnabled = false
            }
            self.fullViewLabel.setTitle(self.fullImageHidden(), for: .normal)
            
            if self.showLabel! {
                self.pageView_label.text = "\(self.page + 1)" + "/" + "\(self.viewConfig.mediaData.count)"
            } else {
                self.pageView.numberOfPages = self.viewConfig.mediaData.count
                self.pageView.currentPage = self.page
            }
            
            let models = self.viewConfig.mediaData[self.page]
            self.updateBottomSize(models: models)
            
            loadFinishBlock()
            
            UIView.animate(withDuration: 0.4) {
                self.alpha = 1
            } completion: { finished in
                self.touchAction()
            }
        }
    }
    
    func fullImageHidden()->String {
        let models = viewConfig.mediaData[page]
        switch models.imageShowType {
        case .FullView:
            return "全景"
        case .ThreeD:
            return "3D"
        case .GIF:
            return "GIF"
        case .Video:
            return "视频"
        default:
            return "普通"
        }
    }
    
    func viewDismissAction() {
        viewConfig.mediaData.enumerated().forEach { index,value in
            let currentImages = contentScrolView.subviews[page] as! PTMediaMediaView
            switch currentImages.dataModel.imageShowType {
            case .GIF:
                currentImages.imageView.stopAnimating()
            case .Video:
                currentImages.player.player?.pause()
            default:break
            }
        }
    
        UIView.animate(withDuration: 0.4) {
            self.fakeNav.alpha = self.hideNavAndBottom! ? 1 : 0
            self.bottomView.alpha = self.fakeNav.alpha
            if self.showLabel! {
                self.pageView_label.alpha = self.hideNavAndBottom! ? 0 : 1
            } else {
                self.pageView.alpha = self.hideNavAndBottom! ? 0 : 1
            }
            
            self.hideNavAndBottom = !self.hideNavAndBottom!
            self.coverView.removeFromSuperview()
            self.tempView.removeFromSuperview()
            self.contentScrolView.removeSubviews()
            self.imagesScrollViews.removeAll()
            self.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
        } completion: { finish in
        }
    }
    
    func saveImage() {
        let model = viewConfig.mediaData[page]
        
        let currentView = imagesScrollViews[page] as! PTMediaMediaView
        switch model.imageShowType {
        case .FullView,.ThreeD:
            if currentView.hasLoadedImage! {
                let fullImage = currentView.panoramaNode?.geometry?.firstMaterial?.diffuse.contents as! UIImage
                saveImageToPhotos(saveImage: fullImage)
            } else {
                if viewSaveImageBlock != nil {
                    viewSaveImageBlock!(false)
                }
            }
        case .Video:
            saveVideoAction(url: model.imageURL as! String)
        default:
            saveImageToPhotos(saveImage: currentView.gifImage!)
        }
    }
    
    func saveVideoAction(url:String) {
        let currentMediaView = imagesScrollViews[page] as! PTMediaMediaView
        let loadingView = PTLoadingView.init(type: .LoopDiagram)
        currentMediaView.player.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.width.equalTo(currentMediaView.frame.size.width * 0.5)
            make.height.equalTo(currentMediaView.frame.size.height * 0.5)
            make.centerX.centerY.equalToSuperview()
        }
        
        let documentDirectory = FileManager.pt.DocumnetsDirectory()
        let fullPath = documentDirectory + "/\(String.currentDate(dateFormatterString: "yyyy-MM-dd_HH:mm:ss")).mp4"
        _ = PTFileDownloadApi(fileUrl: url, saveFilePath: fullPath) { bytesRead, totalBytesRead, progress in
            PTGCDManager.gcdMain {
                loadingView.progress = progress
            }
        } success: { reponse in
            loadingView.removeFromSuperview()
            self.saveVideo(videoPath: fullPath)
        } fail: { error in
        }
    }
    
    func saveVideo(videoPath:String) {
        let url = NSURL.fileURL(withPath: videoPath)
        let compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
        if compatible {
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(save(image:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            if viewSaveImageBlock != nil {
                viewSaveImageBlock!(compatible)
            }
        }
    }
    
    func saveImageToPhotos(saveImage:UIImage) {
        UIImageWriteToSavedPhotosAlbum(saveImage, self, #selector(save(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func save(image:UIImage, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
            
        var saveImageBool:Bool? = false
        if didFinishSavingWithError != nil {
            saveImageBool = false
        } else {
            saveImageBool = true
        }
        
        if viewSaveImageBlock != nil {
            viewSaveImageBlock!(saveImageBool!)
        }
    }
    
    func deleteImage() {
        if contentScrolView.subviews.count == 1 && imagesScrollViews.count == 1 {
            viewDismissAction()
            if viewDeleteImageBlock != nil {
                viewDeleteImageBlock!(0)
            }
        } else {
            let index = page
            let currentImages = contentScrolView.subviews[page] as! PTMediaMediaView
            switch currentImages.dataModel.imageShowType {
            case .GIF:
                currentImages.imageView.stopAnimating()
            case .Video:
                currentImages.player.player?.pause()
            default:
                break
            }
            currentImages.removeFromSuperview()
            
            UIView.animate(withDuration: 0.1) {
                var newIndex = self.page - 1
                if newIndex < 0 {
                    newIndex = 0
                } else if newIndex == 0 {
                    newIndex = 0
                } else {
                    newIndex = self.page - 1
                }
                
                self.page = newIndex
                
                self.viewConfig.mediaData.remove(at: index)
                self.imagesScrollViews.remove(at: index)
                self.contentScrolView.contentSize = CGSize.init(width: CGFloat(self.viewConfig.mediaData.count) * self.frame.size.width, height: self.contentScrolView.contentSize.height)
                self.contentScrolView.setContentOffset(CGPoint.init(x: self.page * Int(self.frame.size.width), y: 0), animated: false)
                if self.viewConfig.mediaData.count > 1 {
                    var textIndex = Int(self.contentScrolView.contentOffset.x / self.contentScrolView.bounds.size.width)
                    if textIndex == 0 {
                        textIndex = 1
                    }
                    self.indexLabel.text = "\(textIndex + 1)/\(self.viewConfig.mediaData.count)"
                } else {
                    self.indexLabel.removeFromSuperview()
                }
                
                let models = self.viewConfig.mediaData[self.page]
                self.updateBottomSize(models: models)
                
                if self.showLabel! {
                    self.pageView_label.text = "\(self.page + 1)" + "/" + "\(self.viewConfig.mediaData.count)"
                } else {
                    self.pageView.numberOfPages = self.viewConfig.mediaData.count
                    self.pageView.currentPage = self.page
                }

                if self.viewDeleteImageBlock != nil {
                    self.viewDeleteImageBlock!(self.page)
                }
            }
        }
    }
    
    func bounceToOriginal() {
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.35) {
            self.tempView.transform = CGAffineTransform.identity
            self.backgroundView.alpha = 1
        } completion: { finish in
            self.isUserInteractionEnabled = true
            self.fakeNav.alpha = 1
            self.bottomView.alpha = 1
            self.tempView.removeFromSuperview()
            self.coverView.removeFromSuperview()
            self.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
            self.backgroundView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
            let currentView = self.getSourceView()
            currentView.alpha = 1
        }
    }
    
    func prepareForHide() {
        backgroundView.insertSubview(coverView, belowSubview: self)
        coverView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        fakeNav.alpha = 0
        bottomView.alpha = 0
        backgroundView.addSubview(tempView)
        backgroundColor = .clear
        backgroundView.backgroundColor = .clear
        let currentView = getSourceView()
        currentView.alpha = 0
    }
    
    func getSourceView()->UIView {
        let currentView = contentScrolView.subviews[page] as! PTMediaMediaView
        return currentView
    }
    
    func hideAnimation() {
        isUserInteractionEnabled = false
        let window = AppWindows!
        var targetTemp:CGRect? = CGRect.init(x: window.center.x, y: window.center.y, width: 0, height: 0)
        let currentView = contentScrolView.subviews[page] as! PTMediaMediaView
        switch currentView.dataModel.imageShowType {
        case .Normal,.GIF:
            targetTemp = currentView.convert(getSourceView().frame, to: self)
        default:
            targetTemp = CGRect.init(x: AppWindows!.center.x, y: AppWindows!.center.y, width: 0, height: 0)
        }
        
        window.windowLevel = .normal
        UIView.animate(withDuration: 0.35) {
            switch currentView.dataModel.imageShowType {
            case .Normal,.GIF:
                self.tempView.transform = self.transform.inverted()
            default:break
            }
            self.coverView.alpha = 0
            self.tempView.frame = targetTemp!
        } completion: { finish in
            self.tempView.removeFromSuperview()
            self.coverView.removeFromSuperview()
            currentView.alpha = 0
            self.viewDismissAction()
            if self.viewerDismissBlock != nil
            {
                self.viewerDismissBlock!()
            }
        }
    }
}

extension PTMediaViewer:UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == contentScrolView {
            let pages:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
            page = pages
            if showLabel! {
                pageView_label.text = "\(pages + 1)/\(viewConfig.mediaData.count)"
            } else {
                pageView.currentPage = pages
            }
            indexLabel.text = "\(pages + 1)/\(viewConfig.mediaData.count)"
            if fullImageHidden() == "全景" {
                fullViewLabel.isUserInteractionEnabled = true
            } else {
                fullViewLabel.isUserInteractionEnabled = false
            }
            fullViewLabel.setTitle(fullImageHidden(), for: .normal)
                        
            let models = viewConfig.mediaData[pages]
            titleLabel.text = models.imageInfo
            titleLabel.isHidden = models.imageInfo.stringIsEmpty()
            viewConfig.mediaData.enumerated().forEach { index,value in
                let currentImages = contentScrolView.subviews[index] as! PTMediaMediaView
                if index == pages {
                    switch currentImages.dataModel.imageShowType {
                    case .GIF:
                        currentImages.imageView.startAnimating()
                    case .Video:
                        contentScrolView.delaysContentTouches = false
                        if !currentImages.playedVideo! {
                            currentImages.playBtn.isHidden = false
                            currentImages.stopBtn.isHidden = true
                            currentImages.videoSlider.isHidden = true
                        } else {
                            currentImages.stopBtn.isHidden = false
                            currentImages.stopBtn.isSelected = true
                            currentImages.videoSlider.isHidden = false
                        }
                        currentImages.player.player?.pause()
                    default:break
                    }
                } else {
                    switch currentImages.dataModel.imageShowType {
                    case .GIF:
                        currentImages.imageView.stopAnimating()
                    case .Video:
                        currentImages.player.player?.pause()
                    default:break
                    }
                }
            }
            
            let currentImages = contentScrolView.viewWithTag(PTSubViewBasicsIndex + pages) as! PTMediaMediaView
            if !currentImages.hasLoadedImage! {
                currentImages.setMediaData(dataModel: models)
            }
            updateBottomSize(models: models)
        }
    }
    
    func updateBottomSize(models:PTViewerModel) {
        titleLabel.text = models.imageInfo
        titleLabel.isHidden = models.imageInfo.stringIsEmpty()
        
        let bottonH:CGFloat = 44
        
        switch viewConfig.actionType {
            case .Empty:
                let infoH = UIView.sizeFor(string: models.imageInfo, font: titleLabel.font, height: CGFloat(MAXFLOAT), width: self.frame.size.width - 20).height
            
                labelScroller.contentSize = CGSize.init(width: self.frame.size.width - 20, height: infoH)
                bottomView.snp.updateConstraints { make in
                    if (bottonH * 2) > infoH && infoH > bottonH {
                        make.height.equalTo(infoH + CGFloat.kTabbarSaveAreaHeight)
                    }  else if infoH < bottonH {
                        make.height.equalTo(bottonH + CGFloat.kTabbarSaveAreaHeight)
                    } else if infoH > (bottonH * 2) {
                        make.height.equalTo(bottonH * 2 + CGFloat.kTabbarSaveAreaHeight)
                    }
                }

                labelScroller.snp.makeConstraints { make in
                    make.left.top.right.equalToSuperview().inset(10)
                    make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
                }
                
                if (bottonH * 2) > infoH && infoH > bottonH {
                    labelScroller.isScrollEnabled = false
                } else if infoH < bottonH {
                    labelScroller.isScrollEnabled = false
                } else if infoH > (bottonH * 2) {
                    labelScroller.isScrollEnabled = true
                }
                
                titleLabel.snp.makeConstraints { make in
                    make.left.top.equalToSuperview()
                    make.width.equalTo(self.frame.size.width - 20)
                }
        default:
            let labelW = self.frame.size.width - 40 - bottonH
            
            let infoH = UIView.sizeFor(string: models.imageInfo, font: titleLabel.font,lineSpacing: 2, height: CGFloat(MAXFLOAT), width: labelW).height
            labelScroller.contentSize = CGSize.init(width: labelW, height: infoH)

            bottomView.snp.updateConstraints { make in
                if (bottonH * 2) > infoH && infoH > bottonH {
                    make.height.equalTo(infoH + CGFloat.kTabbarSaveAreaHeight)
                } else if infoH < bottonH {
                    make.height.equalTo(bottonH + CGFloat.kTabbarSaveAreaHeight + 10)
                } else if infoH > (bottonH * 2) {
                    make.height.equalTo(bottonH * 2 + CGFloat.kTabbarSaveAreaHeight)
                }
            }
            bottomView.addSubview(moreActionButton)
            moreActionButton.snp.makeConstraints { make in
                make.width.height.equalTo(34)
                make.right.equalToSuperview().inset(10)
                make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
            }
            
            labelScroller.snp.makeConstraints { make in
                make.left.top.equalToSuperview().inset(10)
                make.bottom.equalTo(self.moreActionButton)
                make.right.equalTo(self.moreActionButton.snp.left).offset(-10)
            }
            
            if (bottonH * 2) > infoH && infoH > bottonH {
                labelScroller.isScrollEnabled = false
            } else if infoH < bottonH {
                labelScroller.isScrollEnabled = false
            } else if infoH > (bottonH * 2) {
                labelScroller.isScrollEnabled = true
            }

            titleLabel.snp.makeConstraints { make in
                make.width.equalTo(labelW)
                make.centerX.equalToSuperview()
                make.top.equalTo(0)
            }
        }
    }
}
