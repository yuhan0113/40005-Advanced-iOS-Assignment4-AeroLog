//
//  AeroLogWidgetBundle.swift
//  AeroLogWidget
//
//  Created by Yu-Han on 18/10/2025.
//

import WidgetKit
import SwiftUI

@main
struct AeroLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        AeroLogWidget()
        AeroLogWidgetControl()
        AeroLogWidgetLiveActivity()
    }
}
