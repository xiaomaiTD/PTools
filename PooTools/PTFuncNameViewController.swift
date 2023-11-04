//
//  PTFuncNameViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import DeviceKit
import AnyImageKit
import Photos
import Combine

public extension String {
    static let localNetWork = "局域网传送"
    
    static let imageReview = "图片展示"
    static let videoEditor = "视频编辑"
    static let sign = "签名"
    static let dymanicCode = "动态验证码"
    static let osskit = "语音"
    static let vision = "看图识字"

    static let phoneSimpleInfo = "手机信息"
    static let phoneCall = "打电话"
    static let cleanCache = "清理缓存"
    static let touchID = "TouchID"
    static let rotation = "旋转屏幕"
    static let share = "分享"
    static let checkUpdate = "检测更新"

    static let slider = "滑动条"
    static let rate = "评价星星"
    static let segment = "分选栏目"
    static let countLabel = "跳动Label"
    static let throughLabel = "划线Label"
    static let twitterLabel = "推文Label"
    static let movieCutOutput = "类似剪映的视频输出进度效果"
}

class PTFuncNameViewController: PTBaseViewController {

    fileprivate lazy var outputURL :URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDirectory.appendingPathComponent("output.mp4")
        return outputURL
    }()

    private var videoEdit: PTVideoEdit?
    fileprivate var cancellables = Set<AnyCancellable>()

    func rowBaseModel(name:String) -> PTFusionCellModel {
        let models = PTFusionCellModel()
        models.name = .localNetWork
        models.haveLine = true
        models.accessoryType = .DisclosureIndicator
        models.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 12))
        return models
    }
    
    lazy var cSections : [PTSection] = {
        let disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 12))
        let sectionTitleFont:UIFont = .appfont(size: 18,bold: true)
        /**
            网络
         */
        let localNet = self.rowBaseModel(name: .localNetWork)
        
        let netArrs = [localNet]
        
        var netRows = [PTRows]()
        netArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            netRows.append(row)
        }
        
        let sectionModel_net = PTFusionCellModel()
        sectionModel_net.name = "网络"
        sectionModel_net.cellFont = sectionTitleFont
        sectionModel_net.accessoryType = .More
        sectionModel_net.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_net.moreLayoutStyle = .upImageDownTitle

        let netSection = PTSection.init(headerTitle: sectionModel_net.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: netRows,headerDataModel: sectionModel_net)
        
        /**
            图片
         */
        let imageReview = self.rowBaseModel(name: .imageReview)
        
        let videoEditor = self.rowBaseModel(name: .videoEditor)

        let sign = self.rowBaseModel(name: .sign)

        let dymanicCode = self.rowBaseModel(name: .dymanicCode)

        let oss = self.rowBaseModel(name: .osskit)

        let vision = self.rowBaseModel(name: .vision)
        
        let mediaArrs = [imageReview,videoEditor,sign,dymanicCode,oss,vision]
        
        var mediaRows = [PTRows]()
        mediaArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            mediaRows.append(row)
        }
        
        let sectionModel_media = PTFusionCellModel()
        sectionModel_media.name = "多媒体"
        sectionModel_media.cellFont = sectionTitleFont
        sectionModel_media.accessoryType = .More
        sectionModel_media.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_media.moreLayoutStyle = .leftImageRightTitle

        let mediaSection = PTSection.init(headerTitle: sectionModel_media.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: mediaRows,headerDataModel: sectionModel_media)

        /**
            本机
         */
        let jailBroken = PTFusionCellModel()
        jailBroken.name = .phoneSimpleInfo
        jailBroken.cellDescFont = .appfont(size: 12)
        jailBroken.desc = "是否X类型:\(UIDevice.pt.oneOfXDevice() ? "是" : "否"),是否越狱了:\(UIDevice.pt.isJailBroken ? "是" : "否"),机型:\(Device.identifier),运营商:\(String(describing: UIDevice.pt.carrierNames()?.first))"
        jailBroken.accessoryType = .NoneAccessoryView
        
        let callPhone = self.rowBaseModel(name: .phoneCall)
        callPhone.cellDescFont = .appfont(size: 12)
        callPhone.desc = "打电话到13800138000"

        let cleanCaches = self.rowBaseModel(name: .cleanCache)
        cleanCaches.cellDescFont = .appfont(size: 12)
        cleanCaches.desc = "缓存:\(String(format: "%@", PCleanCache.getCacheSize()))"

        let touchID = self.rowBaseModel(name: .touchID)

        let rotation = self.rowBaseModel(name: .rotation)

        let share = self.rowBaseModel(name: .share)

        let checkUpdate = self.rowBaseModel(name: .checkUpdate)

        let phoneArrs = [jailBroken,callPhone,cleanCaches,touchID,rotation,share,checkUpdate]
        
        var phoneRows = [PTRows]()
        phoneArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            phoneRows.append(row)
        }
        
        let sectionModel_phone = PTFusionCellModel()
        sectionModel_phone.name = "本机"
        sectionModel_phone.cellFont = sectionTitleFont
        sectionModel_phone.accessoryType = .More
        sectionModel_phone.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_phone.moreLayoutStyle = .leftTitleRightImage

        let phoneSection = PTSection.init(headerTitle: sectionModel_phone.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: phoneRows,headerDataModel: sectionModel_phone)
        
        /**
            UIKIT
         */
        let slider = self.rowBaseModel(name: .slider)
        
        let rate = self.rowBaseModel(name: .rate)

        let segment = self.rowBaseModel(name: .segment)

        let countLabel = self.rowBaseModel(name: .countLabel)
        
        let throughLabel = self.rowBaseModel(name: .throughLabel)
        
        let twitterLabel = self.rowBaseModel(name: .twitterLabel)
        
        let movieCutOutput = self.rowBaseModel(name: .movieCutOutput)
        
        let uikitArrs = [slider,rate,segment,countLabel,throughLabel,twitterLabel,movieCutOutput]
        
        var uikitRows = [PTRows]()
        uikitArrs.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            uikitRows.append(row)
        }
        
        let sectionModel_uikit = PTFusionCellModel()
        sectionModel_uikit.name = "UIKIT"
        sectionModel_uikit.cellFont = sectionTitleFont
        sectionModel_uikit.accessoryType = .More
        sectionModel_uikit.disclosureIndicatorImage = disclosureIndicatorImage
        sectionModel_uikit.moreLayoutStyle = .upTitleDownImage

        let uikitSection = PTSection.init(headerTitle: sectionModel_uikit.name,headerCls: PTFusionHeader.self,headerID: PTFusionHeader.ID,footerCls: PTVersionFooter.self,footerID: PTVersionFooter.ID,footerHeight: 88,headerHeight: 44, rows: uikitRows,headerDataModel: sectionModel_uikit)

        return [netSection,mediaSection,phoneSection,uikitSection]
    }()
    
    lazy var collectionView : PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Normal
        cConfig.itemHeight = PTAppBaseConfig.share.baseCellHeight
        cConfig.topRefresh = true
        if #available(iOS 17.0, *) {
        } else {
#if POOTOOLS_LISTEMPTYDATA
            cConfig.showEmptyAlert = true
#endif
        }
        let aaaaaaa = PTCollectionView(viewConfig: cConfig)
                
        aaaaaaa.headerInCollection = { kind,collectionView,model,index in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTFusionHeader
            header.sectionModel = (model.headerDataModel as! PTFusionCellModel)
            return header
        }
        aaaaaaa.footerInCollection = { kind,collectionView,model,index in
            if model.footerID == PTVersionFooter.ID {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTVersionFooter
                return footer
            } else {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTTestFooter
                return footer
            }
        }
        aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
            let itemRow = dataModel.rows[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
            return cell
        }
        aaaaaaa.collectionDidSelect = { collectionViews,sModel,indexPath in
            let itemRow = sModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTFusionCellModel)
            if itemRow.title == .imageReview {
                let model1 = PTMediaBrowserModel()
                model1.imageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
                model1.imageInfo = "56555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555555655555555555565555555555556555555555551312333444444"
                
                let model2 = PTMediaBrowserModel()
                model2.imageURL = "http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"
                model2.imageInfo = "123"

                let model3 = PTMediaBrowserModel()
                model3.imageURL = "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
                model3.imageInfo = "MP4"

                let model4 = PTMediaBrowserModel()
                model4.imageURL = "http://img.t.sinajs.cn/t35/style/images/common/face/ext/normal/7a/shenshou_thumb.gif"
                model4.imageInfo = "GIF"

                let mediaConfig = PTMediaBrowserConfig()
                mediaConfig.actionType = .All
                mediaConfig.mediaData = [model1,model2,model3,model4]
                
                let browser = PTMediaBrowserController()
                browser.viewConfig = mediaConfig
                browser.modalPresentationStyle = .fullScreen
                self.present(browser, animated: true)
            } else if itemRow.title == .phoneCall {
                PTPhoneBlock.callPhoneNumber(phoneNumber: "13800138000", call: { duration in
                }, cancel: {
                    
                }, canCall: { finish in
                    
                })
            } else if itemRow.title == .cleanCache {
                if PCleanCache.clearCaches() {
                    UIAlertController.gobal_drop(title: "清理成功")
                    self.showCollectionViewData()
                } else {
                    UIAlertController.gobal_drop(title: "暂时没有缓存了")
                }
            } else if itemRow.title == .touchID {
                let touchID = PTBiologyID.shared
                touchID.biologyStatusBlock = { type in
                    PTNSLogConsole("\(type)")
                }
                touchID.biologyVerifyStatusBlock = { type in
                    PTNSLogConsole("\(type)")
                }
                touchID.biologyStart(alertTitle: "Test")
            } else if itemRow.title == .videoEditor {
                var options = PickerOptionsInfo()
                options.selectLimit = 1
                options.selectOptions = .video
                
                let controller = ImagePickerController(options: options, delegate: self)
                controller.trackDelegate = self
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true, completion: nil)
            } else if itemRow.title == .sign {
                let signConfig = PTSignatureConfig()
                
                let sign = PTSignView(viewConfig: signConfig)
                sign.showView()
                sign.doneBlock = { image in
                    let newImage = UIImageView(image: image)
                    self.view.addSubview(newImage)
                    newImage.snp.makeConstraints { make in
                        make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                        make.top.equalTo(self.collectionView)
                        make.height.equalTo(150)
                    }
                    
                    PTGCDManager.gcdAfter(time: 5) {
                        newImage.removeFromSuperview()
                    }
                }
                sign.dismissBlock = {
                    
                }
            } else if itemRow.title == .rotation {
                let r:Int = Int(arc4random_uniform(6))
                PTRotationManager.share.setOrientation(orientation: UIDeviceOrientation.init(rawValue: r)!)
            } else if itemRow.title == .osskit {
                let vc = PTSpeechViewController()
                self.navigationController?.pushViewController(vc)
            } else if itemRow.title == .share {
                guard let url = URL(string: shareURLString) else {
                    return
                }

                let share = PTShareCustomActivity()
                share.text = shareText
                share.url = url
                share.image = UIImage(named: "DemoImage")
                share.customActivityTitle = "测试Title"
                share.customActivityImage = "🖼️".emojiToImage(emojiFont: .appfont(size: 54))

                let items: [Any] = [shareText, url, UIImage(named: "DemoImage")!]

                let vc = PTActivityViewController(activityItems: items,applicationActivities: [share])
                vc.previewNumberOfLines = 10
                vc.presentActionSheet(self, from: collectionViews.cellForItem(at: indexPath)!)

            } else if itemRow.title == .checkUpdate {
                PTCheckUpdateFunction.share.checkTheVersionWithappid(appid: "6446323709", test: false, url: URL(string: shareURLString), version: "1.0.0", note: "123", force: false,alertType: .User)
            } else {
                let vc = PTFuncDetailViewController(typeString: itemRow.title)
                PTFloatingPanelFuction.floatPanel_VC(vc: vc,panGesDelegate: self,currentViewController: self)
            }
        }
        aaaaaaa.headerRefreshTask = { sender in
            PTGCDManager.gcdAfter(time: 3) {
                sender.endRefreshing()
            }
        }
        return aaaaaaa
    }()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.flashAd(notifi:)), name: NSNotification.Name.init(PLaunchAdDetailDisplayNotification), object: nil)
        
        let more = UIButton(type: .custom)
        more.setTitleColor(.random, for: .normal)
        more.setTitle("More", for: .normal)
        more.bounds = CGRect(x: 0, y: 0, width: 34, height: 34)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubviews([more])
        more.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            more.size.equalTo(more.bounds.size)
            make.bottom.equalToSuperview().inset(5)
        }
#else
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: more)
#endif
        let popoverContent = PTBaseViewController(hideBaseNavBar: true)
        
        let popoverButton = UIButton(type: .custom)
        popoverButton.backgroundColor = .random
        
        popoverContent.view.addSubview(popoverButton)
        popoverButton.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.centerY.centerX.equalToSuperview()
        }
        popoverButton.addActionHandlers { sender in
            popoverContent.dismiss(animated: true) {
                let infoVc = PTSwiftViewController()
                self.navigationController?.pushViewController(infoVc)
            }
        }
        
        more.addActionHandlers { sender in
            self.popover(popoverVC: popoverContent, popoverSize: CGSize(width: 100, height: 300), sender: sender, arrowDirections: .any)
        }
        
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
            make.left.right.bottom.equalToSuperview()
        }
        
        if #available(iOS 17.0, *) {
            self.emptyDataViewConfig = PTEmptyDataViewConfig()
            self.showEmptyView {
                self.emptyReload()
            }
            
            PTGCDManager.gcdAfter(time: 5) {
                self.emptyReload()
            }
        } else {
            self.showCollectionViewData()
        }
    }
    
    func flashAd(notifi:Notification) {
        PTNSLogConsole("启动广告")
    }
    
    @available(iOS 17, *)
    func emptyReload() {
        self.emptyViewLoading()
        PTGCDManager.gcdAfter(time: 2) {
            self.hideEmptyView {
                self.showCollectionViewData()
            }
        }
    }
    
    func showCollectionViewData() {
        collectionView.showCollectionDetail(collectionData: cSections)
    }
}

// MARK: - ImagePickerControllerDelegate
extension PTFuncNameViewController: ImagePickerControllerDelegate {
    
    // 获取PHAsset并转换为AVAsset的方法
    func convertPHAssetToAVAsset(phAsset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, _ in
            completion(avAsset)
        }
    }
        
    func saveVideoToCache(playerItem: AVPlayerItem,result:((_ finish:Bool)->Void)? = nil) {
        let videoAsset = playerItem.asset
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mp4

        guard let exportSession = exportSession else {
            PTNSLogConsole("无法创建AVAssetExportSession")
            return
        }

        exportSession.outputURL = outputURL
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                PTNSLogConsole("视频保存到本地成功")
                if result != nil {
                    result!(true)
                }
            case .failed:
                PTNSLogConsole("视频导出失败：\(exportSession.error?.localizedDescription ?? "")")
                if result != nil {
                    result!(false)
                }
            default:
                break
            }
        }
    }
    
    func saveVideoToAlbum(result:((_ finish:Bool)->Void)? = nil) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL)
        }) { success, error in
            if success {
                PTNSLogConsole("视频保存成功")
                if result != nil {
                    result!(true)
                }
            } else {
                PTNSLogConsole("视频保存失败：\(error?.localizedDescription ?? "")")
                if result != nil {
                    result!(false)
                }
            }
        }
    }

    func imagePicker(_ picker: ImagePickerController, didFinishPicking result: PickerResult) {
        PTNSLogConsole(result.assets.first!.image)
        
        picker.dismiss(animated: true, completion: nil)

        convertPHAssetToAVAsset(phAsset: result.assets.first!.phAsset) { avAsset in
            if let avAsset = avAsset {
                PTGCDManager.gcdMain {
                    let controller = PTVideoEditorVideoEditorViewController(asset: avAsset, videoEdit: self.videoEdit)
                    controller.onEditCompleted
                        .sink {  editedPlayerItem, videoEdit in
                            self.videoEdit = videoEdit
                            
                            self.saveVideoToCache(playerItem: editedPlayerItem) { finish in
                                if finish {
                                    UIImage.pt.getVideoFirstImage(videoUrl: self.outputURL.description) { images in
                                        PTNSLogConsole(images as Any)
                                    }
                                }
                            }
                        }
                        .store(in: &self.cancellables)
                    controller.modalPresentationStyle = .fullScreen
                    let nav = PTBaseNavControl(rootViewController: controller)
                    self.navigationController?.present(nav, animated: true)
                }
            } else {
                UIViewController.gobal_drop(title: "获取失败,请重试")
            }
        }
    }
}

// MARK: - ImageKitDataTrackDelegate
extension PTFuncNameViewController: ImageKitDataTrackDelegate {
    
    func dataTrack(page: AnyImagePage, state: AnyImagePageState) {
        switch state {
        case .enter:
            PTNSLogConsole("[Data Track] ENTER Page: \(page.rawValue)")
        case .leave:
            PTNSLogConsole("[Data Track] LEAVE Page: \(page.rawValue)")
        }
    }
    
    func dataTrack(event: AnyImageEvent, userInfo: [AnyImageEventUserInfoKey: Any]) {
        PTNSLogConsole("[Data Track] EVENT: \(event.rawValue), userInfo: \(userInfo)")
    }
}
