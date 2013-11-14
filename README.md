# AnimatedPath

AnimatedPath explores using the `CAMediaTiming` protocol to interactively control the drawing of a path.

## Basic usage

### Step 1: Draw a Path

- Tap around the screen to add points to a path.
- Drag existing points to move them.
- Tap and hold existing points to remove them.

### Step 2: Animate

- The path is rendered using a `CAShapeLayer` with `speed == 0`.
- The layer has an animation for its [`strokeEnd`](https://developer.apple.com/library/iOs/documentation/GraphicsImaging/Reference/CAShapeLayer_class/Reference/Reference.html#//apple_ref/doc/uid/TP40008314-CH1-SW15) key path with a `fromValue` of 0 and a `toValue` of 1.
- Since the layer's `speed == 0`, adjusting the layer's `timeOffset` controls the time at which the animation is rendered.
- The slider at the top of the screen adjusts the layer's `timeOffset`.

## Getting the Setup Right

The most difficult part of putting this example together was understanding how to add the animation to the layer and still be able to control the animation's progress via the `timeOffset`. Here's what worked:

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

The end result of this approach is that the animation has a `beginTime` of 0 and the shape layer renders it at time `kInitialTimeOffset`.

The `[CATransaction flush]` is required because it forces the system to give the animation added to the layer a `beginTime`. The animation's `beginTime` is calculated by adding its initial value (its value before being added to the layer) to the layer's current time. This is why the layer's `timeOffset` must be set to 0 rather than `kInitialTimeOffset` when the animation is added. Otherwise, the animation's `beginTime` will have already taken `kInitialTimeOffset` into account such that the animation is added to the time range `(kInitialTimeOffset, kInitialTimeOffset + kDuration)` instead of `(0, kDuration)`.

## More Info

- This example was inspired by [Controlling Animation Timing](http://ronnqvi.st/controlling-animation-timing/) by [David Rönnqvist](https://twitter.com/davidronnqvist)
- Apple's [Timing, Timespaces, and CAAnimation](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Animation_Types_Timing/Articles/Timing.html) is a helpful resource.