

//
//  MapViewController.swift
//  OTPHJ
//
//  Created by Brandon Wynne on 10/10/16.
//  Copyright © 2016 A290 Spring 2016 - bmwynne, jfbinzer. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var Map: MKMapView!
    @IBOutlet weak var LocationDetails: UILabel!
    
    var manager:CLLocationManager!
    var myLocations: [CLLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setup our Location Manager
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        
        // user activated automatic authorization info mode
        let status = CLLocationManager.authorizationStatus()
        if status == .NotDetermined || status == .Denied || status == .AuthorizedWhenInUse {
            // present an alert indicating location authorization required
            // and offer to take the user to Settings for the app via
            // UIApplication -openUrl: and UIApplicationOpenSettingsURLString
            manager.requestAlwaysAuthorization()
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        
        
        //Setup our Map View
        Map.delegate = self
        print(mainVariables.topology)
        if (mainVariables.topology) {
            Map.mapType = MKMapType.Standard
        } else {
            Map.mapType = MKMapType.Satellite
        }
        Map.showsUserLocation = true
        
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        LocationDetails.text = "present location : \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)"
        
        //mapview setup to show user location
        Map.delegate = self
        Map.showsUserLocation = true
        Map.mapType = MKMapType(rawValue: 0)!
        Map.userTrackingMode = MKUserTrackingMode(rawValue: 2)!
        
        //drawing path or route covered
        if let oldLocationNew = oldLocation as CLLocation?{
            let oldCoordinates = oldLocationNew.coordinate
            let newCoordinates = newLocation.coordinate
            var area = [oldCoordinates, newCoordinates]
            var polyline = MKPolyline(coordinates: &area, count: area.count)
            Map.addOverlay(polyline)
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if (overlay is MKPolyline) {
            var pr = MKPolylineRenderer(overlay: overlay)
            pr.strokeColor = mainVariables.color
            pr.lineWidth = 2
            return pr
        }
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
}
