//
//  PTChatListModel.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit

public enum PTChatMessageType:Int,CaseIterable {
    case Text
    case Map
    case Media
    case Voice
    case File
    case SystemMessage
    case CustomerMessage
    case Typing
}

public enum PTChatMessageStatus:Int,CaseIterable {
    case Sending
    case Arrived
    case Error
}

@objcMembers
open class PTChatListModel: PTBaseModel {
    ///消息时间戳
    open var messageTimeStamp:TimeInterval = 0
    ///消息ID
    open var msgId:String = ""
    open  var messageType:PTChatMessageType = .Text
    ///创建者ID
    open var creatorId:String = "" {
        didSet {
            belongToMe = (creatorId == PTChatConfig.share.imOwnerId)
        }
    }
    ///内容
    open var msgContent:Any?
    ///消息人头像
    open var senderCover:String = ""
    ///消息状态
    open var messageStatus:PTChatMessageStatus = .Arrived
    ///发送者名字
    open var senderName:String = ""
    ///是否属于我
    open var belongToMe:Bool = false
    
    //MARK: 这个是需要自定义cell时用
    ///自定义CELL的ID
    open var customerCellId:String = ""
    ///是否已讀
    open var isRead:Bool = false
}
