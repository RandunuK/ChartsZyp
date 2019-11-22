//
//  IFillFormatter.swift
//  ChartsZyp
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ChartsZyp
//

import Foundation
import CoreGraphics

/// Protocol for providing a custom logic to where the filling line of a LineDataSet should end. This of course only works if setFillEnabled(...) is set to true.
@objc(IChartFillFormatter)
public protocol IFillFormatter
{
    /// - Returns: The vertical (y-axis) position where the filled-line of the LineDataSet should end.
    func getFillLinePosition(dataSet: ILineChartDataSet, dataProvider: LineChartDataProvider) -> CGFloat
}
