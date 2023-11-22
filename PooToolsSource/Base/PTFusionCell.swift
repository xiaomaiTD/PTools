//
//  PTFusionCell.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import AttributedString
import SwifterSwift

public typealias PTCellSwitchBlock = (_ rowText:String,_ sender:UISwitch)->Void
public typealias PTSectionMoreBlock = (_ rowText:String,_ sender:UIButton)->Void

fileprivate extension UIView {
    /// 绘制简单横线
    func drawLine() -> UIView {
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor(hexString: "#E8E8E8")
        return lineView
    }
}

@objcMembers
public class PTFusionCellContent:UIView {
    public static let ContentIconHeight:CGFloat = CGFloat.ScaleW(w: 64)
    public var switchValueChangeBlock:PTCellSwitchBlock?

    enum PTFusionContentCellType {
        case Name
        case NameContent
        case Content
        case None
    }
    
    enum PTFusionCellImageType {
        case OnlyLeftImage
        case OnlyRightImage
        case BothImage(type:PTFusionContentCellType)
        case LeftImageContent(type:PTFusionContentCellType)
        case RightImageContent(type:PTFusionContentCellType)
        case None(type:PTFusionContentCellType)
    }
    
    enum PTFusionCellAccessoryView {
        case Switch(type:PTFusionCellImageType)
        case DisclosureIndicator(type:PTFusionCellImageType)
        case NoneAccessoryView(type:PTFusionCellImageType)
        case More(type:PTFusionCellImageType)
        case Error
    }
    
    public var cellModel:PTFusionCellModel? {
        didSet {
            removeSubviews()
            loadCellData()
        }
    }
    
    func loadCellData() {
        switch cellModel!.accessoryType {
        case .Switch:
            accessV.removeFromSuperview()
            sectionMore.removeFromSuperview()
            
            valueSwitch.onTintColor = cellModel!.switchOnTinColor
            valueSwitch.thumbTintColor = cellModel!.switchThumbTintColor
            valueSwitch.tintColor = cellModel!.switchTintColor
            valueSwitch.backgroundColor = cellModel!.switchBackgroundColor
            addSubview(valueSwitch)
            valueSwitch.snp.makeConstraints { (make) in
                make.width.equalTo(51)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
            }
            
            PTGCDManager.gcdAfter(time: 0.1) {
                self.valueSwitch.viewCorner(radius: self.valueSwitch.frame.height / 2)
            }
        case .DisclosureIndicator:
            valueSwitch.removeFromSuperview()
            sectionMore.removeFromSuperview()

            self.accessV.loadImage(contentData: cellModel!.disclosureIndicatorImage as Any,iCloudDocumentName: cellModel!.iCloudDocument)
            addSubview(accessV)
            accessV.snp.makeConstraints { make in
                make.width.height.equalTo(14)
                make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                make.centerY.equalToSuperview()
            }
        case .More:
            accessV.removeFromSuperview()
            valueSwitch.removeFromSuperview()
            
            addSubview(sectionMore)

            var moreWith:CGFloat = 0
            let moreStringWidth = UIView.sizeFor(string: self.cellModel!.moreString, font: self.cellModel!.moreFont, height: self.height - (self.cellModel!.imageTopOffset + self.cellModel!.imageBottomOffset)).width
            if !NSObject.checkObject(cellModel!.moreDisclosureIndicator as? NSObject) && !cellModel!.moreString.stringIsEmpty() {
                //两个都有
                PTLoadImageFunction.loadImage(contentData: cellModel!.moreDisclosureIndicator!,iCloudDocumentName: cellModel!.iCloudDocument) { images, image in
                    self.sectionMore.normalTitleFont = self.cellModel!.moreFont
                    self.sectionMore.normalTitle = self.cellModel!.moreString
                    self.sectionMore.normalTitleColor = self.cellModel!.moreColor
                    self.sectionMore.midSpacing = self.cellModel!.moreDisclosureIndicatorSpace
                    self.sectionMore.imageSize = self.cellModel!.moreDisclosureIndicatorSize
                    self.sectionMore.layoutStyle = self.cellModel!.moreLayoutStyle
                    if (images?.count ?? 0) > 1 {
                        self.sectionMore.normalImage = UIImage.animatedImage(with: images!, duration: 2)
                    } else if (images?.count ?? 0) == 1 {
                        self.sectionMore.normalImage = image
                    }
                    
                    switch self.cellModel!.moreLayoutStyle {
                    case .leftImageRightTitle,.leftTitleRightImage:
                        moreWith = self.cellModel!.moreDisclosureIndicatorSize.width + self.cellModel!.moreDisclosureIndicatorSpace + moreStringWidth + 5
                    case .upImageDownTitle,.upTitleDownImage:
                        if moreStringWidth > self.cellModel!.moreDisclosureIndicatorSize.width {
                            moreWith = moreStringWidth + 5
                        } else {
                            moreWith = self.cellModel!.moreDisclosureIndicatorSize.width + 5
                        }
                    }
                    self.sectionMore.snp.makeConstraints { make in
                        make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                        make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                        make.centerY.equalToSuperview()
                        make.width.equalTo(moreWith)
                    }
                }
            } else if NSObject.checkObject(cellModel!.moreDisclosureIndicator as? NSObject) && !cellModel!.moreString.stringIsEmpty() {
                //没图片
                self.sectionMore.normalTitleFont = self.cellModel!.moreFont
                self.sectionMore.normalTitle = self.cellModel!.moreString
                self.sectionMore.normalTitleColor = self.cellModel!.moreColor
                self.sectionMore.midSpacing = 0
                self.sectionMore.imageSize = .zero
                self.sectionMore.layoutStyle = self.cellModel!.moreLayoutStyle
                moreWith = moreStringWidth + 5
                self.sectionMore.snp.makeConstraints { make in
                    make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                    make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                    make.centerY.equalToSuperview()
                    make.width.equalTo(moreWith)
                }
            } else if NSObject.checkObject(cellModel!.moreDisclosureIndicator as? NSObject) && !cellModel!.moreString.stringIsEmpty() {
                //没字
                PTLoadImageFunction.loadImage(contentData: cellModel!.moreDisclosureIndicator!,iCloudDocumentName: cellModel!.iCloudDocument) { images, image in
                    self.sectionMore.midSpacing = 0
                    self.sectionMore.imageSize = self.cellModel!.moreDisclosureIndicatorSize
                    self.sectionMore.layoutStyle = self.cellModel!.moreLayoutStyle
                    if (images?.count ?? 0) > 1 {
                        self.sectionMore.normalImage = UIImage.animatedImage(with: images!, duration: 2)
                    } else if (images?.count ?? 0) == 1 {
                        self.sectionMore.normalImage = image
                    }
                    moreWith = self.cellModel!.moreDisclosureIndicatorSize.width + 5
                    self.sectionMore.snp.makeConstraints { make in
                        make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                        make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                        make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                        make.centerY.equalToSuperview()
                        make.width.equalTo(moreWith)
                    }
                }
            }

        case .NoneAccessoryView:
            accessV.removeFromSuperview()
            valueSwitch.removeFromSuperview()
            sectionMore.removeFromSuperview()
        }
        
        accessoryViewType(type: cellModel!.accessoryType) { cellType in
            setLeftIconView(cellType: cellType)
            setRightIconView(cellType: cellType)
            setTitleLabel(cellType: cellType)
            setRightContent(cellType: cellType)
            setLine(cellType: cellType)
            
            PTGCDManager.gcdMain {
                if self.cellModel!.conrner != [] {
                    self.viewCornerRectCorner(cornerRadii: self.cellModel!.cellCorner, corner: self.cellModel!.conrner)
                } else {
                    self.viewCornerRectCorner(cornerRadii: 0, corner: [.allCorners])
                }
            }
        }
    }
    
    fileprivate lazy var nameTitle:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    lazy var accessV:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    public lazy var valueSwitch : UISwitch = {
        let switchV = UISwitch.init()
        return switchV
    }()
    
    fileprivate lazy var contentLabel : UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    fileprivate lazy var cellIcon:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    public lazy var sectionMore:PTLayoutButton = {
        let view = PTLayoutButton()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    fileprivate lazy var contentButtonLabel:PTLayoutButton = {
        let view = PTLayoutButton()
        view.titleLabel?.numberOfLines = 0
        view.layoutStyle = .leftImageRightTitle
        view.isUserInteractionEnabled = false
        return view
    }()
        
    public lazy var topLineView = drawLine()
    public lazy var lineView = drawLine()
    
    fileprivate lazy var cellContentIcon:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func createSubViews() {
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func accessoryViewType(type:PTFusionShowAccessoryType,finish:((PTFusionCellAccessoryView)->Void)) {
        if (!NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
            (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
            (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
            NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                finish(.Switch(type: .LeftImageContent(type: .Name)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .LeftImageContent(type: .Name)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .LeftImageContent(type: .Name)))
            case .More:
                finish(.More(type: .LeftImageContent(type: .Name)))
            }
        } else if (!NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                   NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                finish(.Switch(type: .LeftImageContent(type: .NameContent)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .LeftImageContent(type: .NameContent)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .LeftImageContent(type: .NameContent)))
            case .More:
                finish(.More(type: .LeftImageContent(type: .NameContent)))
            }
        } else if (!NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                   !NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                finish(.Switch(type: .BothImage(type: .Name)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .BothImage(type: .Name)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .BothImage(type: .Name)))
            case .More:
                finish(.More(type: .BothImage(type: .Name)))
            }
        } else if !NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                    !NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                finish(.Switch(type: .BothImage(type: .Content)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .BothImage(type: .Content)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .BothImage(type: .Content)))
            case .More:
                finish(.More(type: .BothImage(type: .Content)))
            }
        } else if (!NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                   !NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                finish(.Switch(type: .BothImage(type: .NameContent)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .BothImage(type: .NameContent)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .BothImage(type: .NameContent)))
            case .More:
                finish(.More(type: .BothImage(type: .NameContent)))
            }
        } else if !NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                    NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                finish(.Switch(type: .LeftImageContent(type: .Content)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .LeftImageContent(type: .Content)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .LeftImageContent(type: .Content)))
            case .More:
                finish(.More(type: .LeftImageContent(type: .Content)))
            }
        } else if !NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                    NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                finish(.Switch(type: .OnlyLeftImage))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .OnlyLeftImage))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .OnlyLeftImage))
            case .More:
                finish(.More(type: .OnlyLeftImage))
            }
        } else if NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                    !NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                finish(.Switch(type: .OnlyRightImage))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .OnlyRightImage))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .OnlyRightImage))
            case .More:
                finish(.More(type: .OnlyRightImage))
            }
        } else if (NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                   !NSObject.checkObject(cellModel!.contentIcon as? NSObject)){
            switch type {
            case .Switch:
                finish(.Switch(type: .RightImageContent(type: .Name)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .RightImageContent(type: .Name)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .RightImageContent(type: .Name)))
            case .More:
                finish(.More(type: .RightImageContent(type: .Name)))
            }
        } else if (NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                   !NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                finish(.Switch(type: .RightImageContent(type: .NameContent)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .RightImageContent(type: .NameContent)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .RightImageContent(type: .NameContent)))
            case .More:
                finish(.More(type: .RightImageContent(type: .NameContent)))
            }
        } else if NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                    !NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                finish(.Switch(type: .RightImageContent(type: .Content)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .RightImageContent(type: .Content)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .RightImageContent(type: .Content)))
            case .More:
                finish(.More(type: .RightImageContent(type: .Content)))
            }
        } else if (NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                   NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                finish(.Switch(type: .None(type: .NameContent)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .None(type: .NameContent)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .None(type: .NameContent)))
            case .More:
                finish(.More(type: .None(type: .NameContent)))
            }
        } else if !NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                    !NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                finish(.Switch(type: .BothImage(type: .None)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .BothImage(type: .None)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .BothImage(type: .None)))
            case .More:
                finish(.More(type: .BothImage(type: .None)))
            }
        } else if (NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                   (!cellModel!.name.stringIsEmpty() || !cellModel!.desc.stringIsEmpty() || cellModel!.nameAttr != nil) &&
                   (cellModel!.content.stringIsEmpty() && cellModel!.contentAttr == nil) &&
                   NSObject.checkObject(cellModel!.contentIcon as? NSObject)) {
            switch type {
            case .Switch:
                finish(.Switch(type: .None(type: .Name)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .None(type: .Name)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .None(type: .Name)))
            case .More:
                finish(.More(type: .None(type: .Name)))
            }
        } else if NSObject.checkObject(cellModel!.leftImage as? NSObject) &&
                    (cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() && cellModel!.nameAttr == nil) &&
                    (!cellModel!.content.stringIsEmpty() || cellModel!.contentAttr != nil) &&
                    NSObject.checkObject(cellModel!.contentIcon as? NSObject) {
            switch type {
            case .Switch:
                finish(.Switch(type: .None(type: .Content)))
            case .DisclosureIndicator:
                finish(.DisclosureIndicator(type: .None(type: .Content)))
            case .NoneAccessoryView:
                finish(.NoneAccessoryView(type: .None(type: .Content)))
            case .More:
                finish(.More(type: .None(type: .Content)))
            }
        } else {
            finish(.Error)
        }
    }
        
    //MARK: 设置左图标
    func setLeftIconView(cellType:PTFusionCellAccessoryView) {
        switch cellType {
        case .Switch(type: .OnlyLeftImage),
                .Switch(type: .BothImage),
                .Switch(type: .LeftImageContent),
                .DisclosureIndicator(type: .OnlyLeftImage),
                .DisclosureIndicator(type: .BothImage),
                .DisclosureIndicator(type: .LeftImageContent),
                .NoneAccessoryView(type: .OnlyLeftImage),
                .NoneAccessoryView(type: .BothImage),
                .NoneAccessoryView(type: .LeftImageContent),
                .More(type: .OnlyLeftImage),
                .More(type: .BothImage),
                .More(type: .LeftImageContent):
            addSubview(cellIcon)
            cellIcon.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                make.width.equalTo(self.cellIcon.snp.height)
            }
            
            self.cellIcon.loadImage(contentData: cellModel!.leftImage as Any,iCloudDocumentName: cellModel!.iCloudDocument)
        default:
            cellIcon.removeFromSuperview()
        }
    }
    
    //MARK: 设置右图标
    func setRightIconView(cellType:PTFusionCellAccessoryView) {
        switch cellType {
        case .Switch(type: .OnlyRightImage),
                .Switch(type: .BothImage),
                .Switch(type: .RightImageContent),
                .DisclosureIndicator(type: .OnlyRightImage),
                .DisclosureIndicator(type: .BothImage),
                .DisclosureIndicator(type: .RightImageContent),
                .NoneAccessoryView(type: .OnlyRightImage),
                .NoneAccessoryView(type: .BothImage),
                .NoneAccessoryView(type: .RightImageContent),
                .More(type: .OnlyRightImage),
                .More(type: .BothImage),
                .More(type: .RightImageContent):
            
            self.cellContentIcon.loadImage(contentData: cellModel!.contentIcon as Any,iCloudDocumentName: cellModel!.iCloudDocument)            
            addSubview(cellContentIcon)
            cellContentIcon.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                switch cellType {
                case .Switch(type: .OnlyRightImage),
                        .Switch(type: .BothImage),
                        .Switch(type: .RightImageContent):
                    make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                case .DisclosureIndicator(type: .OnlyRightImage),
                        .DisclosureIndicator(type: .BothImage),
                        .DisclosureIndicator(type: .RightImageContent):
                    make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                case .NoneAccessoryView(type: .OnlyRightImage),
                        .NoneAccessoryView(type: .BothImage),
                        .NoneAccessoryView(type: .RightImageContent):
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                case .More(type: .OnlyRightImage),
                        .More(type: .BothImage),
                        .More(type: .RightImageContent):
                    make.right.equalTo(self.sectionMore.snp.left).offset(-self.cellModel!.rightSpace)
                default:
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                }
                make.width.equalTo(self.cellContentIcon.snp.height)
            }
        default:
            cellContentIcon.removeFromSuperview()
        }
    }
    
    //MARK: 设置主文本
    func setTitleLabel(cellType:PTFusionCellAccessoryView) {
        switch cellType {
        case .Switch(type: .LeftImageContent(type: .Name)),
                .Switch(type: .LeftImageContent(type: .NameContent)),
                .Switch(type: .BothImage(type: .Name)),
                .Switch(type: .BothImage(type: .NameContent)),
                .Switch(type: .None(type: .Name)),
                .Switch(type: .None(type: .NameContent)),
                .Switch(type: .RightImageContent(type: .Name)),
                .Switch(type: .RightImageContent(type: .NameContent)),
                .DisclosureIndicator(type: .LeftImageContent(type: .Name)),
                .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                .DisclosureIndicator(type: .BothImage(type: .Name)),
                .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                .DisclosureIndicator(type: .None(type: .Name)),
                .DisclosureIndicator(type: .None(type: .NameContent)),
                .DisclosureIndicator(type: .RightImageContent(type: .Name)),
                .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .RightImageContent(type: .Name)),
                .NoneAccessoryView(type: .RightImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .None(type: .Name)),
                .NoneAccessoryView(type: .None(type: .NameContent)),
                .NoneAccessoryView(type: .LeftImageContent(type: .Name)),
                .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .BothImage(type: .Name)),
                .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                .More(type: .RightImageContent(type: .Name)),
                .More(type: .RightImageContent(type: .NameContent)),
                .More(type: .None(type: .Name)),
                .More(type: .None(type: .NameContent)),
                .More(type: .LeftImageContent(type: .Name)),
                .More(type: .LeftImageContent(type: .NameContent)),
                .More(type: .BothImage(type: .Name)),
                .More(type: .BothImage(type: .NameContent)):
            
            if  cellModel!.nameAttr != nil {
                nameTitle.attributed.text = cellModel!.nameAttr
            } else {
                var atts:ASAttributedString = ASAttributedString(string: "")
                if !cellModel!.name.stringIsEmpty() && cellModel!.desc.stringIsEmpty() {
                    let nameAtts:ASAttributedString =  ASAttributedString("\(cellModel!.name)",.paragraph(.alignment(.left),.lineSpacing(self.cellModel!.labelLineSpace)),.font(cellModel!.cellFont),.foreground(cellModel!.nameColor))
                    atts = nameAtts
                } else if cellModel!.name.stringIsEmpty() && !cellModel!.desc.stringIsEmpty() {
                    let descAtts:ASAttributedString =  ASAttributedString("\(cellModel!.desc)",.paragraph(.alignment(.left),.lineSpacing(self.cellModel!.labelLineSpace)),.font(cellModel!.cellDescFont),.foreground(cellModel!.descColor))
                    atts = descAtts
                } else if !cellModel!.name.stringIsEmpty() && !cellModel!.desc.stringIsEmpty() {
                    let nameAtts:ASAttributedString =  ASAttributedString("\(cellModel!.name)",.paragraph(.alignment(.left),.lineSpacing(self.cellModel!.labelLineSpace)),.font(cellModel!.cellFont),.foreground(cellModel!.nameColor))
                    let descAtts:ASAttributedString =  ASAttributedString("\n\(cellModel!.desc)",.paragraph(.alignment(.left),.lineSpacing(self.cellModel!.labelLineSpace)),.font(cellModel!.cellDescFont),.foreground(cellModel!.descColor))
                    atts = nameAtts + descAtts
                }
                nameTitle.attributed.text = atts
            }
            
            addSubview(nameTitle)
            nameTitle.snp.makeConstraints { make in
                //TODO: 这里要修复如果有Content的时候,文本过长,的问题
                switch cellType {
                case .Switch(type: .None(type: .Name)),
                        .Switch(type: .None(type: .NameContent)),
                        .Switch(type: .RightImageContent(type: .NameContent)),
                        .Switch(type: .RightImageContent(type: .Name)),
                        .DisclosureIndicator(type: .None(type: .Name)),
                        .DisclosureIndicator(type: .None(type: .NameContent)),
                        .DisclosureIndicator(type: .RightImageContent(type: .Name)),
                        .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                        .NoneAccessoryView(type: .None(type: .Name)),
                        .NoneAccessoryView(type: .None(type: .NameContent)),
                        .NoneAccessoryView(type: .RightImageContent(type: .Name)),
                        .NoneAccessoryView(type: .RightImageContent(type: .NameContent)),
                        .More(type: .None(type: .Name)),
                        .More(type: .None(type: .NameContent)),
                        .More(type: .RightImageContent(type: .Name)),
                        .More(type: .RightImageContent(type: .NameContent)):
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                    make.top.equalToSuperview().inset(self.cellModel!.imageTopOffset)
                    make.bottom.equalToSuperview().inset(self.cellModel!.imageBottomOffset)
                case .Switch(type: .LeftImageContent(type: .Name)),
                        .Switch(type: .LeftImageContent(type: .NameContent)),
                        .Switch(type: .BothImage(type: .Name)),
                        .Switch(type: .BothImage(type: .NameContent)),
                        .DisclosureIndicator(type: .LeftImageContent(type: .Name)),
                        .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                        .DisclosureIndicator(type: .BothImage(type: .Name)),
                        .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                        .NoneAccessoryView(type: .LeftImageContent(type: .Name)),
                        .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                        .NoneAccessoryView(type: .BothImage(type: .Name)),
                        .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                        .More(type: .LeftImageContent(type: .Name)),
                        .More(type: .LeftImageContent(type: .NameContent)),
                        .More(type: .BothImage(type: .Name)),
                        .More(type: .BothImage(type: .NameContent)):
                    make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
                    make.top.bottom.equalTo(self.cellIcon)
                default:
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace * 2 + (self.frame.size.height - (self.cellModel!.imageTopOffset + self.cellModel!.imageBottomOffset)))
                    make.top.bottom.equalTo(self.cellIcon)
                }
                
                switch cellType {
                case .Switch(type: .BothImage(type: .Name)),
                        .DisclosureIndicator(type: .BothImage(type: .Name)),
                        .NoneAccessoryView(type: .BothImage(type: .Name)),
                        .More(type: .BothImage(type: .Name)):
                    make.right.equalTo(self.cellContentIcon.snp.left).offset(-self.cellModel!.rightSpace)
                case .Switch(type: .None(type: .Name)):
                    make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                case .DisclosureIndicator(type: .None(type: .Name)):
                    make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                case .More(type: .None(type: .Name)):
                    make.right.equalTo(self.sectionMore.snp.left).offset(-self.cellModel!.rightSpace)
                case .Switch(type: .BothImage(type: .NameContent)),
                        .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                        .More(type: .BothImage(type: .NameContent)),
                        .Switch(type: .None(type: .Content)),
                        .DisclosureIndicator(type: .None(type: .Content)),
                        .More(type: .None(type: .Content)):
                    make.right.equalTo(self.snp.centerX)
                default:
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                }
            }
        default:
            nameTitle.removeFromSuperview()
        }
    }
    
    //MARK: 设置右文本
    func setRightContent(cellType:PTFusionCellAccessoryView) {
        switch cellType {
        case .Switch(type: .BothImage(type: .NameContent)),
                .Switch(type: .BothImage(type: .Content)),
                .Switch(type: .LeftImageContent(type: .NameContent)),
                .Switch(type: .LeftImageContent(type: .Content)),
                .Switch(type: .None(type: .Content)),
                .Switch(type: .None(type: .NameContent)),
                .Switch(type: .RightImageContent(type: .NameContent)),
                .Switch(type: .RightImageContent(type: .Content)),
                .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                .DisclosureIndicator(type: .BothImage(type: .Content)),
                .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                .DisclosureIndicator(type: .None(type: .Content)),
                .DisclosureIndicator(type: .None(type: .NameContent)),
                .DisclosureIndicator(type: .RightImageContent(type: .Content)),
                .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                .NoneAccessoryView(type: .BothImage(type: .Content)),
                .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .LeftImageContent(type: .Content)),
                .NoneAccessoryView(type: .RightImageContent(type: .Content)),
                .NoneAccessoryView(type: .RightImageContent(type: .NameContent)),
                .NoneAccessoryView(type: .None(type: .Content)),
                .NoneAccessoryView(type: .None(type: .NameContent)),
                .More(type: .BothImage(type: .NameContent)),
                .More(type: .BothImage(type: .Content)),
                .More(type: .LeftImageContent(type: .NameContent)),
                .More(type: .LeftImageContent(type: .Content)),
                .More(type: .RightImageContent(type: .Content)),
                .More(type: .RightImageContent(type: .NameContent)),
                .More(type: .None(type: .Content)),
                .More(type: .None(type: .NameContent)):
            if cellModel!.contentAttr != nil && cellModel!.content.stringIsEmpty() {
                contentLabel.attributed.text = cellModel!.contentAttr
            } else if cellModel!.contentAttr == nil && !cellModel!.content.stringIsEmpty() {
                let contentAtts:ASAttributedString =  ASAttributedString("\(cellModel!.content)",.paragraph(.alignment(.right),.lineSpacing(self.cellModel!.labelLineSpace)),.font(cellModel!.contentFont),.foreground(cellModel!.contentTextColor))
                contentLabel.attributed.text = contentAtts
            }
            
            addSubview(contentLabel)
            contentLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                
                switch cellType {
                case .Switch(type: .None(type: .Content)),
                        .DisclosureIndicator(type: .None(type: .Content)),
                        .More(type: .None(type: .Content)):
                    make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
                case .Switch(type: .LeftImageContent(type: .Content)),
                        .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                        .More(type: .LeftImageContent(type: .Content)),
                        .Switch(type: .BothImage(type: .Content)),
                        .DisclosureIndicator(type: .BothImage(type: .Content)),
                        .More(type: .BothImage(type: .Content)):
                    make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
                default:
                    make.left.equalTo(self.snp.centerX).offset(10)
                }
                
                switch cellType {
                case .Switch(type: .None(type: .Content)),
                        .Switch(type: .LeftImageContent(type: .Content)),
                        .Switch(type: .LeftImageContent(type: .NameContent)),
                        .Switch(type: .None(type: .NameContent)):
                    make.right.equalTo(self.valueSwitch.snp.left).offset(-self.cellModel!.rightSpace)
                case .DisclosureIndicator(type: .None(type: .Content)),
                        .DisclosureIndicator(type: .LeftImageContent(type: .Content)),
                        .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                        .DisclosureIndicator(type: .None(type: .NameContent)):
                    make.right.equalTo(self.accessV.snp.left).offset(-self.cellModel!.rightSpace)
                case .More(type: .None(type: .Content)),
                        .More(type: .LeftImageContent(type: .Content)),
                        .More(type: .LeftImageContent(type: .NameContent)),
                        .More(type: .None(type: .NameContent)):
                    make.right.equalTo(self.sectionMore.snp.left).offset(-self.cellModel!.rightSpace)
                case .NoneAccessoryView(type: .BothImage(type: .Content)),
                        .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                        .NoneAccessoryView(type: .LeftImageContent(type: .Content)),
                        .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                        .NoneAccessoryView(type: .None(type: .Content)),
                        .NoneAccessoryView(type: .None(type: .NameContent)),
                        .NoneAccessoryView(type: .RightImageContent(type: .Content)),
                        .NoneAccessoryView(type: .RightImageContent(type: .NameContent)):
                    make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
                default:
                    make.right.equalTo(self.cellContentIcon.snp.left).offset(-self.cellModel!.rightSpace)
                }
            }
        default:
            contentLabel.removeFromSuperview()
        }
    }
    
    //MARK: 设置上下线
    func setLine(cellType:PTFusionCellAccessoryView) {
        lineView.isHidden = !cellModel!.haveLine
        topLineView.isHidden = !cellModel!.haveTopLine
        
        addSubviews([lineView, topLineView])
        lineView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            switch cellType {
            case .Switch(type: .BothImage(type: .Name)),
                    .Switch(type: .BothImage(type: .NameContent)),
                    .Switch(type: .None(type: .Name)),
                    .Switch(type: .None(type: .NameContent)),
                    .Switch(type: .LeftImageContent(type: .Name)),
                    .Switch(type: .LeftImageContent(type: .NameContent)),
                    .Switch(type: .RightImageContent(type: .Name)),
                    .Switch(type: .RightImageContent(type: .NameContent)),
                    .DisclosureIndicator(type: .BothImage(type: .Name)),
                    .DisclosureIndicator(type: .BothImage(type: .NameContent)),
                    .DisclosureIndicator(type: .None(type: .Name)),
                    .DisclosureIndicator(type: .None(type: .NameContent)),
                    .DisclosureIndicator(type: .LeftImageContent(type: .Name)),
                    .DisclosureIndicator(type: .LeftImageContent(type: .NameContent)),
                    .DisclosureIndicator(type: .RightImageContent(type: .Name)),
                    .DisclosureIndicator(type: .RightImageContent(type: .NameContent)),
                    .NoneAccessoryView(type: .BothImage(type: .Name)),
                    .NoneAccessoryView(type: .BothImage(type: .NameContent)),
                    .NoneAccessoryView(type: .LeftImageContent(type: .Name)),
                    .NoneAccessoryView(type: .LeftImageContent(type: .NameContent)),
                    .NoneAccessoryView(type: .None(type: .Name)),
                    .NoneAccessoryView(type: .None(type: .NameContent)),
                    .NoneAccessoryView(type: .RightImageContent(type: .Name)),
                    .NoneAccessoryView(type: .RightImageContent(type: .NameContent)),
                    .More(type: .BothImage(type: .Name)),
                    .More(type: .BothImage(type: .NameContent)),
                    .More(type: .LeftImageContent(type: .Name)),
                    .More(type: .LeftImageContent(type: .NameContent)),
                    .More(type: .None(type: .Name)),
                    .More(type: .None(type: .NameContent)),
                    .More(type: .RightImageContent(type: .Name)),
                    .More(type: .RightImageContent(type: .NameContent)):
                make.left.equalTo(self.nameTitle)
            case .Switch(type: .OnlyLeftImage),
                    .DisclosureIndicator(type: .OnlyLeftImage),
                    .More(type: .OnlyLeftImage):
                make.left.equalTo(self.cellIcon.snp.right).offset(self.cellModel!.leftSpace)
            default:
                make.left.equalToSuperview().inset(self.cellModel!.leftSpace)
            }
        }
        
        topLineView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(self.cellModel!.rightSpace)
            make.top.equalToSuperview()
            make.height.equalTo(1)
            make.left.equalTo(self.lineView)
        }
    }
}

@objcMembers
open class PTFusionCell: PTBaseNormalCell {
    public static let ID = "PTFusionCell"
    
    open var switchValueChangeBlock:PTCellSwitchBlock?
    open var moreActionBlock:PTSectionMoreBlock?
    open var switchValue:Bool? {
        didSet {
            dataContent.valueSwitch.isOn = self.switchValue!
        }
    }

    open var cellModel:PTFusionCellModel? {
        didSet {
            self.dataContent.cellModel = self.cellModel
        }
    }
    
    open var hideTopLine:Bool! {
        didSet {
            self.dataContent.topLineView.isHidden = self.hideTopLine
        }
    }
    
    open var hideBottomLine:Bool! {
        didSet {
            self.dataContent.lineView.isHidden = self.hideBottomLine
        }
    }
    
    fileprivate lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.valueSwitch.addSwitchAction { sender in
            if self.switchValueChangeBlock != nil {
                self.switchValueChangeBlock!(self.cellModel!.name,sender)
            }
        }
        view.sectionMore.addActionHandlers { sender in
            if self.moreActionBlock != nil {
                self.moreActionBlock!(self.cellModel!.name,sender)
            }
        }
        return view
    }()
    
    override init(frame:CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(dataContent)
        dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if POOTOOLS_SWIPECELL
@objcMembers
open class PTFusionSwipeCell: PTBaseSwipeCell {
    public static let ID = "PTFusionSwipeCell"
    
    open var switchValueChangeBlock:PTCellSwitchBlock?
    open var moreActionBlock:PTSectionMoreBlock?
    open var switchValue:Bool? {
        didSet {
            dataContent.valueSwitch.isOn = self.switchValue!
        }
    }

    open var cellModel:PTFusionCellModel? {
        didSet {
            self.dataContent.cellModel = self.cellModel
        }
    }
    
    open var hideTopLine:Bool! {
        didSet {
            self.dataContent.topLineView.isHidden = self.hideTopLine
        }
    }
    
    open var hideBottomLine:Bool! {
        didSet {
            self.dataContent.lineView.isHidden = self.hideBottomLine
        }
    }

    fileprivate lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.valueSwitch.addSwitchAction { sender in
            if self.switchValueChangeBlock != nil {
                self.switchValueChangeBlock!(self.cellModel!.name,sender)
            }
        }
        view.sectionMore.addActionHandlers { sender in
            if self.moreActionBlock != nil {
                self.moreActionBlock!(self.cellModel!.name,sender)
            }
        }
        return view
    }()
    
    override init(frame:CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(dataContent)
        dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
