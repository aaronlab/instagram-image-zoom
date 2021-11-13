//
//  DataSource.swift
//  TableViewCellZoom
//
//  Created by Aaron Lee on 2021/11/13.
//

import Foundation
import RxDataSources

struct DataSource {
    var section: Int
    var items: [Item]
}

extension DataSource: SectionModelType {
    typealias Item = Int
    
    init(original: DataSource, items: [Item]) {
        self = original
        self.items = items
    }
}
