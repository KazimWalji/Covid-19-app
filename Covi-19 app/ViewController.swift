//
//  ViewController.swift
//  Covid-19 SeoulHacks2020
//
//  Created by Kazim Walji on 10/30/20.
//

import UIKit
import AVFoundation
import UserNotifications
import Charts

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource  {
    
    struct Dict: Codable {
        let date: Int
        let positiveIncrease : Int
        let deathIncrease : Int
        let positive : Int
        let death : Int
    }
    struct Dit: Codable {
        let positiveIncrease:Int
        let date: Int
    }
    @IBOutlet weak var dailyCasesLabel: UITextField!
    @IBOutlet weak var dateLabel: UITextField!
    @IBOutlet weak var deathLabel: UITextField!
    @IBOutlet weak var totalDeaths: UITextField!
    @IBOutlet weak var totalPositive: UITextField!
    @IBOutlet weak var handsButton: UIButton!
    @IBOutlet weak var StatePicker: UIPickerView!
    @IBOutlet weak var chart: LineChartView!
    
     let states = [ "USA", "AK",
                                "AL",
                                "AR",
                                "AS",
                                "AZ",
                                "CA",
                                "CO",
                                "CT",
                                "DC",
                                "DE",
                                "FL",
                                "GA",
                                "GU",
                                "HI",
                                "IA",
                                "ID",
                                "IL",
                                "IN",
                                "KS",
                                "KY",
                                "LA",
                                "MA",
                                "MD",
                                "ME",
                                "MI",
                                "MN",
                                "MO",
                                "MS",
                                "MT",
                                "NC",
                                "ND",
                                "NE",
                                "NH",
                                "NJ",
                                "NM",
                                "NV",
                                "NY",
                                "OH",
                                "OK",
                                "OR",
                                "PA",
                                "PR",
                                "RI",
                                "SC",
                                "SD",
                                "TN",
                                "TX",
                                "UT",
                                "VA",
                                "VI",
                                "VT",
                                "WA",
                                "WI",
                                "WV",
                                "WY"]
    
    
    
    var dailyCases = ""
    
    var bellSound: AVAudioPlayer?
    
    let timeShape = CAShapeLayer()
    let shape = CAShapeLayer()
    var remainingTime: TimeInterval = 20
    var endTime: Date?
    var stopwatch =  UILabel()
    var clock = Timer()
    let redCircle = CABasicAnimation(keyPath: "strokeEnd")
    
    var dataEntries: [ChartDataEntry] = []
    
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.StatePicker.delegate = self
        self.StatePicker.dataSource = self
        getPermission()
        handsReminder()
        var api = URL(string: "https://api.covidtracking.com/v1/us/current.json")
        URLSession.shared.dataTask(with: api!) { [self] data, response, error in
                let data = data
            parse(data: data!)
            setUpLabels()
            setClock()
            handsButton.alpha = 1
              }.resume()
         api = URL(string: "https://api.covidtracking.com/v1/us/daily.json")
        URLSession.shared.dataTask(with: api!) { [self] data, response, error in
                let data = data
            parseHistory(data: data!)
              }.resume()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return states.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        states[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(row != 0)
        {
            var api = URL(string: "https://api.covidtracking.com/v1/states/" + states[row].lowercased() + "/current.json")
            URLSession.shared.dataTask(with: api!) { [self] data, response, error in
                    let data = data
                parseState(data: data!)
            }.resume()
            api = URL(string: "https://api.covidtracking.com/v1/states/" + states[row].lowercased() + "/daily.json")
            URLSession.shared.dataTask(with: api!) { [self] data, response, error in
                    let data = data
                parseHistory(data: data!)
                setUpLabels()
                  }.resume()
        }
        else
        {
            var api = URL(string: "https://api.covidtracking.com/v1/us/current.json")
            URLSession.shared.dataTask(with: api!) { [self] data, response, error in
                    let data = data
                parse(data: data!)
                setUpLabels()
                  }.resume()
      }
    }
    
    func getPermission() {
        let abilities = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        self.userNotificationCenter.requestAuthorization(options: abilities) { (success, error) in
            if let error = error {
                print(error)
            }
        }
    }

    func handsReminder() {
        let reminder = UNMutableNotificationContent()
           reminder.title = "Don't forget to wash Your Hands"
           reminder.badge = NSNumber(value: 3)
           let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60,
                                                           repeats: true)
           let request = UNNotificationRequest(identifier: "testNotification",
                                               content: reminder,
                                               trigger: trigger)
           
           userNotificationCenter.add(request) { (error) in
               if let error = error {
                   print(error)
               }
           }
    }
    
    @objc func updateTime() {
        if remainingTime > 0 {
            remainingTime = endTime?.timeIntervalSinceNow ?? 0
            var timeString  = remainingTime.time
            timeString = String(timeString.suffix(2))
            if(timeString.prefix(1) != "0")
            {
            stopwatch.text = String(timeString.suffix(2))
            }
            else
            {
                stopwatch.text = String(timeString.suffix(1))
            }
        } else {
            let path = Bundle.main.path(forResource: "Japanese Temple Bell Small-SoundBible.com-113624364.mp3", ofType:nil)!
            let url = URL(fileURLWithPath: path)

            do {
                bellSound = try AVAudioPlayer(contentsOf: url)
                bellSound?.play()
            } catch {
                print("error")
            }
            stopwatch.text = "20"
            remainingTime = 20
            clock.invalidate()
        }
    }
    
    @IBAction func washHands(_ sender: Any)
    {
        timeShape.add(redCircle, forKey: nil)
        endTime = Date().addingTimeInterval(remainingTime)
        clock = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    func parse(data:Data)
    {
        let decoder = JSONDecoder()
        let parsedData = try! decoder.decode([Dict].self, from: data)
        dailyCasesLabel.text = "New Cases: " + String(parsedData[0].positiveIncrease)
        deathLabel.text = "New Deaths: " + String(parsedData[0].deathIncrease)
        dateLabel.text = getDate(dateInt: parsedData[0].date)
        totalDeaths.text = "Total Deaths: " + String(parsedData[0].death)
        totalPositive.text = "Total Cases: " + String(parsedData[0].positive)
    }
    func parseState(data:Data)
    {
        let decoder = JSONDecoder()
        let parsedData = try! decoder.decode(Dict.self, from: data)
        dailyCasesLabel.text = "New Cases: " + String(parsedData.positiveIncrease)
        deathLabel.text = "New Deaths: " + String(parsedData.deathIncrease)
        dateLabel.text = getDate(dateInt: parsedData.date)
        totalDeaths.text = "Total Deaths: " + String(parsedData.death)
        totalPositive.text = "Total Cases: " + String(parsedData.positive)
    }
    func parseHistory(data:Data)
    {
        let decoder = JSONDecoder()
        let parsedData = try! decoder.decode([Dit].self, from: data)
        var array: Array<Int> = []
        var dates: Array<String> = []
        var currDate = ""
        dataEntries = []
        for i in 0..<array.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: Double(array[i]))
          dataEntries.append(dataEntry)
        }
        var lineChartDataSet = LineChartDataSet(entries: dataEntries, label: nil)
        var lineChartData = LineChartData(dataSet: lineChartDataSet)
           chart.data = lineChartData
        for i in stride(from: 5, through: 0, by: -1)
        {
            array.append(parsedData[i].positiveIncrease)
            currDate = String(parsedData[i].date)
            currDate = String(currDate.dropFirst(4))
            if(String(currDate.suffix(2)).prefix(1) == "0")
            {
                currDate = currDate.prefix(2) + "/" + currDate.suffix(1)
                print(currDate)
                dates.append(currDate)
            }
            else
            {
            currDate = currDate.prefix(2) + "/" + currDate.suffix(2)
            dates.append(currDate)
            }
        }

        for i in 0..<array.count {
            let dataEntry = ChartDataEntry(x:Double(i), y: Double(array[i]))
          dataEntries.append(dataEntry)
        }
        self.chart.xAxis.valueFormatter = DefaultAxisValueFormatter(block: {(index, _) in
            return dates[Int(index)]
        })
        self.chart.leftAxis.valueFormatter = DefaultAxisValueFormatter(block: {(index, _) in
            return ""
        })
        self.chart.rightAxis.valueFormatter = DefaultAxisValueFormatter(block: {(index, _) in
            return ""
        })
        let set = LineChartDataSet(entries: dataEntries, label: "Covid-19 Daily Cases")
            set.setColor(NSUIColor.red, alpha: CGFloat(1))
            set.circleColors = [NSUIColor.red]
            set.circleRadius = 5
        set.valueFont = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 10)!
        self.chart.xAxis.gridLineWidth = 0.5
        self.chart.drawGridBackgroundEnabled = false
        self.chart.xAxis.labelFont = UIFont(name: "AppleSDGothicNeo-Regular", size: 15)!
        self.chart.xAxis.setLabelCount(dates.count, force: true)
        self.chart.leftAxis.drawAxisLineEnabled = false
        self.chart.rightAxis.drawAxisLineEnabled = false
        self.chart.rightAxis.drawGridLinesEnabled = false
        self.chart.leftAxis.drawGridLinesEnabled = false
           lineChartData = LineChartData(dataSet: set)
           chart.data = lineChartData
        
    }
    
    func setUpLabels()
    {
        //let merica = UILabel(frame: CGRect(x: view.frame.minX - 50 ,y: 120, width: 700, height: 50))
        //merica.textAlignment = .center
        //merica.textColor = UIColor.blue
        //merica.font = UIFont(name: "GillSans-SemiBold", size: 35)!
        //merica.text = "United States 🇺🇸"
        //merica.center.x = self.view.center.x
        //view.addSubview(merica)
        dailyCasesLabel.font = UIFont(name: "GillSans-SemiBold", size: 35)!
        dailyCasesLabel.center = CGPoint(x: 210, y: 490)
        deathLabel.font = UIFont(name: "GillSans-SemiBold", size: 35)!
        deathLabel.center = CGPoint(x: 215, y: 550)
        totalDeaths.font = UIFont(name: "GillSans-SemiBold", size: 35)!
        totalDeaths.center = CGPoint(x: 200, y: 610)
        totalPositive.font = UIFont(name: "GillSans-SemiBold", size: 35)!
        totalPositive.center = CGPoint(x: 200, y: 670)
        dateLabel.textColor = UIColor.darkGray
        dateLabel.center.x = 280
        dateLabel.center.y = 70
}

    func getDate(dateInt: Int) -> String
    {
        var date = String(dateInt)
        date = String(date.suffix(4))
        print(String(date.prefix(4)))
        if(String(date.prefix(2)) == "11")
        {
        date = String(date.suffix(2))
        date = "Last Updated: November " + date
        }
        else
        {
            date = String(date.suffix(2))
            date = "Last Updated: October " + date
        }
        return date
    }
    
    func setClock() //function is my own but had to refrence stack overflow because my knowledge in animation is limited.
    {
        shape.path = UIBezierPath(arcCenter: CGPoint(x: view.frame.midX , y: 795), radius:
                                            75, startAngle: -1.5708, endAngle: 4.71239, clockwise: true).cgPath
        shape.strokeColor = UIColor.white.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 10
        view.layer.addSublayer(shape)
        
       timeShape.path = UIBezierPath(arcCenter: CGPoint(x: view.frame.midX , y: 795), radius:
                                                75, startAngle: -1.5708, endAngle: 4.71239, clockwise: true).cgPath
       timeShape.strokeColor = UIColor.red.cgColor
       timeShape.fillColor = UIColor.clear.cgColor
       timeShape.lineWidth = 10
        view.layer.addSublayer(timeShape)
        
        stopwatch = UILabel(frame: CGRect(x: view.frame.midX-40 ,y: 795, width: 100, height: 50))
        stopwatch.textColor = UIColor.white
        stopwatch.font = UIFont(name: "Menlo-Bold", size: 30)!
        stopwatch.textAlignment = .center
        stopwatch.text = "20"
        view.addSubview(stopwatch)
        
        redCircle.fromValue = 0
        redCircle.toValue = 1
        redCircle.duration = remainingTime
    }
    
}

extension TimeInterval {
    var time: String {
        return String(format:"%02d:%02d", Int(self/60),  Int(ceil(truncatingRemainder(dividingBy: 60))) )
    }
}
