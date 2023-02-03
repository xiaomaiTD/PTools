//
//  PTUtils.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AVFoundation
import NotificationBannerSwift
import SwiftDate

@inline(__always) private func isIPhoneXSeries() -> Bool {
    var iPhoneXSeries = false
    if UIDevice.current.userInterfaceIdiom != .phone {
        return iPhoneXSeries
    }

    let mainWindow:UIView = UIApplication.shared.delegate!.window!!
    if (mainWindow.safeAreaInsets.bottom) > 0.0 {
        iPhoneXSeries = true
    }

    return iPhoneXSeries
}

@objc public enum CheckContractTimeRelationships:Int
{
    case Expire
    case ReadyExpire
    case Normal
    case Error
}

@objc public enum PTUrlStringVideoType:Int {
    case MP4
    case MOV
    case ThreeGP
    case UNKNOW
}

@objc public enum PTAboutImageType:Int {
    case JPEG
    case JPEG2000
    case PNG
    case GIF
    case TIFF
    case WEBP
    case BMP
    case ICO
    case ICNS
    case UNKNOW
}

@objc public enum TemperatureUnit:Int
{
    case Fahrenheit
    case CentigradeDegree
}

@objc public enum GradeType:Int
{
    case normal
    case TenThousand
    case HundredMillion
}

@objcMembers
public class PTUtils: NSObject {
        
    public static let share = PTUtils()
    public var timer:DispatchSourceTimer?
    
    @available(iOS, introduced: 2.0, deprecated: 13.0, message: "這個方法在iOS13之後不能使用了")
    public class func showNetworkActivityIndicator(_ show:Bool)
    {
        PTUtils.gcdMain {
            UIApplication.shared.isNetworkActivityIndicatorVisible = show
        }
    }
    
    //MARK: GCD延時執行
    ///GCD延時執行
    public class func gcdAfter(time:TimeInterval,
                             block:@escaping (()->Void))
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: block)
    }
    
    //MARK: gcdMain是用於在背景執行非同步任務的，它可以在多個不同的系統線程上執行任務。
    ///gcdMain是用於在背景執行非同步任務的，它可以在多個不同的系統線程上執行任務。
    public class func gcdMain(block:@escaping (()->Void))
    {
        DispatchQueue.main.async(execute: block)
    }
    
    //MARK: gcdGobal是用於在主執行緒上執行非同步任務的，通常用於更新UI或進行其他與用戶交互有關的操作。
    ///gcdGobal是用於在主執行緒上執行非同步任務的，通常用於更新UI或進行其他與用戶交互有關的操作。
    public class func gcdGobal(block:@escaping (()->Void))
    {
        DispatchQueue.global(qos: .userInitiated).async(execute: block)
    }
            
    public class func timeRunWithTime_base(customQueName:String,timeInterval:TimeInterval,finishBlock:@escaping ((_ finish:Bool,_ time:Int)->Void))
    {
        let customQueue = DispatchQueue(label: customQueName)
        var newCount = Int(timeInterval) + 1
        PTUtils.share.timer = DispatchSource.makeTimerSource(flags: [], queue: customQueue)
        PTUtils.share.timer!.schedule(deadline: .now(), repeating: .seconds(1))
        PTUtils.share.timer!.setEventHandler {
            DispatchQueue.main.async {
                newCount -= 1
                finishBlock(false,newCount)
                if newCount < 1 {
                    DispatchQueue.main.async {
                        finishBlock(true,0)
                    }
                    PTUtils.share.timer!.cancel()
                    PTUtils.share.timer = nil
                }
            }
        }
        PTUtils.share.timer!.resume()
    }
    
    public class func timeRunWithTime(timeInterval:TimeInterval,
                                    sender:UIButton,
                                    originalTitle:String,
                                    canTap:Bool,
                                timeFinish:(()->Void)?)
    {
        PTUtils.timeRunWithTime_base(customQueName:"TimeFunction",timeInterval: timeInterval) { finish, time in
            if finish
            {
                sender.setTitle(originalTitle, for: sender.state)
                sender.isUserInteractionEnabled = canTap
                if timeFinish != nil
                {
                    timeFinish!()
                }
            }
            else
            {
                let strTime = String.init(format: "%.2d", time)
                let buttonTime = String.init(format: "%@", strTime)
                sender.setTitle(buttonTime, for: sender.state)
                sender.isUserInteractionEnabled = false
            }
        }
    }
            
    public class func sizeFor(string:String,
                              font:UIFont,
                              lineSpacing:CGFloat? = nil,
                              height:CGFloat,
                              width:CGFloat)->CGSize
    {
        var dic = [NSAttributedString.Key.font:font] as! [NSAttributedString.Key:Any]
        if lineSpacing != nil
        {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = lineSpacing!
            dic[NSAttributedString.Key.paragraphStyle] = paraStyle
        }
        let size = string.boundingRect(with: CGSize.init(width: width, height: height), options: [.usesLineFragmentOrigin,.usesDeviceMetrics], attributes: dic, context: nil).size
        return size
    }

    public class func getCurrentVCFrom(rootVC:UIViewController)->UIViewController
    {
        var currentVC : UIViewController?
        
        if rootVC is UITabBarController
        {
            currentVC = PTUtils.getCurrentVCFrom(rootVC: (rootVC as! UITabBarController).selectedViewController!)
        }
        else if rootVC is UINavigationController
        {
            currentVC = PTUtils.getCurrentVCFrom(rootVC: (rootVC as! UINavigationController).visibleViewController!)
        }
        else
        {
            currentVC = rootVC
        }
        return currentVC!
    }
    
    public class func getCurrentVC(anyClass:UIViewController? = UIViewController())->UIViewController
    {
        let currentVC = PTUtils.getCurrentVCFrom(rootVC: (AppWindows?.rootViewController ?? anyClass!))
        return currentVC
    }
    
    public class func returnFrontVC()
    {
        let vc = PTUtils.getCurrentVC()
        if vc.presentingViewController != nil
        {
            vc.dismiss(animated: true, completion: nil)
        }
        else
        {
            vc.navigationController?.popViewController(animated: true, nil)
        }
    }
    
    public class func cgBaseBundle()->Bundle
    {
        let bundle = Bundle.init(for: self)
        return bundle
    }
    
    public class func color(name:String,traitCollection:UITraitCollection,bundle:Bundle? = PTUtils.cgBaseBundle())->UIColor
    {
        return UIColor(named: name, in: bundle!, compatibleWith: traitCollection) ?? .randomColor
    }
    
    public class func image(name:String,traitCollection:UITraitCollection,bundle:Bundle? = PTUtils.cgBaseBundle())->UIImage
    {
        return UIImage(named: name, in: bundle!, compatibleWith: traitCollection) ?? UIColor.randomColor.createImageWithColor()
    }
    
    public class func darkModeImage(name:String,bundle:Bundle? = PTUtils.cgBaseBundle())->UIImage
    {
        return PTUtils.image(name: name, traitCollection: (UIApplication.shared.delegate?.window?!.rootViewController!.traitCollection)!,bundle: bundle!)
    }
        
    //MARK: SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    public class func gobalWebImageLoadOption()->SDWebImageOptions
    {
        #if DEBUG
        let userDefaults = UserDefaults.standard.value(forKey: "sdwebimage_option")
        let devServer:Bool = userDefaults == nil ? true : (userDefaults as! Bool)
        if devServer
        {
            return .retryFailed
        }
        else
        {
            return .lowPriority
        }
        #else
        return .retryFailed
        #endif
    }
    
    //MARK: 弹出框
    class open func gobal_drop(title:String?,
                               titleFont:UIFont? = UIFont.appfont(size: 16),
                               titleColor:UIColor? = .black,
                               subTitle:String? = nil,
                               subTitleFont:UIFont? = UIFont.appfont(size: 16),
                               subTitleColor:UIColor? = .black,
                               bannerBackgroundColor:UIColor? = .white,
                               notifiTap:(()->Void)? = nil)
    {
        var titleStr = ""
        if title == nil || (title ?? "").stringIsEmpty()
        {
            titleStr = ""
        }
        else
        {
            titleStr = title!
        }
        
        var subTitleStr = ""
        if subTitle == nil || (subTitle ?? "").stringIsEmpty()
        {
            subTitleStr = ""
        }
        else
        {
            subTitleStr = subTitle!
        }
                
        let banner = FloatingNotificationBanner(title:titleStr,subtitle: subTitleStr)
        banner.duration = 1.5
        banner.backgroundColor = bannerBackgroundColor!
        banner.subtitleLabel?.textAlignment = PTUtils.sizeFor(string: subTitleStr, font: subTitleFont!, height:44, width: CGFloat(MAXFLOAT)).width > (CGFloat.kSCREEN_WIDTH - 36) ? .left : .center
        banner.subtitleLabel?.font = subTitleFont
        banner.subtitleLabel?.textColor = subTitleColor!
        banner.titleLabel?.textAlignment = PTUtils.sizeFor(string: titleStr, font: titleFont!, height:44, width: CGFloat(MAXFLOAT)).width > (CGFloat.kSCREEN_WIDTH - 36) ? .left : .center
        banner.titleLabel?.font = titleFont
        banner.titleLabel?.textColor = titleColor!
        banner.show(queuePosition: .front, bannerPosition: .top ,cornerRadius: 15)
        banner.onTap = {
            if notifiTap != nil
            {
                notifiTap!()
            }
        }
    }

    //MARK: 生成CollectionView的Group
    class open func gobal_collection_gird_layout(data:[AnyObject],
                                                 size:CGSize? = CGSize.init(width: (CGFloat.kSCREEN_WIDTH - 10 * 2)/3, height: (CGFloat.kSCREEN_WIDTH - 10 * 2)/3),
                                                 originalX:CGFloat? = 10,
                                                 mainWidth:CGFloat? = CGFloat.kSCREEN_WIDTH,
                                                 cellRowCount:NSInteger? = 3,
                                                 sectionContentInsets:NSDirectionalEdgeInsets? = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0),
                                                 contentTopAndBottom:CGFloat? = 0,
                                                 cellLeadingSpace:CGFloat? = 0,
                                                 cellTrailingSpace:CGFloat? = 0)->NSCollectionLayoutGroup
    {
        let bannerItemSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.fractionalHeight(1))
        let bannerItem = NSCollectionLayoutItem.init(layoutSize: bannerItemSize)
        var bannerGroupSize : NSCollectionLayoutSize

        var customers = [NSCollectionLayoutGroupCustomItem]()
        var groupH:CGFloat = 0

        let itemH = size!.height
        let itemW = size!.width

        var x:CGFloat = originalX!,y:CGFloat = 0 + contentTopAndBottom!
        data.enumerated().forEach { (index,value) in
            if index < cellRowCount!
            {
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: x, y: y, width: itemW, height: itemH), zIndex: 1000+index)
                customers.append(customItem)
                x += itemW + cellLeadingSpace!
                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom!
                }
            }
            else
            {
                x += itemW + cellLeadingSpace!
                if index > 0 && (index % cellRowCount! == 0)
                {
                    x = originalX!
                    y += itemH + cellTrailingSpace!
                }

                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom!
                }
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: x, y: y, width: itemW, height: itemH), zIndex: 1000+index)
                customers.append(customItem)
            }
        }

        bannerItem.contentInsets = sectionContentInsets!
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(mainWidth!-originalX!*2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
            customers
        })
    }
    
    //MARK: 计算CollectionView的Group高度
    class open func gobal_collection_gird_layout_content_height(data:[AnyObject],
                                                                size:CGSize? = CGSize.init(width: (CGFloat.kSCREEN_WIDTH - 10 * 2)/3, height: (CGFloat.kSCREEN_WIDTH - 10 * 2)/3),
                                                                cellRowCount:NSInteger? = 3,
                                                                originalX:CGFloat? = 10,
                                                                contentTopAndBottom:CGFloat? = 0,
                                                                cellLeadingSpace:CGFloat? = 0,
                                                                cellTrailingSpace:CGFloat? = 0)->CGFloat
    {
        var groupH:CGFloat = 0
        let itemH = size!.height
        let itemW = size!.width
        var x:CGFloat = originalX!,y:CGFloat = 0 + contentTopAndBottom!
        data.enumerated().forEach { (index,value) in
            if index < cellRowCount!
            {
                x += itemW + cellLeadingSpace!
                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom!
                }
            }
            else
            {
                x += itemW + cellLeadingSpace!
                if index > 0 && (index % cellRowCount! == 0)
                {
                    x = originalX!
                    y += itemH + cellTrailingSpace!
                }

                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom!
                }
            }
        }
        return groupH
    }

    //MARK: 获取一个输入内最大的一个值
    ///获取一个输入内最大的一个值
    class open func maxOne<T:Comparable>( _ seq:[T]) -> T{

        assert(seq.count>0)
        return seq.reduce(seq[0]){
            max($0, $1)
        }
    }
    
    //MARK: 华氏摄氏度转普通摄氏度/普通摄氏度转华氏摄氏度
    ///华氏摄氏度转普通摄氏度/普通摄氏度转华氏摄氏度
    class open func temperatureUnitExchangeValue(value:CGFloat,changeToType:TemperatureUnit) ->CGFloat
    {
        switch changeToType {
        case .Fahrenheit:
            return 32 + 1.8 * value
        case .CentigradeDegree:
            return (value - 32) / 1.8
        default:
            return 0
        }
    }
            
    //MARK: 找出某view的superview
    ///找出某view的superview
    class open func findSuperViews(view:UIView)->[UIView]
    {
        var temp = view.superview
        let result = NSMutableArray()
        while temp != nil {
            result.add(temp!)
            temp = temp!.superview
        }
        return result as! [UIView]
    }
    
    //MARK: 找出某views的superview
    ///找出某views的superview
    class open func findCommonSuperView(firstView:UIView,other:UIView)->[UIView]
    {
        let result = NSMutableArray()
        let sOne = self.findSuperViews(view: firstView)
        let sOther = self.findSuperViews(view: other)
        var i = 0
        while i < min(sOne.count, sOther.count) {
            if sOne == sOther
            {
                result.add(sOne)
                i += 1
            }
            else
            {
                break
            }
        }
        return result as! [UIView]
    }
        
    //MARK: 这个方法可以用于UITextField中,检测金额输入
    class open func textInputAmoutRegex(text:NSString,range:NSRange,replacementString:NSString)->Bool
    {
        let len = (range.length > 0) ? (text.length - range.length) : (text.length + replacementString.length)
        if len > 20
        {
            return false
        }
        let str = NSString(format: "%@%@", text,replacementString)
        return (str as String).isMoneyString()
    }
    
    //MARK: 查找某字符在字符串的位置
    class open func rangeOfSubString(fullStr:NSString,subStr:NSString)->[String]
    {
        var rangeArray = [String]()
        for i in 0..<fullStr.length
        {
            let temp:NSString = fullStr.substring(with: NSMakeRange(i, subStr.length)) as NSString
            if temp.isEqual(to: subStr as String)
            {
                let range = NSRange(location: i, length: subStr.length)
                rangeArray.append(NSStringFromRange(range))
            }
        }
        return rangeArray
    }
            
    //MARK: 合同时间状态检测
    open class func checkContractTimeType(begainTime:String,
                                          endTime:String,
                                          readyExpTime:Int)->CheckContractTimeRelationships
    {
        let begainTimeDate = begainTime.toDate("yyyy-MM-dd")!
        let endTimeDate = endTime.toDate("yyyy-MM-dd")!
        let timeDifference = endTimeDate.timeIntervalSince(begainTimeDate)
        let thirty = NSNumber(integerLiteral: readyExpTime).floatValue
        let result = timeDifference.float - thirty
        if result > (-thirty) && result < thirty
        {
            return .ReadyExpire
        }
        else if result < (-thirty)
        {
            return .Expire
        }
        else if result > 0
        {
            return .Normal
        }
        else
        {
            return .Error
        }
    }
    
    open class func checkContractTimeType_now(endTime:String,readyExpTime:Int)->CheckContractTimeRelationships
    {        
        return PTUtils.checkContractTimeType(begainTime: Date().toFormat("yyyy-MM-dd"), endTime: endTime, readyExpTime: readyExpTime)
    }
    
    //MARK: 檢測當前系統是否小於某個版本系統
    ///檢測當前系統是否小於某個版本系統
    /// - Returns: Bool
    class func lessThanSysVersion(version:NSString,equal:Bool) -> Bool
    {
        return UIDevice.current.systemVersion.compare("\(version)",options: .numeric) != (equal ? .orderedDescending : .orderedAscending)
    }
}

//MARK: OC-FUNCTION
extension PTUtils
{
    public class func oc_isiPhoneSeries()->Bool
    {
        return isIPhoneXSeries()

    }
    
    public class func oc_alert_only_show(title:String?,message:String?)
    {
        PTUtils.oc_alert_base(title: title ?? "", msg: message ?? "", okBtns: [], cancelBtn: "确定", showIn: AppWindows!.rootViewController!) {
            
        } moreBtn: { index, title in
            
        }
    }
    
    public class func oc_alert_base(title:String,msg:String,okBtns:[String],cancelBtn:String,showIn:UIViewController,cancel:@escaping (()->Void),moreBtn:@escaping ((_ index:Int,_ title:String)->Void))
    {
        UIAlertController.base_alertVC(title: title, msg: msg, okBtns: okBtns, cancelBtn: cancelBtn, showIn: showIn, cancel: cancel, moreBtn: moreBtn)
    }

    public class func oc_size(string:String,
                              font:UIFont,
                              lineSpacing:CGFloat = CGFloat.ScaleW(w: 3),
                              height:CGFloat,
                              width:CGFloat)->CGSize
    {
        return PTUtils.sizeFor(string: string, font: font,lineSpacing: lineSpacing, height: height, width: width)
    }
    
    //MARK: 时间
    class open func oc_currentTimeFunction(dateFormatter:NSString)->String
    {
        return String.currentDate(dateFormatterString: dateFormatter as String)
    }
    
    class open func oc_currentTimeToTimeInterval(dateFormatter:NSString)->TimeInterval
    {
        return String.currentDate(dateFormatterString: dateFormatter as String).dateStrToTimeInterval(dateFormat: dateFormatter as String)
    }

    class open func oc_dateStringFormat(dateString:String,formatString:String)->NSString
    {
        let regions = Region(calendar: Calendars.republicOfChina,zone: Zones.asiaHongKong,locale: Locales.chineseChina)
        return dateString.toDate(formatString,region: regions)!.toString() as NSString
    }
    
    class open func oc_dateFormat(date:Date,formatString:String)->String
    {
        return date.toFormat(formatString)
    }    
}
