//
//  EditCardPhysicalVM.swift
//  VirtualBusinessCard
//
//  Created by Arek Otto on 01/08/2020.
//  Copyright © 2020 Arek Otto. All rights reserved.
//

import UIKit
import CoreMotion

protocol EditCardPhysicalVMDelegate: class {
    func didUpdateMotionData(_ motion: CMDeviceMotion, over timeFrame: TimeInterval)
}

final class EditCardPhysicalVM: AppViewModel, MotionDataSource {

    private(set) lazy var motionManager = CMMotionManager()

    private var preloadedTextures: [UIImage] = [
        Asset.Images.PrebundledTexture.texture1.image,
        Asset.Images.PrebundledTexture.texture2.image,
        Asset.Images.PrebundledTexture.texture3.image,
        Asset.Images.PrebundledTexture.texture4.image
    ]

    weak var delegate: EditCardPhysicalVMDelegate?

    let images: (cardFront: UIImage, cardBack: UIImage)

    let specularMax: Float = 2
    let normalMax: Float = 2
    let cornerRadiusHeightMultiplierMax: Float = 0.2
    let hapticSharpnessMax: Float = 1

    private(set) var cardProperties: CardPhysicalProperties

    init(frontCardImage: UIImage, backCardImage: UIImage, physicalCardProperties: CardPhysicalProperties) {
        images = (frontCardImage, backCardImage)
        cardProperties = physicalCardProperties
    }

    func didReceiveMotionData(_ motion: CMDeviceMotion, over timeFrame: TimeInterval) {
        delegate?.didUpdateMotionData(motion, over: timeFrame)
    }
}

// MARK: - ViewController API

extension EditCardPhysicalVM {

    var texture: UIImage {
        get { cardProperties.texture }
        set { cardProperties.texture = newValue }
    }

    var specular: Float {
        get { cardProperties.specular }
        set { cardProperties.specular = newValue }
    }

    var normal: Float {
        get { cardProperties.normal }
        set { cardProperties.normal = newValue }
    }

    var cornerRadiusHeightMultiplier: Float {
        get { cardProperties.cornerRadiusHeightMultiplier }
        set { cardProperties.cornerRadiusHeightMultiplier = newValue }
    }

    var hapticSharpness: Float {
        get { cardProperties.hapticSharpness }
        set { cardProperties.hapticSharpness = newValue }
    }

    var title: String {
        NSLocalizedString("Card Properties", comment: "")
    }

    var selectedTextureItemIndexPath: IndexPath? {
        guard let itemIdx = preloadedTextures.firstIndex(of: texture) else { return nil }
        return IndexPath(item: itemIdx)
    }

    func numberOfItems() -> Int {
        preloadedTextures.count
    }

    func textureItem(at indexPath: IndexPath) -> EditCardPhysicalView.TextureCollectionCell.DataModel {
        let texture = preloadedTextures[indexPath.item]
        return EditCardPhysicalView.TextureCollectionCell.DataModel(textureImage: texture)
    }

    func didSelectTextureItem(at indexPath: IndexPath) {
        texture = preloadedTextures[indexPath.item]
    }

    func dataModel() -> CardFrontBackView.ImageDataModel {
        return CardFrontBackView.ImageDataModel(
            frontImage: images.cardFront,
            backImage: images.cardBack,
            textureImage: texture,
            normal: CGFloat(normal),
            specular: CGFloat(specular),
            cornerRadiusHeightMultiplier: CGFloat(cornerRadiusHeightMultiplier)
        )
    }
}

// MARK: - CardPhysicalProperties

extension EditCardPhysicalVM {
    struct CardPhysicalProperties {
        var texture: UIImage
        var specular: Float
        var normal: Float
        var cornerRadiusHeightMultiplier: Float
        var hapticSharpness: Float
    }
}
