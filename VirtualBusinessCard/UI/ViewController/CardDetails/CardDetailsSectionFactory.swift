//
//  CardDetailsSectionFactory.swift
//  VirtualBusinessCard
//
//  Created by Arek Otto on 03/07/2020.
//  Copyright © 2020 Arek Otto. All rights reserved.
//

import UIKit

struct CardDetailsSectionFactory {
        
    typealias Section = CardDetailsVM.Section
    typealias Item = CardDetailsVM.Item
    typealias Action = CardDetailsVM.Action

    let card: ReceivedBusinessCardMC
    let tags: [BusinessCardTagMC]

    var imageProvider: (_ action: Action) -> UIImage?
    
    func makeRows() -> [Section] {
        let sections: [Section?] = [
            makeCardImagesSection(),
            makeEditableDataSection(),
            makeMetaSection(),
            makePersonalDataSection(),
            makeContactSection(),
            makeAddressSection()
        ]
        return sections.compactMap { $0 }
    }

    private func makeMetaSection() -> Section? {
        let dataModel = TitleValueCollectionCell.DataModel(title: NSLocalizedString("Date Received", comment: ""), value: card.receivingDataFormatted)
        return Section(item: Item(itemNumber: 0, dataModel: .dataCell(dataModel), actions: []))
    }
    
    private func makeCardImagesSection() -> Section? {
        let localization = card.displayedLocalization
        let imagesDataModel = CardFrontBackView.URLDataModel(
            frontImageURL: localization.frontImage.url,
            backImageURL: localization.backImage.url,
            textureImageURL: localization.texture.image.url,
            normal: CGFloat(localization.texture.normal),
            specular: CGFloat(localization.texture.specular),
            cornerRadiusHeightMultiplier: CGFloat(localization.cornerRadiusHeightMultiplier)
        )
        return Section(item: Item(itemNumber: 0, dataModel: .cardImagesCell(imagesDataModel), actions: []))
    }

    private func makeEditableDataSection() -> Section? {

        let hasTags = !tags.isEmpty
        let tagsItem = TitleValueImageCollectionViewCell.DataModel(
            title: NSLocalizedString("Tags", comment: ""),
            value: hasTags ? tags.map(\.title).joined(separator: ",\n") : NSLocalizedString("No tags.", comment: ""),
            primaryImage: imageProvider(.editTags)
        )

        let hasNotes = !card.notes.isEmpty
        let notesItem = TitleValueImageCollectionViewCell.DataModel(
            title: NSLocalizedString("Notes", comment: ""),
            value: hasNotes ? card.notes : NSLocalizedString("No notes.", comment: ""),
            primaryImage: imageProvider(.editNotes)
        )

        let editableData: [(dataModel: TitleValueImageCollectionViewCell.DataModel, actions: [Action])] = [
            (tagsItem, [.editTags]),
            (notesItem, hasNotes ? [.copy, .editNotes] : [.editNotes])
        ]

        return Section(items: editableData.enumerated().map { index, dm in
            Item(itemNumber: index, dataModel: .dataCellImage(dm.dataModel), actions: dm.actions)
        })
    }
    
    private func makePersonalDataSection() -> Section? {
        let personalData = [
            TitleValueCollectionCell.DataModel(title: NSLocalizedString("Name", comment: ""), value: card.ownerDisplayName),
            TitleValueCollectionCell.DataModel(title: NSLocalizedString("Position", comment: ""), value: card.displayedLocalization.position.title),
            TitleValueCollectionCell.DataModel(title: NSLocalizedString("Company", comment: ""), value: card.displayedLocalization.position.company)
        ]
        
        let includedPersonalDataRows = personalData.filter { $0.value ?? "" != "" }
        if includedPersonalDataRows.isEmpty {
            return nil
        }
        return Section(items: includedPersonalDataRows.enumerated().map { index, dm in
            Item(itemNumber: index, dataModel: .dataCell(dm), actions: [.copy])
        })
    }
    
    private func makeContactSection() -> Section? {
        let localization = card.displayedLocalization
        
        let phoneItem = TitleValueImageCollectionViewCell.DataModel(
            title: NSLocalizedString("Phone", comment: ""),
            value: localization.contact.phoneNumberPrimary,
            primaryImage: imageProvider(.call)
        )
        
        let phoneSecondaryItem = TitleValueImageCollectionViewCell.DataModel(
            title: NSLocalizedString("Phone Secondary", comment: ""),
            value: localization.contact.phoneNumberSecondary,
            primaryImage: imageProvider(.call)
        )
        
        let emailItem = TitleValueImageCollectionViewCell.DataModel(
            title: NSLocalizedString("Email", comment: ""),
            value: localization.contact.email,
            primaryImage: imageProvider(.sendEmail)
        )
        
        let websiteItem = TitleValueImageCollectionViewCell.DataModel(
            title: NSLocalizedString("Website", comment: ""),
            value: localization.contact.website,
            primaryImage: imageProvider(.visitWebsite)
        )
        
        let faxItem = TitleValueImageCollectionViewCell.DataModel(
            title: NSLocalizedString("Fax", comment: ""),
            value: localization.contact.fax,
            primaryImage: nil
        )
        
        let contactData: [(dataModel: TitleValueImageCollectionViewCell.DataModel, actions: [Action])] = [
            (phoneItem, [.copy, .call]),
            (phoneSecondaryItem, [.copy, .call]),
            (emailItem, [.copy, .sendEmail]),
            (websiteItem, [.copy, .visitWebsite]),
            (faxItem, [.copy])
        ]
        
        let includedContactDataRows = contactData.filter { $0.dataModel.value ?? "" != "" }
        if includedContactDataRows.isEmpty {
            return nil
        }
        
        return Section(items: includedContactDataRows.enumerated().map { index, dm in
            Item(itemNumber: index, dataModel: .dataCellImage(dm.dataModel), actions: dm.actions)
        })
    }
    
    private func makeAddressSection() -> Section? {
        let address = card.addressFormatted
        if address == "" {
            return nil
        }
        let dm = TitleValueImageCollectionViewCell.DataModel(
            title: NSLocalizedString("Address", comment: ""),
            value: address,
            primaryImage: imageProvider(.navigate)
        )
        return Section(item: Item(itemNumber: 0, dataModel: .dataCellImage(dm), actions: [.copy, .navigate]))
    }
}
