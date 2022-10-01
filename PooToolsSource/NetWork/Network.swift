//
//  Network.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/21.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD
import KakaJSON
import SwiftyJSON

public enum NetWorkStatus: String {
    case unknown      = "未知网络"
    case notReachable = "网络无连接"
    case wwan         = "2，3，4G网络"
    case wifi          = "wifi网络"
}

public enum NetWorkEnvironment: String {
    case Development  = "开发环境"
    case Test         = "测试环境"
    case Distribution = "生产环境"
}

public typealias ReslutClosure = (_ result: ResponseModel?,_ error: AFError?) -> Void
public typealias NetWorkStatusBlock = (_ NetWorkStatus: String, _ NetWorkEnvironment: String,_ NetworkStatusType:NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
public typealias NetWorkErrorBlock = () -> Void
public typealias NetWorkServerStatusBlock = (_ result: ResponseModel) -> Void
public typealias UploadProgress = (_ progress: Progress) -> Void

// MARK: - 网络运行状态监听
public class XMNetWorkStatus {
    
    static let shared = XMNetWorkStatus()
    /// 当前网络环境状态
    private var currentNetWorkStatus: NetWorkStatus = .wifi
    /// 当前运行环境状态
    private var currentEnvironment: NetWorkEnvironment = .Test
    
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.baidu.com")
    
    private func detectNetWork(netWork: @escaping NetWorkStatusBlock) {
        reachabilityManager?.startListening(onUpdatePerforming: { [weak self] (status) in
            guard let weakSelf = self else { return }
            if self?.reachabilityManager?.isReachable ?? false {
                switch status {
                case .notReachable:
                    weakSelf.currentNetWorkStatus = .notReachable
                case .unknown:
                    weakSelf.currentNetWorkStatus = .unknown
                case .reachable(.cellular):
                    weakSelf.currentNetWorkStatus = .wwan
                case .reachable(.ethernetOrWiFi):
                    weakSelf.currentNetWorkStatus = .wifi
                }
            } else {
                weakSelf.currentNetWorkStatus = .notReachable
            }
            netWork(weakSelf.currentNetWorkStatus.rawValue, weakSelf.currentEnvironment.rawValue,status)
        })
    }
    
    ///监听网络运行状态
    public func obtainDataFromLocalWhenNetworkUnconnected(handle:((NetworkReachabilityManager.NetworkReachabilityStatus)->Void)?) {
        detectNetWork { (status, environment,statusType)  in
            PTNSLog("当前网络环境为-> \(status) 当前运行环境为-> \(environment)")
            if handle != nil
            {
                handle!(statusType)
            }
        }
    }
}


@objcMembers
public class Network: NSObject {
    
    static public let share = Network()
        
    static var header:HTTPHeaders?
    
    public var netRequsetTime:TimeInterval = 20
    public var serverAddress:String = ""
    public var userToken:String = ""

    /// manager
    private static var manager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Network.share.netRequsetTime
        return Session(configuration: configuration)
    }()
    
    /// manager
    static var hud: MBProgressHUD = {
        let hud = MBProgressHUD.init(view: AppWindows!)
        AppWindows!.addSubview(hud)
        hud.show(animated: true)
        return hud
    }()
    //JSONEncoding  JSON参数
    //URLEncoding    URL参数
    
    /// 项目总接口
    /// - Parameters:
    ///   - urlStr: url地址
    ///   - method: 方法类型，默认post
    ///   - parameters: 请求参数，默认nil
    ///   - modelType: 是否需要传入接口的数据模型，默认nil
    ///   - encoder: 编码方式，默认url编码
    ///   - showHud: 是否需要loading，默认true
    ///   - resultBlock: 方法回调
    class public func requestApi(urlStr:String,
                          method: HTTPMethod = .post,
                          parameters: Parameters? = nil,
                          modelType: Convertible.Type? = nil,
                          encoder:ParameterEncoding = URLEncoding.default,
                          showHud:Bool? = true,
                          jsonRequest:Bool? = false,
                          netWorkErrorBlock:NetWorkErrorBlock? = nil,
                          netWorkServerStatusBlock:NetWorkServerStatusBlock? = nil,
                          resultBlock: @escaping ReslutClosure){
        
        
        let urlStr = Network.share.serverAddress + urlStr
        
        // 判断网络是否可用
        if let reachabilityManager = XMNetWorkStatus.shared.reachabilityManager {
            if !reachabilityManager.isReachable {
                if netWorkErrorBlock != nil
                {
                    netWorkErrorBlock!()
                }
                return
            }
        }
        
        let token = Network.share.userToken
        if !token.stringIsEmpty() {
            header = HTTPHeaders.init(["token":token,"device":"iOS"])
            if jsonRequest!
            {
                header!["Content-Type"] = "application/json;charset=UTF-8"
                header!["Accept"] = "application/json"
            }
        }
        
        if showHud!{
            Network.hud.show(animated: true)
        }
        PTLocalConsoleFunction.share.pNSLog("😂😂😂😂😂😂😂😂😂😂😂😂\n❤️1.请求地址 = \(urlStr)\n💛2.参数 = \(parameters?.jsonString() ?? "没有参数")\n💙3.请求头 = \(header?.dictionary.jsonString() ?? "没有请求头")\n😂😂😂😂😂😂😂😂😂😂😂😂")
        PTUtils.showNetworkActivityIndicator(true)
        
        Network.manager.request(urlStr, method: method, parameters: parameters, encoding: encoder, headers: header).responseData { data in
            if showHud! {
                Network.hud.hide(animated: true)
            }
            PTUtils.showNetworkActivityIndicator(false)
            switch data.result {
            case .success(_):
                let json = JSON(data.value ?? "")
                guard let jsonStr = json.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.prettyPrinted) else { return }
                
                PTLocalConsoleFunction.share.pNSLog("😂😂😂😂😂😂😂😂😂😂😂😂\n❤️1.请求地址 = \(urlStr)\n💛2.result:\(jsonStr)\n😂😂😂😂😂😂😂😂😂😂😂😂")

                guard let responseModel = jsonStr.kj.model(ResponseModel.self) else { return }

                if netWorkServerStatusBlock != nil
                {
                    netWorkServerStatusBlock!(responseModel)
                }
                
                guard let modelType = modelType else { resultBlock(responseModel,nil); return }
                if responseModel.data is [String : Any] {
                    guard let reslut = responseModel.data as? [String : Any] else {resultBlock(responseModel,nil); return }
//                    if reslut["list"] is Array<Any> {
//                        responseModel.datas = (reslut["list"] as! Array<Any>).kj.modelArray(type: modelType)
//                    }else if reslut["routine_my_menus"]is Array<Any> {//针对个人中心的功能菜单做转换
//                        responseModel.datas = (reslut["routine_my_menus"] as! Array<Any>).kj.modelArray(type: modelType)
//                    }else {
                        responseModel.data = reslut.kj.model(type: modelType)
//                    }
                }else if responseModel.data is Array<Any> {
                    responseModel.datas = (responseModel.data as! Array<Any>).kj.modelArray(type: modelType)
                }
                
                resultBlock(responseModel,nil)

            case .failure(let error):
                PTLocalConsoleFunction.share.pNSLog("------------------------------------>\n接口:\(urlStr)\n----------------------出现错误----------------------\n\(String(describing: error.errorDescription))",error: true)
                resultBlock(nil,error)
            }
        }
    }
    
    /// 图片上传接口
    /// - Parameters:
    ///   - images: 图片集合
    ///   - progressBlock: 进度回调
    ///   - success: 成功回调
    ///   - failure: 失败回调
    class public func imageUpload(images:[UIImage]?,
                           path:String? = "/api/project/ossImg",
                           fileKey:String? = "images",
                           parmas:[String:String]? = nil,
                           netWorkErrorBlock:NetWorkErrorBlock? = nil,
                           progressBlock:UploadProgress? = nil,
                           resultBlock: @escaping ReslutClosure) {
        
        let pathUrl = Network.share.serverAddress + path!
        
        // 判断网络是否可用
        if let reachabilityManager = XMNetWorkStatus.shared.reachabilityManager {
            if !reachabilityManager.isReachable {
                if netWorkErrorBlock != nil
                {
                    netWorkErrorBlock!()
                }
                return
            }
        }
        
        let hud:MBProgressHUD = MBProgressHUD.showAdded(to: AppWindows!, animated: true)
        hud.show(animated: true)
        
        var headerDic = [String:String]()
        headerDic["device"] = "iOS"
        let token = Network.share.userToken
        if !token.stringIsEmpty()
        {
            headerDic["token"] = token
        }
        let requestHeaders = HTTPHeaders.init(headerDic)
        
        Network.manager.upload(multipartFormData: { (multipartFormData) in
            images?.enumerated().forEach { index,image in
                if let imgData = image.jpegData(compressionQuality: 0.2) {
                    multipartFormData.append(imgData, withName: fileKey!,fileName: "image_\(index).png", mimeType: "image/png")
                }
            }
            if parmas != nil
            {
                parmas?.keys.enumerated().forEach({ index,value in
                    multipartFormData.append(Data(parmas![value]!.utf8), withName: value)
                })
            }
        }, to: pathUrl,method: .post, headers: requestHeaders) { (result) in
        }
        .uploadProgress(closure: { (progress) in
            if progressBlock != nil
            {
                progressBlock!(progress)
            }
        })
        .response { response in
            hud.hide(animated: true)
            
            switch response.result {
            case .success(let result):
                guard let responseModel = result?.toDict()?.kj.model(ResponseModel.self) else { return }
                PTLocalConsoleFunction.share.pNSLog("😂😂😂😂😂😂😂😂😂😂😂😂\n❤️1.请求地址 = \(pathUrl)\n💛2.result:\(result!.toDict()!)\n😂😂😂😂😂😂😂😂😂😂😂😂")
                resultBlock(responseModel,nil)
            case .failure(let error):
                PTLocalConsoleFunction.share.pNSLog("😂😂😂😂😂😂😂😂😂😂😂😂\n❤️1.请求地址 =\(pathUrl)\n💛2.error:\(error)",error: true)
                resultBlock(nil,error)

            }
        }
    }
}