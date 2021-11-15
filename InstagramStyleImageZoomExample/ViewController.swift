//
//  ViewController.swift
//  InstagramStyleImageZoomExample
//
//  Created by Aaron Lee on 2021/11/13.
//

import UIKit
import Then
import RxSwift
import RxCocoa
import RxGesture
import RxDataSources
import SnapKit
import Kingfisher

fileprivate let tableViewCellIdentifier = "tableViewCell"

class ViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private var viewModel = ViewModel()
    
    // MARK: - Public Properties
    
    var bag = DisposeBag()
    
    var tableView = UITableView()
        .then {
            $0.rowHeight = UIScreen.main.bounds.width
            $0.allowsSelection = false
            $0.separatorStyle = .none
        }
    
    var pinchedImageBackgroundView = UIView()
        .then {
            $0.backgroundColor = .black
            $0.alpha = 0
        }
    
    var pinchedImageView = UIImageView()
        .then {
            $0.alpha = 0
            $0.clipsToBounds = true
            $0.contentMode = .scaleAspectFill
        }
    
    var safeAreaCoverView = UIView()
        .then {
            $0.backgroundColor = .white
            $0.alpha = 0
        }
    
    var isImagePinched = false
    
    var imageViewDidPinch = PublishSubject<UIPinchGestureRecognizer>()
    
    var imageViewDidPan = PublishSubject<UIPanGestureRecognizer>()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        layoutView()
        bindRx()
    }
}

// MARK: - Layout

extension ViewController {
    
    private func configureView() {
        view.backgroundColor = .white
        
        configureTableView()
        
        configureBackgroundView()
        
        configureImageView()
        
        view.addSubview(safeAreaCoverView)
        
    }
    
    private func configureTableView() {
        tableView.register(TableViewCell.self, forCellReuseIdentifier: tableViewCellIdentifier)
        view.addSubview(tableView)
    }
    
    private func configureBackgroundView() {
        view.addSubview(pinchedImageBackgroundView)
    }
    
    private func configureImageView() {
        view.addSubview(pinchedImageView)
        pinchedImageView.center = view.center
    }
    
    private func layoutView() {
        layoutTableView()
        layoutSafeAreaCoverView()
        layoutBackgroundView()
    }
    
    private func layoutTableView() {
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func layoutSafeAreaCoverView() {
        safeAreaCoverView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }
    
    private func layoutBackgroundView() {
        pinchedImageBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
}

// MARK: - Bind

extension ViewController: PinchableViewControllerType {
    
    private func bindRx() {
        bindDataSource()
        bindImageViewPinchGesture()
        bindImageViewPanGesture()
    }
    
    private func bindDataSource() {
        let dataSource = createDataSource(with: tableViewCellIdentifier)
        
        viewModel
            .output
            .dataSource
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
    }
    
    private func createDataSource(with tableViewCellIdentifier: String) -> RxTableViewSectionedReloadDataSource<DataSource> {
        let dataSource = RxTableViewSectionedReloadDataSource<DataSource> { [weak self] dataSource,
            tableView,
            indexPath,
            imageIndex in
            
            guard let self = self,
                  let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath) as? TableViewCell else {
                      return UITableViewCell()
                  }
            
            self.configureCell(with: cell, imageIndex: imageIndex)
            self.bindCellPinchGesture(with: cell)
            self.bindCellPanGesture(with: cell)
            
            return cell
            
        }
        
        return dataSource
    }
    
    private func configureCell(with cell: TableViewCell, imageIndex: Int) {
        let imageName = "\(imageIndex)"
        let title = "Image \(imageName)"
        
        cell.labelTitle.text = title
        
        let size = CGSize(width: UIScreen.main.bounds.width,
                          height: UIScreen.main.bounds.width)
        let processor = DownsamplingImageProcessor(size: size)
        
        let image = UIImage(named: imageName)
        
        cell.imageViewThumbnail.kf
            .setImage(with: URL(string: ""),
                      placeholder: image,
                      options: [
                        .processor(processor),
                        .transition(.fade(0.15)),
                      ])
    }
    
    private func bindCellPinchGesture(with cell: TableViewCell) {
        let cellImageViewGestureObservable = cell.imageViewThumbnail
            .rx
            .pinchGesture(configuration: nil)
        
        cellImageViewGestureObservable
            .when(.began)
            .do(onNext: { [weak self] _ in
                self?.safeAreaCoverView.alpha = 0
            })
            .bind(to: imageViewDidPinch)
            .disposed(by: cell.bag)
        
        cellImageViewGestureObservable
            .when(.changed)
            .bind(to: imageViewDidPinch)
            .disposed(by: cell.bag)
        
        cellImageViewGestureObservable
            .when(.ended)
            .do(onNext: { [weak self] _ in
                UIView.animate(withDuration: 0.3) {
                    self?.safeAreaCoverView.alpha = 1
                }
            })
            .bind(to: imageViewDidPinch)
            .disposed(by: cell.bag)
    }
    
    private func bindCellPanGesture(with cell: TableViewCell) {
        cell.imageViewThumbnail
            .rx
            .panGesture(configuration: nil)
            .bind(to: imageViewDidPan)
            .disposed(by: cell.bag)
    }
    
}
