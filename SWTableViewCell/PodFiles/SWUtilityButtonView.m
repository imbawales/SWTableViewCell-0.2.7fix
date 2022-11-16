//
//  SWUtilityButtonView.m
//  SWTableViewCell
//
//  Created by Matt Bowman on 11/27/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import "SWUtilityButtonView.h"
#import "SWUtilityButtonTapGestureRecognizer.h"
#import "SWConstants.h"

@implementation SWUtilityButtonView

#pragma mark - SWUtilityButonView initializers

//[ Modified by Stayp 2014/08/14
/*
- (id)initWithUtilityButtons:(NSArray *)utilityButtons parentCell:(SWTableViewCell *)parentCell utilityButtonSelector:(SEL)utilityButtonSelector
*/
- (id)initWithUtilityButtons:(NSArray *)utilityButtons
                  parentCell:(SWTableViewCell *)parentCell
       utilityButtonSelector:(SEL)utilityButtonSelector
             WithButtonWidth:(CGFloat)width
//] Modified by Stayp 2014/08/14
{
    self = [super init];
    
    if (self) {
        self.utilityButtons = utilityButtons;
        self.width = width; // Added by Stayp 2014/08/14
        self.utilityButtonWidth = [self calculateUtilityButtonWidth];
        self.parentCell = parentCell;
        self.utilityButtonSelector = utilityButtonSelector;
    }
    
    return self;
}

//[ Modified by Stayp 2014/08/14
/*
- (id)initWithFrame:(CGRect)frame utilityButtons:(NSArray *)utilityButtons parentCell:(SWTableViewCell *)parentCell utilityButtonSelector:(SEL)utilityButtonSelector
 */
- (id)initWithFrame:(CGRect)frame
     utilityButtons:(NSArray *)utilityButtons
         parentCell:(SWTableViewCell *)parentCell
utilityButtonSelector:(SEL)utilityButtonSelector
    WithButtonWidth:(CGFloat)width
//] Modified by Stayp 2014/08/14
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.utilityButtons = utilityButtons;
        self.width = width; // Added by Stayp 2014/08/14
        self.utilityButtonWidth = [self calculateUtilityButtonWidth];
        self.parentCell = parentCell;
        self.utilityButtonSelector = utilityButtonSelector;
    }
    
    return self;
}

#pragma mark Populating utility buttons

- (CGFloat)calculateUtilityButtonWidth
{
    CGFloat buttonWidth = _width; //kUtilityButtonWidthDefault;  // Modified by Stayp 2014/08/14
    if (buttonWidth * _utilityButtons.count > kUtilityButtonsWidthMax)
    {
        CGFloat buffer = (buttonWidth * _utilityButtons.count) - kUtilityButtonsWidthMax;
        buttonWidth -= (buffer / _utilityButtons.count);
    }
    return buttonWidth;
}

- (CGFloat)utilityButtonsWidth
{
    return (_utilityButtons.count * _utilityButtonWidth);
}

- (void)populateUtilityButtons
{
    NSUInteger utilityButtonsCounter = 0;
    for (UIButton *utilityButton in _utilityButtons)
    {
        CGFloat utilityButtonXCord = 0;
        if (utilityButtonsCounter >= 1) utilityButtonXCord = _utilityButtonWidth * utilityButtonsCounter;
        [utilityButton setFrame:CGRectMake(utilityButtonXCord, 0, _utilityButtonWidth, CGRectGetHeight(self.bounds))];
//        [utilityButton setTag:utilityButtonsCounter]; // Commented by Stayp 2014/08/14
        SWUtilityButtonTapGestureRecognizer *utilityButtonTapGestureRecognizer = [[SWUtilityButtonTapGestureRecognizer alloc] initWithTarget:_parentCell
                                                                                                                                      action:_utilityButtonSelector];
        utilityButtonTapGestureRecognizer.buttonIndex = utilityButtonsCounter;
        utilityButtonTapGestureRecognizer.buttonType = utilityButton.tag; // Added by Stayp 2014/08/14
        
        [utilityButton addGestureRecognizer:utilityButtonTapGestureRecognizer];
        [self addSubview: utilityButton];
        utilityButtonsCounter++;
    }
}

- (void)setHeight:(CGFloat)height
{
    for (NSUInteger utilityButtonsCounter = 0; utilityButtonsCounter < _utilityButtons.count; utilityButtonsCounter++)
    {
        UIButton *utilityButton = (UIButton *)_utilityButtons[utilityButtonsCounter];
        CGFloat utilityButtonXCord = 0;
        if (utilityButtonsCounter >= 1) utilityButtonXCord = _utilityButtonWidth * utilityButtonsCounter;
        [utilityButton setFrame:CGRectMake(utilityButtonXCord, 0, _utilityButtonWidth, height)];
    }
}

@end

