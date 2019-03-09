//
//  TBTabBar.m
//  TBTabBarController
//
//  Created by Timur Ganiev on 03/02/2019.
//  Copyright © 2019 Timur Ganiev. All rights reserved.
//

#import "TBTabBar.h"
#import "TBTabBar+Private.h"

#import "TBTabBarButton.h"

@interface TBTabBar()

@property (strong, nonatomic) NSArray <TBTabBarButton *> *buttons;

@property (strong, nonatomic) UIView *separatorView;

/** Stack view with tab bar buttons */
@property (strong, nonatomic) UIStackView *stackView;

/** An array of constraints */
@property (strong, nonatomic) NSArray <NSLayoutConstraint *> *stackViewConstraints;

/** A height or width constraint of the separator view */
@property (strong, nonatomic) NSLayoutConstraint *separatorViewDimensionConstraint;

@end

@implementation TBTabBar

@synthesize defaultTintColor = _defaultTintColor;

#pragma mark - Public

- (instancetype)init {
    
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        [self tb_commonInitWithLayoutOrientation:TBTabBarLayoutOrientationHorizontal];
    }
    
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self tb_commonInitWithLayoutOrientation:TBTabBarLayoutOrientationHorizontal];
    }
    
    return self;
}


- (instancetype)initWithLayoutOrientation:(TBTabBarLayoutOrientation)layoutOrientation {
    
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        [self tb_commonInitWithLayoutOrientation:layoutOrientation];
    }
    
    return self;
}


#pragma mark UITraitEnvironment

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    
    if (_separatorViewDimensionConstraint.constant != self.traitCollection.displayScale) {
        _separatorViewDimensionConstraint.constant = (1.0 / self.traitCollection.displayScale);
    }
    
    [super traitCollectionDidChange:previousTraitCollection];
}


#pragma mark - Private

- (void)tb_commonInitWithLayoutOrientation:(TBTabBarLayoutOrientation)layoutOrientation {
    
    // Public
    _layoutOrientation = layoutOrientation;
    _contentInsets = UIEdgeInsetsZero;
    
    // Private
    _vertical = (_layoutOrientation == TBTabBarLayoutOrientationVertical);
    
    [self tb_setup];
}


- (void)tb_setup {
    
    self.backgroundColor = [UIColor whiteColor];
    
    // Separator view
    _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
    _separatorView.translatesAutoresizingMaskIntoConstraints = false;
    _separatorView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    
    [self addSubview:_separatorView];
    
    // Stack view
    _stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
    _stackView.axis = self.isVertical ? UILayoutConstraintAxisVertical : UILayoutConstraintAxisHorizontal;
    _stackView.alignment = UIStackViewAlignmentCenter;
    _stackView.distribution = UIStackViewDistributionFillEqually;
    _stackView.spacing = 4.0;
    _stackView.translatesAutoresizingMaskIntoConstraints = false;
    
    [self addSubview:_stackView];
    
    // Constraints
    [self tb_setupConstraints];
}


#pragma mark Layout

- (void)tb_setupConstraints {
    
    UILayoutGuide *layoutGuide = self.safeAreaLayoutGuide;
    
    // Separator view
    UIView *separatorView = self.separatorView;
    
    NSMutableArray *constraints = [NSMutableArray arrayWithObjects:[separatorView.rightAnchor constraintEqualToAnchor:self.rightAnchor], [separatorView.topAnchor constraintEqualToAnchor:self.topAnchor], nil]; // Init an array with shared constraints
    
    NSLayoutYAxisAnchor *bottomAnchor = nil; // When a tab bar is horizontal (on the bottom of the view controller), it has to play cool with the safe area layout guide
    
    CGFloat const separatorViewSize = (self.traitCollection.displayScale > 0.0) ? (1.0 / self.traitCollection.displayScale) : (1.0 / [UIScreen mainScreen].scale); // Check just in case
    
    if (self.isVertical == false) {
        bottomAnchor = layoutGuide.bottomAnchor;
        _separatorViewDimensionConstraint = [separatorView.heightAnchor constraintEqualToConstant:separatorViewSize];
        [constraints addObjectsFromArray:@[[separatorView.leftAnchor constraintEqualToAnchor:self.leftAnchor], _separatorViewDimensionConstraint]];
    } else {
        bottomAnchor = self.bottomAnchor;
        _separatorViewDimensionConstraint = [separatorView.widthAnchor constraintEqualToConstant:separatorViewSize];
        [constraints addObjectsFromArray:@[[separatorView.bottomAnchor constraintEqualToAnchor:bottomAnchor], _separatorViewDimensionConstraint]];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
    
    // Stack view
    UIStackView *stackView = self.stackView;
    
    UIEdgeInsets contentInsets = self.contentInsets;
    
    _stackViewConstraints = @[[stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:contentInsets.top], [stackView.leftAnchor constraintEqualToAnchor:layoutGuide.leftAnchor constant:contentInsets.left], [stackView.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:contentInsets.bottom], [stackView.rightAnchor constraintEqualToAnchor:layoutGuide.rightAnchor constant:contentInsets.right]]; // Capture an array of the stack view constraints to change their contsants later
    
    [NSLayoutConstraint activateConstraints:_stackViewConstraints];
}


#pragma mark Callbacks

- (void)tb_didSelectItem:(TBTabBarButton *)button {
    
    if (self.delegate == nil) {
        return;
    }
    
    NSUInteger const buttonIndex = [self.buttons indexOfObject:button];
    
    if (buttonIndex != NSNotFound) {
        [self.delegate tabBar:self didSelectItem:self.items[buttonIndex]];
    }
}


#pragma mark Getters

- (UIColor *)separatorColor {
    
    return self.separatorView.backgroundColor;
}


- (UIColor *)defaultTintColor {
    
    if (_defaultTintColor == nil) {
        _defaultTintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    }
    
    return _defaultTintColor;
}


#pragma mark Setters

- (void)setItems:(NSArray <TBTabBarItem *> *)items {
    
    if ([items isEqual:_items]) {
        return;
    }
    
    if (self.buttons.count > 0) {
        for (TBTabBarButton *button in self.buttons) {
            [button removeFromSuperview];
        }
        self.buttons = nil;
    }
    
    _items = items;
    
    NSMutableArray <TBTabBarButton *> *buttons = [NSMutableArray arrayWithCapacity:items.count];
    
    UIStackView *stackView = self.stackView;
    
    for (TBTabBarItem *item in _items) {
        
        TBTabBarButton *button = [[TBTabBarButton alloc] initWithTabBarItem:item];
        button.tintColor = self.defaultTintColor;
        
        [button addTarget:self action:@selector(tb_didSelectItem:) forControlEvents:UIControlEventTouchUpInside];
        
        [stackView addArrangedSubview:button];
        
        if (self.isVertical == false) {
            [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:stackView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0].active = true;
        } else {
            [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:stackView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0].active = true;
        }
        
        [buttons addObject:button];
    }
    
    self.buttons = [buttons copy];
    
    self.buttons[self.selectedIndex].tintColor = self.selectedTintColor;
}


- (void)setSeparatorColor:(UIColor *)separatorColor {
    
    self.separatorView.backgroundColor = separatorColor;
}


- (void)setDefaultTintColor:(UIColor *)defaultTintColor {
    
    if (defaultTintColor != nil) {
        _defaultTintColor = defaultTintColor;
    } else {
        _defaultTintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    }
    
    for (TBTabBarButton *button in self.buttons) {
        button.tintColor = _defaultTintColor;
    }
}


- (void)setSelectedTintColor:(UIColor *)selectedTintColor {
    
    _selectedTintColor = selectedTintColor;
    
    self.buttons[self.selectedIndex].tintColor = _selectedTintColor;
}


- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    
    _selectedIndex = selectedIndex;
    
    for (TBTabBarButton *button in self.buttons) {
        button.tintColor = self.defaultTintColor;
    }
    
    self.buttons[_selectedIndex].tintColor = self.selectedTintColor;
}


- (void)setContentInsets:(UIEdgeInsets)insets {
    
    if (UIEdgeInsetsEqualToEdgeInsets(_contentInsets, insets)) {
        return;
    }
    
    _contentInsets = insets;
    
    // Yeah, that doesn't look like a good solution
    [_stackViewConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger index, BOOL *_Nonnull stop) {
        
        CGFloat inset = 0.0;
        
        switch (index) {
            case 0:
                inset = insets.top;
                break;
            case 1:
                inset = insets.left;
                break;
            case 2:
                inset = insets.bottom;
                break;
            case 3:
                inset = insets.right;
                break;
            default:
                break;
        }
        
        if (constraint.constant != inset) {
            constraint.constant = inset;
        }
    }];
}

@end


