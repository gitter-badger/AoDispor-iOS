//
//  MasterViewController.swift
//  Ao Dispor
//
//  Created by André Lamelas on 02/06/16.
//  Copyright © 2016 Ao Dispor. All rights reserved.
//

import UIKit
import Koloda
import Font_Awesome_Swift
import MessageUI

class MasterViewController: CardExplorerViewController {
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    var action:Action?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.delegate = self
        self.searchBar.placeholder = NSLocalizedString("De quem precisa?", comment: "")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let titleView = UILabel()
        titleView.text = "Ao Dispor"
        titleView.font = UIFont(name: "DancingScriptOT", size: 36)!
        titleView.textColor = UIColor.titleBlue()

        let width = titleView.sizeThatFits(CGSizeMake(CGFloat.max, CGFloat.max)).width
        titleView.frame = CGRect(origin:CGPointZero, size:CGSizeMake(width, 500))
        self.navigationItem.titleView = titleView
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(MasterViewController.resetSearch))
        titleView.userInteractionEnabled = true
        titleView.addGestureRecognizer(recognizer)

        let rightButton = UIBarButtonItem(title: NSLocalizedString("Favoritos", comment:""), style: .Done, target: self, action: #selector(MasterViewController.showFavorites))
        rightButton.FAIcon = .FAStarO
        self.navigationItem.rightBarButtonItem = rightButton
        
        contactButton.setTitle(NSLocalizedString("Contactar", comment: ""), forState: .Normal)
        nextButton.setTitle(NSLocalizedString("Seguinte", comment: ""), forState: .Normal)

        favoriteButton.setFAIcon(.FAStarO, forState: .Normal)
        favoriteButton.setFATitleColor(UIColor.lightGrayColor(), forState: .Disabled)

        self.updateFavoritesButtonStar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func resetSearch() {
        self.showSearchViewControllerWithAction(.ResetSearch)
    }
    
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFavorites" {
            if Favorites.numberOfFavorites() == 0 {
                return
            }

            let controller = segue.destinationViewController as! FavoritesViewController
            controller.navigationItem.title = NSLocalizedString("Favoritos", comment:"")
            controller.navigationItem.leftItemsSupplementBackButton = true
        }  /*else if segue.identifier == "showSearchScreen" {
            let controller = segue.destinationViewController as! SearchViewController
            controller.action = self.action
            self.dismissViewControllerAnimated(true, completion: nil)
        }*/
    }

    func showSearchViewControllerWithAction(action: Action) {
        SearchViewController.action = action
        self.navigationController?.popViewControllerAnimated(true)
    }

    func updateFavoritesButtonStar() {
        if(Favorites.numberOfFavorites() > 0) {
            self.navigationItem.rightBarButtonItem!.FAIcon = .FAStar
        } else {
            self.navigationItem.rightBarButtonItem!.FAIcon = .FAStarO
        }
    }
}

// MARK: - Button Actions
extension MasterViewController {
    @IBAction func showFavorites(sender: AnyObject) {
        performSegueWithIdentifier("showFavorites", sender: sender)
    }

    @IBAction func contactProfessional(sender: AnyObject) {
        let professional = self.cardsToExplore[self.kolodaView.currentCardIndex]
        let string_id = professional.string_id

        API.sharedInstance.privateInfoFor(string_id!)
        API.sharedInstance.delegate = self
    }

    @IBAction func nextProfessional(sender: AnyObject) {
        self.kolodaView.swipe(.Left)
    }

    @IBAction func markContactAsFavorite(sender: AnyObject) {
        let professionalToAdd = self.cardsToExplore[self.kolodaView.currentCardIndex]
        if !Favorites.appendOrRemove(professionalToAdd) {
            favoriteButton.setFAIcon(.FAStarO, forState: .Normal)
            self.updateFavoritesButtonStar()
            return
        }
        self.updateFavoritesButtonStar()

        self.allowedDirections.append(SwipeResultDirection.Up)
        let originalCardSwipeActionAnimationDuration = cardSwipeActionAnimationDuration
        cardSwipeActionAnimationDuration = originalCardSwipeActionAnimationDuration * 3
        self.kolodaView.swipe(.Up)
        cardSwipeActionAnimationDuration = originalCardSwipeActionAnimationDuration
        self.allowedDirections.removeLast()
    }
}

//MARK: - KolodaViewDelegate
extension MasterViewController {
    override func kolodaDidRunOutOfCards(koloda: KolodaView) {
        if hasMorePages {
            self.showSearchViewControllerWithAction(.NextPage)
        } else {
            koloda.resetCurrentCardIndex()
        }
    }

    override func koloda(koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView {
        let professional = cardsToExplore[Int(index)]
        let professionalCard = super.koloda(koloda, viewForCardAtIndex: index) as? ProfessionalCard

        self.favoriteButton = professionalCard?.favoriteButton

        favoriteButton.setFAIcon(.FAStarO, forState: .Normal)
        favoriteButton.addTarget(self, action: #selector(MasterViewController.markContactAsFavorite), forControlEvents: .TouchUpInside)
        professionalCard!.contactButton.addTarget(self, action: #selector(MasterViewController.contactProfessional), forControlEvents: .TouchUpInside)

        if Favorites.isFavorite(professional) {
            favoriteButton.setFAIcon(.FAStar, forState: .Normal)
        }

        return professionalCard!
    }

    override func koloda(koloda: KolodaView, didShowCardAtIndex index: UInt) {
        //TODO mudar a estrela consoante seja favorito ou não
        let professional = cardsToExplore[Int(index)]
        if Favorites.isFavorite(professional) {
            favoriteButton.setFAIcon(.FAStar, forState: .Normal)
            return
        }
        favoriteButton.setFAIcon(.FAStarO, forState: .Normal)
    }

    override func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {
        let professional = self.cardsToExplore[Int(index)]
        let string_id = professional.string_id

        API.sharedInstance.privateInfoFor(string_id!)
        API.sharedInstance.delegate = self
    }
}

//MARK: - APIReplyDelegate
extension MasterViewController:APIReplyDelegate {
    func returnPrivateInfo(privateInfo: PrivateInfo) {
        //let string = NSLocalizedString("Entre imediatamante em contacto com este profissional através do número:", comment: "")
        //let alertController = UIAlertController(title: NSLocalizedString("Contactar este profissional", comment:""), message: "\(string)\n\(privateInfo.phone!)", preferredStyle: .ActionSheet)

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancelar", comment:""), style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)

        let OKAction = UIAlertAction(title: NSLocalizedString("Telefonar", comment:""), style: .Default) { (action) in
            let phone = "tel://\(privateInfo.phone!)"
            let open = NSURL(string: phone)!

            UIApplication.sharedApplication().openURL(open)
        }
        alertController.addAction(OKAction)

        let SMSAction = UIAlertAction(title: NSLocalizedString("Enviar SMS", comment:""), style: .Default) { (action) in
            let messageVC = MFMessageComposeViewController()
            messageVC.body = "";
            messageVC.recipients = [privateInfo.phone!]
            messageVC.messageComposeDelegate = self;

            self.presentViewController(messageVC, animated: true, completion: nil)
        }
        alertController.addAction(SMSAction)

        var favoriteActionLabel = NSLocalizedString("Adicionar aos Favoritos", comment:"")

        if Favorites.isFavorite(self.cardsToExplore[self.kolodaView.currentCardIndex]) {
                favoriteActionLabel = NSLocalizedString("Remover dos Favoritos", comment:"")
        }
        let FavoriteAction = UIAlertAction(title: favoriteActionLabel, style: .Default) { (action) in
            let professionalToAdd = self.cardsToExplore[self.kolodaView.currentCardIndex]
            Favorites.appendOrRemove(professionalToAdd)
            self.updateFavoritesButtonStar()

        }
        alertController.addAction(FavoriteAction)

        let ShareAction = UIAlertAction(title: NSLocalizedString("Partilhar", comment: ""), style: .Default) { (action) in
            let professionalToShare = self.cardsToExplore[self.kolodaView.currentCardIndex]
            let url = "http://www.aodispor.pt/\(professionalToShare.string_id!)"
            let professionalURL = NSURL(string: url)
            let objectsToShare:[AnyObject] = [professionalURL!]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
        alertController.addAction(ShareAction)

        self.presentViewController(alertController, animated: true, completion: nil)
    }
}

//MARK: - MFMessageComposeViewControllerDelegate
extension MasterViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

//MARK: - UISearchBarDelegate
extension MasterViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text! = API.sharedInstance.searchData.query
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar){
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.endEditing(true)

        self.showSearchViewControllerWithAction(.Search(query: searchBar.text!))
    }
}
