//
//  PTDevFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import Kingfisher

public typealias DevTask = () -> Void
public typealias FlexDevTask = (Bool) -> Void

@objcMembers
public class PTDevFunction: NSObject {
    public static let share = PTDevFunction()
    
    public var mn_PFloatingButton : PFloatingButton?
    //去開發人員設置界面
    public var goToAppDevVC:DevTask?
    //開啟/關閉Flex
    /*
     #if DEBUG
     if FLEXManager.shared.isHidden {
         FLEXManager.shared.showExplorer()
     } else {
         FLEXManager.shared.hideExplorer()
     }
     #endif
     */
    public var flex:DevTask?
    public var flexBool:FlexDevTask?
    public var HyperioniOS:DevTask?
    //開啟/關閉inAppViewDebugger
    /*
     #if DEBUG
        InAppViewDebugger.present()
     #endif
     */
    public var inApp:DevTask?

    private var maskView:PTDevMaskView?
    
    public func createLabBtn() {
        if UIApplication.applicationEnvironment() != .appStore {
            UserDefaults.standard.set(true,forKey: LocalConsole.ConsoleDebug)
            if self.mn_PFloatingButton == nil {
                mn_PFloatingButton = PFloatingButton.init(view: AppWindows as Any, frame: CGRect.init(x: 0, y: 200, width: 50, height: 50))
                mn_PFloatingButton?.backgroundColor = .randomColor
                
                let btnLabel = UILabel()
                btnLabel.textColor = .randomColor
                btnLabel.sizeToFit()
                btnLabel.textAlignment = .center
                btnLabel.font = .systemFont(ofSize: 13)
                btnLabel.numberOfLines = 0
                btnLabel.text = "实验室"
                mn_PFloatingButton?.addSubview(btnLabel)
                btnLabel.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                mn_PFloatingButton?.longPressBlock = { (sender) in
                    UIAlertController.base_alertVC(msg: "调试框架",okBtns: ["全部开启","FLEX","Log","FPS","全部关闭","调试功能界面","检测界面","HyperioniOS","DEVMask"],cancelBtn: "取消") {
                        
                    } moreBtn: { index, title in
                        if title == "全部开启" {
                            PTDevFunction.GobalDevFunction_open { show in
                                if self.flexBool != nil {
                                    self.flexBool!(show)
                                }
                            }
                        } else if title == "全部关闭" {
                            PTDevFunction.GobalDevFunction_close { show in
                                if self.flexBool != nil {
                                    self.flexBool!(show)
                                }
                            }
                        } else if title == "FLEX" {
                            if self.flex != nil {
                                self.flex!()
                            }
                        } else if title == "Log" {
                            if PTLocalConsoleFunction.share.localconsole.terminal == nil {
                                PTLocalConsoleFunction.share.localconsole.createSystemLogView()
                            } else {
                                PTLocalConsoleFunction.share.localconsole.cleanSystemLogView()
                            }
                        } else if title == "FPS" {
                            if PCheckAppStatus.shared.closed {
                                PCheckAppStatus.shared.open()
                            } else {
                                PCheckAppStatus.shared.close()
                            }
                        } else if title == "调试功能界面" {
                            if self.goToAppDevVC != nil {
                                self.goToAppDevVC!()
                            }
                        } else if title == "检测界面" {
                            if self.inApp != nil {
                                self.inApp!()
                            }
                        } else if title == "HyperioniOS" {
                            if self.HyperioniOS != nil {
                                self.HyperioniOS!()
                            }
                        } else if title == "DEVMask" {
                            if self.maskView != nil {
                                self.maskView?.removeFromSuperview()
                                self.maskView = nil
                            } else {
                                let maskConfig = PTDevMaskConfig()
                                
                                self.maskView = PTDevMaskView(config: maskConfig)
                                self.maskView?.frame = AppWindows!.frame
                                AppWindows?.addSubview(self.maskView!)
                            }
                        }
                    }
                }
            }
        }
    }
    
    public class func GobalDevFunction_open(flexTask:(Bool)->Void) {
        if UIApplication.applicationEnvironment() != .appStore {
            flexTask(true)
            PTLocalConsoleFunction.share.localconsole.createSystemLogView()
            PCheckAppStatus.shared.open()
            
            let devShare = PTDevFunction.share
            if devShare.maskView == nil {
                let maskConfig = PTDevMaskConfig()
                
                devShare.maskView = PTDevMaskView(config: maskConfig)
                devShare.maskView?.frame = AppWindows!.frame
                AppWindows?.addSubview(devShare.maskView!)
            }
        }
    }

    public class func GobalDevFunction_close(flexTask:(Bool)->Void) {
        if UIApplication.shared.inferredEnvironment != .appStore {
            flexTask(false)
            PTLocalConsoleFunction.share.localconsole.cleanSystemLogView()
            PCheckAppStatus.shared.close()
            
            let devShare = PTDevFunction.share
            if devShare.maskView != nil {
                devShare.maskView?.removeFromSuperview()
                devShare.maskView = nil
            }
        }
    }

    public func lab_btn_release() {
        UserDefaults.standard.set(false,forKey: LocalConsole.ConsoleDebug)
        self.mn_PFloatingButton?.removeFromSuperview()
        self.mn_PFloatingButton = nil
    }

    //MARK: SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    public class func gobalWebImageLoadOption()->KingfisherOptionsInfo {
        #if DEBUG
        let userDefaults = UserDefaults.standard.value(forKey: "sdwebimage_option")
        let devServer:Bool = userDefaults == nil ? true : (userDefaults as! Bool)
        if devServer {
            return [KingfisherOptionsInfoItem.cacheOriginalImage]
        } else {
            return [.lowDataModeSource,.memoryCacheExpiration(.seconds(60)).diskCacheExpiration(.seconds(20))]
        }
        #else
        return [KingfisherOptionsInfoItem.cacheOriginalImage]
        #endif
    }
}
