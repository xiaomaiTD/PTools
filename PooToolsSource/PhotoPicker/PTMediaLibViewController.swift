//
//  PTMediaLibViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import Photos
import Combine
import AVFoundation

public class PTMediaLibView:UIView {
        
    public var updateTitle:PTActionTask?
    
    fileprivate static func outputURL()->URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDirectory.appendingPathComponent("\(Date().getTimeStamp()).mp4")
        return outputURL
    }
    
    var selectedModelDidUpdate:PTActionTask?
    
    var showCameraCell: Bool {
        if PTMediaLibConfig.share.allowTakePhotoInLibrary, currentAlbum!.isCameraRoll {
            return true
        }
        return false
    }

    private var videoEdit: PTVideoEdit?
    fileprivate var cancellables = Set<AnyCancellable>()
    
    var selectedCount:((Int)->Void)?
    
    var totalModels:[PTMediaModel]! = [PTMediaModel]()
    var selectedModel: [PTMediaModel] = [] {
        didSet {
            if self.selectedModelDidUpdate != nil {
                self.selectedModelDidUpdate!()
            }
        }
    }

    var currentAlbum:PTMediaLibListModel? {
        didSet {
            if currentAlbum != nil {
                if updateTitle != nil {
                    updateTitle!()
                }
                loadMedia()
            }
        }
    }
    
    lazy var collectionView : PTCollectionView = {
        
        let config = PTCollectionViewConfig()
        config.viewType = .Gird
        config.itemOriginalX = 0
        config.cellLeadingSpace = 1
        config.cellTrailingSpace = 1
        config.rowCount = 3
        let itemHeight:CGFloat = (CGFloat.kSCREEN_WIDTH - CGFloat(config.rowCount - 1) * config.cellLeadingSpace) / CGFloat(config.rowCount)
        config.itemHeight = itemHeight

        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTMediaLibConfig.share

            let itemRow = sectionModel.rows[indexPath.row]
            if itemRow.ID == PTMediaLibCell.ID {
                let cellModel = (itemRow.dataModel as! PTMediaModel)
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTMediaLibCell
                cell.selectedBlock = { [weak self] isSelected in
                    guard let `self` = self else { return }

                    if !cellModel.isSelected {
                        guard canAddModel(cellModel, currentSelectCount: self.selectedModel.count, sender: PTUtils.getCurrentVC()) else { return }
                        downloadAssetIfNeed(model: cellModel, sender: PTUtils.getCurrentVC()) {
                            if !self.shouldDirectEdit(cellModel) {
                                cellModel.isSelected = true
                                self.selectedModel.append(cellModel)
                                isSelected(true)
                                config.didSelectAsset?(cellModel.asset)
                                self.refreshCellIndex()
                            }
                        }
                    } else {
                        cellModel.isSelected = false
                        self.selectedModel.removeAll(where: { $0 == cellModel })
                        isSelected(false)
                        config.didDeselectAsset?(cellModel.asset)
                        self.refreshCellIndex()
                    }
                }
                
                cell.editButton.addActionHandlers { sender in
                    switch cellModel.type {
                    case .video:
                        let _ = PTMediaLibManager.fetchAVAsset(forVideo: cellModel.asset) { avAsset, parma in
                            if avAsset != nil {
                                let controller = PTVideoEditorVideoEditorViewController(asset: avAsset!, videoEdit: self.videoEdit)
                                controller.onEditCompleted
                                    .sink {  editedPlayerItem, videoEdit in
                                        self.videoEdit = videoEdit
                                        
                                        for (index, selM) in self.selectedModel.enumerated() {
                                            if cellModel == selM {
                                                self.saveVideoToCache(playerItem: editedPlayerItem) { fileURL, finish in
                                                    if finish {
                                                        PTMediaLibManager.saveVideoToAlbum(url: fileURL!) { isFinish, asset in
                                                            let m = PTMediaModel(asset: asset!)
                                                            m.isSelected = true
                                                            self.selectedModel[index] = m
                                                            config.didSelectAsset?(asset!)
                                                        }
                                                    }
                                                }
                                                break
                                            }
                                        }
                                    }
                                    .store(in: &self.cancellables)
                                let nav = PTBaseNavControl(rootViewController: controller)
                                nav.modalPresentationStyle = .fullScreen
                                PTUtils.getCurrentVC().present(nav, animated: true)
                            }
                        }
                    default:
                        PTMediaLibManager.fetchImage(for: cellModel.asset, size: cellModel.previewSize) { image, isDegraded in
                            if !isDegraded {
                                if let image = image {
                                    let vc = PTEditImageViewController(readyEditImage: image)
                                    vc.editFinishBlock = { ei ,editImageModel in
                                        for (index, selM) in self.selectedModel.enumerated() {
                                            if cellModel == selM {
                                                cellModel.isSelected = true
                                                cellModel.editImage = ei
                                                cellModel.editImageModel = editImageModel
                                                self.selectedModel[index] = cellModel
                                                PTMediaLibConfig.share.didSelectAsset?(cellModel.asset)
                                                break
                                            }
                                        }
                                    }
                                    let nav = PTBaseNavControl(rootViewController: vc)
                                    nav.view.backgroundColor = .black
                                    nav.modalPresentationStyle = .fullScreen
                                    PTUtils.getCurrentVC().present(nav, animated: true)
                                }
                            }
                        }
                    }
                }
                
                if let index = self.selectedModel.firstIndex(where: { $0 == cellModel }) {
                    self.setCellIndex(cell, index: index + 1)
                } else {
                    cell.selectButton.normalTitle = ""
                }
                self.setCellMaskView(cell, isSelected: cellModel.isSelected, model: cellModel)
                cell.cellModel = cellModel
                return cell
            } else {
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTCameraCell
                return cell
            }
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            let itemRow = sectionModel.rows[indexPath.row]
            if itemRow.ID == PTCameraCell.ID {
                let config = PTMediaLibConfig.share

                if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                    PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle: "PT Photo picker bad".localized(), icon:.Error,style: .Normal)
                } else if PTMediaLibManager.hasCameraAuthority() {
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.allowsEditing = false
                    picker.videoQuality = .typeHigh
                    picker.sourceType = .camera
                    picker.cameraDevice = config.cameraConfiguration.devicePosition.cameraDevice
                    if config.cameraConfiguration.showFlashSwitch {
                        picker.cameraFlashMode = .auto
                    } else {
                        picker.cameraFlashMode = .off
                    }
                    var mediaTypes:[String] = []
                    if config.cameraConfiguration.allowTakePhoto {
                        mediaTypes.append("public.image")
                    }
                    if config.cameraConfiguration.allowRecordVideo {
                        mediaTypes.append("public.movie")
                    }
                    picker.mediaTypes = mediaTypes
                    picker.videoMaximumDuration = TimeInterval(config.cameraConfiguration.maxRecordDuration)
                    PTUtils.getCurrentVC().showDetailViewController(picker, sender: nil)
                } else {
                    PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle: "PT Photo picker can not take photo".localized(), icon:.Error,style: .Normal)
                }
            } else {
                let config = PTMediaLibConfig.share
                if config.maxSelectCount == 1 {
                    let cellModel = (itemRow.dataModel as! PTMediaModel)
                    self.selectedModel.append(cellModel)
                    config.didSelectAsset?(cellModel.asset)
                    if let vc = self.parentViewController as? PTMediaLibViewController {
                        vc.requestSelectPhoto(viewController:vc)
                    }
                }
            }
        }
        return view
    }()
    
    init(currentModels:PTMediaLibListModel) {
        super.init(frame: .zero)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.currentAlbum = currentModels
        markSelected(source: &self.totalModels, selected: &self.selectedModel)
        PTGCDManager.gcdAfter(time: 0.35) {
            self.collectionView.contentCollectionView.scrollToBottom()
        }
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadMedia() {
        PTGCDManager.gcdMain {
            self.totalModels.removeAll()
            var rows = [PTRows]()

            self.totalModels.append(contentsOf: self.currentAlbum!.models)
            self.totalModels.enumerated().forEach { index,value in
                let row = PTRows(cls:PTMediaLibCell.self,ID: PTMediaLibCell.ID,dataModel: value)
                rows.append(row)
            }
            
            if self.showCameraCell {
                let row = PTRows(cls:PTCameraCell.self,ID: PTCameraCell.ID)
                rows.insert(row, at: rows.count)
            }
            let section = PTSection(rows: rows)
            self.collectionView.showCollectionDetail(collectionData: [section])
        }
    }
    
    private func refreshCellIndex() {
        PTGCDManager.gcdMain {
            let visibleIndexPaths = self.collectionView.contentCollectionView.indexPathsForVisibleItems
            
            visibleIndexPaths.forEach { indexPath in
                if let cell = self.collectionView.contentCollectionView.cellForItem(at: indexPath) as? PTMediaLibCell {
                    let m = self.totalModels[indexPath.row]
                    
                    var idx = 0
                    var isSelected = false
                    for (index, selM) in self.selectedModel.enumerated() {
                        if m == selM {
                            idx = (index + 1)
                            isSelected = true
                            break
                        }
                    }
                    
                    self.setCellIndex(cell, index: idx)
                    self.setCellMaskView(cell, isSelected: isSelected, model: m)
                    self.setTitleButton()
                }
            }
        }
    }
    
    private func setTitleButton() {
        PTGCDManager.gcdMain {
            if self.selectedCount != nil {
                self.selectedCount!(self.selectedModel.count)
            }
        }
    }
    
    private func setCellIndex(_ cell: PTMediaLibCell?, index: Int) {
        cell?.cellSelectedIndex = index
    }
    
    private func setCellMaskView(_ cell: PTMediaLibCell, isSelected: Bool, model: PTMediaModel) {
        cell.coverView.isHidden = true
        cell.enableSelect = true
        let config = PTMediaLibConfig.share
        let uiConfig = PTMediaLibUIConfig.share

        if isSelected {
            cell.coverView.backgroundColor = .DevMaskColor
            cell.coverView.isHidden = false
            cell.editButton.isHidden = false
            cell.layer.borderColor = config.selectedBorderColor.cgColor
            cell.layer.borderWidth = 4
        } else {
            cell.editButton.isHidden = true
            let selCount = selectedModel.count
            if selCount < config.maxSelectCount {
                if config.allowMixSelect {
                    let videoCount = selectedModel.filter { $0.type == .video }.count
                    if videoCount >= config.maxVideoSelectCount, model.type == .video {
                        cell.coverView.backgroundColor = .DevMaskColor
                        cell.coverView.isHidden = !uiConfig.showInvalidMask
                        cell.enableSelect = false
                    } else if (config.maxSelectCount - selCount) <= (config.minVideoSelectCount - videoCount), model.type != .video {
                        cell.coverView.backgroundColor = .DevMaskColor
                        cell.coverView.isHidden = !uiConfig.showInvalidMask
                        cell.enableSelect = false
                    }
                } else if selCount > 0 {
                    cell.coverView.backgroundColor = .DevMaskColor
                    cell.coverView.isHidden = (!uiConfig.showInvalidMask || model.type != .video)
                    cell.enableSelect = model.type != .video
                }
            } else if selCount >= config.maxSelectCount {
                cell.coverView.backgroundColor = .DevMaskColor
                cell.coverView.isHidden = !uiConfig.showInvalidMask
                cell.enableSelect = false
            }
            cell.layer.borderWidth = 0
        }
    }
    
    private func shouldDirectEdit(_ model: PTMediaModel) -> Bool {
        let config = PTMediaLibConfig.share
        
        let canEditImage = config.editAfterSelectThumbnailImage &&
            config.allowEditImage &&
            config.maxSelectCount == 1 &&
            model.type.rawValue < PTMediaModel.MediaType.video.rawValue
        
        let canEditVideo = (config.editAfterSelectThumbnailImage &&
            config.allowEditVideo &&
            model.type == .video &&
            config.maxSelectCount == 1) ||
            (config.allowEditVideo &&
                model.type == .video &&
                !config.allowMixSelect &&
                config.cropVideoAfterSelectThumbnail)
        
        // 当前未选择图片 或已经选择了一张并且点击的是已选择的图片
        let flag = selectedModel.isEmpty || (selectedModel.count == 1 && selectedModel.first?.ident == model.ident)
                
        return flag && (canEditImage || canEditVideo)
    }
    
    private func save(image: UIImage?, videoUrl: URL?) {
        if let image = image {
            PTAlertTipControl.present(title:"",subtitle: "PT Alert Doning".localized(), icon:.Heart,style: .Normal)
            PTMediaLibManager.saveImageToAlbum(image: image) { [weak self] suc, asset in
                if suc, let asset = asset {
                    let model = PTMediaModel(asset: asset)
                    self?.handleDataArray(newModel: model)
                } else {
                    PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle: "PT Photo picker save image error".localized(), icon:.Error,style: .Normal)
                }
            }
        } else if let videoUrl = videoUrl {
            PTAlertTipControl.present(title:"",subtitle: "PT Alert Doning".localized(), icon:.Heart,style: .Normal)
            PTMediaLibManager.saveVideoToAlbum(url: videoUrl) { [weak self] suc, asset in
                if suc, let at = asset {
                    let model = PTMediaModel(asset: at)
                    self?.handleDataArray(newModel: model)
                } else {
                    PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle: "PT Photo picker save video error".localized(), icon:.Error,style: .Normal)
                }
            }
        }
    }
    
    private func handleDataArray(newModel: PTMediaModel) {
        totalModels.insert(newModel, at: 0)
        let config = PTMediaLibConfig.share
        
        var canSelect = true
        // If mixed selection is not allowed, and the newModel type is video, it will not be selected.
        if !config.allowMixSelect, newModel.type == .video {
            canSelect = false
        }
        // 单选模式，且不显示选择按钮时，不允许选择
        if config.maxSelectCount == 1, !config.showSelectBtnWhenSingleSelect {
            canSelect = false
        }
        if canSelect, canAddModel(newModel, currentSelectCount: selectedModel.count, sender: PTUtils.getCurrentVC(), showAlert: false) {
            if !shouldDirectEdit(newModel) {
                newModel.isSelected = true
                totalModels.append(newModel)
                config.didSelectAsset?(newModel.asset)
                
                if config.callbackDirectlyAfterTakingPhoto {
                    if let vc = self.parentViewController as? PTMediaLibViewController {
                        vc.requestSelectPhoto()
                    }
                    return
                }
            }
        }
        
        loadMedia()
    }
}

extension PTMediaLibView:PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        PTGCDManager.gcdMain {
            self.loadMedia()
        }
    }
}

extension PTMediaLibView:UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            let image = info[.originalImage] as? UIImage
            let url = info[.mediaURL] as? URL
            self.save(image: image, videoUrl: url)
        }
    }
}

extension PTMediaLibView {
    
    func saveVideoToCache(fileURL:URL = PTMediaLibView.outputURL(),playerItem: AVPlayerItem,result:((_ fileURL:URL?,_ finish:Bool)->Void)? = nil) {
        let videoAsset = playerItem.asset
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mp4

        guard let exportSession = exportSession else {
            PTNSLogConsole("无法创建AVAssetExportSession")
            return
        }

        exportSession.outputURL = fileURL
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                PTNSLogConsole("视频保存到本地成功")
                if result != nil {
                    result!(fileURL,true)
                }
            case .failed:
                PTNSLogConsole("视频导出失败：\(exportSession.error?.localizedDescription ?? "")")
                if result != nil {
                    result!(nil,false)
                }
            default:
                break
            }
        }
    }
}

public class PTMediaLibViewController: PTFloatingBaseViewController {

    public var selectImageBlock: (([PTResultModel], Bool) -> Void)?
    /// Callback for photos that failed to parse
    /// block params
    ///  - params1: failed assets.
    ///  - params2: index for asset
    public var selectImageRequestErrorBlock: (([PHAsset], [Int]) -> Void)?

    private lazy var fetchImageQueue = OperationQueue()

    private var currentAlbum:PTMediaLibListModel!
    var totalModels = [PTMediaModel]()
    var selectedModel: [PTMediaModel] = []

    private var isSelectOriginal = false
    private lazy var fakeNav:UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var dismissButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 18)), for: .normal)
        view.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return view
    }()
    
    private lazy var submitButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("✅".emojiToImage(emojiFont: .appfont(size: 18)), for: .normal)
        view.addActionHandlers { sender in
            self.requestSelectPhoto(viewController: self)
        }
        return view
    }()
    
    private lazy var selectLibButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.layoutStyle = .leftTitleRightImage
        view.imageSize = CGSize(width: 10, height: 10)
        view.normalImage = "🔽".emojiToImage(emojiFont: .appfont(size: 10))
        view.normalTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.normalSubTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.hightlightTitleColor = PTAppBaseConfig.share.viewDefaultTextColor
        view.normalTitleFont = .appfont(size: 15)
        view.addActionHandlers { sender in
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
            
            let config = PTMediaLibConfig.share
            
            if self.mediaListView.currentAlbum != nil {
                let vc = PTMediaLibAlbumListViewController(albumList: self.mediaListView.currentAlbum!)
                let nav = PTBaseNavControl(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
                vc.selectedModelHandler = { model in
                    self.selectLibButton.normalTitle = "\(model.title)"
                    if model.models.isEmpty {
                        model.refetchPhotos()
                        self.mediaListView.currentAlbum = model
                    } else {
                        self.mediaListView.currentAlbum = model
                    }
                }
            } else {
                PTMediaLibManager.getCameraRollAlbum(allowSelectImage: config.allowSelectImage, allowSelectVideo: config.allowSelectVideo) { model in
                    let vc = PTMediaLibAlbumListViewController(albumList: model)
                    let nav = PTBaseNavControl(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                    vc.selectedModelHandler = { model in
                        self.selectLibButton.normalTitle = "\(model.title)"
                        self.mediaListView.currentAlbum = model
                    }
                }
            }
        }
        return view
    }()
    
    private lazy var mediaListView : PTMediaLibView = {
        let view = PTMediaLibView(currentModels: self.currentAlbum)
        view.selectedCount = { index in
            if index > 0 {
                self.selectLibButton.normalSubTitleFont = .appfont(size: 12)
                self.selectLibButton.normalSubTitle = String(format: "PT Photo picker selected count".localized(), "\(index)")
            } else {
                self.selectLibButton.normalSubTitle = ""
            }
        }
        view.updateTitle = {
            self.selectLibButton.normalTitle = self.mediaListView.currentAlbum!.title
        }
        view.selectedModelDidUpdate = {
            self.selectedModel = self.mediaListView.selectedModel
            self.totalModels = self.mediaListView.totalModels
        }
        return view
    }()
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([fakeNav])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(8)
            make.height.equalTo(54)
        }
        
        createNavSubs()

        let config = PTMediaLibConfig.share
        PTMediaLibManager.getCameraRollAlbum(allowSelectImage: config.allowSelectImage, allowSelectVideo: config.allowSelectVideo) { model in
            self.currentAlbum = model
            if self.currentAlbum.models.isEmpty {
                PTGCDManager.gcdMain {
                    self.currentAlbum.refetchPhotos()
                    self.view.addSubviews([self.mediaListView])
                    self.mediaListView.snp.makeConstraints { make in
                        make.left.right.bottom.equalToSuperview()
                        make.top.equalTo(self.fakeNav.snp.bottom)
                    }
                    self.mediaListView.currentAlbum = self.currentAlbum
                }
            } else {
                self.view.addSubviews([self.mediaListView])
                self.mediaListView.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(self.fakeNav.snp.bottom)
                }
                self.mediaListView.currentAlbum = self.currentAlbum
            }
        }
    }
    
    func createNavSubs() {
        fakeNav.addSubviews([dismissButton,submitButton,selectLibButton])
        dismissButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.bottom.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        submitButton.snp.makeConstraints { make in
            make.size.bottom.equalTo(self.dismissButton)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        
        selectLibButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }
        
    public func mediaLibShow(panGesDelegate:(UIViewController & UIGestureRecognizerDelegate)? = nil) {
#if POOTOOLS_FLOATINGPANEL
        if panGesDelegate != nil {
            PTUtils.getCurrentVC().sheetPresent_floating(modalViewController: self, type: .large, scale: 1,panGesDelegate:panGesDelegate) {
                
            } dismissCompletion: {
                
            }
        } else {
            showMediaLib()
        }
#else
        showMediaLib()
#endif
        
        if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    private func showMediaLib() {
        if #available(iOS 15.0,*) {
            PTUtils.getCurrentVC().sheetPresent(modalViewController: self, type: .large, scale: 1) {
                
            }
        } else {
            PTUtils.getCurrentVC().present(self, animated: true)
        }
    }
}

extension PTMediaLibViewController {
    public func requestSelectPhoto(viewController: UIViewController? = nil) {
        guard !selectedModel.isEmpty else {
            selectImageBlock?([], isSelectOriginal)
            viewController?.dismiss(animated: true, completion: nil)
            return
        }
        
        let config = PTMediaLibConfig.share
        
        if config.allowMixSelect {
            let videoCount = selectedModel.filter { $0.type == .video }.count
            
            if videoCount > config.maxVideoSelectCount {
                PTAlertTipControl.present(title: "PT Alert Opps".localized(),subtitle:String(format: "PT Photo picker video select more than max".localized(), "\(config.maxVideoSelectCount)"),icon:.Error,style:.Normal)
                return
            } else if videoCount < config.minVideoSelectCount {
                PTAlertTipControl.present(title: "PT Alert Opps".localized(),subtitle:String(format: "PT Photo picker video select less than min".localized(), "\(config.minVideoSelectCount)"),icon:.Error,style:.Normal)
                return
            }
        }
        
        PTAlertTipControl.present(title: "",subtitle:"PT Alert Doning".localized(),icon:.Heart,style:.Normal)
        
        let isOriginal = config.allowSelectOriginal ? isSelectOriginal : config.alwaysRequestOriginal
        
        let callback = { [weak self] (sucModels: [PTResultModel], errorAssets: [PHAsset], errorIndexs: [Int]) in
            
            func call() {
                self?.selectImageBlock?(sucModels, isOriginal)
                if !errorAssets.isEmpty {
                    self?.selectImageRequestErrorBlock?(errorAssets, errorIndexs)
                }
            }
            
            if let vc = viewController {
                vc.dismiss(animated: true) {
                    call()
                }
            } else {
                call()
            }
            
            self?.selectedModel.removeAll()
            self?.totalModels.removeAll()
        }
        
        var results: [PTResultModel?] = Array(repeating: nil, count: selectedModel.count)
        var errorAssets: [PHAsset] = []
        var errorIndexs: [Int] = []
        
        var sucCount = 0
        let totalCount = selectedModel.count
        
        for (i, m) in selectedModel.enumerated() {
            let operation = PTFetchImageOperation(model: m, isOriginal: isOriginal) { image, asset in
                
                sucCount += 1
                
                if let image = image {
                    let isEdited = m.editImage != nil && !config.saveNewImageAfterEdit
                    let model = PTResultModel(
                        asset: asset ?? m.asset,
                        image: image,
                        isEdited: isEdited,
                        editModel: isEdited ? m.editImageModel : nil,
                        avEditorOutputItem: m.avEditorOutputItem,
                        index: i
                    )
                    results[i] = model
                    PTNSLogConsole("PTPhotoBrowser: suc request \(i)")
                } else {
                    errorAssets.append(m.asset)
                    errorIndexs.append(i)
                    PTNSLogConsole("PTPhotoBrowser: failed request \(i)")
                }
                
                guard sucCount >= totalCount else { return }
                
                callback(results.compactMap { $0 },errorAssets,errorIndexs)
            }
            fetchImageQueue.addOperation(operation)
        }
    }

}