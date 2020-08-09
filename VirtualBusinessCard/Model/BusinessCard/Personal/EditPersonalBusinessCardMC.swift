//
//  EditPersonalBusinessCardMC.swift
//  VirtualBusinessCard
//
//  Created by Arek Otto on 03/08/2020.
//  Copyright © 2020 Arek Otto. All rights reserved.
//

import Firebase

class EditPersonalBusinessCardMC {

    private static let unsavedObjectID = ""
    private static let unsavedImageID = ""
    private static let unsavedImageURL = URL(string: "0")!

    let storage = Storage.storage().reference()
    let userID: UserID
    let editedCardDataID: UUID

    private var card: PersonalBusinessCard

    var cardID: String { card.id }

    var editedCardData: BusinessCardData {
        get {
            guard let editedCardData = card.languageVersions.first(where: { $0.id == editedCardDataID }) else {
                fatalError("The card \(cardID) does not contain a language version with id \(editedCardDataID)")
            }
            return editedCardData
        }
        set {
            guard let editedCardDataIndex = card.languageVersions.firstIndex(where: { $0.id == editedCardDataID }) else {
                fatalError("The card \(cardID) does not contain a language version with id \(editedCardDataID)")
            }
            card.languageVersions[editedCardDataIndex] = newValue
        }
    }

    var cornerRadiusHeightMultiplier: Float {
        get { editedCardData.cornerRadiusHeightMultiplier }
        set { editedCardData.cornerRadiusHeightMultiplier = newValue }
    }

    var frontImage: BusinessCardData.Image {
        get { editedCardData.frontImage }
        set { editedCardData.frontImage = newValue }
    }

    var backImage: BusinessCardData.Image {
        get { editedCardData.backImage }
        set { editedCardData.backImage = newValue }
    }
    var texture: BusinessCardData.Texture {
        get { editedCardData.texture }
        set { editedCardData.texture = newValue }
    }

    var position: BusinessCardData.Position {
        get { editedCardData.position }
        set { editedCardData.position = newValue }
    }

    var name: BusinessCardData.Name {
        get { editedCardData.name }
        set { editedCardData.name = newValue }
    }

    var contact: BusinessCardData.Contact {
        get { editedCardData.contact }
        set { editedCardData.contact = newValue }
    }

    var address: BusinessCardData.Address {
        get { editedCardData.address }
        set { editedCardData.address = newValue }
    }

    init(userID: UserID, editedCardDataID: UUID, card: PersonalBusinessCard) {
        self.userID = userID
        self.editedCardDataID = editedCardDataID
        self.card = card
    }
}

extension EditPersonalBusinessCardMC {

    func personalBusinessCardMC() -> PersonalBusinessCardMC {
        PersonalBusinessCardMC(businessCard: card)
    }

    convenience init(userID: UserID) {
        let cardDataID = UUID()
        let cardData = BusinessCardData(
            id: cardDataID,
            frontImage: BusinessCardData.Image(id: Self.unsavedImageID, url: Self.unsavedImageURL),
            backImage: BusinessCardData.Image(id: Self.unsavedImageID, url: Self.unsavedImageURL),
            texture: BusinessCardData.Texture(image: BusinessCardData.Image(id: Self.unsavedImageID, url: Self.unsavedImageURL), specular: 0.5, normal: 0.5),
            position: BusinessCardData.Position(),
            name: BusinessCardData.Name(),
            contact: BusinessCardData.Contact(),
            address: BusinessCardData.Address(),
            hapticFeedbackSharpness: 0.5,
            cornerRadiusHeightMultiplier: 0,
            isDefault: true
        )
        self.init(userID: userID, editedCardDataID: cardDataID, card: PersonalBusinessCard(id: Self.unsavedObjectID, creationDate: Date(), languageVersions: [cardData]))
    }
}

extension EditPersonalBusinessCardMC: Equatable {
    static func == (lhs: EditPersonalBusinessCardMC, rhs: EditPersonalBusinessCardMC) -> Bool {
        lhs.card == rhs.card
    }
}

extension EditPersonalBusinessCardMC {
    var imageStoragePath: String {
        "\(userID)/\(editedCardDataID)"
    }

    var frontImageStoragePath: String? {
        let frontImageID = frontImage.id
        guard frontImageID != Self.unsavedImageID else { return nil }
        return "\(imageStoragePath)/\(frontImageID)"
    }

    var backImageStoragePath: String? {
        let backImageID = backImage.id
        guard backImageID != Self.unsavedImageID else { return nil }
        return "\(imageStoragePath)/\(backImageID)"
    }

    var textureImageStoragePath: String? {
        let textureImageID = texture.image.id
        guard textureImageID != Self.unsavedImageID else { return nil }
        return "\(imageStoragePath)/\(textureImageID)"
    }

    func save(in collectionReference: CollectionReference, completion: ((Result<Void, Error>) -> Void)? = nil) {

        let docRef: DocumentReference
        if card.id == Self.unsavedObjectID {
            docRef = collectionReference.document()
            card.id = docRef.documentID
        } else {
            docRef = collectionReference.document(card.id)
        }

        docRef.setData(card.asDocument()) { error in
            if let err = error {
                print(err.localizedDescription)
                completion?(.failure(err))
            } else {
                completion?(.success(()))
            }
        }
    }
}
