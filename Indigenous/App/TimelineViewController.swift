//
//  TimelineViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//
import UIKit
import Social
import MobileCoreServices

class TimelineViewController: UITableViewController {
    
    var channel: Channel? = nil
    var timeline: [TimelinePost] = []
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeline.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell", for: indexPath)
        
        cell.textLabel?.text = timeline[indexPath.row].name ?? timeline[indexPath.row].content?.text ?? timeline[indexPath.row].summary ?? "Content Can't Display"
        
        return cell
    }
    
    
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
//        getChannelData {
//            DispatchQueue.main.async {
//                refreshControl.endRefreshing()
//            }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
//        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
//        getChannelData()
        
        getSingleChannelData(channel: self.channel!) {
            print("All done with timeline")
        }
    }
    
    func getSingleChannelData(channel: Channel, callback: (() -> ())? = nil) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        
        guard let microsubEndpoint = micropubAuth?["microsub_endpoint"] as? String else {
            print("microsubEndpoint failure")
            return
        }
        
        guard var microsubUrl = URLComponents(string: microsubEndpoint) else {
            print("Making url of microsub fails")
            return
        }
        
        if microsubUrl.queryItems == nil {
            microsubUrl.queryItems = []
        }
        
        microsubUrl.queryItems?.append(URLQueryItem(name: "action", value: "timeline"))
        microsubUrl.queryItems?.append(URLQueryItem(name: "channel", value: channel.uid))
        
        guard let microsub = microsubUrl.url else {
            print("Error making final url")
            return
        }
        
        guard let access_token = micropubAuth?["access_token"] as? String else {
            print("Access Token Error")
            return
        }
        
        var request = URLRequest(url: microsub)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling POST on \(microsubUrl)")
                print(error ?? "No error present")
                return
            }
            
            // Check if endpoint is in the HTTP Header fields
            if let httpResponse = response as? HTTPURLResponse, let body = String(data: data!, encoding: .utf8) {
                if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                    if httpResponse.statusCode == 200 {
                        if contentType == "application/json" {
                            let timelineResponse = try! JSONDecoder().decode(TimelineApiResponse.self, from: body.data(using: .utf8)!)
                            
                            self.timeline = timelineResponse.items
                            
                            //        movies.sort() { $0.title < $1.title }
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                            
                            callback?()
                        }
                    } else {
                        print("Status Code not 200")
                        print(httpResponse)
                        print(body)
                    }
                }
            }
            
        }
        
        task.resume()
    }
    
}

