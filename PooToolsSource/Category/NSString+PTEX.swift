//
//  NSString+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/11/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

public extension NSString
{
    /*  银行卡号有效性问题Luhn算法
     *  现行 16 位银联卡现行卡号开头 6 位是 622126～622925 之间的，7 到 15 位是银行自定义的，
     *  可能是发卡分行，发卡网点，发卡序号，第 16 位是校验码。
     *  16 位卡号校验位采用 Luhm 校验方法计算：
     *  1，将未带校验位的 15 位卡号从右依次编号 1 到 15，位于奇数位号上的数字乘以 2
     *  2，将奇位乘积的个十位全部相加，再加上所有偶数位上的数字
     *  3，将加法和加上校验位能被 10 整除。
     */
    func bankCardLuhmCheck()->Bool
    {
        if String(format: "%@", self).stringIsEmpty()
        {
            return false
        }
        
        if self.length < 3
        {
            return false
        }
        
        let lastNum:NSString = self.substring(from: (self.length - 1)) as NSString
        let forwardNum:NSString = self.substring(to: (self.length - 1)) as NSString
        
        let forwardArr = NSMutableArray(capacity: 0)
        for i in 0..<forwardNum.length
        {
            let subStr:NSString = forwardNum.substring(with: NSMakeRange(i, 1)) as NSString
            forwardArr.add(subStr)
        }
        
        let forwardDescArr = NSMutableArray(capacity: 0)
        var i = Int(forwardArr.count - 1)
        while i > -1 {
            //前15位或者前18位倒序存进数组
            forwardDescArr.append(forwardArr[i])
            i -= 1
        }
        
        let arrOddNum = NSMutableArray(capacity: 0)
        let arrOddNum2 = NSMutableArray(capacity: 0)
        let arrEvenNum = NSMutableArray(capacity: 0)
        
        for i in 0..<forwardDescArr.count {
            let num = (forwardDescArr[i] as! NSString).intValue
            if i % 2 != 0 {
                //偶数位
                arrEvenNum.append(NSNumber(value: num))
            } else {
                //奇数位
                if num * 2 < 9 {
                    arrOddNum.append(NSNumber(value: num * 2))
                } else {
                    let decadeNum = (num * 2) / 10
                    let unitNum = (num * 2) % 10
                    arrOddNum2.append(NSNumber(value: unitNum))
                    arrOddNum2.append(NSNumber(value: decadeNum))
                }
            }
        }

        var sumOddNumTotal = 0
        for (_, obj) in arrOddNum.enumerated() {
            sumOddNumTotal += (obj as AnyObject).intValue
        }

        var sumOddNum2Total = 0
        for (_, obj) in arrOddNum2.enumerated() {
            sumOddNum2Total += (obj as AnyObject).intValue
        }

        var sumEvenNumTotal = 0
        for (_, obj) in arrEvenNum.enumerated() {
            sumEvenNumTotal += (obj as AnyObject).intValue
        }

        let lastNumber = lastNum.intValue

        let luhmTotal = Int(lastNumber) + sumEvenNumTotal + sumOddNum2Total + sumOddNumTotal
        return (luhmTotal % 10 == 0) ? true : false
    }
        
    func getBankName()->NSString{
        if self.bankCardLuhmCheck()
        {
            return NSString(format: "https://ccdcapi.alipay.com/validateAndCacheCardInfo.json?_input_charset=utf-8&cardNo=%@&cardBinCheck=true", self)
        }
        else
        {
            return self
        }
    }
    
    /*
     身份证号:加权因子
     中国大陆个人身份证号验证 Chinese Mainland Personal ID Card Validation
     */
    func isValidateIdentity()->Bool
    {
        if self.length != 18
        {
            return false
        }
        
        let regex2 = "^(^[1-9]\\d{7}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}$)|(^[1-9]\\d{5}[1-9]\\d{3}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])((\\d{4})|\\d{3}[Xx])$)$"
        let identityStringPredicate = NSPredicate(format: "SELF MATCHES %@", regex2)
        if !identityStringPredicate.evaluate(with: self)
        {
            return false
        }
        
        let idCardWi = [ "7", "9", "10", "5", "8", "4", "2", "1", "6", "3", "7", "9", "10", "5", "8", "4", "2" ] //将前17位加权因子保存在数组里
        let idCardY = [ "1", "0", "10", "9", "8", "7", "6", "5", "4", "3", "2" ] //这是除以11后，可能产生的11位余数、验证码，也保存成数组
        var idCardWiSum = 0
        for i in 0..<17
        {
            let subStringIndex = self.substring(with: NSMakeRange(i, 1)).int!
            let idCardWithIndex = idCardWi[i].int!
            idCardWiSum += (subStringIndex * idCardWithIndex)
        }
        
        let idCardMod = idCardWiSum % 11
        let idCardLast:NSString = self.substring(with: NSMakeRange(17, 1)) as NSString
        if idCardMod == 2
        {
            if !idCardLast.isEqual(to: "X") || idCardLast.isEqual(to: "x")
            {
                return false
            }
        }
        else
        {
            if !idCardLast.isEqual(to: idCardY[idCardMod])
            {
                return false
            }
        }
        return true
    }
    
    /*
        从身份证上获取生日
     */
    func birthdayFromIdentityCard()->NSString
    {
        let result = NSMutableString(capacity: 0)
        var year:NSString = ""
        var month:NSString = ""
        var day:NSString = ""
        if self.isValidateIdentity()
        {
            year = self.substring(with: NSMakeRange(6, 4)) as NSString
            month = self.substring(with: NSMakeRange(10, 2)) as NSString
            day = self.substring(with: NSMakeRange(12, 2)) as NSString
            
            result.append(year as String)
            result.append("-")
            result.append(month as String)
            result.append("-")
            result.append(day as String)
            return result
        }
        else
        {
            return "1970-01-01"
        }
    }
    
    /*
        从身份证上获取年龄
     */
    func getIdentityCardAge()->NSString
    {
        if self.isValidateIdentity()
        {
            let formatterTow = DateFormatter()
            formatterTow.dateFormat = "yyyy-MM-dd"
            let birthday = self.birthdayFromIdentityCard()
            let bsyDate = formatterTow.date(from: birthday as String)
            let dateDiff = bsyDate!.timeIntervalSinceNow
            let age = trunc(dateDiff / (60 * 60 * 24)) / 365
            return "\(-age)" as NSString
        }
        else
        {
            return "99999"
        }
    }
    
    func getuperDigit()->NSString
    {
        let range:NSRange = self.range(of: ".")
        if range.length != 0
        {
            let tmpArray:[String] = self.components(separatedBy: ".")
            let integerNumber = (tmpArray[0] as NSString).integerValue
            let dotNumber = tmpArray.last
            let integerNumberStr = PTUtils.getIntPartUper(digit: integerNumber)
            if integerNumberStr.isEqual(to: "元")
            {
                return NSString(format: "%@", PTUtils.getPartAfterDot(digitStr: dotNumber! as NSString))
            }
            return NSString(format: "%@%@", PTUtils.getIntPartUper(digit: integerNumber),PTUtils.getPartAfterDot(digitStr: dotNumber! as NSString))
        }
        else
        {
            let integerNumber = self.integerValue
            let tmpStr = PTUtils.getIntPartUper(digit: integerNumber)
            if tmpStr.isEqual(to: "元")
            {
                return "零元整"
            }
            else
            {
                return NSString(format: "%@整", PTUtils.getIntPartUper(digit: integerNumber))
            }
        }
    }
    
    @objc func contentTypeForUrl()->PTUrlStringVideoType
    {
        let pathEX = self.pathExtension.lowercased()
        
        if pathEX.contains("mp4")
        {
            return .MP4
        }
        else if pathEX.contains("mov")
        {
            return .MOV
        }
        else if pathEX.contains("3gp")
        {
            return .ThreeGP
        }
        return .UNKNOW
    }
}
