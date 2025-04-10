//
//  VideoCell.swift
//  VidiFrame
//
//  Created by 이상훈 on 4/11/25.
//

import UIKit

class VideoCell: UITableViewCell {
    static let identifier = "VideoCell"

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16.s, weight: .bold)
        $0.textColor = .black
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
}
