//
//  SearchTrainPresenterTests.swift
//  MyTravelHelperTests
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import XCTest
@testable import MyTravelHelper

class SearchTrainPresenterTests: XCTestCase {
    var presenter: SearchTrainPresenter!
    var view = SearchTrainMockView()
    var interactor = SearchTrainInteractorMock()
    
    override func setUp() {
        presenter = SearchTrainPresenter()
        presenter.view = view
        presenter.interactor = interactor
        interactor.presenter = presenter
    }
    
    func testfetchallStations() {
        presenter.fetchallStations()
        
        XCTAssertTrue(view.isSaveFetchedStatinsCalled)
    }
    
    func testsourceanddestination() {
        presenter.fetchTrainsFromSource(sourceCode: "cock", destinationCode: "hston")
        XCTAssertTrue(view.isUpdateLatestTrainList)
    }
    
    func testshowinvalidsourceordestinationalert(){
        presenter?.showInvalidSourceDestinationAlert()
        XCTAssertTrue(view.isShowInvalidSourceOrDestinationAlert)
    }
    
    
    
    func testfetchedtrainsList_nil() {
           presenter.fetchedTrainsList(trainsList: nil)
           XCTAssertTrue(view.isshowNoTrainsFoundAlert)
    }
    
    
    func testshownotrainavailbilityfromsource() {
        presenter.showNoTrainAvailbilityFromSource()
        XCTAssertTrue(view.isshowNoTrainAvailbilityFromSource)
    }
    
    
    func testshownointernetavailabilitymessage() {
           presenter.showNoInterNetAvailabilityMessage()
           XCTAssertTrue(view.isshowNoInterNetAvailabilityMessage)
       }
    
    override func tearDown() {
        presenter = nil
    }
}


class SearchTrainMockView:PresenterToViewProtocol {
    func saveFetchedStations(stations: [Station]?) {
        isSaveFetchedStatinsCalled = true
    }
    
    var isSaveFetchedStatinsCalled = false
    var isUpdateLatestTrainList = false
    var isShowInvalidSourceOrDestinationAlert = false
    var isshowNoTrainsFoundAlert = false
    var isshowNoTrainAvailbilityFromSource = false
    var isshowNoInterNetAvailabilityMessage = false
    
    func showInvalidSourceOrDestinationAlert() {
        isShowInvalidSourceOrDestinationAlert = true
    }
    
    func updateLatestTrainList(trainsList: [StationTrain]) {
        isUpdateLatestTrainList = true
    }
    
    func showNoTrainsFoundAlert() {
        isshowNoTrainsFoundAlert =  true
    }
    
    
    
    func showNoTrainAvailbilityFromSource() {
        isshowNoTrainAvailbilityFromSource = true
    }
    
    func showNoInterNetAvailabilityMessage() {
        isshowNoInterNetAvailabilityMessage = true
    }
}

class SearchTrainInteractorMock:PresenterToInteractorProtocol {
    func showInvalidSourceOrDestinationAlert() {
        presenter?.showInvalidSourceOrDestinationAlert()
    }
    
    func showNoTrainsFoundAlert(){
        presenter?.showNoTrainAvailbilityFromSource()
    }
    
    var presenter: InteractorToPresenterProtocol?
    
    func fetchallStations() {
        let station = Station(desc: "Belfast Central", latitude: 54.6123, longitude: -5.91744, code: "BFSTC", stationId: 228)
        presenter?.stationListFetched(list: [station])
    }
    
    func fetchTrainsFromSource(sourceCode: String, destinationCode: String) {
        let train = StationTrain(trainCode: "D257", fullName: "Cork", stationCode: "CORk", trainDate: "07 Jul 2020", dueIn: 23, lateBy: 0, expArrival: "00:00", expDeparture: "20:00")
        
        presenter?.fetchedTrainsList(trainsList: [train])
        
    }
}
