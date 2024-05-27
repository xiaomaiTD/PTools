//
//  PTCrashDetailViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SnapKit
import SwifterSwift

class PTCrashDetailViewController: PTBaseViewController {
    
    fileprivate var viewModel:PTCrashDetailModel!
    
    lazy var fakeNav : UIView = {
        let view = UIView()
        view.backgroundColor = .randomColor
        return view
    }()
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 44
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.headerInCollection = { kind,collectionView,model,index in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTFusionHeader
            header.sectionModel = (model.headerDataModel as! PTFusionCellModel)
            return header
        }
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
            return cell
        }
        view.collectionDidSelect = { collection,model,indexPath in
            if PTCrashDetailViewController.Features(rawValue: indexPath.section)?.title == "Context" {
                let cellModel = self.viewModel.dataSourceForItem(indexPath)
                if cellModel?.title == "Snapshot" {
                    let image = self.viewModel.data.context.uiImage
                    let vc = PTDebugSnapshotViewController(snapshotImage: image)
                    self.navigationController?.pushViewController(vc)
                }
            }
        }
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        navigationController?.navigationBar.isHidden = true
#endif
    }
    
    init(viewModel: PTCrashDetailModel!) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubviews([fakeNav,newCollectionView])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight)
            make.top.equalTo(20)
        }
        
        let button = UIButton(type: .custom)
        button.backgroundColor = .randomColor
        fakeNav.addSubviews([button])
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
        }
        
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
                
        loadListData()
    }
    
    func loadListData() {
        var sections = [PTSection]()
        
        PTCrashDetailViewController.Features.allCases.enumerated().forEach { index,value in
            var rows = [PTRows]()
            let rowCount = self.viewModel.numberOfItems(section: index)
            for i in 0..<rowCount {
                let cellRealModel = self.viewModel.dataSourceForItem(IndexPath(row: i, section: index))
                switch PTCrashDetailViewController.Features(rawValue: index) {
                case .details,.stackTrace:
                    let cellModel = self.normalCellModel(name: cellRealModel?.title ?? "", content: cellRealModel?.detail ?? "")
                    let row = PTRows(cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: cellModel)
                    rows.append(row)
                case .context:
                    let cellModel = self.tapCellModel(name: cellRealModel?.title ?? "")
                    let row = PTRows(cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: cellModel)
                    rows.append(row)
                default:
                    break
                }
            }
            let headerModel = PTFusionCellModel()
            headerModel.name = value.title
            let section = PTSection(headerCls:PTFusionHeader.self,headerID:PTFusionHeader.ID,headerHeight: 34,rows: rows,headerDataModel: headerModel)
            sections.append(section)
        }
        
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    func normalCellModel(name:String,content:String) ->PTFusionCellModel {
        let model = PTFusionCellModel()
        model.name = name
        model.content = content
        return model
    }
    
    func tapCellModel(name:String) ->PTFusionCellModel {
        let model = PTFusionCellModel()
        model.name = name
        model.accessoryType = .DisclosureIndicator
        model.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
        return model
    }
}

extension PTCrashDetailViewController {
    enum Features: Int, CaseIterable {
        case details
        case context
        case stackTrace

        var title: String {
            switch self {
            case .details:
                return "Detail"
            case .context:
                return "Context"
            case .stackTrace:
                return "Stack Trace"
            }
        }
    }
}
