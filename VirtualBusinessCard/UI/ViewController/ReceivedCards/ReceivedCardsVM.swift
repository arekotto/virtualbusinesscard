//
//  ReceivedCardsVM.swift
//  VirtualBusinessCard
//
//  Created by Arek Otto on 15/06/2020.
//  Copyright © 2020 Arek Otto. All rights reserved.
//

import Firebase
import CoreMotion
import UIKit

protocol ReceivedBusinessCardsVMDelegate: class {
    func refreshData(animated: Bool)
    func refreshLayout(style: CardFrontBackView.Style)
    func didUpdateMotionData(_ motion: CMDeviceMotion, over timeFrame: TimeInterval)
}

final class ReceivedCardsVM: PartialUserViewModel, MotionDataSource {

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ReceivedCardsView.CollectionCell.DataModel>

    weak var delegate: ReceivedBusinessCardsVMDelegate?

    var presentedIndexPath: IndexPath?

    private(set) lazy var motionManager = CMMotionManager()

    private(set) var cellStyle = CardFrontBackView.Style.expanded
    private(set) lazy var selectedSortMode = sortActions.first!.mode

    let title: String
    let dataFetchMode: DataFetchMode

    private var user: UserMC?
    private var cards = [ReceivedBusinessCardMC]()
    private var displayedCardIndexes = [Int]()
    
    private let sortActions = defaultSortActions()

    init(userID: UserID, title: String, dataFetchMode: DataFetchMode) {
        self.title = title
        self.dataFetchMode = dataFetchMode
        super.init(userID: userID)
    }

    func didReceiveMotionData(_ motion: CMDeviceMotion, over timeFrame: TimeInterval) {
        delegate?.didUpdateMotionData(motion, over: timeFrame)
    }
}

// MARK: - ViewController API

extension ReceivedCardsVM {
    
    var cellSizeControlImage: UIImage {
        let imgConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        switch cellStyle {
        case .compact:
            return UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: imgConfig)!
        case .expanded:
            return UIImage(systemName: "arrow.down.right.and.arrow.up.left", withConfiguration: imgConfig)!
        }
    }
    
    var sortControlImage: UIImage {
        let imgConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        return UIImage(systemName: "arrow.up.arrow.down", withConfiguration: imgConfig)!
    }

    func startUpdatingMotionData() {
        startUpdatingMotionData(in: cellStyle.motionDataUpdateInterval)
    }
    
    func dataSnapshot() -> Snapshot {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(displayedCardIndexes.map { cellViewModel(for: cards[$0].displayedLocalization, withNumber: $0) })
        return snapshot
    }

    func detailsViewModel(for indexPath: IndexPath) -> CardDetailsVM {
        let card = cards[displayedCardIndexes[indexPath.item]]
        let prefetchedDM = CardDetailsVM.PrefetchedData(
            dataModel: sceneViewModel(for: card.displayedLocalization),
            hapticSharpness: card.displayedLocalization.hapticFeedbackSharpness
        )
        return CardDetailsVM(userID: userID, cardID: card.id, initialLoadDataModel: prefetchedDM)
    }
    
    func toggleCellSizeMode() {
        switch cellStyle {
        case .compact:
            cellStyle = .expanded
            startUpdatingMotionData(in: 0.1)
        case .expanded:
            startUpdatingMotionData(in: 0.2)
            cellStyle = .compact
        }
        delegate?.refreshLayout(style: cellStyle)
    }
    
    func beginSearch(for query: String) {
        DispatchQueue.global().async {
            let newDisplayedCardIndexes: [Int]
            if query.isEmpty {
                newDisplayedCardIndexes = Array(0 ..< self.cards.count)
            } else {
                newDisplayedCardIndexes = self.cards.enumerated()
                    .filter { _, card in Self.shouldDisplayCard(card, forQuery: query) }
                    .map { idx, _ in idx }
            }
            if newDisplayedCardIndexes != self.displayedCardIndexes {
                DispatchQueue.main.async {
                    self.displayedCardIndexes = newDisplayedCardIndexes
                    self.delegate?.refreshData(animated: true)
                }
            }
        }
    }
    
    func sortingAlertControllerDataModel() -> SortingAlertControllerDataModel {
        SortingAlertControllerDataModel(title: NSLocalizedString("Sort cards by:", comment: ""), actions: sortActions)
    }
    
    func setSortMode(_ mode: SortMode) {
        guard sortActions.contains(where: { $0.mode == mode}) else { return }
        selectedSortMode = mode
        DispatchQueue.global().async {
            let newSortedCards = Self.sortCards(self.cards, using: mode)
            DispatchQueue.main.async {
                self.cards = newSortedCards
                self.delegate?.refreshData(animated: true)
            }
        }
    }

    private func cellViewModel(for localization: BusinessCardLocalization, withNumber number: Int) -> ReceivedCardsView.CollectionCell.DataModel {
        ReceivedCardsView.CollectionCell.DataModel(modelNumber: number, sceneDataModel: sceneViewModel(for: localization))
    }

    private func sceneViewModel(for localization: BusinessCardLocalization) -> CardFrontBackView.URLDataModel {
        CardFrontBackView.URLDataModel(
            frontImageURL: localization.frontImage.url,
            backImageURL: localization.backImage.url,
            textureImageURL: localization.texture.image.url,
            normal: CGFloat(localization.texture.normal),
            specular: CGFloat(localization.texture.specular),
            cornerRadiusHeightMultiplier: CGFloat(localization.cornerRadiusHeightMultiplier)
        )
    }
}

// MARK: - Sorting static helpers

extension ReceivedCardsVM {
    
    private static func defaultSortActions() -> [SortAction] {
        return [
            SortAction(mode: SortMode(property: .firstName, direction: .ascending), title: NSLocalizedString("First name - ascending", comment: "")),
            SortAction(mode: SortMode(property: .firstName, direction: .descending), title: NSLocalizedString("First name - descending", comment: "")),
            SortAction(mode: SortMode(property: .lastName, direction: .ascending), title: NSLocalizedString("Last name - ascending", comment: "")),
            SortAction(mode: SortMode(property: .lastName, direction: .descending), title: NSLocalizedString("Last name - descending", comment: "")),
            SortAction(mode: SortMode(property: .receivingDate, direction: .ascending), title: NSLocalizedString("Receiving date - ascending", comment: "")),
            SortAction(mode: SortMode(property: .receivingDate, direction: .descending), title: NSLocalizedString("Receiving date - descending", comment: ""))
        ]
    }
    
    private static func sortCards(_ cards: [ReceivedBusinessCardMC], using mode: SortMode) -> [ReceivedBusinessCardMC] {
        switch mode.property {
        case .firstName:
            switch mode.direction {
            case .ascending: return cards.sorted(by: Self.cardSorterFirstNameAscending)
            case .descending: return cards.sorted(by: Self.cardSorterFirstNameDescending)
            }
        case .lastName:
            switch mode.direction {
            case .ascending: return cards.sorted(by: Self.cardSorterLastNameAscending)
            case .descending: return cards.sorted(by: Self.cardSorterLastNameDescending)
            }
        case .receivingDate:
            switch mode.direction {
            case .ascending: return cards.sorted(by: Self.cardSorterDateAscending)
            case .descending: return cards.sorted(by: Self.cardSorterDateDescending)
            }
        }
    }
    
    private static func cardSorterFirstNameAscending(_ lhs: ReceivedBusinessCardMC, _ rhs: ReceivedBusinessCardMC) -> Bool {
        (lhs.displayedLocalization.name.first ?? "") <= (rhs.displayedLocalization.name.first ?? "")
    }
    
    private static func cardSorterFirstNameDescending(_ lhs: ReceivedBusinessCardMC, _ rhs: ReceivedBusinessCardMC) -> Bool {
        (lhs.displayedLocalization.name.first ?? "") >= (rhs.displayedLocalization.name.first ?? "")
    }
    
    private static func cardSorterLastNameAscending(_ lhs: ReceivedBusinessCardMC, _ rhs: ReceivedBusinessCardMC) -> Bool {
        (lhs.displayedLocalization.name.last ?? "") <= (rhs.displayedLocalization.name.last ?? "")
    }
    
    private static func cardSorterLastNameDescending(_ lhs: ReceivedBusinessCardMC, _ rhs: ReceivedBusinessCardMC) -> Bool {
        (lhs.displayedLocalization.name.last ?? "") >= (rhs.displayedLocalization.name.last ?? "")
    }
    
    private static func cardSorterDateAscending(_ lhs: ReceivedBusinessCardMC, _ rhs: ReceivedBusinessCardMC) -> Bool {
        lhs.receivingDate <= rhs.receivingDate
    }
    
    private static func cardSorterDateDescending(_ lhs: ReceivedBusinessCardMC, _ rhs: ReceivedBusinessCardMC) -> Bool {
        lhs.receivingDate >= rhs.receivingDate
    }
}

// MARK: - Firebase static helpers

extension ReceivedCardsVM {
    
    private static func mapAllCards(from querySnap: QuerySnapshot) -> [ReceivedBusinessCardMC] {
        querySnap.documents.compactMap {
            guard let bc = ReceivedBusinessCard(queryDocumentSnapshot: $0) else {
                print(#file, "Error mapping business card:", $0.documentID)
                return nil
            }
            return ReceivedBusinessCardMC(card: bc)
        }
    }
    
    private static func mapCards(from querySnap: QuerySnapshot, containedIn ids: [BusinessCardID]) -> [ReceivedBusinessCardMC] {
        var idsDict = [String: Bool]()
        ids.forEach { idsDict[$0] = true }
        
        return querySnap.documents.compactMap {
            
            guard idsDict[$0.documentID] == true else { return nil }
            
            guard let bc = ReceivedBusinessCard(queryDocumentSnapshot: $0) else {
                print(#file, "Error mapping business card:", $0.documentID)
                return nil
            }
            return ReceivedBusinessCardMC(card: bc)
        }
    }
    
    private static func shouldDisplayCard(_ card: ReceivedBusinessCardMC, forQuery query: String) -> Bool {
        let name = card.displayedLocalization.name
        let names = [name.first ?? "", name.last ?? "", name.middle ?? "" ]
        return names.contains(where: { $0.contains(query) })
    }
}

// MARK: - Section

extension ReceivedCardsVM {
    enum Section {
        case main
    }
}

// MARK: - Firebase fetch

extension ReceivedCardsVM {
    private var receivedCardsCollectionReference: CollectionReference {
        userPublicDocumentReference.collection(ReceivedBusinessCard.collectionName)
    }
    
    func fetchData() {
        receivedCardsCollectionReference.addSnapshotListener { [weak self] querySnapshot, error in
            self?.receivedCardsCollectionDidChange(querySnapshot: querySnapshot, error: error)
        }
    }
    
    private func receivedCardsCollectionDidChange(querySnapshot: QuerySnapshot?, error: Error?) {
        guard let querySnap = querySnapshot else {
            print(#file, error?.localizedDescription ?? "")
            return
        }
        
        DispatchQueue.global().async {
            
            let newCardsSorted = self.mapAndSortCards(querySnapshot: querySnap)
            
            DispatchQueue.main.async {
                self.cards = newCardsSorted
                self.displayedCardIndexes = Array(0 ..< newCardsSorted.count)
                self.delegate?.refreshData(animated: false)
            }
        }
    }
    
    private func mapAndSortCards(querySnapshot: QuerySnapshot) -> [ReceivedBusinessCardMC] {
        let newCards: [ReceivedBusinessCardMC]
        switch self.dataFetchMode {
        case .allReceivedCards: newCards = Self.mapAllCards(from: querySnapshot)
        case .specifiedIDs(let ids): newCards = Self.mapCards(from: querySnapshot, containedIn: ids)
        }
        return Self.sortCards(newCards, using: self.selectedSortMode)
    }
}

// MARK: - DataFetchMode

extension ReceivedCardsVM {    
    enum DataFetchMode {
        case allReceivedCards
        case specifiedIDs(_ ids: [BusinessCardID])
    }
}

// MARK: - Sorting

extension ReceivedCardsVM {
    
    struct SortingAlertControllerDataModel {
        let title: String
        let actions: [SortAction]
    }
    
    struct SortMode: Equatable {
        let property: Property
        let direction: Direction
    }
    
    struct SortAction {
        let mode: SortMode
        let title: String
    }
    
}

extension ReceivedCardsVM.SortMode {
    enum Property {
        case firstName, lastName, receivingDate
    }

    enum Direction {
        case ascending, descending
    }
}

private extension CardFrontBackView.Style {
    var motionDataUpdateInterval: TimeInterval {
        switch self {
        case .compact: return 0.1
        case .expanded: return 0.2
        }
    }
}
