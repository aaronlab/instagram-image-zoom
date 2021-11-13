//
//  ViewModel.swift
//  TableViewCellZoom
//
//  Created by Aaron Lee on 2021/11/13.
//

import Foundation
import RxSwift
import RxCocoa

protocol ViewModelOutput {
    var images: BehaviorRelay<[Int]> { get }
}

extension ViewModelOutput {
    var dataSource: Observable<[DataSource]> {
        return images
            .map { [DataSource(section: 0, items: $0)] }
    }
}

protocol ViewModelType {
    associatedtype Output
    
    var output: Output { get }
}

class ViewModel: ViewModelType {
    
    var output = Output()
    
    struct Output: ViewModelOutput {
        var images = BehaviorRelay<[Int]>(value: ThumbnailImage.allCases.map { $0.rawValue })
    }
    
}

/// Image Name
enum ThumbnailImage: Int, CaseIterable {
    case image1
    case image2
    case image3
    case image4
    case image5
    case image6
    case image7
    case image8
    case image9
    case image10
}
