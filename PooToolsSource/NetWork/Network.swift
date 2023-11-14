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
import Network

public let NetWorkNoError = NSError(domain: "PT Network no network".localized(), code: 99999999996)
public let NetWorkJsonExplainError = NSError(domain: "PT Network json fail".localized(), code: 99999999998)
public let NetWorkModelExplainError = NSError(domain: "PT Network model fail".localized(), code: 99999999999)
public let NetWorkDownloadError = NSError(domain: "PT Network download fail".localized(), code: 99999999997)

public let AppTestMode = "PT App network environment test".localized()
public let AppCustomMode = "PT App network environment custom".localized()
public let AppDisMode = "PT App network environment distribution".localized()

public enum NetWorkStatus: Int {
    case unknown
    case notReachable
    case wwan
    case wifi
    
    static func valueName(type:NetWorkStatus) -> String {
        switch type {
        case .unknown:
            "PT App network status unknow".localized()
        case .notReachable:
            "PT App network status disconnect".localized()
        case .wwan:
            "2,3,4G,5G"
        case .wifi:
            "WIFI"
        }
    }
}

public enum NetWorkEnvironment: Int {
    case Development
    case Test
    case Distribution
    
    static func valueName(type:NetWorkEnvironment) -> String {
        switch type {
        case .Development:
            "PT App network environment custom".localized()
        case .Test:
            "PT App network environment test".localized()
        case .Distribution:
            "PT App network environment distribution".localized()
        }
    }
}

public typealias NetWorkStatusBlock = (_ NetWorkStatus: String, _ NetWorkEnvironment: String,_ NetworkStatusType:NetworkReachabilityManager.NetworkReachabilityStatus) -> Void
public typealias NetWorkServerStatusBlock = (_ result: ResponseModel) -> Void
public typealias UploadProgress = (_ progress: Progress) -> Void

public var PTBaseURLMode:NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.AppServiceIdentifier else { return .Distribution }
    if sliderValue == "1" {
        return .Distribution
    } else if sliderValue == "2" {
        return .Test
    } else if sliderValue == "3" {
        return .Development
    }
    return .Distribution
}

// MARK: - 网络运行状态监听
@objcMembers
public class XMNetWorkStatus {
    
    public static let shared = XMNetWorkStatus()
    /// 当前网络环境状态
    private var currentNetWorkStatus: NetWorkStatus = .wifi
    /// 当前运行环境状态
    private var currentEnvironment: NetWorkEnvironment = .Test
    
    private let monitor = NWPathMonitor()

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
            
            netWork(NetWorkStatus.valueName(type: weakSelf.currentNetWorkStatus), NetWorkEnvironment.valueName(type: weakSelf.currentEnvironment),status)
        })
    }
    
    ///监听网络运行状态
    public func obtainDataFromLocalWhenNetworkUnconnected(handle:((NetworkReachabilityManager.NetworkReachabilityStatus)->Void)?) {
        detectNetWork { (status, environment,statusType)  in   
                        
            PTNSLogConsole(String(format: "PT App current mode".localized(), status,environment))

            if handle != nil {
                handle!(statusType)
            }
        }
    }
    
    public func netWork(handle: @escaping (_ status:NetWorkStatus)->Void) {
        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                handle(.wifi)
            } else if path.usesInterfaceType(.cellular) {
                handle(.wwan)
            } else {
                handle(.notReachable)
            }
        }
        let queue = DispatchQueue(label: "Network")
        monitor.start(queue: queue)
    }
    
    public func checkNetworkStatusCancel() {
        monitor.cancel()
    }
    
    deinit {
        checkNetworkStatusCancel()
    }
}

@objcMembers
public class Network: NSObject {
    
    static public let share = Network()
            
    ///网络请求时间
    public var netRequsetTime:TimeInterval = 20
    public var serverAddress:String = ""
    public var serverAddress_dev:String = ""
    public var userToken:String = ""

    /// manager
    private static var manager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Network.share.netRequsetTime
        return Session(configuration: configuration)
    }()
    
    /// manager
    public static var hud: MBProgressHUD = {
        let hud = MBProgressHUD.init(view: AppWindows!)
        AppWindows!.addSubview(hud)
        hud.show(animated: true)
        return hud
    }()
    
    //MARK: 服务器URL
    public class func gobalUrl() -> String {
        if UIApplication.applicationEnvironment() != .appStore {
            PTNSLogConsole("PTBaseURLMode:\(PTBaseURLMode)")
            switch PTBaseURLMode {
            case .Development:
                let url_debug:String = PTCoreUserDefultsWrapper.AppRequestUrl
                if url_debug.isEmpty {
                    return Network.share.serverAddress_dev
                } else {
                    return url_debug
                }
            case .Test:
                return Network.share.serverAddress_dev
            case .Distribution:
                return Network.share.serverAddress
            }
        } else {
            return Network.share.serverAddress
        }
    }
    
    //JSONEncoding  JSON参数
    //URLEncoding    URL参数
    /// 项目总接口
    /// - Parameters:
    ///   - needGobal:
    ///   - urlStr: url地址
    ///   - method: 方法类型，默认post
    ///   - header:
    ///   - parameters: 请求参数，默认nil
    ///   - modelType: 是否需要传入接口的数据模型，默认nil
    ///   - encoder: 编码方式，默认url编码
    ///   - jsonRequest:
    ///  - Returns: ResponseModel
    class public func requestApi(needGobal:Bool? = true,
                                 urlStr:String,
                                 method: HTTPMethod = .post,
                                 header:HTTPHeaders? = nil,
                                 parameters: Parameters? = nil,
                                 modelType: Convertible.Type? = nil,
                                 encoder:ParameterEncoding = URLEncoding.default,
                                 jsonRequest:Bool? = false) async throws -> ResponseModel {
        
        let urlStr1 = (needGobal! ? Network.gobalUrl() : "") + urlStr
        if !urlStr1.isURL() {
            throw AFError.invalidURL(url: "https://www.qq.com")
        }
        
        // 判断网络是否可用
        if let reachabilityManager = XMNetWorkStatus.shared.reachabilityManager {
            if !reachabilityManager.isReachable {
                throw AFError.createURLRequestFailed(error: NetWorkNoError)
            }
        }
        
        var apiHeader = HTTPHeaders()
        let token = Network.share.userToken
        if !token.stringIsEmpty() && header == nil {
            apiHeader = HTTPHeaders.init(["token":token,"device":"iOS"])
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        } else if token.stringIsEmpty() && header != nil {
            apiHeader = header!
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        } else if !token.stringIsEmpty() && header != nil {
            apiHeader = header!
            apiHeader["token"] = token
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        }
        
        var postString = ""
        switch method {
        case .post:
            postString = "POST请求"
        case .get:
            postString = "GET请求"
        default:
            postString = "其他"
        }
        PTNSLogConsole("🌐❤️1.请求地址 = \(urlStr1)\n💛2.参数 = \(parameters?.jsonString() ?? "没有参数")\n💙3.请求头 = \(header?.dictionary.jsonString() ?? "没有请求头")\n🩷4.请求类型 = \(postString)🌐")
        
        return try await withCheckedThrowingContinuation { continuation in
            Network.manager.request(urlStr1, method: method, parameters: parameters, encoding: encoder, headers: apiHeader).responseData { data in
                switch data.result {
                case .success(_):
                    let json = JSON(data.value ?? "")
                    guard let jsonStr = json.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.prettyPrinted) else {
                        continuation.resume(throwing: AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: NetWorkJsonExplainError)))
                        return
                    }
                    
                    PTNSLogConsole("🌐接口请求成功回调🌐\n❤️1.请求地址 = \(urlStr1)\n💛2.result:\(jsonStr)🌐")
                    
                    guard let responseModel = jsonStr.kj.model(ResponseModel.self) else {
                        continuation.resume(throwing: AFError.requestAdaptationFailed(error: NetWorkModelExplainError))
                        return
                    }
                    responseModel.originalString = jsonStr
                                        
                    guard let modelType1 = modelType else { continuation.resume(returning: responseModel); return }
                    if responseModel.data is [String : Any] {
                        guard let reslut = responseModel.data as? [String : Any] else { continuation.resume(returning: responseModel); return }
                        responseModel.data = reslut.kj.model(type: modelType1)
                    } else if responseModel.data is Array<Any> {
                        responseModel.datas = (responseModel.data as! Array<Any>).kj.modelArray(type: modelType1)
                    } else {
                        responseModel.customerModel = responseModel.originalString.kj.model(type:modelType1)
                    }
                    continuation.resume(returning: responseModel)
                case .failure(let error):
                    PTNSLogConsole("❌接口:\(urlStr1)\n🎈----------------------出现错误----------------------🎈\(String(describing: error.errorDescription))❌",error: true)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
        
    /// 图片上传接口
    /// - Parameters:
    ///   - needGobal:是否使用全局URL
    ///   - images: 图片集合
    ///   - path:路徑
    ///   - fileKey:fileKey
    ///   - parmas:數據
    ///   - header:頭部
    ///   - modelType:Model
    ///   - jsonRequest:是否jsonRequest
    ///   - pngData:是否Png
    ///   - progressBlock: 进度回调
    /// - Returns:ResponseModel
    class public func imageUpload(needGobal:Bool? = true,
                                  images:[UIImage]?,
                                  path:String? = "/api/project/ossImg",
                                  method: HTTPMethod = .post,
                                  fileKey:[String]? = ["images"],
                                  parmas:[String:String]? = nil,
                                  header:HTTPHeaders? = nil,
                                  modelType: Convertible.Type? = nil,
                                  jsonRequest:Bool? = false,
                                  pngData:Bool? = true,
                                  progressBlock:UploadProgress? = nil) async throws -> ResponseModel {
        
        let pathUrl = (needGobal! ? Network.gobalUrl() : "") + path!
        if !pathUrl.isURL() {
            throw AFError.invalidURL(url: "https://www.qq.com")
        }

        // 判断网络是否可用
        if let reachabilityManager = XMNetWorkStatus.shared.reachabilityManager {
            if !reachabilityManager.isReachable {
                throw AFError.createURLRequestFailed(error: NetWorkNoError)
            }
        }
        
        var apiHeader = HTTPHeaders()
        let token = Network.share.userToken
        if !token.stringIsEmpty() && header == nil {
            apiHeader = HTTPHeaders.init(["token":token,"device":"iOS"])
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        } else if token.stringIsEmpty() && header != nil {
            apiHeader = header!
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        } else if !token.stringIsEmpty() && header != nil {
            apiHeader = header!
            apiHeader["token"] = token
            if jsonRequest! {
                apiHeader["Content-Type"] = "application/json;charset=UTF-8"
                apiHeader["Accept"] = "application/json"
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            Network.manager.upload(multipartFormData: { multipartFormData in
                images?.enumerated().forEach { index,image in
                    if pngData! {
                        if let imgData = image.pngData() {
                            multipartFormData.append(imgData, withName: fileKey![index],fileName: "image_\(index).png", mimeType: "image/png")
                        }
                    } else {
                        if let imgData = image.jpegData(compressionQuality: 0.2) {
                            multipartFormData.append(imgData, withName: fileKey![index],fileName: "image_\(index).png", mimeType: "image/png")
                        }
                    }
                }
                if parmas != nil {
                    parmas?.keys.enumerated().forEach({ index,value in
                        multipartFormData.append(Data(parmas![value]!.utf8), withName: value)
                    })
                }
            }, to: pathUrl,method: method,headers: apiHeader).uploadProgress(closure: { progress in
                PTGCDManager.gcdMain() {
                    if progressBlock != nil {
                        progressBlock!(progress)
                    }
                }
            }).response { response in
                switch response.result {
                case .success(_):
                    let json = JSON(response.value! ?? "")
                    guard let jsonStr = json.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.prettyPrinted) else {
                        continuation.resume(throwing: AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: NetWorkJsonExplainError)))
                        return
                    }
                    
                    guard let responseModel = jsonStr.kj.model(ResponseModel.self) else {
                        continuation.resume(throwing: AFError.requestAdaptationFailed(error: NetWorkModelExplainError))
                        return
                    }
                    
                    responseModel.originalString = jsonStr
                    PTNSLogConsole("🌐❤️1.请求地址 = \(pathUrl)\n💛2.result:\(String(describing: jsonStr))🌐")
                    guard let modelType1 = modelType else {
                        continuation.resume(returning: responseModel); return }
                    if responseModel.data is [String : Any] {
                        guard let reslut = responseModel.data as? [String : Any] else { continuation.resume(returning: responseModel); return }
                        responseModel.data = reslut.kj.model(type: modelType1)
                    } else if responseModel.data is Array<Any> {
                        responseModel.datas = (responseModel.data as! Array<Any>).kj.modelArray(type: modelType1)
                    } else {
                        responseModel.customerModel = responseModel.originalString.kj.model(type:modelType1)
                    }
                    
                    continuation.resume(returning: responseModel)
                case .failure(let error):
                    PTNSLogConsole("❌❤️1.请求地址 =\(pathUrl)\n💛2.error:\(error)❌",error: true)
                    continuation.resume(throwing:error)
                }
            }
        }
    }
}

@objcMembers
public class PTFileDownloadApi: NSObject {
    
    public typealias FileDownloadProgress = (_ bytesRead:Int64,_ totalBytesRead:Int64,_ progress:Double)->()
    public typealias FileDownloadSuccess = (_ reponse:Any)->()
    public typealias FileDownloadFail = (_ error:Error?)->()
    
    public var fileUrl:String = ""
    public var saveFilePath:String = "" // 文件下载保存的路径
    public var cancelledData : Data?//用于停止下载时,保存已下载的部分
    public var downloadRequest:DownloadRequest? //下载请求对象
    public var destination:DownloadRequest.Destination!//下载文件的保存路径
    
    public var progress:FileDownloadProgress?
    public var success:FileDownloadSuccess?
    public var fail:FileDownloadFail?
    
    private var queue:DispatchQueue = DispatchQueue.main
  
    // 默认主线程
    public convenience init(fileUrl:String,saveFilePath:String,queue:DispatchQueue? = DispatchQueue.main,progress:FileDownloadProgress?,success:FileDownloadSuccess?, fail:FileDownloadFail?) {
        
        self.init()
        self.fileUrl = fileUrl
        self.saveFilePath = saveFilePath
        self.success = success
        self.progress = progress
        self.fail = fail
        
        if queue != nil {
            self.queue = queue!
        }
        
        // 配置下载存储路径
        destination = {_,response in
            let saveUrl = URL(fileURLWithPath: saveFilePath)
            return (saveUrl,[.removePreviousFile, .createIntermediateDirectories] )
        }
        // 这里直接就开始下载了
        startDownloadFile()
    }
    
    // 暂停下载
    public func suspendDownload() {
        downloadRequest?.task?.suspend()
    }
    // 取消下载
    public func cancelDownload() {
        downloadRequest?.cancel()
        downloadRequest = nil;
        progress = nil
    }
    
    // 开始下载
    public func startDownloadFile() {
        if cancelledData != nil {
            downloadRequest = AF.download(resumingWith: cancelledData!, to: destination)
            downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                PTGCDManager.gcdMain {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
            
        } else if downloadRequest != nil {
            downloadRequest?.task?.resume()
        } else {
            downloadRequest = AF.download(fileUrl, to: destination)
            downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                PTGCDManager.gcdMain {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            
            downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
        }
    }
    
    //根据下载状态处理
    private func downloadResponse(response:AFDownloadResponse<Data>) {
        switch response.result {
        case .success:
            if let data = response.value, data.count > 1000 {
                if success != nil{
                    PTGCDManager.gcdMain {
                        self.success?(response)
                    }
                }
            } else {
                PTGCDManager.gcdMain {
                    self.fail?(NetWorkDownloadError as Error)
                }
            }
        case .failure:
            cancelledData = response.resumeData//意外停止的话,把已下载的数据存储起来
            PTGCDManager.gcdMain {
                self.fail?(response.error)
            }
        }
    }
}
