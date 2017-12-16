//
//  RealLinkParser.swift
//  RelLinkParser
//
//  Created by Eddie Hinkle on 4/29/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public class RealLinkParser {
    
//    public enum IndieWebEndpointType: String {
//        case Authorization = "authorization_endpoint"
//        case Token = "token_endpoint"
//        case Micropub = "micropub"
//    }

    /**
     Retrieves all HTTP Link Headers and relationship tags from site's HTML
     
     - Parameters
        - fromUrl: The normalized URL to get relationship tags from.
        - completion: A closure that gets called with the dictionary of the links after processing.
     */
    public static func getRelLinks(fromUrl url: URL, completion: @escaping ([String: [URL]]) -> ()) {
        let fetchSitesGroup = DispatchGroup()
        var endpoints: [String: [URL]] = [:]
        
        fetchSitesGroup.enter()
        fetchSiteData(fromUrl: url) { (httpHeader, htmlBody) in
            
            let fetchLinksGroup = DispatchGroup()
            
            fetchLinksGroup.enter()
            fetchEndpoints(fromHttpHeaders: httpHeader) { endpointUrls in
                for urlType in endpointUrls.keys {
                    endpoints = saveEndpointUrls(endpointUrls[urlType]!, withName: urlType, inDictionary: endpoints)
                    if let finalUrl = httpHeader.url {
                        endpoints["url"] = [finalUrl]
                    }
                }
                fetchLinksGroup.leave()
            }
        
            if let html = htmlBody {
                fetchLinksGroup.enter()
                fetchLinks(fromHtml: html) { endpointUrls in
                    for urlType in endpointUrls.keys {
                        endpoints = saveEndpointUrls(endpointUrls[urlType]!, withName: urlType, inDictionary: endpoints)
                        if let finalUrl = httpHeader.url {
                            endpoints["url"] = [finalUrl]
                        }
                    }
                    fetchLinksGroup.leave()
                }
            }
            
            
            fetchLinksGroup.notify(queue: DispatchQueue.global(qos: .background)) {
                fetchSitesGroup.leave()
            }
        }
        
        fetchSitesGroup.notify(queue: DispatchQueue.global(qos: .background)) {
            completion(endpoints)
        }
    }
    
    // Input: Any URL or string like "eddiehinkle.com"
    // Output: Normlized URL (default to http if no scheme, default "/" path)
    //         or return false if not a valid URL (has query string params, etc)
    public static func normalizeMeURL(url: String) -> URL? {
        
        var meUrl = URLComponents(string: url)
        
        // If there is no scheme or host, the host is probably in the path
        if (meUrl?.scheme == nil && meUrl?.host == nil) {
            // If the path is nil or empty, then our url is probably empty. Mayday!
            if (meUrl?.path == nil || meUrl?.path == "") {
                return nil;
            }
            
            // Split the path into segments so we can seperate the host and the path
            let pathSegments = meUrl?.path.characters.split(separator: "/").map(String.init)
            
            meUrl?.host = pathSegments?.first;
            meUrl?.path = "/" + (pathSegments?.dropFirst().joined() ?? "")
        }
        
        // If no scheme, we default to http
        if (meUrl?.scheme == nil) {
            meUrl?.scheme = "http"
        } else if (meUrl?.scheme != "http" && meUrl?.scheme != "https") {
            // If there is a scheme, we only accept http and https schemes
            print("Scheme existed and wasn't http or https: \(meUrl?.scheme ?? "No Scheme")")
            return nil
        }
        
        // We default to a path of /
        if (meUrl?.path == nil || meUrl?.path == "") {
            meUrl?.path = "/"
        }
        
        // We don't want query or fragment messing up our url. Just set those to nil
        meUrl?.fragment = nil
        meUrl?.query = nil
        
        return meUrl?.url
    }
    
    public static func fetchSiteData(fromUrl meUrl: URL, completion: @escaping ((HTTPURLResponse, Data?)) -> ()) {
        let request = URLRequest(url: meUrl)
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on \(meUrl)")
                print(error ?? "No error present")
                return
            }
            
            // Check if endpoint is in the HTTP Header fields
            if let httpResponse = response as? HTTPURLResponse {
                completion((httpResponse, data))
            }
            
        }
        
        task.resume()
        
    }
    
    public static func fetchEndpoints(fromHttpHeaders httpResponse: HTTPURLResponse, completion: @escaping ([String: [URL]]) -> ()) {
        
        var endpointsFound: [String: [URL]] = [:]
        
        // Get link field
        if let linkHeaderString = httpResponse.allHeaderFields["Link"] as? String {
            // Split Link String into the various segments
            let linkHeaders = linkHeaderString.characters.split(separator: ",").map({charactersSequence in
                // Run regex on each link segment
                return self.linkMatches(for: "<([a-zA-Z:\\/\\.]+)>; rel=\"([a-zA-Z_-]+)\"", in: String.init(charactersSequence))
            })
            
            for headerLink in linkHeaders {
                if (headerLink.count > 0) {
                    let linkType = headerLink[1]
                    if let linkUrl = URL(string: headerLink[0]) {
                        if endpointsFound[linkType] == nil {
                            endpointsFound[linkType] = []
                        }
                        endpointsFound[linkType]?.append(linkUrl)
                    }
                }
            }
        }
        
        completion(endpointsFound)
        
    }
    
    public static func fetchLinks(fromHtml htmlBody: Data, completion: @escaping ([String: [URL]]) -> ()) {
        
        var endpointsFound: [String: [URL]] = [:]
        
        // Parse HTML from returned body
        if let doc = try? HTML(html: htmlBody, encoding: .utf8) {
            // Look for all rel tags
            for relTag in doc.css("[rel]") {
                if let relLink = relTag["href"], let relName = relTag["rel"] {
                    // if any rel tags have multiple relations, we should store each one seperately
                    for individualRelName in relName.components(separatedBy: " ") {
                        endpointsFound = saveEndpointUrl(relLink, withName: individualRelName, inDictionary: endpointsFound)
                    }
                }
            }
        }
        
        completion(endpointsFound)
        
    }
    
    static func saveEndpointUrl(_ url: String,
                         withName name: String,
                         inDictionary existingEndpoints: [String: [URL]]) -> [String: [URL]] {
        
        var endpointsFound = existingEndpoints
        
        if let linkUrl = URL(string: url) {
            if endpointsFound[name] == nil {
                endpointsFound[name] = []
            }
            endpointsFound[name]?.append(linkUrl)
        }
        
        return endpointsFound
    }
    
    static func saveEndpointUrls(_ urls: [URL],
                                withName name: String,
                                inDictionary existingEndpoints: [String: [URL]]) -> [String: [URL]] {
        
        var endpointsFound = existingEndpoints
        
        if endpointsFound[name] == nil {
            endpointsFound[name] = []
        }
        if let existingUrls = existingEndpoints[name] {
            endpointsFound[name] = existingUrls + urls
        } else {
            endpointsFound[name] = urls
        }
        
        return endpointsFound
    }
    
    // Utlity Methods
    static func linkMatches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            var matches: [String] = []

            for match in results {
                for n in 1..<match.numberOfRanges {
                    let range = match.range(at: n)
                    let r = text.index(text.startIndex, offsetBy: range.location) ..< text.index(text.startIndex, offsetBy: range.location+range.length)
                    matches.append(text.substring(with: r))
                }
            }
            
            
            
            return matches
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
}
