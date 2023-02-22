//
//  VideoClipsTableViewController.swift
//  SCBApp
//
//  Created by Andrei Yakugov on 5/2/22.
//

import UIKit
import Photos
import AVKit

class VideoClipsTableViewController: UITableViewController {
    
    var photosurl = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Saved Video Clips"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "vclip")
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //navigationItem.rightBarButtonItem = editButtonItem
        // Request access to PhotosApp
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            
            // Handle restricted or denied state
            if status == .restricted || status == .denied
            {
                print("Status: Restricted or Denied")
            }
            
            // Handle limited state
            if status == .limited
            {
                self?.fetchVideos()
                print("Status: Limited")
            }
            
            // Handle authorized state
            if status == .authorized
            {
                self?.fetchVideos()
                print("Status: Full access")
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

        }
    func fetchVideos()
        {
            let options = PHFetchOptions()
            options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            // Fetch all video assets from the Photos Library as fetch results
            let fetchResults = PHAsset.fetchAssets(with: options)
            
            // Loop through all fetched results
            fetchResults.enumerateObjects({ [weak self] (object, count, stop) in

                let name = object.originalFilename
                
                if name!.contains("abcd") {
                    // Add video object to our video array
                    self?.photosurl.append(object)
                }
            })
            
            // Reload the table view on the main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return photosurl.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "vclip")!
                
        // Get video asset at current index
        let videoAsset = photosurl[indexPath.row]
        
        cell.textLabel?.text = "Video from \( videoAsset.modificationDate ?? Date() )"
        
        // Load video thumbnail
        PHCachingImageManager.default().requestImage(for: videoAsset,
                                                             targetSize: CGSize(width: 100, height: 100),
                                                             contentMode: .aspectFill,
                                                             options: nil) { (photo, _) in
                    
            cell.imageView?.image = photo
                    
        }
                
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            photosurl.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get video asset at current index
                let videoAsset = photosurl[indexPath.row]
                
                // Fetch the video asset
                PHCachingImageManager.default().requestAVAsset(forVideo: videoAsset, options: nil) { [weak self] (video, _, _) in
                    if let video = video
                    {
                        // Launch video player in the main thread
                        DispatchQueue.main.async {
                            self?.playVideo(video)
                        }
                    }
                }


    }
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    // Function to play video player in AVPlayerViewController
    private func playVideo(_ video: AVAsset)
    {
        let playerItem = AVPlayerItem(asset: video)
        let player = AVPlayer(playerItem: playerItem)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
}
extension PHAsset {
    var originalFilename: String? {
        return PHAssetResource.assetResources(for: self).first?.originalFilename
    }
}
