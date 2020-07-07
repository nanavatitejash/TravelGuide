//
//  SearchTrainViewController.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import UIKit
import SwiftSpinner
import DropDown

class SearchTrainViewController: UIViewController {
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var sourceTxtField: UITextField!
    @IBOutlet weak var trainsListTable: UITableView!

    var stationsList:[Station] = [Station]()
    var trains:[StationTrain] = [StationTrain]()
    var presenter:ViewToPresenterProtocol?
    var dropDown = DropDown()
    var transitPoints:(source:String,destination:String) = ("","")
    var fav = [Int:String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        trainsListTable.isHidden = true
        trainsListTable.tableFooterView = UIView()
         trainsListTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.trainsListTable.allowsMultipleSelectionDuringEditing = false

        self.checkForFavourite()
        



    }
    
    func checkForFavourite(){
        let favourite = UserDefaults.standard.object([Int: String].self, with: "fav")
        self.fav = favourite ?? [:]
        if self.fav.count > 0{
            trainsListTable.isHidden = false
            trainsListTable.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if stationsList.count == 0 {
            SwiftSpinner.useContainerView(view)
            SwiftSpinner.show("Please wait loading station list ....")
            presenter?.fetchallStations()
        }
    }
    
   

    @IBAction func searchTrainsTapped(_ sender: Any) {
        view.endEditing(true)
        showProgressIndicator(view: self.view)
        presenter?.searchTapped(source: transitPoints.source, destination: transitPoints.destination)
    }
}

extension SearchTrainViewController:PresenterToViewProtocol {
    func selectFav(station: String) {
    }
    
    func showNoInterNetAvailabilityMessage() {
        trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        showAlert(title: "No Internet", message: "Please Check you internet connection and try again", actionTitle: "Okay")
    }

    func showNoTrainAvailbilityFromSource() {
        //trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        showAlert(title: "No Trains", message: "Sorry No trains arriving source station in another 90 mins", actionTitle: "Okay")
    }

    func updateLatestTrainList(trainsList: [StationTrain]) {
        hideProgressIndicator(view: self.view)
        trains = trainsList
        trainsListTable.isHidden = false
        trainsListTable.reloadData()
    }

    func showNoTrainsFoundAlert() {
       // trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        showAlert(title: "No Trains", message: "Sorry No trains Found from source to destination in another 90 mins", actionTitle: "Okay")
    }

    func showAlert(title:String,message:String,actionTitle:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func showAlertFavourite(title:String,message:String,actionTitle:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Source", style: .default, handler: { (action) in
            self.transitPoints.source = title
            self.sourceTxtField.text = title
        }))

        alert.addAction(UIAlertAction(title: "Destination", style: .default, handler: { (action) in
            self.transitPoints.destination = title
            self.destinationTextField.text = title
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))

        

        self.present(alert, animated: true, completion: nil)
    }

    func showInvalidSourceOrDestinationAlert() {
        trainsListTable.isHidden = true
        hideProgressIndicator(view: self.view)
        showAlert(title: "Invalid Source/Destination", message: "Invalid Source or Destination Station names Please Check", actionTitle: "Okay")
    }

    func saveFetchedStations(stations: [Station]?) {
        if let _stations = stations {
          self.stationsList = _stations
        }
        SwiftSpinner.hide()
    }
}

extension SearchTrainViewController:UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        dropDown = DropDown()
        dropDown.anchorView = textField
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.dataSource =  stationsList.map {$0.stationDesc}
        dropDown.selectionAction = { (index: Int, item: String) in
            if textField == self.sourceTxtField {
                self.transitPoints.source = item

            }else {
                self.transitPoints.destination = item
            }

            
            self.fav[index] = item
            
            UserDefaults.standard.set(object: self.fav, forKey: "fav")
            textField.text = item

            self.trainsListTable.isHidden = false
            self.trainsListTable.reloadData()
            
        }
        dropDown.show()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dropDown.hide()
        return textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let inputedText = textField.text {
            var desiredSearchText = inputedText
            if string != "\n" && !string.isEmpty{
                desiredSearchText = desiredSearchText + string
            }else {
                desiredSearchText = String(desiredSearchText.dropLast())
            }

            
            let stations = stationsList.map{$0.stationDesc}

            
            dropDown.dataSource = stations
            dropDown.show()
            dropDown.reloadAllComponents()
        }
        return true
    }
}

extension SearchTrainViewController:UITableViewDataSource,UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.fav.count > 0{
            if self.trains.count > 0{
                return 2
            }else{
                return 1
            }
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "Favourite"
        } else {
            return "Trains"
        }
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if indexPath.section == 0{
            let delete = UITableViewRowAction(style: .destructive, title: "delete") { (action, indexPath) in
                // delete item at indexPath
                var arrayFromDic = Array(self.fav.values.map{ $0 })
                
                arrayFromDic.remove(at: indexPath.row)

                

                self.trainsListTable.reloadData()

            }
            return [delete]
        }
        return []
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.fav.count > 0{
            if section == 0{
                return self.fav.count
            } else if section == 1{
                if self.trains.count > 0{
                    return self.trains.count
                }
            }
        }
        return trains.count
    }
    
    private func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //return true

        if indexPath.section == 0{
            return true
        } else {
            return false
        }
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    private func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCell.EditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            self.fav[indexPath.row] = ""
            self.trainsListTable.reloadData()
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.fav.count > 0{
            if indexPath.section == 0{
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as
                UITableViewCell
                let arrayFromDic = Array(self.fav.values.map{ $0 })

                cell.textLabel?.text = arrayFromDic[indexPath.row]
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "train", for: indexPath) as! TrainInfoCell
                       let train = trains[indexPath.row]
                       cell.trainCode.text = train.trainCode
                       cell.souceInfoLabel.text = train.stationFullName
                       cell.sourceTimeLabel.text = train.expDeparture
                       if let _destinationDetails = train.destinationDetails {
                           cell.destinationInfoLabel.text = _destinationDetails.locationFullName
                           cell.destinationTimeLabel.text = _destinationDetails.expDeparture
                       }
                       return cell
            }
        }
        
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "train", for: indexPath) as! TrainInfoCell
        let train = trains[indexPath.row]
        cell.trainCode.text = train.trainCode
        cell.souceInfoLabel.text = train.stationFullName
        cell.sourceTimeLabel.text = train.expDeparture
        if let _destinationDetails = train.destinationDetails {
            cell.destinationInfoLabel.text = _destinationDetails.locationFullName
            cell.destinationTimeLabel.text = _destinationDetails.expDeparture
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.fav.count > 0{
            if indexPath.section == 0{
                return 44
            } else {
                return 140
            }
        }
        return 140
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.fav.count > 0{
            if indexPath.section == 0{
                let arrayFromDic = Array(self.fav.values.map{ $0 })
                showAlertFavourite(title: arrayFromDic[indexPath.row], message: "Select \(arrayFromDic[indexPath.row]) as source or destination", actionTitle: "Okay")

            }
        }
    }
}


extension UserDefaults {
    func object<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = self.value(forKey: key) as? Data else { return nil }
        return try? decoder.decode(type.self, from: data)
    }

    func set<T: Codable>(object: T, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
        let data = try? encoder.encode(object)
        self.set(data, forKey: key)
    }
}

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}
