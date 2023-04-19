//
//  PTFunctionCellModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public enum PTFusionShowAccessoryType:Int {
    case Switch
    case DisclosureIndicator
    case NoneAccessoryView
}

open class PTFusionCellModel: NSObject {
    ///图片名
    open var leftImage:Any?
    ///图片上下间隔默认CGFloat.ScaleW(w: 5)
    open var imageTopOffset:CGFloat = CGFloat.ScaleW(w: 5)
    open var imageBottomOffset:CGFloat = CGFloat.ScaleW(w: 5)
    ///名
    open var name:String = ""
    ///名字颜色
    open var nameColor:UIColor = UIColor.black
    ///主标题下的描述
    open var desc:String = ""
    ///主标题下文字颜色
    open var descColor:UIColor = UIColor.lightGray
    ///主标题的富文本
    open var nameAttr:NSAttributedString?
    ///描述
    open var content:String = ""
    ///描述文字颜色
    open var contentTextColor:UIColor = UIColor.black
    ///Content的富文本
    open var contentAttr:NSAttributedString?
    ///content字体
    open var contentFont:UIFont = .appfont(size: 16)
    ///AccessoryView类型
    open var accessoryType:PTFusionShowAccessoryType = .NoneAccessoryView
    ///是否有线
    open var haveLine:Bool = false
    ///字体
    open var cellFont:UIFont = .appfont(size: 16)
    ///Desc字体
    open var cellDescFont:UIFont = .appfont(size: 14)
    ///ID
    open var cellID:String? = ""
    ///是否已经选择了
    open var cellSelect:Bool? = false
    ///当前选择的Indexpath
    open var cellIndexPath:IndexPath?
    ///Cell的AccessViewImage
    open var disclosureIndicatorImage :Any?
    ///Cell的圓角處理
    open var conrner:UIRectCorner = []
    ///Cell的是否顯示Icon
    open var contentIcon:Any?
    ///Cell的右間隔
    open var rightSpace:CGFloat = 10
    ///Cell的左間隔
    open var leftSpace:CGFloat = 10
    ///Cell的圓角度數
    open var cellCorner:CGFloat = 10
    ///Cell的Switch的顏色
    open var switchTinColor:UIColor = .systemGreen
}
