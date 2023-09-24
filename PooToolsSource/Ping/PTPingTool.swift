//
//  PTPingTool.swift
//  ZolaFly
//
//  Created by 邓杰豪 on 21/9/23.
//  Copyright © 2023 LYH. All rights reserved.
//

import Foundation
import UIKit

public enum PTPingTimeInterval {
    case second(_ interval: TimeInterval)       //秒
    case millisecond(_ interval: TimeInterval)  //毫秒
    case microsecond(_ interval: TimeInterval)  //微秒

    public var second: TimeInterval {
        switch self {
            case .second(let interval):
                return interval
            case .millisecond(let interval):
                return interval / 1000.0
            case .microsecond(let interval):
                return interval / 1000000.0
        }
    }
}

public struct PTPingResponse {
    public var pingAddressIP = ""
    public var responseTime: PTPingTimeInterval = .second(0)
    public var responseBytes: Int = 0
}

public typealias PingComplete = ((_ response: PTPingResponse?, _ error: Error?) -> Void)

public enum NetworkActivityIndicatorStatus {
    case auto       //自动显示
    case always     //一直显示
    case none       //不显示
}

public enum PTPingError: Error, Equatable {
    case requestError   //发起失败
    case receiveError   //响应失败
    case timeout        //超时
}

struct PTPingItem {
    var sendTime = Date()
    var sequence: UInt16 = 0
}

open class PTPingTool: NSObject {
    public var timeout: PTPingTimeInterval = .millisecond(1000)  //自定义超时时间，默认1000毫秒，设置为0则一直等待
    public var debugLog = true                                  //是否开启日志输出
    public var stopWhenError = false                            //遇到错误停止ping
    public private(set) var isPing = false
    public var isRunning: Bool = false
    public var showNetworkActivityIndicator: NetworkActivityIndicatorStatus = .none              //是否在状态栏显示
    
    public var hostName: String? {
        get {
            return self.pinger.hostName
        }
        set {
            let oldPinger = self.pinger
            var host = newValue ?? "www.apple.com"
            if host.isEmpty {
                host = "www.apple.com"
            }
            self.pinger = SimplePing(hostName: host)
            self.pinger.delegate = self
            if self.isPing {
                self.start(pingType: oldPinger.addressStyle, interval: self.pingInterval, complete: self.complete)
            }
        }
    }

    private var pinger: SimplePing
    private var pingInterval: PTPingTimeInterval = .second(0)
    private var complete: PingComplete?
    private var lastSendItem: PTPingItem?
    private var lastReciveItem: PTPingItem?
    private var sendTimer: Timer?
    private var checkTimer: Timer?
    private var pingAddressIP = ""

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public init(hostName: String? = nil) {
        var host = hostName ?? "www.apple.com"
        if host.isEmpty {
            host = "www.apple.com"
        }
        self.pinger = SimplePing(hostName: host)
        super.init()
        self.pinger.delegate = self
    }

    public convenience init(url: URL?) {
        self.init(hostName: url?.host)
    }

    /// 开始ping请求
    /// - Parameters:
    ///   - pingType: ping的类型
    ///   - interval: 是否重复定时ping
    ///   - complete: 请求的回调
    public func start(pingType: AddressStyle = .any, interval: PTPingTimeInterval = .second(0), complete: PingComplete? = nil) {
        //移除消息订阅
        NotificationCenter.default.removeObserver(self)
        //切到后台
        NotificationCenter.default.addObserver(self, selector: #selector(_didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        //切到前台
        NotificationCenter.default.addObserver(self, selector: #selector(_didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        //开始请求
        self.pingStart(pingType: pingType, interval: interval, complete: complete)
    }

    //结束ping
    public func stop() {
        //移除消息订阅
        NotificationCenter.default.removeObserver(self)
        //移除顶部状态栏显示
        if self.showNetworkActivityIndicator == .auto || self.showNetworkActivityIndicator == .none {
            PTPingActivityIndicator.shared.isHidden = true
        } else {
            PTPingActivityIndicator.shared.isHidden = false
        }
        //结束状态
        self.pingStop()
    }
}

private extension PTPingTool {
    /// 开始ping请求
    func pingStart(pingType: AddressStyle = .any, interval: PTPingTimeInterval = .second(0), complete: PingComplete? = nil) {
        self.pingStop()
        if self.showNetworkActivityIndicator == .auto || self.showNetworkActivityIndicator == .always {
            PTPingActivityIndicator.shared.isHidden = false
        } else {
            PTPingActivityIndicator.shared.isHidden = true
        }

        self.pingInterval = interval
        self.complete = complete
        self.pinger.addressStyle = pingType
        self.pinger.start()
        self.isRunning = true

        if interval.second > 0 {
            self.sendTimer = Timer(timeInterval: interval.second, repeats: true, block: { [weak self] (_) in
                guard let self = self else { return }
                self.pingStart(pingType: pingType, interval: interval, complete: complete)
            })
            //循环发送
            RunLoop.main.add(self.sendTimer!, forMode: .common)
        }
    }

    func pingStop() {
        self.pingComplete()
        //停止发送ping
        self.sendTimer?.invalidate()
        self.sendTimer = nil
        self.isRunning = false
    }

    //ping完成一次之后的清理，ping成功或失败均会调用
    func pingComplete() {
        self.pinger.stop()
        self.isPing = false
        self.lastSendItem = nil
        self.lastReciveItem = nil
        self.pingAddressIP = ""
        //检测超时的timer停止
        self.checkTimer?.invalidate()
        self.checkTimer = nil
    }

    @objc func _didEnterBackground() {
        if self.debugLog {
            PTNSLogConsole("didEnterBackground: stop ping")
        }
        self.pingStop()
    }

    @objc func _didBecomeActive() {
        if self.debugLog {
            PTNSLogConsole("didBecomeActive: ping resume")
        }
        self.start(pingType: self.pinger.addressStyle, interval: self.pingInterval, complete: self.complete)
    }

    func sendPingData() {
        guard !self.isPing else { return }
        self.pinger.sendPing(data: nil)
    }

    func displayAddressForAddress(address: NSData) -> String {
        var hostStr = [Int8](repeating: 0, count: Int(NI_MAXHOST))

        let success = getnameinfo(
            address.bytes.assumingMemoryBound(to: sockaddr.self),
            socklen_t(address.length),
            &hostStr,
            socklen_t(hostStr.count),
            nil,
            0,
            NI_NUMERICHOST
        ) == 0
        let result: String
        if success {
            result = String(cString: hostStr)
        } else {
            result = "?"
        }
        return result
    }

    func shortErrorFromError(error: NSError) -> String {
        if error.domain == kCFErrorDomainCFNetwork as String && error.code == Int(CFNetworkErrors.cfHostErrorUnknown.rawValue) {
            if let failureObj = error.userInfo[kCFGetAddrInfoFailureKey as String] {
                if let failureNum = failureObj as? NSNumber {
                    if failureNum.intValue != 0 {
                        let f = gai_strerror(Int32(failureNum.intValue))
                        if f != nil {
                            return String(cString: f!)
                        }
                    }
                }
            }
        }
        if let result = error.localizedFailureReason {
            return result
        }
        return error.localizedDescription
    }
}

extension PTPingTool: SimplePingDelegate {
    
    public func simplePing(_ pinger: SimplePing, didStart address: Data) {
        self.pingAddressIP = self.displayAddressForAddress(address: NSData(data: address))
        if self.debugLog {
            PTNSLogConsole("ping: ", self.pingAddressIP)
        }
        //发送一次ping
        self.sendPingData()
    }

    public func simplePing(_ pinger: SimplePing, didFail error: Error) {
        if self.debugLog {
            PTNSLogConsole("ping failed: ", self.shortErrorFromError(error: error as NSError))
        }
        PTPingActivityIndicator.shared.update(time: 460)
        if let complete = self.complete {
            complete(nil, PTPingError.requestError)
        }
        //标记完成
        self.pingComplete()
        //停止ping
        if self.stopWhenError {
            self.pingStop()
        }
    }

    public func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        if self.debugLog {
            PTNSLogConsole("ping sent \(packet.count) data bytes, icmp_seq=\(sequenceNumber)")
        }
        self.isPing = true
        self.lastSendItem = PTPingItem(sendTime: Date(), sequence: sequenceNumber)
        //发送数据之后监测是否超时
        if self.timeout.second > 0 {
            self.checkTimer?.invalidate()
            self.checkTimer = nil
            self.checkTimer = Timer(timeInterval: self.timeout.second, repeats: false, block: { [weak self] (_) in
                guard let self = self else { return }
                if self.lastSendItem?.sequence != self.lastReciveItem?.sequence {
                    PTPingActivityIndicator.shared.update(time: 460)
                    //超时
                    if let complete = self.complete {
                        complete(nil, PTPingError.timeout)
                    }
                    //标记完成
                    self.pingComplete()
                    //停止ping
                    if self.stopWhenError {
                        self.pingStop()
                    }
                }
            })
            RunLoop.main.add(self.checkTimer!, forMode: .common)
        }
    }

    public func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        if self.debugLog {
            PTNSLogConsole("ping send error: ", sequenceNumber, self.shortErrorFromError(error: error as NSError))
        }
        PTPingActivityIndicator.shared.update(time: 460)
        if let complete = self.complete {
            complete(nil, PTPingError.receiveError)
        }
        //标记完成
        self.pingComplete()
        //停止ping
        if self.stopWhenError {
            self.pingStop()
        }
    }

    public func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        if let sendPingItem = lastSendItem {
            let time = Date().timeIntervalSince(sendPingItem.sendTime).truncatingRemainder(dividingBy: 1) * 1000
            if self.debugLog {
                PTNSLogConsole("\(packet.count) bytes from \(pingAddressIP): icmp_seq=\(sequenceNumber) time=\(time)ms")
            }
            PTPingActivityIndicator.shared.update(time: Int(time))
            if let complete = self.complete {
                let response = PTPingResponse(pingAddressIP: self.pingAddressIP, responseTime: .millisecond(time), responseBytes: packet.count)
                complete(response, nil)
            }
            self.lastReciveItem = PTPingItem(sendTime: Date(), sequence: sequenceNumber)
            //标记完成
            self.pingComplete()
        }
    }

    public func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        if self.debugLog {
            PTNSLogConsole("unexpected receive packet, size=\(packet.count)")
        }
        //标记完成
        self.pingComplete()
        //停止ping
        if self.stopWhenError {
            self.pingStop()
        }
    }
}