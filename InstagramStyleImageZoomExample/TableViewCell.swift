//
//  TableViewCell.swift
//  TableViewCellZoom
//
//  Created by Aaron Lee on 2021/11/13.
//

import UIKit
import RxSwift
import Then
import SnapKit

class TableViewCell: UITableViewCell {
    
    // MARK: - Public Properties
    
    var bag = DisposeBag()
    
    let labelTitle = UILabel()
        .then {
            $0.textAlignment = .left
            $0.font = .preferredFont(forTextStyle: .title3)
        }
    
    let imageViewThumbnail = UIImageView()
        .then {
            $0.clipsToBounds = true
            $0.contentMode = .scaleAspectFill
        }
    
    private let imageBackgroundView = UIView()
        .then {
            $0.backgroundColor = .black.withAlphaComponent(0.4)
        }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
        layoutView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        layoutView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
        imageViewThumbnail.image = nil
    }
    
    private func configureView() {
        selectionStyle = .none
        contentView.backgroundColor = .clear
        
        contentView.addSubview(labelTitle)
        contentView.addSubview(imageBackgroundView)
        contentView.addSubview(imageViewThumbnail)
    }
    
    private func layoutView() {
        labelTitle.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(16)
        }
        
        imageViewThumbnail.snp.makeConstraints {
            $0.top.equalTo(labelTitle.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-8)
        }
        
        imageBackgroundView.snp.makeConstraints {
            $0.edges.equalTo(imageViewThumbnail)
        }
    }
    
}
