//
//  MeasureData.swift
//  WebRTC-Demo
//
//  Created by 文涛 on 2020/11/19.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import HandyJSON

struct MeasureData: HandyJSON {
    
    var type = DataType.req
    var action = "test"
    var num = 0
    var time = Int(NSDate().timeIntervalSince1970*1000)
    var randomStr = "说的就是的看时导航栏就粮食店街灵飞经拉的屎家乐鸡粉达拉斯家乐福简单来说记录集发来的圣诞节浪费捡垃圾砥砺奋进垃圾砥砺奋进按逻辑砥砺奋进阿来得及是否连接大两岁距离放假ADSL数据分类甲氨蝶呤十几分连接的哈啥的时间里的骄傲的房间里阿三打两建了圣诞节浪费记录集"
    
    
    enum DataType: String, HandyJSONEnum {
        case req
        case resp
    }
}
