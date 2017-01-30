//
//  FirstViewController.swift
//  iLight
//
//  Created by Joris Huizinga on 10/12/2016.
//  Copyright © 2016 Joris Huizinga. All rights reserved.
//

import UIKit;
import CoreLocation;
import HomeKit;

class FirstViewController: UIViewController, CLLocationManagerDelegate, HMHomeManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    let homeManager = HMHomeManager();
    let locationManager = CLLocationManager();
    var beaconsInProximity: [CLBeacon] = [];
    let beaconUUID: String = "11984894-7042-9801-839A-ADECCDFEDFF0";
    let beaconMajor = 0x1;
    let beaconMinor: [Int] = [0x1, 0x7];
    let homeName = "iLight";
    var lamps = [HMAccessory]();
    var lampNames = [String]();
    var pickerNames = [String: HMAccessory]();
    var selectedLamp: HMAccessory!;
    var lightHome: HMHome!;
    var firstLight: HMAccessory!;
    var secondLight: HMAccessory!;
    var thirdTestLight: HMAccessory!;
    let beaconRegion: CLBeaconRegion = CLBeaconRegion(proximityUUID: NSUUID(uuidString:"11984894-7042-9801-839A-ADECCDFEDFF0")as! UUID, identifier: "Beaconons");
    
    @IBOutlet weak var lampSwitch: UISwitch!
    @IBOutlet weak var configureLampButton: UIButton!
    @IBOutlet weak var lampPicker: UIPickerView!
    @IBOutlet weak var identifyLampButton: UIButton!
    @IBOutlet weak var lampSelectedLabel: UILabel!
    @IBOutlet weak var lampStatusLabel: UILabel!
    @IBOutlet weak var beaconStatusLabel: UILabel!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if(selectedLamp != nil){
            updateLampLabel(selectedLamp);
            updateLampStatusLabel(selectedLamp);
        }else{
            updateLampLabelNoLamp();
            updateLampStatusLabelNoStatus();
        }
        homeManager.delegate = self;
        lampPicker.delegate = self;
        lampPicker.dataSource = self;
        locationManager.delegate = self;
        locationManager.requestAlwaysAuthorization();
        locationManager.startMonitoring(for: beaconRegion);
        locationManager.startRangingBeacons(in: beaconRegion);
        locationManager.requestState(for: beaconRegion);
    }

    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        for home in homeManager.homes{
            for accessory in home.accessories{
                if(accessory.name.contains("lamp")){
                    lamps.append(accessory);
                    pickerNames[String(describing: accessory.services[1].characteristics[0].value)] = accessory;
                    print("Added accessory " + String(describing: accessory.services[1].characteristics[0].value) + " to lamp list");
                }
            }
        }
        if(lamps.count != 0){
            for index in 0...(lamps.count - 1){
                lampNames.append(String(describing: lamps[index].services[1].characteristics[0].value));
            }
        }
    }
    
    func locationManager(_: CLLocationManager, didRangeBeacons: [CLBeacon], in: CLBeaconRegion){
        for beacon in didRangeBeacons{
            if(beacon.proximity == CLProximity.immediate){
                beaconsInProximity.append(beacon);
            }else{
                if(beaconsInProximity.contains(beacon)){
                    for index in 0...beaconsInProximity.count{
                        if(beaconsInProximity[index] == beacon){
                            beaconsInProximity.remove(at: index);
                        }
                    }
                }
            }
        }
        for beacon in beaconsInProximity{
            if(beacon.major.intValue == beaconMajor){
                if(beacon.minor.intValue == 0x3){
                    if(selectedLamp != nil){
                        switchLamp(selectedLamp, true);
                        beaconStatusLabel.text = "region detected";
                    }
                }else{
                    if(selectedLamp != nil){
                        switchLamp(selectedLamp, false);
                        beaconStatusLabel.text = "lamping all the lamps that have ever lamped";
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let bRegion = region as! CLBeaconRegion;
        if(bRegion.proximityUUID == beaconRegion.proximityUUID){
            print("Correct region");
            beaconStatusLabel.text = "Entered beacon region";
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let bRegion = region as! CLBeaconRegion;
        if(bRegion.proximityUUID == beaconRegion.proximityUUID){
            print("Exited correct region");
            beaconStatusLabel.text = "Beacon region left";
        }
    }
    
    @IBAction func configureLampButtonPressed(_ sender: AnyObject){
        if(pickerNames[lampNames[lampPicker.selectedRow(inComponent: 0)]] != nil){
            selectedLamp = pickerNames[lampNames[lampPicker.selectedRow(inComponent: 0)]];
        }
        if(selectedLamp != nil){
            updateLampLabel(selectedLamp);
            updateLampStatusLabel(selectedLamp);
        }else{
            updateLampLabelNoLamp();
            updateLampStatusLabelNoStatus();
        }
        
    }
    
    @IBAction func identifyLampButtonPressed(_ sender: AnyObject){
        if(selectedLamp != nil){
            identifyLamp(selectedLamp);
        }
    }
    
    @IBAction func lampSwitchFlipped(_ sender: AnyObject){
        if(selectedLamp != nil){
            switchLamp(selectedLamp, lampSwitch.isOn);
            updateLampStatusLabel(selectedLamp);
        }else{
            lampSwitch.setOn(!lampSwitch.isOn, animated: true);
            updateLampStatusLabelNoStatus();
        }
    }
    
    func updateLampLabelNoLamp(){
        lampSelectedLabel.text = "No lamp selected";
    }
    
    func updateLampLabel(_ lamp: HMAccessory){
        lampSelectedLabel.text = "Selected lamp: " + lamp.name;
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return lampNames.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        return lampNames[row];
    }
    
    func booleanToInt(_ value: Bool) -> Int{
        if(value){
            return 1;
        }else{
            return 0;
        }
    }
    
    func sendLocalNotificationWithMessage(_ message: String!){
        
    }
    
    func switchLamp(_ lamp: HMAccessory, _ value: Bool){
        lamp.services[1].characteristics[1].writeValue(booleanToInt(value), completionHandler: {
            error in
            if let error = error{
                print("Something went wrong! \(error)");
            }
        })
    }
    
    func identifyLamp(_ lamp: HMAccessory){
        lamp.services[0].characteristics[3].writeValue(1, completionHandler: {
            error in
            if let error = error{
                print("Something went wrong! \(error)");
            }
        })
    }
    
    func updateLampStatusLabel(_ lamp: HMAccessory){
        lampStatusLabel.text = "Lamp status: " + String(describing: selectedLamp.services[1].characteristics[1].value);
    }
    
    func updateLampStatusLabelNoStatus(){
        lampStatusLabel.text = "Select a lamp";
    }
}

