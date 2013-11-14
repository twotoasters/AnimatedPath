//
//  PathBuilderViewController.m
//  AnimatedPath
//
//  Created by Andrew Hershberger on 11/13/13.
//  Copyright (c) 2013 Two Toasters, LLC. All rights reserved.
//

#import "PathBuilderViewController.h"
#import "PathBuilderView.h"
#import "ShapeView.h"

static CFTimeInterval const kDuration = 2.0;
static CFTimeInterval const kInitialTimeOffset = 2.0;

@interface PathBuilderViewController ()
@property (nonatomic, readonly) PathBuilderView *pathBuilderView;
@end

@implementation PathBuilderViewController

- (void)loadView
{
    self.view = [[PathBuilderView alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.pathBuilderView.pathShapeView.shapeLayer.strokeColor = [UIColor blackColor].CGColor;
    self.pathBuilderView.prospectivePathShapeView.shapeLayer.strokeColor = [UIColor grayColor].CGColor;
    self.pathBuilderView.pointsShapeView.shapeLayer.strokeColor = [UIColor blackColor].CGColor;

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:NSStringFromSelector(@selector(strokeEnd))];
    animation.fromValue = @0.0;
    animation.toValue = @1.0;
    animation.removedOnCompletion = NO;
    animation.duration = kDuration;
    [self.pathBuilderView.pathShapeView.shapeLayer addAnimation:animation forKey:NSStringFromSelector(@selector(strokeEnd))];

    self.pathBuilderView.pathShapeView.shapeLayer.speed = 0;
    self.pathBuilderView.pathShapeView.shapeLayer.timeOffset = 0.0;

    [CATransaction flush];

    self.pathBuilderView.pathShapeView.shapeLayer.timeOffset = kInitialTimeOffset;

    UISwitch *showDotsSwitch = [[UISwitch alloc] init];
    showDotsSwitch.on = YES;
    [showDotsSwitch addTarget:self action:@selector(showDotsSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
    showDotsSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:showDotsSwitch];

    UILabel *showDotsLabel = [[UILabel alloc] init];
    showDotsLabel.text = NSLocalizedString(@"Show dots", nil);
    showDotsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:showDotsLabel];

    UISlider *strokeEndSlider = [[UISlider alloc] init];
    strokeEndSlider.minimumValue = 0.0;
    strokeEndSlider.maximumValue = kDuration;
    strokeEndSlider.value = kInitialTimeOffset;
    strokeEndSlider.continuous = YES;
    [strokeEndSlider addTarget:self action:@selector(strokeEndSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    strokeEndSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:strokeEndSlider];

    UIButton *drawPathButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [drawPathButton setTitle:NSLocalizedString(@"Draw Path", nil) forState:UIControlStateNormal];
    [drawPathButton addTarget:self action:@selector(drawPathButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    drawPathButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:drawPathButton];

    NSDictionary *views = NSDictionaryOfVariableBindings(showDotsLabel, showDotsSwitch, drawPathButton);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[showDotsLabel]-[showDotsSwitch]->=20-[drawPathButton]-|"
                                                                      options:NSLayoutFormatAlignAllCenterY
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[showDotsSwitch]-|" options:0 metrics:nil views:views]];

    id topLayoutGuide = self.topLayoutGuide;
    views = NSDictionaryOfVariableBindings(strokeEndSlider, topLayoutGuide);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[strokeEndSlider]-|"
                                                                      options:NSLayoutFormatAlignAllCenterY
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][strokeEndSlider]" options:0 metrics:nil views:views]];
}

- (PathBuilderView *)pathBuilderView
{
    return (PathBuilderView *)self.view;
}

- (void)showDotsSwitchValueChanged:(UISwitch *)showDotsSwitch
{
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.pathBuilderView.pointsShapeView.alpha = showDotsSwitch.on ? 1.0 : 0.0;
                     }
                     completion:nil];
}

- (void)strokeEndSliderValueChanged:(UISlider *)strokeEndSlider
{
    self.pathBuilderView.pathShapeView.shapeLayer.timeOffset = strokeEndSlider.value;
}

- (void)drawPathButtonTapped
{
    CFTimeInterval timeOffset = self.pathBuilderView.pathShapeView.shapeLayer.timeOffset;
    [CATransaction setCompletionBlock:^{
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:NSStringFromSelector(@selector(strokeEnd))];
        animation.fromValue = @0.0;
        animation.toValue = @1.0;
        animation.removedOnCompletion = NO;
        animation.duration = kDuration;
        self.pathBuilderView.pathShapeView.shapeLayer.speed = 0;
        self.pathBuilderView.pathShapeView.shapeLayer.timeOffset = 0;
        [self.pathBuilderView.pathShapeView.shapeLayer addAnimation:animation forKey:NSStringFromSelector(@selector(strokeEnd))];
        [CATransaction flush];
        self.pathBuilderView.pathShapeView.shapeLayer.timeOffset = timeOffset;
    }];

    self.pathBuilderView.pathShapeView.shapeLayer.timeOffset = 0.0;
    self.pathBuilderView.pathShapeView.shapeLayer.speed = 1.0;

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:NSStringFromSelector(@selector(strokeEnd))];
    animation.fromValue = @0.0;
    animation.toValue = @1.0;
    animation.duration = kDuration;

    [self.pathBuilderView.pathShapeView.shapeLayer addAnimation:animation forKey:NSStringFromSelector(@selector(strokeEnd))];
}

@end
