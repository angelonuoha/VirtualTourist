//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Angel Onuoha on 1/24/20.
//  Copyright © 2020 Angel Onuoha. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedPin: MapLocations!
    
    var dataController: DataController!
    
    var backgroundContext: NSManagedObjectContext!
    
    private var blockOperation = BlockOperation()
    
    var flickrPhotos: [FlickrPhoto]!
    
    var group: DispatchGroup! = DispatchGroup()
    
    var fetchedResultsController: NSFetchedResultsController<PhotoAlbums>!

    fileprivate func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<PhotoAlbums> = PhotoAlbums.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "photos", ascending: false)
        let predicate = NSPredicate(format: "photosFromCoordinates == %@", selectedPin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(String(describing: selectedPin))")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("error fetching photo album")
        }
    }
    
    fileprivate func savePicturesToDB() {
        if self.flickrPhotos != nil{
            for photo in self.flickrPhotos {
                group.enter()
                let farmId = photo.farm
                let serverId = photo.server
                let id = photo.id
                let secret = photo.secret
                FlickrAPI.getFlickrImages(farmId: farmId, serverId: serverId, id: id, secret: secret) { (data, error) in
                    if data != nil {
                        let photoInAlbum = PhotoAlbums(context: self.dataController.viewContext)
                        photoInAlbum.photosFromCoordinates = self.selectedPin
                        photoInAlbum.photos = data
                        try? self.dataController.viewContext.save()
                        self.group.leave()
                    }
                }
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapView.addAnnotation(selectedPin! as MKAnnotation)
        mapView.delegate = self
        mapView.centerCoordinate = selectedPin.coordinate
        activityIndicator.startAnimating()
        
        savePicturesToDB()
        group.wait()
        
        setUpFetchedResultsController()
        activityIndicator.stopAnimating()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        collectionView.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
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
    
    @IBAction func newCollection(_ sender: Any) {
        FlickrAPI.getPhotos(latitude: selectedPin.coordinate.latitude, longitude: selectedPin.coordinate.longitude) { (flickrResponse, error) in
            self.flickrPhotos = flickrResponse
            try? self.dataController.viewContext.save()
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        }
    }
    
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[0].numberOfObjects ?? 0
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageViewCell", for: indexPath) as! FlickrImageViewCell
        cell.activityIndicator.startAnimating()
        let aPhoto = self.fetchedResultsController.object(at: indexPath)
        let photo = UIImage(data: aPhoto.photos!)
        cell.imageView.image = photo
        cell.activityIndicator.stopAnimating()
        return cell
    }
        
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
  
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperation = BlockOperation()
    }

    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else { break }
                blockOperation.addExecutionBlock {
                    self.collectionView?.insertItems(at: [newIndexPath])
                }
            case .delete:
                guard let indexPath = indexPath else { break }
                
                blockOperation.addExecutionBlock {
                    self.collectionView?.deleteItems(at: [indexPath])
                }
            case .update:
                print("before update")
                guard let indexPath = indexPath else { break }
                print("update")
                blockOperation.addExecutionBlock {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                
                blockOperation.addExecutionBlock {
                    self.collectionView?.moveItem(at: indexPath, to: newIndexPath)
                }
            @unknown default:
                fatalError()
            }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("fetched results did change")
        collectionView?.performBatchUpdates({
            self.blockOperation.start()
            }, completion: nil)
    }
}

