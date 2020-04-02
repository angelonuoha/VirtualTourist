//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Angel Onuoha on 1/24/20.
//  Copyright © 2020 Angel Onuoha. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editingButton: UIButton!
    
    var dataController: DataController!
    
    var editingPin = false
    
    var backgroundContext: NSManagedObjectContext!
    
    var annotations: [MKPointAnnotation?]!
    
    var droppedPin: MapLocations!
    
    var mapLocations: [MapLocations]!
    
    var selectedPin: MapLocations!
    
    var fetchedResultsController: NSFetchedResultsController<MapLocations>!
    
    var flickrPhotos: [FlickrPhoto]!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<MapLocations> = MapLocations.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    fileprivate func setUpMapPins() {
        setupFetchedResultsController()
        let pins = fetchedResultsController.fetchedObjects!
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = pin.latitude
            annotation.coordinate.longitude = pin.longitude
            mapView.addAnnotation(annotation)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let reloadMapView = UserDefaults.standard.value(forKey: "lastCoordinateView") as! [Double]? {
            mapView.centerCoordinate.latitude = reloadMapView[0]
            mapView.centerCoordinate.longitude = reloadMapView[1]
            mapView.region.span.latitudeDelta = reloadMapView[2]
            mapView.region.span.longitudeDelta = reloadMapView[3]
        }
        setupFetchedResultsController()
        setUpMapPins()
        mapLocations = fetchedResultsController.fetchedObjects!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        editingButton.setTitle("Edit", for: .normal)
        
        // Allow the map view to recognize a long tap
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap(sender:)))
        mapView.addGestureRecognizer(longTapGesture)
        
        
        
        mapView.reloadInputViews()
        backgroundContext = dataController.backgroundContext
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    @IBAction func editButton(_ sender: Any) {
        editingButton.setTitle("Done", for: .selected)
        editingPin = !editingPin
        editingButton.isSelected = editingPin
    }
    
    // Add a pin to the map on a long tap
    @objc func longTap(sender: UIGestureRecognizer) {
        if !editingPin {
            if sender.state == .began {
                print("long tap")
                let locationInView = sender.location(in: mapView)
                let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
                droppedPin = MapLocations(annotationLatitude: locationOnMap.latitude, annotationLongitude: locationOnMap.longitude, context: dataController.viewContext)
                self.mapView.addAnnotation(droppedPin)
                try? dataController.viewContext.save()
            }
        }
        
    }
    
    // Format the pin
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView?.canShowCallout = false
        }
        else {
            pinView!.annotation = annotation
        }

        return pinView
    }
    
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        saveLastMapView()
    }
    
    // Persist the user's last view of the map
    fileprivate func saveLastMapView() {
        let visibleRegion = mapView.region
        let centerLat = mapView.centerCoordinate.latitude
        let centerLon = mapView.centerCoordinate.longitude
        
        let centerLatSpan = visibleRegion.span.latitudeDelta
        let centerLonSpan = visibleRegion.span.longitudeDelta
        let lastCoordinateView = [centerLat, centerLon, centerLatSpan, centerLonSpan]
        UserDefaults.standard.set(lastCoordinateView, forKey: "lastCoordinateView")
    }
    
   
    
    // Respond to pin taps
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("selected")
        let selectedLongitude = view.annotation!.coordinate.longitude as Double
        let selectedLatitude = view.annotation!.coordinate.latitude as Double
        setupFetchedResultsController()
        mapLocations = fetchedResultsController.fetchedObjects!
        guard let index = mapLocations.firstIndex(where: { (mapLocations) -> Bool in
            return mapLocations.latitude == selectedLatitude && mapLocations.longitude == selectedLongitude
        }) else {
            print("failed to find coordinates")
            return
        }
        selectedPin = mapLocations[index]
        if !editingPin {
            FlickrAPI.getPhotos(latitude: selectedLatitude, longitude: selectedLongitude, completion: handleSelectedPinResponse(flickrResponse: error:))
        } else {
            self.mapView.removeAnnotations(mapView.annotations)
            dataController.viewContext.delete(selectedPin)
            try? dataController.viewContext.save()
            setUpMapPins()
        }
        
    }
    
    func handleSelectedPinResponse(flickrResponse: [FlickrPhoto]?, error: Error?) {
        flickrPhotos = flickrResponse
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "photoAlbumSegue", sender: nil)
        }
        
    }
    
    // Pass pin information to the Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! PhotoAlbumViewController
        vc.selectedPin = selectedPin
        vc.dataController = dataController
        vc.backgroundContext = backgroundContext
        vc.flickrPhotos = flickrPhotos
    }

}

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    
}
