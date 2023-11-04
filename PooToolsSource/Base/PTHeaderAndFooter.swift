//
//  PTFusionHeader.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 4/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import AttributedString

public class PTFusionHeader: PTBaseCollectionReusableView {
    static let ID = "PTFusionHeader"
    
    open var switchValueChangeBLock:PTCellSwitchBlock?
    
    open var sectionModel:PTFusionCellModel? {
        didSet {
            self.dataContent.cellModel = self.sectionModel
        }
    }
    
    open lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.switchValueChangeBLock = self.switchValueChangeBLock
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(dataContent)
        dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    
}

public class PTVersionFooter: PTBaseCollectionReusableView {
    static let ID = "PTVersionFooter"
    
    lazy var verionLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        
        let att:ASAttributedString = """
        \(wrap: .embedding("""
        \("\(kAppName! + " " + kAppVersion! + "(\(kAppBuildVersion!))")",.foreground(.lightGray),.font(PTAppBaseConfig.share.privacyNameFont),.paragraph(.alignment(.center)))
        \("隐私政策",.foreground(.systemBlue),.font(PTAppBaseConfig.share.privacyNameFont),.paragraph(.alignment(.center)),.underline(.single,color: .systemBlue),.action {
                let url = URL(string: PTAppBaseConfig.share.privacyURL)!
                PTAppStoreFunction.jumpLink(url: url)
        })
        """))
        """
        view.attributed.text = att
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(verionLabel)
        verionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(5)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

