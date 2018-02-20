//
//  ViewController.swift
//  TorresJonathan_MultipeerConnectivityProject
//
//  Created by Jonathan Torres on 12/9/16.
//  Copyright © 2016 Jonathan Torres. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    //Menu UI Elements
    @IBOutlet weak var playbtnOutlet: UIButton!
    @IBOutlet weak var joinBtnOutlet: UIButton!
    @IBOutlet weak var hostBtnOutlet: UIButton!
    @IBOutlet weak var statusLabel: UILabel!

    //GameView
    @IBOutlet weak var gameView: UIView!
    
    //Player Settings
    var playerOneReady = false
    var playerTwoReady = false
    var playerOneChoice = "None"
    var playerTwoChoice = "None"
    var playerOneScore = 0
    var playerTwoScore = 0
    
    
    //Gameplay UIElements
    @IBOutlet weak var rockOutlet: UIButton!
    @IBOutlet weak var paperOutlet: UIButton!
    @IBOutlet weak var scissorOutlet: UIButton!
    @IBOutlet weak var readyOutlet: UIButton!
    @IBOutlet weak var playerOneImage: UIImageView!
    @IBOutlet weak var playerTwoImage: UIImageView!
    @IBOutlet weak var timerOutlet: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var selectedHand: UILabel!
    
    
    
    //Gameplay Elements
    var countdownSeconds = 3
    var mainTimer = Timer()
    var miscTimer = Timer()
    var winner = ""
    var userExit = false
    
    
    //Connect to other devices
    var peerID: MCPeerID! // Our Device ID (name) as viwed by other
    var session: MCSession! //The "Connection" between devices
    var brower: MCBrowserViewController! //Perbuilt VC that serches for nearby Advertisers
    var advertiser: MCAdvertiserAssistant! //Helps us easily advertise to nearby browsers

    
    //Name fore the Service
    let serviceID = "john-rps"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set an ID
        peerID = MCPeerID(displayName: "Opponent")
        
        //Use name to create a session
        session = MCSession(peer: peerID)
        //Set the delegate to this VC
        session.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //When the Play button from the Main Menu is presssed
    @IBAction func playBtn(_ sender: UIButton) {

        //Show and Hide buttons in the main menu
        if playbtnOutlet.titleLabel?.text == "Play"{
            joinBtnOutlet.isHidden = false
            hostBtnOutlet.isHidden = false
            playbtnOutlet.setTitle("Exit", for: .normal)
        }
        else if playbtnOutlet.titleLabel?.text == "Exit"{
            
            joinBtnOutlet.isHidden = true
            hostBtnOutlet.isHidden = true
            playbtnOutlet.setTitle("Play", for: .normal)
        }
        
        else if playbtnOutlet.titleLabel?.text == "Cancel"{
        
            joinBtnOutlet.isHidden = false
            hostBtnOutlet.isHidden = false
            advertiser.stop()
            advertiser = nil
            playbtnOutlet.setTitle("Exit", for: .normal)
            statusLabel.text = nil
        }

        
    }
    //Function to join a server.
    @IBAction func joinBtn(_ sender: UIButton) {
        
        if session == nil{return}
        //Browesr will look for advertiser
        
        brower = MCBrowserViewController(serviceType: serviceID, session: session)
        
        brower.delegate = self
        
        self.present(brower, animated: true, completion: nil)
        
    }
    //Function to Host a server
    @IBAction func hostBtn(_ sender: UIButton) {
        
        if session == nil{return}
        
        if advertiser == nil{
            
            advertiser = MCAdvertiserAssistant(serviceType: serviceID, discoveryInfo: nil, session: session)
            
            advertiser.start()
            joinBtnOutlet.isHidden = true
            hostBtnOutlet.isHidden = true
            playbtnOutlet.setTitle("Cancel", for: .normal)
            statusLabel.text = "Looking for Players..."
            
        }

        
    }

    
    //Mark - MCBrowser
    
    // Notifies the delegate, when the user taps the done button.
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController){
        
        brower.dismiss(animated: true, completion: nil)
    }
    
    
    // Notifies delegate that the user taps the cancel button.
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController){
        
        brower.dismiss(animated: true, completion: nil)
    }
    
    //Mark - MCSession
    
    
    // Minimum number of peers in a session.
    public let kMCSessionMinimumNumberOfPeers: Int = 1
    
    // Maximum number of peers in a session.
    public let kMCSessionMaximumNumberOfPeers: Int = 2
    
    // Remote peer changed state.
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState){
        
        DispatchQueue.main.async {
            //if connected
            if state == MCSessionState.connected{
                self.statusLabel.text = "Status Connected: Connected"
                self.gameView.isHidden = false
            }
                //Connecting
            else if state == MCSessionState.connecting{
                self.statusLabel.text = "Status Connected: Connecting..."
            }
                //If the opponent exit's the game
            else if state == MCSessionState.notConnected && self.userExit == true{
                
                self.userExit = false
             
                if self.advertiser != nil{self.advertiser.stop()}
                
                let alertController = UIAlertController(title: "You have left the game.", message: "", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {
                    UIAlertAction in
                }
                
                
                alertController.addAction(okAction)
                
                
                self.present(alertController, animated: true, completion: nil)

                
            }
                //If a Player disconnects and display an Alert if so
            else{
                self.gameView.isHidden = true
                self.playerTwoScore = 0
                self.playerOneScore = 0
                self.resetAll()
                self.statusLabel.text = ""
                
                if self.advertiser != nil{self.advertiser.stop()}
                
                let alertController = UIAlertController(title: "There was a Connection error.", message: "Returning to the Main Menu.", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) {
                    UIAlertAction in
                }

                
                alertController.addAction(okAction)

                
                self.present(alertController, animated: true, completion: nil)
                
            }
        }
        
    }

    
    // Received data from remote peer.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID){
     
        //Recive what the opponet chose
        if let otherPlayerChoise: String = String(data: data, encoding: String.Encoding.utf8){
            
            DispatchQueue.main.async {
                self.playerTwoChoice = otherPlayerChoise
            }
        }
        
        
        //Recive when the opponet is ready
        if let otherPlayerReady:Bool = NSKeyedUnarchiver.unarchiveObject(with: data) as? Bool{
            
            DispatchQueue.main.async {
                self.playerTwoReady = otherPlayerReady
                
                //If both player are ready start the game
                if self.playerOneReady == true && self.playerTwoReady == true{
                   self.readyOutlet.isHidden = true
                    
                    self.mainTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.countDown), userInfo: nil, repeats: true)
                    
                }
                
            }
        }
        
    }
    
    
    // Received a byte stream from remote peer.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID){
        
    }
    
    
    // Start receiving a resource from remote peer.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress){
        
    }
    
    
    // Finished receiving a resource from remote peer and saved the content
    // in a temporary location - the app is responsible for moving the file
    // to a permanent location within its sandbox.
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?){
        
    }
    
    
    //Mark -- Core Gameplay
   
    
    //Set the variables that the user chose
    @IBAction func playerChoice(_ sender: UIButton) {
        
        switch sender.tag {
        case 0:
            
            playerOneChoice = "Rock"
            selectedHand.text = "Your choice: \(playerOneChoice)"
            
            if let playerChoice: Data = playerOneChoice.data(using: String.Encoding.utf8){
                
                do{
                    try session.send(playerChoice, toPeers: session.connectedPeers, with: .reliable)
                }
                catch{
                    
                }
                
            }
            
        case 1:
            
            playerOneChoice = "Paper"
            selectedHand.text = "Your choice: \(playerOneChoice)"
            
            if let playerChoice: Data = playerOneChoice.data(using: String.Encoding.utf8){
                
                do{
                    try session.send(playerChoice, toPeers: session.connectedPeers, with: .reliable)
                }
                catch{
                    
                }
                
            }
            
        case 2:
            
            playerOneChoice = "Scissor"
            
            selectedHand.text = "Your choice: \(playerOneChoice)"
            
            if let playerChoice: Data = playerOneChoice.data(using: String.Encoding.utf8){
                
                do{
                    try session.send(playerChoice, toPeers: session.connectedPeers, with: .reliable)
                }
                catch{
                    
                }
                
            }
            
        default:
            playerOneChoice = "None"
            selectedHand.text = "Your choice: \(playerOneChoice)"
            // Player did not select
            
        }
    }
    
    
    //Set player as "Ready"
    @IBAction func playerReadyBtn(_ sender: UIButton) {
        
        
        if playerOneReady == false {
            playerOneReady = true
            readyOutlet.setTitle("Ready", for: .normal)
        }
        else if playerOneReady == true{
            playerOneReady = false
            readyOutlet.setTitle("Not Ready", for: .normal)
        }
        
        
        if let playerChoice: NSData = NSKeyedArchiver.archivedData(withRootObject: playerOneReady) as NSData?{
            
            do{
                try session.send(playerChoice as Data, toPeers: session.connectedPeers, with: .reliable)
            }
            catch{
                
            }
            
        }
        
        //If both player are ready start the game
        if playerOneReady == true && playerTwoReady == true{
        readyOutlet.isHidden = true
        mainTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.countDown), userInfo: nil, repeats: true)
        }
        
    }
    
    //Func that starts the round
    func roundStart(){
        
        //Set Player One's image
        switch playerOneChoice {
        case "Rock":
            playerOneImage.image = #imageLiteral(resourceName: "Rock_Image_Purple")
        case "Paper":
            playerOneImage.image = #imageLiteral(resourceName: "Paper_Image_Purple")
        case "Scissor":
            playerOneImage.image = #imageLiteral(resourceName: "Scissors_Images_Purple")
        default:
            playerOneImage.image = #imageLiteral(resourceName: "QuestionMark_Image_Purple")
        }
        //Set Player Two's image
        switch playerTwoChoice {
        case "Rock":
            playerTwoImage.image = #imageLiteral(resourceName: "Rock_Image_Purple")
        case "Paper":
            playerTwoImage.image = #imageLiteral(resourceName: "Paper_Image_Purple")
        case "Scissor":
            playerTwoImage.image = #imageLiteral(resourceName: "Scissors_Images_Purple")
        default:
            playerTwoImage.image = #imageLiteral(resourceName: "QuestionMark_Image_Purple")
        }
        
        
        //Win Conditions
        
        //if its a draw
        if playerOneChoice == playerTwoChoice{
            winner = "It's A Draw!"
        }
        
            //If staements if the opponent wins
        else if playerOneChoice == "Rock" && playerTwoChoice == "Paper"{winner = "You Lose";playerTwoScore += 1}
            
        else if playerOneChoice == "Scissor" &&  playerTwoChoice == "Rock"{winner = "You Lose";playerTwoScore += 1}
            
        else if playerOneChoice == "Paper" && playerTwoChoice ==  "Scissor"{winner = "You Lose";playerTwoScore += 1}
            
        else if playerOneChoice == "None"{winner = "You Lose"; playerTwoScore += 1}
         
            
           //If staements if the user wins
        else if playerTwoChoice == "None"{winner = "You Win"; playerOneScore += 1}
            
        else {
            winner = "You Win"
            playerOneScore += 1
        }
        
        //Timer for reviewing the results
        miscTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ViewController.resetAll), userInfo: nil, repeats: false)
        scoreLabel.text = "\(playerOneScore)-\(playerTwoScore)"
    }
    
    //Func to start the count down
    func countDown(){
        
        //when the counter hits 0 start the round
        if countdownSeconds == 0{
            gameView.isUserInteractionEnabled = false
            roundStart()
            mainTimer.invalidate()
            timerOutlet.text = winner
        }
        else{
            timerOutlet.text =  "\(countdownSeconds)"
        }
        
        countdownSeconds -= 1
        
    }
    
    //Reset all var's to default
    func resetAll(){
        countdownSeconds = 3
        playerOneReady = false
        playerTwoReady = false
        readyOutlet.setTitle("Not Ready", for: .normal)
        playerTwoChoice = "None"
        playerOneChoice = "None"
        playerOneImage.image = #imageLiteral(resourceName: "Player1_Image_Purple")
        playerTwoImage.image = #imageLiteral(resourceName: "Player2_Image_Purple")
        timerOutlet.text = "Waiting for Players"
        readyOutlet.isHidden = false
        selectedHand.text = "Your choice: None"
        gameView.isUserInteractionEnabled = true
    }
    
    @IBAction func Exit(_ sender: UIButton) {
        
        
        self.gameView.isHidden = true
        self.playerTwoScore = 0
        self.playerOneScore = 0
        self.resetAll()
        self.statusLabel.text = ""
        session.disconnect()
        userExit = true
    }
}

