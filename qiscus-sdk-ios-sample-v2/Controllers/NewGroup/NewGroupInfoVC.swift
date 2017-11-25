//
//  NewGroupInfoVC.swift
//  qiscus-sdk-ios-sample-v2
//
//  Created by Rohmad Sasmito on 11/17/17.
//  Copyright © 2017 Qiscus Technology. All rights reserved.
//

import UIKit

class NewGroupInfoVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    fileprivate var viewModel = GroupInfoViewModel()
    
    var selectedContacts = [Contact]() {
        didSet {
            self.viewModel.itemSelecteds.append(contentsOf: selectedContacts)
        }
    }
    var groupName: String? {
        didSet {
            if groupName != nil {
                self.isEnableButton(isEnable())
            }
        }
    }
    var avatarURL: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension NewGroupInfoVC {
    func setupUI() -> Void {
        self.title = "Add Group Info"
        
        viewModel.delegate = self
        viewModel.loadData()
        
        // MARK: - Register table & cell
        tableView.backgroundColor       = UIColor.baseBgTableView
        tableView.delegate              = self.viewModel
        tableView.dataSource            = self.viewModel
        tableView.estimatedRowHeight    = 100
        tableView.rowHeight             = UITableViewAutomaticDimension
        tableView.register(GroupInfoCell.nib,
                           forCellReuseIdentifier: GroupInfoCell.identifier)
        tableView.register(SetGroupPhotoCell.nib,
                           forCellReuseIdentifier: SetGroupPhotoCell.identifier)
        tableView.register(ContactCell.nib,
                           forCellReuseIdentifier: ContactCell.identifier)
        
        let rightButton = UIBarButtonItem(barButtonSystemItem: .done,
                                          target: self,
                                          action: #selector(done(_:)))
        self.navigationItem.rightBarButtonItem = rightButton
        self.isEnableButton(false)
        self.setBackTitle()
    }
    
    @objc func done(_ sender: Any) {
        guard let title = self.groupName else { return }
        let emails = self.selectedContacts.flatMap({ $0.email })
        
        print("create group :\(title) with participants: \(emails) avatar: \(self.avatarURL)")
        createGroupChat(emails, title: title, avatarURL: self.avatarURL)
    }
    
    func isEnable() -> Bool {
        guard let name = self.groupName else { return false }
        return (name.count >= 3 && self.selectedContacts.count >= 2)
    }
    
    func isEnableButton(_ enable: Bool) {
        self.navigationItem.rightBarButtonItem?.isEnabled = enable
    }
    
    // MARK: - Upload image to server
    func uploadImage(of image: UIImage) {
        let imagePath = UIImage.uploadImagePreparation(pickedImage: image)
        self.isEnableButton(false)
        
        Api.uploadImage(Helper.URL_UPLOAD, headers: Helper.headers, image: imagePath, completion: { result in
            switch(result) {
            case .succeed(let value):
                if let val = value as? ImageFile {
                    self.avatarURL = val.url
                    print("change avatar is success. Value: \(val.name) - \(val.url)")
                }
                
                self.isEnableButton(true)
                break
            case .failed(value: let m):
                print("change avatar is failure. Error: \(m)")
                self.isEnableButton(true)
                break
            case .onProgress(progress: let p):
                print("change avatar is progress. Progress: \(p)")
            }
        })
    }
}

extension NewGroupInfoVC: GroupInfoViewDelegate {
    func groupAvatarDidChanged(_ image: UIImage?) {
        guard let image = image else { return }
        self.uploadImage(of: image)
        
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func groupNameDidChanged(_ name: String) {
        groupName = name
    }
    
    func participantDidChanged(_ participants: [Contact]) {
        self.isEnableButton(isEnable())
        
        viewModel.loadData()
    }
    
    func participantDidUpdated() {
        tableView.reloadData()
    }
}
