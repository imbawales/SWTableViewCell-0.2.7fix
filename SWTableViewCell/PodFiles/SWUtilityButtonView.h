//
//  SWUtilityButtonView.h
//  SWTableViewCell
//
//  Created by Matt Bowman on 11/27/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SWTableViewCell;

@interface SWUtilityButtonView : UIView

@property (nonatomic, strong) NSArray *utilityButtons;
@property (nonatomic) CGFloat utilityButtonWidth;
@property (nonatomic, weak) SWTableViewCell *parentCell;
@property (nonatomic) SEL utilityButtonSelector;
@property (nonatomic) CGFloat height;

//[ Modified by Stayp 2014/08/14
/*
- (id)initWithUtilityButtons:(NSArray *)utilityButtons parentCell:(SWTableViewCell *)parentCell utilityButtonSelector:(SEL)utilityButtonSelector;

- (id)initWithFrame:(CGRect)frame utilityButtons:(NSArray *)utilityButtons parentCell:(SWTableViewCell *)parentCell utilityButtonSelector:(SEL)utilityButtonSelector;
*/

@property (nonatomic) CGFloat width;

- (id)initWithUtilityButtons:(NSArray *)utilityButtons
                  parentCell:(SWTableViewCell *)parentCell
       utilityButtonSelector:(SEL)utilityButtonSelector
             WithButtonWidth:(CGFloat)width;

- (id)initWithFrame:(CGRect)frame
     utilityButtons:(NSArray *)utilityButtons
         parentCell:(SWTableViewCell *)parentCell
utilityButtonSelector:(SEL)utilityButtonSelector
    WithButtonWidth:(CGFloat)width;
//] Modified by Stayp 2014/08/14

- (void)populateUtilityButtons;
- (CGFloat)utilityButtonsWidth;

@end
