//
//  CircularRadarArcChartRenderer.swift
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

open class CircularRadarArcChartRenderer: LineRadarRenderer
{
    private lazy var accessibilityXLabels: [String] = {
        guard let chart = chart else { return [] }
        guard let formatter = chart.xAxis.valueFormatter else { return [] }

        let maxEntryCount = chart.data?.maxEntryCountSet?.entryCount ?? 0
        return stride(from: 0, to: maxEntryCount, by: 1).map {
            formatter.stringForValue(Double($0), axis: chart.xAxis)
        }
    }()

    @objc open weak var chart: CircularRadarArcChartView?

    @objc public init(chart: CircularRadarArcChartView, animator: Animator, viewPortHandler: ViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.chart = chart
    }
    
    open override func drawData(context: CGContext)
    {
        guard let chart = chart else { return }
        
        let radarData = chart.data
        
        if radarData != nil
        {
            let mostEntries = radarData?.maxEntryCountSet?.entryCount ?? 0
            let dataSetCount = radarData?.dataSets.count ?? 0
            var i: Int = 0;

            // If we redraw the data, remove and repopulate accessible elements to update label values and frames
            self.accessibleChartElements.removeAll()

            // Make the chart header the first element in the accessible elements array
            if let accessibilityHeaderData = radarData as? RadarChartData {
                let element = createAccessibleHeader(usingChart: chart,
                                                     andData: accessibilityHeaderData,
                                                     withDefaultDescription: "Radar Chart")
                self.accessibleChartElements.append(element)
            }

            for set in radarData!.dataSets as! [IRadarChartDataSet]
            {
                i+=1
                if(set.isVisible){
                    drawDataSet(context: context, dataSet: set, mostEntries: mostEntries, isLastDataSet: i==dataSetCount)
                }
            }
        }
    }
    
    /// Draws the RadarDataSet
    ///
    /// - Parameters:
    ///   - context:
    ///   - dataSet:
    ///   - mostEntries: the entry count of the dataset with the most entries
    internal func drawDataSet(context: CGContext, dataSet: IRadarChartDataSet, mostEntries: Int, isLastDataSet: Bool)
    {
        guard let chart = chart else { return }
        let twoPi = CGFloat.init(2*Double.pi)
        let oneDegreeInRadians = CGFloat.init(Double.pi/180) ;
        
        context.saveGState()
        
        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        
        let sliceangle = chart.sliceAngle
        
        // calculate the factor that is needed for transforming the value to pixels
        let factor = chart.factor
        let rotationAngle = chart.rotationAngle;
        
        let center = chart.centerOffsets
       
        var pOutPrevious = CGPoint.init(x: 0.0, y: 0.0)
        var pOutFirstForLast = CGPoint.init(x: 0.0, y: 0.0)
        let entryCount = dataSet.entryCount
        let path = CGMutablePath()
        
        var hasMovedToPoint = false

        let prefix: String = chart.data?.accessibilityEntryLabelPrefix ?? "Item"
        let description = dataSet.label ?? ""

        // Make a tuple of (xLabels, value, originalIndex) then sort it
        // This is done, so that the labels are narrated in decreasing order of their corresponding value
        // Otherwise, there is no non-visual logic to the data presented
        let accessibilityEntryValues =  Array(0 ..< entryCount).map { (dataSet.entryForIndex($0)?.y ?? 0, $0) }
        let accessibilityAxisLabelValueTuples = zip(accessibilityXLabels, accessibilityEntryValues).map { ($0, $1.0, $1.1) }.sorted { $0.1 > $1.1 }
        let accessibilityDataSetDescription: String = description + ". \(entryCount) \(prefix + (entryCount == 1 ? "" : "s")). "
        let accessibilityFrameWidth: CGFloat = 22.0 // To allow a tap target of 44x44

        var accessibilityEntryElements: [NSUIAccessibilityElement] = []

        //var oval: CGRect = CGRect.init();
        
        for j in 0 ..< entryCount
        {
            context.setFillColor(dataSet.fillColor.cgColor)
            guard let e = dataSet.entryForIndex(j) else { continue }
            
            let p = center.moving(distance: CGFloat((e.y - chart.chartYMin) * Double(factor) * phaseY),
                                  atAngle: sliceangle * CGFloat(j) * CGFloat(phaseX) + chart.rotationAngle)
            
            
            
            if p.x.isNaN
            {
                continue
            }
            
            if !hasMovedToPoint
            {
                path.move(to: p)
                if(isLastDataSet){
                    pOutFirstForLast = p
                }
                hasMovedToPoint = true
            }
            else
            {
                let xNotFromCenter = abs(pOutPrevious.x - center.x) > 0
                let yNotFromCenter = abs(pOutPrevious.y - center.y) > 0
                let xIsNotCenter = abs(p.x - center.x) > 0
                let yIsNotCenter = abs(p.y - center.y) > 0
                let xIsNotPrevious = abs(pOutPrevious.x - p.x) > 0
                let yIsNotPrevious = abs(pOutPrevious.y - p.y) > 0

                if ((xNotFromCenter||yNotFromCenter) && (xIsNotCenter||yIsNotCenter)) {
                    let radius = sqrt(pow(p.x - center.x, 2) + pow(p.y - center.y, 2))
                    let startAngle = ((sliceangle * (CGFloat)(j - 1) + rotationAngle) * oneDegreeInRadians).truncatingRemainder(dividingBy: (twoPi))
                    let sweepAngle = sliceangle * oneDegreeInRadians
                    let endAngle = (startAngle + sweepAngle).truncatingRemainder(dividingBy: (twoPi))
                    //print("\(isLastDataSet) \(startAngle) \(endAngle) ");
                    path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                }else if(isLastDataSet && j == entryCount - 1){
                    let _xIsNotCenter  = abs(pOutFirstForLast.x - center.x) > 0
                    let _yIsNotCenter  = abs(pOutFirstForLast.y - center.y) > 0
                    
                    if(_xIsNotCenter || _yIsNotCenter){
                        let radius = sqrt(pow(p.x - center.x, 2) + pow(p.y - center.y, 2))
                        let startAngle = ((sliceangle * (CGFloat)(j) + rotationAngle) * oneDegreeInRadians)//.truncatingRemainder(dividingBy: (twoPi))
                        let sweepAngle = sliceangle * oneDegreeInRadians
                        let endAngle = (startAngle + sweepAngle).truncatingRemainder(dividingBy: (twoPi))
                        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle:endAngle , clockwise: false)
                        //print("\(isLastDataSet) \(startAngle) \(endAngle) ");
                    }
                }else if(yIsNotPrevious || xIsNotPrevious){
                    path.addLine(to: p)
                }
            }

            pOutPrevious = p

            let accessibilityLabel = accessibilityAxisLabelValueTuples[j].0
            let accessibilityValue = accessibilityAxisLabelValueTuples[j].1
            let accessibilityValueIndex = accessibilityAxisLabelValueTuples[j].2

            let axp = center.moving(distance: CGFloat((accessibilityValue - chart.chartYMin) * Double(factor) * phaseY),
                                    atAngle: sliceangle * CGFloat(accessibilityValueIndex) * CGFloat(phaseX) + chart.rotationAngle)

            let axDescription = description + " - " + accessibilityLabel + ": \(accessibilityValue) \(chart.data?.accessibilityEntryLabelSuffix ?? "")"
            let axElement = createAccessibleElement(withDescription: axDescription,
                                                    container: chart,
                                                    dataSet: dataSet)
            { (element) in
                element.accessibilityFrame = CGRect(x: axp.x - accessibilityFrameWidth,
                                                    y: axp.y - accessibilityFrameWidth,
                                                    width: 2 * accessibilityFrameWidth,
                                                    height: 2 * accessibilityFrameWidth)
            }

            accessibilityEntryElements.append(axElement)
        }
        
        // if this is the largest set, close it
        if dataSet.entryCount < mostEntries
        {
            // if this is not the largest set, draw a line to the center before closing
            path.addLine(to: center)
        }
        
        path.closeSubpath()
        
        // draw filled
        if dataSet.isDrawFilledEnabled
        {
            if dataSet.fill != nil
            {
                drawFilledPath(context: context, path: path, fill: dataSet.fill!, fillAlpha: dataSet.fillAlpha)
            }
            else
            {
                drawFilledPath(context: context, path: path, fillColor: dataSet.fillColor, fillAlpha: dataSet.fillAlpha)
            }
        }
        
        // draw the line (only if filled is disabled or alpha is below 255)
        if !dataSet.isDrawFilledEnabled || dataSet.fillAlpha < 1.0
        {
            context.setStrokeColor(dataSet.color(atIndex: 0).cgColor)
            context.setLineWidth(dataSet.lineWidth)
            context.setAlpha(1.0)

            context.beginPath()
            context.addPath(path)
            context.strokePath()

            let axElement = createAccessibleElement(withDescription: accessibilityDataSetDescription,
                                                    container: chart,
                                                    dataSet: dataSet)
            { (element) in
                element.isHeader = true
                element.accessibilityFrame = path.boundingBoxOfPath
            }

            accessibleChartElements.append(axElement)
            accessibleChartElements.append(contentsOf: accessibilityEntryElements)
        }
        
        accessibilityPostLayoutChangedNotification()

        context.restoreGState()
    }
    
    /// Draws the provided path in filled mode with the provided color and alpha.
    @objc open override func drawFilledPath(context: CGContext, path: CGPath, fillColor: NSUIColor, fillAlpha: CGFloat)
    {
        context.saveGState()
        context.beginPath()
        context.addPath(path)
        
        // filled is usually drawn with less alpha
        context.setAlpha(fillAlpha)
        
        context.setFillColor(fillColor.cgColor)
        context.fillPath()
        
        context.restoreGState()
    }
    
    
    open override func drawValues(context: CGContext)
    {
        guard
            let chart = chart,
            let data = chart.data
            else { return }
        
        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        
        let sliceangle = chart.sliceAngle
        
        // calculate the factor that is needed for transforming the value to pixels
        let factor = chart.factor
        
        let center = chart.centerOffsets
        
        let yoffset = CGFloat(5.0)
        
        for i in 0 ..< data.dataSetCount
        {
            guard let
                dataSet = data.getDataSetByIndex(i) as? IRadarChartDataSet,
                shouldDrawValues(forDataSet: dataSet)
                else { continue }
            
            let entryCount = dataSet.entryCount
            
            let iconsOffset = dataSet.iconsOffset
            
            for j in 0 ..< entryCount
            {
                guard let e = dataSet.entryForIndex(j) else { continue }
                
                let p = center.moving(distance: CGFloat(e.y - chart.chartYMin) * factor * CGFloat(phaseY),
                                      atAngle: sliceangle * CGFloat(j) * CGFloat(phaseX) + chart.rotationAngle)
                
                let valueFont = dataSet.valueFont
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                if dataSet.isDrawValuesEnabled
                {
                    ChartUtils.drawText(
                        context: context,
                        text: formatter.stringForValue(
                            e.y,
                            entry: e,
                            dataSetIndex: i,
                            viewPortHandler: viewPortHandler),
                        point: CGPoint(x: p.x, y: p.y - yoffset - valueFont.lineHeight),
                        align: .center,
                        attributes: [NSAttributedString.Key.font: valueFont,
                            NSAttributedString.Key.foregroundColor: dataSet.valueTextColorAt(j)]
                    )
                }
                
                if let icon = e.icon, dataSet.isDrawIconsEnabled
                {
                    var pIcon = center.moving(distance: CGFloat(e.y) * factor * CGFloat(phaseY) + iconsOffset.y,
                                              atAngle: sliceangle * CGFloat(j) * CGFloat(phaseX) + chart.rotationAngle)
                    pIcon.y += iconsOffset.x
                    
                    ChartUtils.drawImage(context: context,
                                         image: icon,
                                         x: pIcon.x,
                                         y: pIcon.y,
                                         size: icon.size)
                }
            }
        }
    }
    
    open override func drawExtras(context: CGContext)
    {
        drawCircularWebAndValuePercentages(context: context)
    }
    
    private var _webLineSegmentsBuffer = [CGPoint](repeating: CGPoint(), count: 2)

    @objc open func drawCircularWebAndValuePercentages(context: CGContext)
    {
        guard
            let chart = chart,
            let radarData = chart.data as? RadarChartData
            else { return }
        let legendHeight = chart.legend.textHeightMax
        let twoPi = CGFloat.init(2*Double.pi)
        let oneDegreeInRadians = CGFloat.init(Double.pi/180);

        context.saveGState()
        
        // calculate the factor that is needed for transforming the value to
        // pixels
        let factor = chart.factor
        let rotationangle = chart.rotationAngle
        let colors = radarData.getColors()
        let dataSets = radarData.dataSets as? Array<IRadarChartDataSet>
        let sliceangle = chart.sliceAngle
        
        let textPath = CGMutablePath()
        let center = chart.centerOffsets
        
        // draw the web lines that come from the center
        context.setLineWidth(chart.webLineWidth)
        context.setStrokeColor(chart.webColor.cgColor)
        context.setAlpha(chart.webAlpha)
        
        let xIncrements = 1 + chart.skipWebLineCount
        let maxEntryCount = chart.data?.maxEntryCountSet?.entryCount ?? 0

        for i in stride(from: 0, to: maxEntryCount, by: xIncrements)
        {
            let p = center.moving(distance: CGFloat(chart.yRange) * factor,
                                  atAngle: sliceangle * CGFloat(i) + rotationangle)
            
             }
        
        // draw the inner-web
        context.setLineWidth(chart.innerWebLineWidth)
        context.setStrokeColor(chart.innerWebColor.cgColor)
        context.setAlpha(chart.webAlpha)
        
        //let chartRadius = chart.radius
        let labelCount = chart.yAxis.entryCount
        let colorCount = colors!.count as! Int
        
        for j in 0 ..< labelCount
        {
            for i in 0 ..< colorCount
            {
                let r = CGFloat(chart.yAxis.entries[j] - chart.chartYMin) * factor

                let p1 = center.moving(distance: r, atAngle: sliceangle * CGFloat(i) + rotationangle)
                let p2 = center.moving(distance: r, atAngle: sliceangle * CGFloat(i + 1) + rotationangle)
                
                if(labelCount - 1 == j){
                    textPath.closeSubpath()
                    context.setFillColor(dataSets![i].fillColor.cgColor)
                    context.setShouldAntialias(true)
                    context.setAlpha(chart.webAlpha)
                    let radius = r
                    
                    let sweepAngle = sliceangle * oneDegreeInRadians
                    let startAngle = ((sliceangle * CGFloat.init(i) + rotationangle) * oneDegreeInRadians).truncatingRemainder(dividingBy: twoPi)
                    let endAngle = (startAngle + sweepAngle).truncatingRemainder(dividingBy: twoPi)
                    context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    context.addLine(to: center)
                    context.fillPath()
                    context.closePath()
                    let dataSet = dataSets![i]
                    var value = dataSet.entryForIndex(i)?.y ?? 0.0
                    value = value < 0 ? 0.0 : value
                    let valueString = String(format: "%.1f", value) + "%"
                    if(i>1 && i<4){
                        centreArcPerpendicular(text: dataSet.label ?? "0.0%", context: context, radius: radius+legendHeight/2, angle: -(startAngle + 0.524), colour: dataSets![i].fillColor, font: NSUIFont.systemFont(ofSize: 14), clockwise: false, circleCenter: center)
                        centreArcPerpendicular(text: valueString, context: context, radius: radius+(legendHeight*1.5), angle: -(startAngle + 0.524), colour: dataSets![i].fillColor, font: NSUIFont.systemFont(ofSize: 14), clockwise: false, circleCenter: center)
                    }else{
                        centreArcPerpendicular(text: dataSet.label ?? "0.0%", context: context, radius: radius+legendHeight/2, angle: -(startAngle + 0.524), colour: dataSets![i].fillColor, font: NSUIFont.systemFont(ofSize: 14), clockwise: true, circleCenter: center)
                        centreArcPerpendicular(text: valueString, context: context, radius: radius+(legendHeight*1.5), angle: -(startAngle + 0.524), colour: dataSets![i].fillColor, font: NSUIFont.systemFont(ofSize: 14), clockwise: true, circleCenter: center)
                    }
                    
                    context.closePath()
                }
                }
        }
        
        context.restoreGState()
    }
    
    @objc open func drawWeb(context: CGContext)
    {
        guard
            let chart = chart,
            let data = chart.data
            else { return }
        
        let sliceangle = chart.sliceAngle
        
        context.saveGState()
        
        // calculate the factor that is needed for transforming the value to
        // pixels
        let factor = chart.factor
        let rotationangle = chart.rotationAngle
        
        let center = chart.centerOffsets
        
        // draw the web lines that come from the center
        context.setLineWidth(chart.webLineWidth)
        context.setStrokeColor(chart.webColor.cgColor)
        context.setAlpha(chart.webAlpha)
        
        let xIncrements = 1 + chart.skipWebLineCount
        let maxEntryCount = chart.data?.maxEntryCountSet?.entryCount ?? 0

        for i in stride(from: 0, to: maxEntryCount, by: xIncrements)
        {
            let p = center.moving(distance: CGFloat(chart.yRange) * factor,
                                  atAngle: sliceangle * CGFloat(i) + rotationangle)
            
            _webLineSegmentsBuffer[0].x = center.x
            _webLineSegmentsBuffer[0].y = center.y
            _webLineSegmentsBuffer[1].x = p.x
            _webLineSegmentsBuffer[1].y = p.y
            
            context.strokeLineSegments(between: _webLineSegmentsBuffer)
        }
        
        // draw the inner-web
        context.setLineWidth(chart.innerWebLineWidth)
        context.setStrokeColor(chart.innerWebColor.cgColor)
        context.setAlpha(chart.webAlpha)
        
        let labelCount = chart.yAxis.entryCount
        
        for j in 0 ..< labelCount
        {
            for i in 0 ..< data.entryCount
            {
                let r = CGFloat(chart.yAxis.entries[j] - chart.chartYMin) * factor

                let p1 = center.moving(distance: r, atAngle: sliceangle * CGFloat(i) + rotationangle)
                let p2 = center.moving(distance: r, atAngle: sliceangle * CGFloat(i + 1) + rotationangle)
                
                _webLineSegmentsBuffer[0].x = p1.x
                _webLineSegmentsBuffer[0].y = p1.y
                _webLineSegmentsBuffer[1].x = p2.x
                _webLineSegmentsBuffer[1].y = p2.y
                
                context.strokeLineSegments(between: _webLineSegmentsBuffer)
            }
        }
        
        context.restoreGState()
    }
    
    private var _highlightPointBuffer = CGPoint()

    open override func drawHighlighted(context: CGContext, indices: [Highlight])
    {
        guard
            let chart = chart,
            let radarData = chart.data as? RadarChartData
            else { return }
        
        context.saveGState()
        
        let sliceangle = chart.sliceAngle
        
        // calculate the factor that is needed for transforming the value pixels
        let factor = chart.factor
        
        let center = chart.centerOffsets
        
        for high in indices
        {
            guard
                let set = chart.data?.getDataSetByIndex(high.dataSetIndex) as? IRadarChartDataSet,
                set.isHighlightEnabled
                else { continue }
            
            guard let e = set.entryForIndex(Int(high.x)) as? RadarChartDataEntry
                else { continue }
            
            if !isInBoundsX(entry: e, dataSet: set)
            {
                continue
            }
            
            context.setLineWidth(radarData.highlightLineWidth)
            if radarData.highlightLineDashLengths != nil
            {
                context.setLineDash(phase: radarData.highlightLineDashPhase, lengths: radarData.highlightLineDashLengths!)
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            context.setStrokeColor(set.highlightColor.cgColor)
            
            let y = e.y - chart.chartYMin
            
            _highlightPointBuffer = center.moving(distance: CGFloat(y) * factor * CGFloat(animator.phaseY),
                                                  atAngle: sliceangle * CGFloat(high.x) * CGFloat(animator.phaseX) + chart.rotationAngle)
            
            high.setDraw(pt: _highlightPointBuffer)
            
            // draw the lines
            drawHighlightLines(context: context, point: _highlightPointBuffer, set: set)
            
            if set.isDrawHighlightCircleEnabled
            {
                if !_highlightPointBuffer.x.isNaN && !_highlightPointBuffer.y.isNaN
                {
                    var strokeColor = set.highlightCircleStrokeColor
                    if strokeColor == nil
                    {
                        strokeColor = set.color(atIndex: 0)
                    }
                    if set.highlightCircleStrokeAlpha < 1.0
                    {
                        strokeColor = strokeColor?.withAlphaComponent(set.highlightCircleStrokeAlpha)
                    }
                    
                    drawHighlightCircle(
                        context: context,
                        atPoint: _highlightPointBuffer,
                        innerRadius: set.highlightCircleInnerRadius,
                        outerRadius: set.highlightCircleOuterRadius,
                        fillColor: set.highlightCircleFillColor,
                        strokeColor: strokeColor,
                        strokeWidth: set.highlightCircleStrokeWidth)
                }
            }
        }
        
        context.restoreGState()
    }
    
    internal func drawHighlightCircle(
        context: CGContext,
        atPoint point: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        fillColor: NSUIColor?,
        strokeColor: NSUIColor?,
        strokeWidth: CGFloat)
    {
        context.saveGState()
        
        if let fillColor = fillColor
        {
            context.beginPath()
            context.addEllipse(in: CGRect(x: point.x - outerRadius, y: point.y - outerRadius, width: outerRadius * 2.0, height: outerRadius * 2.0))
            if innerRadius > 0.0
            {
                context.addEllipse(in: CGRect(x: point.x - innerRadius, y: point.y - innerRadius, width: innerRadius * 2.0, height: innerRadius * 2.0))
            }
            
            context.setFillColor(fillColor.cgColor)
            context.fillPath(using: .evenOdd)
        }
            
        if let strokeColor = strokeColor
        {
            context.beginPath()
            context.addEllipse(in: CGRect(x: point.x - outerRadius, y: point.y - outerRadius, width: outerRadius * 2.0, height: outerRadius * 2.0))
            context.setStrokeColor(strokeColor.cgColor)
            context.setLineWidth(strokeWidth)
            context.strokePath()
        }
        
        context.restoreGState()
    }

    private func createAccessibleElement(withDescription description: String,
                                         container: CircularRadarArcChartView,
                                         dataSet: IRadarChartDataSet,
                                         modifier: (NSUIAccessibilityElement) -> ()) -> NSUIAccessibilityElement {

        let element = NSUIAccessibilityElement(accessibilityContainer: container)
        element.accessibilityLabel = description

        // The modifier allows changing of traits and frame depending on highlight, rotation, etc
        modifier(element)

        return element
    }
    
    func centreArcPerpendicular(text str: String, context: CGContext, radius r: CGFloat, angle theta: CGFloat, colour c: NSUIColor, font: NSUIFont, clockwise: Bool, circleCenter: CGPoint){
        // *******************************************************
        // This draws the String str around an arc of radius r,
        // with the text centred at polar angle theta
        // *******************************************************
        let characters: [String] = str.map { String($0) } // An array of single character strings, each character in str
        let l = characters.count
        let attributes = [NSAttributedString.Key.font: font]
        var arcs: [CGFloat] = [] // This will be the arcs subtended by each character
        var totalArc: CGFloat = 0 // ... and the total arc subtended by the string
        // Calculate the arc subtended by each letter and their total
        for i in 0 ..< l {
            arcs += [chordToArc(characters[i].size(withAttributes: attributes).width, radius: r)]
            totalArc += arcs[i]
        }
        // Are we writing clockwise (right way up at 12 o'clock, upside down at 6 o'clock)
        // or anti-clockwise (right way up at 6 o'clock)?
        let direction: CGFloat = clockwise ? -1 : 1
        let slantCorrection: CGFloat = clockwise ? -.pi / 2 : .pi / 2
        // The centre of the first character will then be at
        // thetaI = theta - totalArc / 2 + arcs[0] / 2
        // But we add the last term inside the loop
        var thetaI = theta - direction * totalArc / 2
        for i in 0 ..< l {
            thetaI += direction * arcs[i] / 2
            // Call centerText with each character in turn.
            // Remember to add +/-90º to the slantAngle otherwise
            // the characters will "stack" round the arc rather than "text flow"
            centre(text: characters[i], context: context, radius: r, angle: thetaI, colour: c, font: font, slantAngle: thetaI + slantCorrection, circleCenter: circleCenter)
            // The centre of the next character will then be at
            // thetaI = thetaI + arcs[i] / 2 + arcs[i + 1] / 2
            // but again we leave the last term to the start of the next loop...
            thetaI += direction * arcs[i] / 2
        }
    }
    func chordToArc(_ chord: CGFloat, radius: CGFloat) -> CGFloat {
        // *******************************************************
        // Simple geometry
        // *******************************************************
        return 2 * asin(chord / (2 * radius))
    }
    func centre(text str: String, context: CGContext, radius r: CGFloat, angle theta: CGFloat, colour c: NSUIColor, font: NSUIFont, slantAngle: CGFloat, circleCenter: CGPoint ) {
        // *******************************************************
        // This draws the String str centred at the position
        // specified by the polar coordinates (r, theta)
        // i.e. the x= r * cos(theta) y= r * sin(theta)
        // and rotated by the angle slantAngle
        // *******************************************************
        // Set the text attributes
        let attributes = [NSAttributedString.Key.foregroundColor: c, NSAttributedString.Key.font: font]
        //let attributes = [NSForegroundColorAttributeName: c, NSFontAttributeName: font]
        //context.translateBy(x: circleCenter.x, y: circleCenter.y)
        // Save the context
        context.saveGState()
        context.translateBy(x: circleCenter.x, y: circleCenter.y)
        context.scaleBy(x: 1, y: -1)
        // Undo the inversion of the Y-axis (or the text goes backwards!)
        context.scaleBy(x: 1, y: -1)
        // Move the origin to the centre of the text (negating the y-axis manually)
        context.translateBy(x: r * cos(theta), y: -(r * sin(theta)))
        // Rotate the coordinate system
        context.rotate(by: -slantAngle)
        // Calculate the width of the text
        let offset = str.size(withAttributes: attributes)
        // Move the origin by half the size of the text
        context.translateBy (x: -offset.width / 2, y: -offset.height / 2) // Move the origin to the centre of the text (negating the y-axis manually)
        //
        
        // Draw the text
        str.draw(at: CGPoint(x:0, y:0), withAttributes: attributes)
        // Restore the context
        context.restoreGState()
    }
}

