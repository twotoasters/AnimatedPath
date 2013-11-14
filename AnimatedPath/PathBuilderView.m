//
//  PathBuilderView.m
//  AnimatedPath
//
//  Created by Andrew Hershberger on 11/13/13.
//  Copyright (c) 2013 Two Toasters, LLC. All rights reserved.
//

#import "PathBuilderView.h"
#import "ShapeView.h"

static CGFloat const kDistanceThreshold = 10.0;
static CGFloat const kPointDiameter = 7.0;

@interface PathBuilderView ()
@property (nonatomic, strong) NSMutableArray *points;
@property (nonatomic, strong) NSValue *prospectivePointValue;
@property (nonatomic) NSUInteger indexOfSelectedPoint;
@property (nonatomic) CGVector touchOffsetForSelectedPoint;
@property (nonatomic, strong) NSTimer *pressTimer;
@property (nonatomic) BOOL ignoreTouchEvents;

@end

@implementation PathBuilderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _points = [[NSMutableArray alloc] init];
        self.multipleTouchEnabled = NO;

        _ignoreTouchEvents = NO;
        _indexOfSelectedPoint = NSNotFound;

        _pathShapeView = [[ShapeView alloc] init];
        _pathShapeView.shapeLayer.fillColor = nil;
        _pathShapeView.backgroundColor = [UIColor clearColor];
        _pathShapeView.opaque = NO;
        _pathShapeView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_pathShapeView];

        _prospectivePathShapeView = [[ShapeView alloc] init];
        _prospectivePathShapeView.shapeLayer.fillColor = nil;
        _prospectivePathShapeView.backgroundColor = [UIColor clearColor];
        _prospectivePathShapeView.opaque = NO;
        _prospectivePathShapeView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_prospectivePathShapeView];

        _pointsShapeView = [[ShapeView alloc] init];
        _pointsShapeView.backgroundColor = [UIColor clearColor];
        _pointsShapeView.opaque = NO;
        _pointsShapeView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_pointsShapeView];

        NSDictionary *views = NSDictionaryOfVariableBindings(_pathShapeView, _prospectivePathShapeView, _pointsShapeView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pathShapeView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_prospectivePathShapeView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pointsShapeView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pathShapeView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_prospectivePathShapeView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pointsShapeView]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.pointsShapeView.shapeLayer.fillColor = self.tintColor.CGColor;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.ignoreTouchEvents) {
        return;
    }

    NSValue *pointValue = [self pointValueWithTouches:touches];

    NSIndexSet *indexes = [self.points indexesOfObjectsPassingTest:^BOOL(NSValue *existingPointValue, NSUInteger idx, BOOL *stop) {
        CGPoint point = [pointValue CGPointValue];
        CGPoint existingPoint = [existingPointValue CGPointValue];
        CGFloat distance = ABS(point.x - existingPoint.x) + ABS(point.y - existingPoint.y);
        return distance < kDistanceThreshold;
    }];

    if ([indexes count] > 0) {
        self.indexOfSelectedPoint = [indexes lastIndex];

        NSValue *existingPointValue = [self.points objectAtIndex:self.indexOfSelectedPoint];
        CGPoint point = [pointValue CGPointValue];
        CGPoint existingPoint = [existingPointValue CGPointValue];
        self.touchOffsetForSelectedPoint = CGVectorMake(point.x - existingPoint.x, point.y - existingPoint.y);

        self.pressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                           target:self
                                                         selector:@selector(pressTimerFired:)
                                                         userInfo:nil
                                                          repeats:NO];
    }
    else {
        self.prospectivePointValue = pointValue;
    }

    [self updatePaths];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.ignoreTouchEvents) {
        return;
    }

    [self.pressTimer invalidate];
    self.pressTimer = nil;

    NSValue *pointValue = [self pointValueWithTouches:touches];

    if (self.indexOfSelectedPoint != NSNotFound) {
        NSValue *offsetPointValue = [self pointValueByRemovingOffset:self.touchOffsetForSelectedPoint fromPointValue:pointValue];
        [self.points replaceObjectAtIndex:self.indexOfSelectedPoint withObject:offsetPointValue];
    }
    else {
        self.prospectivePointValue = pointValue;
    }

    [self updatePaths];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.ignoreTouchEvents) {
        self.ignoreTouchEvents = NO;
        return;
    }

    [self.pressTimer invalidate];
    self.pressTimer = nil;

    self.indexOfSelectedPoint = NSNotFound;
    self.prospectivePointValue = nil;
    [self updatePaths];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.ignoreTouchEvents) {
        self.ignoreTouchEvents = NO;
        return;
    }

    [self.pressTimer invalidate];
    self.pressTimer = nil;

    NSValue *pointValue = [self pointValueWithTouches:touches];

    if (self.indexOfSelectedPoint != NSNotFound) {
        NSValue *offsetPointValue = [self pointValueByRemovingOffset:self.touchOffsetForSelectedPoint fromPointValue:pointValue];
        [self.points replaceObjectAtIndex:self.indexOfSelectedPoint withObject:offsetPointValue];
        self.indexOfSelectedPoint = NSNotFound;
    }
    else {
        [self.points addObject:pointValue];
        self.prospectivePointValue = nil;
    }

    [self updatePaths];
}

#pragma mark - Action Methods

- (void)pressTimerFired:(NSTimer *)timer
{
    [self.pressTimer invalidate];
    self.pressTimer = nil;

    [self.points removeObjectAtIndex:self.indexOfSelectedPoint];
    self.indexOfSelectedPoint = NSNotFound;
    self.ignoreTouchEvents = YES;

    [self updatePaths];
}

#pragma mark - Helper Methods

- (void)updatePaths
{
    {
        UIBezierPath *path = [[UIBezierPath alloc] init];
        for (NSValue *pointValue in self.points) {
            CGPoint point = [pointValue CGPointValue];
            [path appendPath:[UIBezierPath bezierPathWithArcCenter:point radius:kPointDiameter / 2.0 startAngle:0.0 endAngle:2 * M_PI clockwise:YES]];
        }
        self.pointsShapeView.shapeLayer.path = path.CGPath;
    }

    if ([self.points count] >= 2) {
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path moveToPoint:[[self.points firstObject] CGPointValue]];

        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [self.points count] - 1)];
        [self.points enumerateObjectsAtIndexes:indexSet
                                       options:0
                                    usingBlock:^(NSValue *pointValue, NSUInteger idx, BOOL *stop) {
                                        [path addLineToPoint:[pointValue CGPointValue]];
                                    }];

        self.pathShapeView.shapeLayer.path = path.CGPath;
    }
    else {
        self.pathShapeView.shapeLayer.path = nil;
    }

    if ([self.points count] >= 1 && self.prospectivePointValue) {
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path moveToPoint:[[self.points lastObject] CGPointValue]];
        [path addLineToPoint:[self.prospectivePointValue CGPointValue]];

        self.prospectivePathShapeView.shapeLayer.path = path.CGPath;
    }
    else {
        self.prospectivePathShapeView.shapeLayer.path = nil;
    }
}

- (NSValue *)pointValueWithTouches:(NSSet *)touches
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    return [NSValue valueWithCGPoint:point];
}

- (NSValue *)pointValueByRemovingOffset:(CGVector)offset fromPointValue:(NSValue *)pointValue
{
    CGPoint point = [pointValue CGPointValue];
    CGPoint offsetPoint = CGPointMake(point.x - offset.dx, point.y - offset.dy);
    return [NSValue valueWithCGPoint:offsetPoint];
}

@end
