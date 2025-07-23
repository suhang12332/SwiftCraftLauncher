//
//  CommonView.swift
//  MLauncher
//
//  Created by su on 2025/6/2.
//
import SwiftUI

func ErrorView(_ error: Error) -> some View {
    ContentUnavailableView {
        Label("result.error".localized(),systemImage: "xmark.icloud")

    } description: {
        Text(error.localizedDescription)
    }
    
    
    
}

func EmptyResultView() -> some View {
    ContentUnavailableView {
        Label(
            "result.empty".localized(),
            systemImage: "magnifyingglass"
        )
    }
    
}
