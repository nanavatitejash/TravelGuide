//
//  SearchTrainInteractor.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import Foundation
import XMLParsing
//import Alamofire

class SearchTrainInteractor: PresenterToInteractorProtocol {
    func showInvalidSourceOrDestinationAlert() {
        self.presenter!.showInvalidSourceOrDestinationAlert()
    }
    
    var _sourceStationCode = String()
    var _destinationStationCode = String()
    var presenter: InteractorToPresenterProtocol?
    
    func fetchallStations() {
        if Reach().isNetworkReachable() == true {
            
            let urlString = "http://api.irishrail.ie/realtime/realtime.asmx/getAllStationsXML"
            
            URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
                if let data = data{
                    let station = try? XMLDecoder().decode(Stations.self, from: data)
                    DispatchQueue.main.async {
                        self.presenter!.stationListFetched(list: station!.stationsList)
                        
                    }
                }
                
            }.resume()
            
            
        } else {
            DispatchQueue.main.async {
                self.presenter!.showNoInterNetAvailabilityMessage()
                
            }
            
        }
    }
    
    func fetchTrainsFromSource(sourceCode: String, destinationCode: String) {
        _sourceStationCode = sourceCode
        _destinationStationCode = destinationCode
        let urlString = "http://api.irishrail.ie/realtime/realtime.asmx/getStationDataByCodeXML?StationCode=\(sourceCode)"
        if Reach().isNetworkReachable() {
            
            URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
                if let data = data{
                    let stationData = try? XMLDecoder().decode(StationData.self, from: data)
                    if let _trainsList = stationData?.trainsList {
                        self.proceesTrainListforDestinationCheck(trainsList: _trainsList)
                    } else {
                        DispatchQueue.main.async {
                            self.presenter!.showNoTrainAvailbilityFromSource()
                        }
                    }
                }
                if let _ = error {
                    DispatchQueue.main.async {
                        
                        self.presenter!.showInvalidSourceOrDestinationAlert()
                    }
                }
                
            }.resume()
            
            
            
        } else {
            DispatchQueue.main.async {
                self.presenter!.showNoInterNetAvailabilityMessage()
                
            }
        }
    }
    
    private func proceesTrainListforDestinationCheck(trainsList: [StationTrain]) {
        var _trainsList = trainsList
        
        let group = DispatchGroup()
        
        for index  in 0...trainsList.count-1 {
            group.enter()
            let dateStr = trainsList[index].trainDate
            
            let _urlString = "http://api.irishrail.ie/realtime/realtime.asmx/getTrainMovementsXML?TrainId=\(trainsList[index].trainCode)&TrainDate=\(String(describing: dateStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!))"
            print(_urlString)
            if Reach().isNetworkReachable() {
                URLSession.shared.dataTask(with: URL(string: _urlString)!) { (data, response, error) in
                    if let  data = data{
                        let trainMovements = try? XMLDecoder().decode(TrainMovementsData.self, from: data)
                        
                        if let _movements = trainMovements?.trainMovements {
                            let sourceIndex = _movements.firstIndex(where: {$0.locationCode.caseInsensitiveCompare(self._sourceStationCode) == .orderedSame})
                            let destinationIndex = _movements.firstIndex(where: {$0.locationCode.caseInsensitiveCompare(self._destinationStationCode) == .orderedSame})
                            let desiredStationMoment = _movements.filter{$0.locationCode.caseInsensitiveCompare(self._destinationStationCode) == .orderedSame}
                            let isDestinationAvailable = desiredStationMoment.count == 1
                            
                            if isDestinationAvailable  && sourceIndex! < destinationIndex! {
                                _trainsList[index].destinationDetails = desiredStationMoment.first
                            }
                        }
                        if let _ = error {
                            DispatchQueue.main.async {
                                self.presenter!.showInvalidSourceOrDestinationAlert()
                            }
                        }
                        group.leave()
                    }
                    
                }.resume()
                
                
            } else {
                DispatchQueue.main.async {
                    self.presenter!.showNoInterNetAvailabilityMessage()
                    
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            let sourceToDestinationTrains = _trainsList.filter{$0.destinationDetails != nil}
            self.presenter!.fetchedTrainsList(trainsList: sourceToDestinationTrains)
        }
    }
}
