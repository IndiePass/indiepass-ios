//
//  PostingViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/9/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit
import Photos

class PostingViewController: UIViewController, UITextViewDelegate, SimpleSelectionDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, URLSessionTaskDelegate, UICollectionViewDataSource {

    public var currentPost: MicropubPost? = nil
    public var displayAsModal: Bool = true
    public var delegate: PostingViewDelegate? = nil
    public var replyContext: Jf2Post? = nil
    
    var activeAccount: IndieAuthAccount? = nil
    var originalPost: MicropubPost? = nil
    var tagOptions: [String] = ["Test", "Testing 1", "Testing 4"]
    var currentSelectionView: String? = nil
    var imagePicker = UIImagePickerController()
    var currentUploading: [Int] = []
    var keyboardHeight: CGFloat = 0
    
    @IBOutlet weak var postContentField: UITextView!
    @IBOutlet weak var replyToLabel: UILabel!
    @IBOutlet weak var replyToViewHeight: NSLayoutConstraint!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var titleViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tagsButton: UIBarButtonItem!
    @IBOutlet weak var syndicateButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var uploadButton: UIBarButtonItem!
    @IBOutlet weak var bottomToolbar: UIToolbar!
    @IBOutlet weak var toolbarBottomHeight: NSLayoutConstraint!
    @IBOutlet weak var photoUploads: UICollectionView!
    @IBOutlet weak var photoUploadsHeight: NSLayoutConstraint!
    
    // Posting Status View
    @IBOutlet var postingStatusView: UIView!
    @IBOutlet weak var postingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var postingStatus: UILabel!
    @IBOutlet weak var postingStatusBottom: NSLayoutConstraint!
    @IBOutlet weak var postingStatusTop: NSLayoutConstraint!
    
    @IBAction func cancelModal(_ sender: Any) {
        if hasPostChanged() {
            let alert = UIAlertController(title: "Save Draft", message: "Would you like to save this post as a draft?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { action in
                self.currentPost = nil
                self.clearPostDraft()
                self.close()
            }))
            alert.addAction(UIAlertAction(title: "Save Draft", style: .default, handler: { action in
                self.close()
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.close()
        }
    }
    
    @IBAction func selectImage(_ sender: UIBarButtonItem) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            openImageSelection()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    self.openImageSelection()
                }
            }
        case .restricted:
            // same same
            print("User do not have access to photo album.")
        case .denied:
            // same same
            print("User has denied the permission.")
        case .limited:
            openImageSelection()
        }
    }
    
    func openImageSelection() {
        DispatchQueue.main.async {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = .photoLibrary;
                self.imagePicker.allowsEditing = false
                
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let newImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            if self.currentPost?.properties.photo == nil {
                self.currentPost?.properties.photo = []
            }
            
            var newPhoto = MicropubPhoto()
            newPhoto.image = newImage
            self.currentPost?.properties.photo?.append(newPhoto)
            let uploadingId = (self.currentPost?.properties.photo?.count)! - 1
            currentUploading.append(uploadingId)
            
            if let fileUrl = info[UIImagePickerControllerImageURL] as? URL {
                MicropubPost.uploadToMediaEndpoint(image: newPhoto.image!, withId: "\(uploadingId)", ofType: "image/jpeg", withName: fileUrl.lastPathComponent, forUser: activeAccount!, withDelegate: self) { imageUrl in
                    self.currentPost?.properties.photo?[uploadingId].uploadedUrl = imageUrl
                    self.currentPost?.properties.photo?[uploadingId].progressPercent = nil
                    DispatchQueue.main.async {
                        self.photoUploads.reloadData()
                        self.updatePostingView(withAnimation: true)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.imagePicker.dismiss(animated: true) {}
        }
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {

        let uploadProgress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        if let uploadingIdString = session.sessionDescription, let uploadingId = Int(uploadingIdString) {
            print("update info for \(uploadingId)")
            currentPost?.properties.photo?[uploadingId].progressPercent = uploadProgress
        }
        
        DispatchQueue.main.async {
            self.photoUploads.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentPost?.properties.photo?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = photoUploads.dequeueReusableCell(withReuseIdentifier: "photoUploadCell", for: indexPath) as! PhotoUploadCollectionViewCell
        if let photoInfo = currentPost?.properties.photo?[indexPath.row] {
            cell.imageView.image = photoInfo.image
            if let progress = photoInfo.progressPercent {
                if progress == 1 {
                    cell.progressView.isHidden = true
                } else {
                    cell.progressView.isHidden = false
                    cell.progressView.setProgress(progress, animated: true)
                }
            } else {
                cell.progressView.isHidden = true
            }
        }
        return cell
    }
    
    @IBAction func sendPost(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.postingStatusView.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            self.postingActivityIndicator.isHidden = false
            self.postingActivityIndicator.activityIndicatorViewStyle = .white
            self.postingActivityIndicator.startAnimating()
            self.postingStatus.text = "Sending micropub post..."
            self.view.layoutIfNeeded()
            self.postingStatusTop.constant = 0
            self.postingStatusBottom.constant = 0
            
            UIView.animate(withDuration: 0.4, animations: {
                self.navigationController?.navigationBar.layer.zPosition = -1;
                self.view.layoutIfNeeded()
                
                if let account = self.activeAccount, var post = self.currentPost {
                    
                    post.properties.content = self.postContentField.text
                    post.properties.name = self.titleField.text
                    if (post.properties.name?.isEmpty ?? false) {
                        post.properties.name = nil
                    }
            
                    DispatchQueue.global(qos: .background).async {
                        MicropubPost.send(post: post, as: .urlencoded, forUser: account) { error in
                            
                            if let errorString = error {
                                
                                DispatchQueue.main.async {
                                    self.postingStatusView.backgroundColor = UIColor.red
                                    self.postingActivityIndicator.stopAnimating()
                                    self.postingActivityIndicator.isHidden = true
                                    
                                    UIView.animate(withDuration: 1, animations: {
                                        self.view.layoutIfNeeded()
                                        self.postingStatus.text = errorString
                                
                                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                                            self.postingStatusTop.constant = -100
                                            self.postingStatusBottom.constant = 100
                                            
                                            UIView.animate(withDuration: 0.4, animations: {
                                                self.view.layoutIfNeeded()
                                                
                                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                                    self.navigationController?.navigationBar.layer.zPosition = 0;
                                                    if let post = self.currentPost {
                                                        self.savePostDraft(post: post)
                                                    }
                                                }
                                            })
                                        }
                                    })
                                }
                                
                            } else {
                                
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                                    self.postingStatusTop.constant = -100
                                    self.postingStatusBottom.constant = 100
                                    
                                    UIView.animate(withDuration: 0.4, animations: {
                                        self.view.layoutIfNeeded()

                                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                            self.navigationController?.navigationBar.layer.zPosition = 0;
                                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                                self.currentPost = nil
                                                self.clearPostDraft()
                                                self.close()
                                            }
                                        }
                                    })
                                }
                                
                            }
                            
                        }
                    }
                }
            })
        }
    }
    
    func close() {
        if displayAsModal {
            self.dismiss(animated: true, completion: nil)
        } else {
            // TODO: how to communicate that it's completed rather than cancelled
            delegate?.removePostingView()
        }
    }
    
    func savePostDraft(post: MicropubPost) {
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        if let currentPostData = try? JSONEncoder().encode(post) {
            defaults?.set(currentPostData, forKey: "draftPost")
        }
    }
    
    func clearPostDraft() {
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        if let currentPostData = try? JSONEncoder().encode(MicropubPost(type: .entry, properties: MicropubPostProperties())) {
            defaults?.set(currentPostData, forKey: "draftPost")
        }
    }
    
    func getPostDraft() -> MicropubPost? {
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        if let draftPostData = defaults?.data(forKey: "draftPost"),
           let draftPost = try? JSONDecoder().decode(MicropubPost.self, from: draftPostData) {
                return draftPost
        }
        return nil
    }
    
    func newCreated(item: SimpleSelectionItem) {
        if let currentView = currentSelectionView {
            switch currentView {
                case "tags":
                    tagOptions.append(item.label)
                    if item.selected {
                        if currentPost?.properties.category == nil {
                            currentPost?.properties.category = []
                        }
                        currentPost?.properties.category?.append(item.label)
                    }
                default:
                    break
            }
        }
    }
    
    func selectionWasUpdated(currentlySelected: [Int]) {
        
        
        if let currentView = currentSelectionView {
            switch currentView {
            case "tags":
                currentPost?.properties.category = currentlySelected.map { selectedId in
                    return tagOptions[selectedId]
                }
            case "syndicate":
                currentPost?.properties.mpSyndicateTo = currentlySelected.map { selectedId in
                    return (activeAccount?.micropub_config?.syndicateTo?[selectedId].uid.absoluteString)!
                }
            default:
                break
            }
        }
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        keyboardHeight = keyboardFrame.height
        updatePostingView(withAnimation: true, forDuration: keyboardDuration)
    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification) {
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        keyboardHeight = 0
        updatePostingView(withAnimation: true, forDuration: keyboardDuration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postContentField.delegate = self
        photoUploads.dataSource = self
        setupKeyboardObservers()
        
        tagsButton.image = UIImage.fontAwesomeIcon(name: .tags, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        syndicateButton.image = UIImage.fontAwesomeIcon(name: .shareAlt, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        
        if !displayAsModal {
            navigationItem.leftBarButtonItem = nil
        }
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccountId = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let currentAccount = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccountId]) {
            
                activeAccount = currentAccount
            
                if currentPost == nil {
                    currentPost = getPostDraft()
                }
            
                if currentPost == nil {
                    currentPost = MicropubPost(type: .entry, properties: MicropubPostProperties())
                }
            
                originalPost = currentPost
            
                postContentField.text = currentPost?.properties.content
            
                if activeAccount?.micropub_config?.mediaEndpoint == nil {
                    uploadButton.isEnabled = false
                }
            
//                XRay.parse(url: URL(string: (self.currentPost?.properties.inReplyTo)!)!) { parsedResponse, error in
//                    print("Finished Parsing")
//                    print(parsedResponse?.data.name)
//                    print(parsedResponse?.data.content?.text)
//                    print(parsedResponse?.data.author?.name)
//                    print(parsedResponse?.data.photo?[0])
//                }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        postContentField.becomeFirstResponder()
        updatePostingView(withAnimation: false)
        
        if let categoryCount = currentPost?.properties.category?.count, categoryCount > 0 {
            tagsButton.tintColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)
        } else {
            tagsButton.tintColor = self.view.tintColor
        }
        
        if let syndicateCount = currentPost?.properties.mpSyndicateTo?.count, syndicateCount > 0 {
            syndicateButton.tintColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)
        } else {
            syndicateButton.tintColor = self.view.tintColor
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParentViewController {
            if hasPostChanged() == false {
                // Post hasn't changed since load, so we don't want to save it
                self.currentPost = nil
            }

            if var post = currentPost {
                post.properties.content = postContentField.text
                print("Saved post draft")
                savePostDraft(post: post)
            }
        } else {
            if currentPost != nil, hasPostChanged(), var post = currentPost {
                post.properties.content = postContentField.text
                print("Saved post draft")
                savePostDraft(post: post)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func hasPostChanged() -> Bool {
        if let firstPost = currentPost, let secondPost = originalPost {
            return !(firstPost == secondPost)
        }
        return false
    }
    
    func updatePostingView(withAnimation animate: Bool) {
        updatePostingView(withAnimation: animate, forDuration: 1.0)
    }
    
    func updatePostingView(withAnimation shouldAnimate: Bool, forDuration duration: Double) {
        DispatchQueue.main.async {
            var shouldDisplayReplyView = false
            var shouldDisplayTitleView = false
            var newTitle = "New Post"
            
            if let replyUrl = self.currentPost?.properties.inReplyTo {
                newTitle = "New Reply"
                self.replyToLabel.text = "Replying to: \(replyUrl)"
                shouldDisplayReplyView = true
            }
            
            if self.replyContext != nil, self.replyContext?.type == .repo {
                shouldDisplayTitleView = true
                self.titleField.placeholder = "Issue Title"
                newTitle = "New Issue"
                if let repoUrl = self.replyContext?.url?.absoluteString {
                    print(repoUrl.components(separatedBy: "/"))
                    var repoParts = repoUrl.components(separatedBy: "/")
                    if let repoName = repoParts.popLast(), let repoOwner = repoParts.popLast() {
                        self.replyToLabel.text = "Issue for \(repoName) by \(repoOwner)"
                    }
                }
                
            }
            
            if let characterCount = self.currentPost?.properties.content?.count, characterCount >= 280 {
                shouldDisplayTitleView = true
            }
            
            self.view.layoutIfNeeded()
            
            if shouldDisplayReplyView {
                self.replyToLabel.isHidden = false
                self.replyToViewHeight.constant = 48;
            } else {
                self.replyToLabel.isHidden = true
                self.replyToViewHeight.constant = 0;
            }
            
            if shouldDisplayTitleView {
                self.titleViewHeight.constant = 40
                self.titleField.isHidden = false
            } else {
                self.titleField.isHidden = true
                self.titleViewHeight.constant = 0
            }
            
            if let photoCount = self.currentPost?.properties.photo?.count, photoCount > 0 {
                self.photoUploadsHeight.constant = 50
            } else {
                self.photoUploadsHeight.constant = 0
            }
            
            // TODO: iPhone X needs +30 to the keyboard height, but only if height > 0
            self.toolbarBottomHeight.constant = -self.keyboardHeight
            
            //(self.keyboardHeight == 0 ? 0 : self.keyboardHeight)
            
            self.title = newTitle
            
            if shouldAnimate {
                UIView.animate(withDuration: duration, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        currentPost?.properties.content = postContentField.text
        if let characterCount = currentPost?.properties.content?.count {
            switch characterCount {
            case 0:
                updatePostingView(withAnimation: true)
                break
            case 279:
                updatePostingView(withAnimation: true)
                break
            case 280:
                updatePostingView(withAnimation: true)
                break
            default:
                break
            }
        }
        return true
    }
    
//    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
//        textView.inputAccessoryView = postInputView
//        return true
//    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "manageTags" {
            if let nextVC = segue.destination as? SimpleSelectionViewController {
                nextVC.delegate = self
                nextVC.title = "Tags"
                nextVC.options = tagOptions.map { tag in
                    let tagExists = currentPost?.properties.category?.contains(tag) ?? false
                    return SimpleSelectionItem(label: tag, selected: tagExists)
                }
                currentSelectionView = "tags"
            }
        }
        
        if segue.identifier == "chooseSyndicate" {
            if let nextVC = segue.destination as? SimpleSelectionViewController {
                nextVC.delegate = self
                nextVC.title = "Syndication Targets"
                nextVC.readOnly = true
                nextVC.options = activeAccount?.micropub_config?.syndicateTo?.map { syndicateTarget in
                    let targetSelected = currentPost?.properties.mpSyndicateTo?.contains(syndicateTarget.uid.absoluteString) ?? false
                    return SimpleSelectionItem(label: syndicateTarget.name, selected: targetSelected)
                } ?? []
                currentSelectionView = "syndicate"
            }
        }
    }


}
