//
//  ViewController.swift
//  Swift Weather
//
//  Created by duan jian on 15/3/14.
//  Copyright (c) 2015年 duan jian. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController,CLLocationManagerDelegate {

    let locationManager:CLLocationManager = CLLocationManager()
    
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loading: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //将位置管理对象的托管交给当前Controller
        locationManager.delegate = self
        //设置位置管理对象采用最优定位
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        self.loadingIndicator.startAnimating()
        
        let background = UIImage(named: "background.png")
        self.view.backgroundColor = UIColor(patternImage: background!)
        
        //判断是否为iOS8平台，是则使用请求授权
        if isiOS8() {
            locationManager.requestAlwaysAuthorization()
        }
        //开始更新位置信息
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //判断是否是iOS8平台，截取系统版本号的第一位进行判断
    func isiOS8 () -> Bool{
        let sysVersion = UIDevice.currentDevice().systemVersion
        let index = advance(sysVersion.startIndex, 1)
        return sysVersion.substringToIndex(index) == "8"
    }
    
    //委托：更新位置信息后执行的方法
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var location:CLLocation = locations[locations.count - 1] as CLLocation
        if location.horizontalAccuracy > 0 {
            println(location.coordinate.latitude)
            println(location.coordinate.longitude)
            
            //根据经纬度坐标获取天气信息
            self.updateWeatherInfo(location.coordinate.latitude,
                longitude: location.coordinate.longitude)
            
            //获取完信息后停止更新
            locationManager.stopUpdatingLocation()
        }
    }
    
    //更新天气信息
    func updateWeatherInfo(latitude:CLLocationDegrees,longitude:CLLocationDegrees){
        //请求操作对象
        let manager = AFHTTPRequestOperationManager()
        //请求URL
        let url = "http://api.openweathermap.org/data/2.5/weather"
        //请求参数
        let params = ["lat":latitude,"lon":longitude,"cnt":0]
        //发出get请求
        manager.GET(url,
            parameters: params,
            //成功回调
            success: { (operation: AFHTTPRequestOperation!,
                responseObject: AnyObject!) in
                println("JSON: " + responseObject.description!)
                //成功后执行函数
                self.updateUISuccess(responseObject as NSDictionary!)
                
            },
            //失败回调
            failure: { (operation: AFHTTPRequestOperation!,
                error: NSError!) in
                println("Error: " + error.localizedDescription)
                
                
        })
    }
    
    //成功更新UI函数
    func updateUISuccess(jsonResult: NSDictionary!){
        
        //成功后取消加载图标和label
        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.hidden = true
        self.loading.text = nil
        
        //取出响应json中得数据
        if let tmpResult = jsonResult["main"]?["temp"]? as? Double {
            var temperature: Double
            if jsonResult["sys"]?["country"]? as String == "US" {
                temperature = round(((tmpResult - 273.15) * 1.8) + 32)
            }else{
                temperature = round(tmpResult - 273.15)
            }
            
            self.temperature.text = "\(temperature)°"
            self.temperature.font = UIFont.boldSystemFontOfSize(65)
            
            var name = jsonResult["name"]? as String
            self.location.font = UIFont.boldSystemFontOfSize(25)
            self.location.text = "\(name)"
            
            var condition = (jsonResult["weather"]? as NSArray)[0]["id"]? as Int
            var sunrise = jsonResult["sys"]?["sunrise"]? as Double
            var sunset = jsonResult["sys"]?["sunset"]? as Double
            
            var nightTime = false
            var now = NSDate().timeIntervalSince1970
            
            if now < sunrise || now > sunset {
                nightTime = true
            }
            
            //更新图标
            self.updateWeatherIcon(condition, nightTime:nightTime)
        }else{
            self.loading.text = "Error: Data Not Found"
        }
    }
    
    //更新天气图标
    func updateWeatherIcon(condition:Int, nightTime:Bool){
        if condition < 300 {
            if nightTime {
                self.icon.image = UIImage(named: "tstorm1_night")
            }else{
                self.icon.image = UIImage(named: "tstorm1")
            }
        }
            // Drizzle
        else if (condition < 500) {
            self.icon.image = UIImage(named: "light_rain")
            
        }
            // Rain / Freezing rain / Shower rain
        else if (condition < 600) {
            self.icon.image = UIImage(named: "shower3")
        }
            // Snow
        else if (condition < 700) {
            self.icon.image = UIImage(named: "snow4")
        }
            // Fog / Mist / Haze / etc.
        else if (condition < 771) {
            if nightTime {
                self.icon.image = UIImage(named: "fog_night")
            } else {
                self.icon.image = UIImage(named: "fog")
            }
        }
            // Tornado / Squalls
        else if (condition < 800) {
            self.icon.image = UIImage(named: "tstorm3")
        }
            // Sky is clear
        else if (condition == 800) {
            if (nightTime){
                self.icon.image = UIImage(named: "sunny_night")
            }
            else {
                self.icon.image = UIImage(named: "sunny")
            }
        }
            // few / scattered / broken clouds
        else if (condition < 804) {
            if (nightTime){
                self.icon.image = UIImage(named: "cloudy2_night")
            }
            else{
                self.icon.image = UIImage(named: "cloudy2")
            }
        }
            // overcast clouds
        else if (condition == 804) {
            self.icon.image = UIImage(named: "overcast")
        }
            // Extreme
        else if ((condition >= 900 && condition < 903) || (condition > 904 && condition < 1000)) {
            self.icon.image = UIImage(named: "tstorm3")
        }
            // Cold
        else if (condition == 903) {
            self.icon.image = UIImage(named: "snow5")
        }
            // Hot
        else if (condition == 904) {
            self.icon.image = UIImage(named: "sunny")
        }
            // Weather condition is not available
        else {
            self.icon.image = UIImage(named: "dunno")
        }

    }
    
    //委托：获取位置信息出错时
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
        self.loading.text = "Error: \(error)"
    }
    
    
    
    
    
    
    


}

