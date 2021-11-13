//
//  ViewController.swift
//  TableViewCellZoom
//
//  Created by Aaron Lee on 2021/11/13.
//

import UIKit
import Then
import RxSwift
import RxGesture
import RxDataSources
import SnapKit
import Kingfisher

fileprivate let tableViewCellIdentifier = "tableViewCell"

class ViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private var bag = DisposeBag()
    
    private var viewModel = ViewModel()
    
    private let tableView = UITableView()
        .then {
            $0.rowHeight = UIScreen.main.bounds.width
            $0.allowsSelection = false
            $0.separatorStyle = .none
        }
    
    private let backgroundView = UIView()
        .then {
            $0.backgroundColor = .black
            $0.alpha = 0
        }
    
    private let pinchedImageView = UIImageView()
        .then {
            $0.alpha = 0
            $0.clipsToBounds = true
            $0.contentMode = .scaleAspectFill
        }
    
    private let safeAreaCoverView = UIView()
        .then {
            $0.backgroundColor = .white
            $0.alpha = 0
        }
    
    private var isPinched = false
    
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
        view.addSubview(backgroundView)
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
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
}

// MARK: - Bind

extension ViewController {
    
    private func bindRx() {
        bindDataSource()
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
            .bind(onNext: { [weak self] gesture in
                self?.cellPinchGestureDidBegan(cell: cell, gesture: gesture)
            })
            .disposed(by: cell.bag)
        
        cellImageViewGestureObservable
            .when(.changed)
            .bind(onNext: { [weak self] gesture in
                self?.cellPinchGestureDidChange(cell: cell, gesture: gesture)
            })
            .disposed(by: cell.bag)
        
        cellImageViewGestureObservable
            .when(.ended)
            .bind(onNext: { [weak self] gesture in
                self?.cellPinchGestureDidEnd(cell: cell, gesture: gesture)
            })
            .disposed(by: cell.bag)
    }
    
    private func cellPinchGestureDidBegan(cell: TableViewCell, gesture: UIPinchGestureRecognizer) {
        guard let cellImageView = gesture.view as? UIImageView else { return }
        
        if gesture.scale < 1 { return }
        
        if isPinched { return }
        
        // Flags
        isPinched = true
        tableView.isScrollEnabled = false
        
        // Image
        let image = cell.imageViewThumbnail.image
        pinchedImageView.image = image
        
        // Position + Frame
        let convertedFrame = cellImageView.convert(cellImageView.bounds, to: view)
        pinchedImageView.frame = convertedFrame
        
        // Visiblity
        pinchedImageView.alpha = 1
        safeAreaCoverView.alpha = 0
        cellImageView.alpha = 0
        
        UIView.animate(withDuration: 0.15) {
            self.backgroundView.alpha = 0.6
        }
    }
    
    private func cellPinchGestureDidChange(cell: TableViewCell, gesture: UIPinchGestureRecognizer) {
        let maxScale: CGFloat = max(0.8, gesture.scale)
        pinchedImageView.transform = CGAffineTransform(scaleX: maxScale, y: maxScale)
    }
    
    private func cellPinchGestureDidEnd(cell: TableViewCell, gesture: UIPinchGestureRecognizer) {
        guard let cellImageView = gesture.view as? UIImageView else { return }
            gesture.scale = 1
            
            UIView.animate(withDuration: 0.3) {
                self.safeAreaCoverView.alpha = 1
                self.backgroundView.alpha = 0
                self.pinchedImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.pinchedImageView.frame = cellImageView.convert(cellImageView.bounds, to: self.view)
                
            } completion: { _ in
                self.tableView.isScrollEnabled = true
                self.isPinched = false
                
                self.pinchedImageView.alpha = 0
                cellImageView.alpha = 1
            }
        
    }
    
    private func bindCellPanGesture(with cell: TableViewCell) {
        cell.imageViewThumbnail
            .rx
            .gesture(.pan(configuration: nil))
            .bind(onNext: { [weak self] gesture in
                guard let self = self,
                      let gesture = gesture as? UIPanGestureRecognizer,
                      self.isPinched else { return }
                
                self.cellPanGestureDidRecognize(gesture)
            })
            .disposed(by: cell.bag)
    }
    
    private func cellPanGestureDidRecognize(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        pinchedImageView.center = CGPoint(x: pinchedImageView.center.x + translation.x, y: pinchedImageView.center.y + translation.y)
        gesture.setTranslation(.zero, in: view)
    }
    
}
