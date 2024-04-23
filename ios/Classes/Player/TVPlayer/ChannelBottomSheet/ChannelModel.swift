//
//  ChannelModel.swift
//  Runner
//
//  Created by Sunnatillo Shavkatov on 21/04/22.
//
import UIKit

struct Channels{
    
    var title, subtitle, imageUrl,timeLbl,placeholderImage,logoImage,id,url : String
    var passedPercentage: String
    var remindedTime: String
    
    init(title : String, subtitle :String, imageUrl :String,timeLbl: String,placeholderImage: String,logoImage:String,id:String,url:String,passedPercentage: String,remindedTime:String){
        self.title = title
        self.subtitle = subtitle
        self.imageUrl = imageUrl
        self.timeLbl = timeLbl
        self.logoImage = logoImage
        self.placeholderImage = placeholderImage
        self.id = id
        self.url = url
        self.passedPercentage = passedPercentage
        self.remindedTime = remindedTime
    }
    
    static  func fromDictinaryChannel(map: [Dictionary<String, Any>])-> [Channels] {
        var channels : [Channels] = []
        map.forEach({ elements in
            channels.append(Channels(title: elements["title_ru"] as? String ?? "", subtitle: elements["description_ru"] as? String ?? "", imageUrl: elements["image_url"] as? String ?? "", timeLbl: "12:00", placeholderImage: elements["place_holder"] as? String ?? "", logoImage: elements["image"] as? String ?? "",id: elements["id"] as? String ?? "", url: elements["url"] as? String ?? "",passedPercentage: elements["passed_percentage"] as? String ?? "", remindedTime: elements["reminded_time"] as? String ?? ""))
            print("PassedPercentage -> \(elements["passed_percentage"] as? String ?? "")")
        })
        return channels
    }
}
