//
//  ViewController.swift
//  RockfordCrimeMap
//
//  Created by CHuck Konkol
//

//1 Imports
import UIKit
import MapKit
import Foundation

//2 Add MKMapViewDelegate,CLLocationManagerDelegate to viewcontroller
class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
    //IBOutlets

//3 Create Outlets
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblCrimeRange: UILabel!
    @IBOutlet weak var DateSlider: UISlider!

//4 Create Variables
    private var locationManager = CLLocationManager()
    private var dataPoints:[DataPoints] = [DataPoints]()
    var crimedate:String!
    var currentValue:Int!
    var myloc:CLLocation = CLLocation()
    let startLocation = CLLocation(latitude: 42.306713, longitude: -88.989403	)
    //The distance mentioned is in meters.
    let initialRadius:CLLocationDistance = 20000

//5 DateSlider determines how far back to get crime json and display on map

    @IBAction func DateSliderUp(sender: UISlider) {
         currentValue = Int(sender.value)
        //Get Date
        let now = NSDate()
        mapView.removeAnnotations(mapView.annotations)
        var i = 1
        while i <= currentValue {
            
            let daysToAdd = i
            let calculatedDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Day, value: -daysToAdd, toDate: now, options: NSCalendarOptions.init(rawValue: 0))
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let newDates = dateFormatter.stringFromDate(calculatedDate!)
            crimedate = newDates
            loadDataFromSODAApi()
            i = i + 1
        }
 
    }
    
//6 Date on label
    
    @IBAction func DateSlider(sender: UISlider) {
       currentValue = Int(sender.value)
       lblCrimeRange.text = "\(currentValue) Days Ago Until Now."
    }
    

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        myloc = location
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
    }
    
//7 When App loads
    //MARK: View Controller Methods.
    override func viewDidLoad() {
        super.viewDidLoad()
      //GET DATE
         let now = NSDate()
        let calculatedDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Day, value: -1, toDate: now, options: NSCalendarOptions.init(rawValue: 0))
      //Formate Date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let newDates = dateFormatter.stringFromDate(calculatedDate!)
        crimedate = newDates
        
        centerMapOnLocation(startLocation)
        checkLocationAuthorizationStatus()
        mapView.delegate = self
      
        loadDataFromSODAApi()
        setUpNavigationBar()
        mapView.showsUserLocation = true
    }
//8 Needed to update location when user moves
    func mapView(mapView: MKMapView, didUpdateUserLocation
        userLocation: MKUserLocation) {
        mapView.centerCoordinate = userLocation.location!.coordinate
    }

//9 Confirm user gives access to location
    
    //MARK: Setup Methods
    //Check the location Authorization
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    //Center the map onto a particular location.
    func centerMapOnLocation(location:CLLocation){
        let coordinateRegion:MKCoordinateRegion! = MKCoordinateRegionMakeWithDistance(location.coordinate, initialRadius * 2.0, initialRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

//10 Nav Bar Color
    func setUpNavigationBar(){
        self.navigationBar.barTintColor = UIColor.redColor()
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
    }

    
//11 Load Data from JSON

    //Load data from endpoint given
    func loadDataFromSODAApi(){
        let session:NSURLSession! = NSURLSession.sharedSession()
        let url:NSURL! = NSURL(string: "https://data.illinois.gov/resource/ctfx-e3rj.json?occurred_on_date=\(crimedate)")
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error in
            guard let actualData = data else{
                return
            }
            do{
                let jsonResult:NSArray = try NSJSONSerialization.JSONObjectWithData(actualData, options: NSJSONReadingOptions.MutableLeaves) as! NSArray
              //  print("Number of Json Results loaded  = \(jsonResult.count)")
                dispatch_async(dispatch_get_main_queue(), {
                    for item in jsonResult {
                        let dataDictionary = item as! NSDictionary
                        let datapoint:DataPoints! = DataPoints.fromDataArray(dataDictionary)
                        self.dataPoints.append(datapoint)
                        var thepoint = MKPointAnnotation()
                        thepoint = MKPointAnnotation()
                        thepoint.coordinate = datapoint.coordinate
                        thepoint.title = datapoint.title
                        thepoint.subtitle = datapoint.district
                        self.mapView.addAnnotation(thepoint)
                                               }
                })

            }catch let parseError{
                print("Response Status - \(parseError)")
            }
        })
        task.resume()
    }

   
    

   }



