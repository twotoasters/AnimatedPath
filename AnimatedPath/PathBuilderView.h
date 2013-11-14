//
//  PathBuilderView.h
//  AnimatedPath
//
//  Created by Andrew Hershberger on 11/13/13.
//  Copyright (c) 2013 Two Toasters, LLC. All rights reserved.
//

@import UIKit;

@class ShapeView;

@interface PathBuilderView : UIView

@property (nonatomic, strong, readonly) ShapeView *pathShapeView;
@property (nonatomic, strong, readonly) ShapeView *prospectivePathShapeView;
@property (nonatomic, strong, readonly) ShapeView *pointsShapeView;

@end
