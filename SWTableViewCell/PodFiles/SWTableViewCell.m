//
//  SWTableViewCell.m
//  SWTableViewCell
//
//  Created by Chris Wendel on 9/10/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import "SWTableViewCell.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "SWUtilityButtonView.h"

static NSString * const kTableViewCellContentView = @"UITableViewCellContentView";

#pragma mark - SWUtilityButtonView

@interface SWTableViewCell () <UIScrollViewDelegate>
{
//[ Modified by Stayp 2014/08/14
/*
    SWCellState _cellState; // The state of the cell within the scroll view, can be left, right or middle
*/
//] Modified by Stayp 2014/08/14
    CGFloat additionalRightPadding;
    
    dispatch_once_t onceToken;
}

@property (nonatomic, strong) SWUtilityButtonView *scrollViewButtonViewLeft;
@property (nonatomic, strong) SWUtilityButtonView *scrollViewButtonViewRight;
//@property (nonatomic, weak) UIView *scrollViewContentView;    // Commented by Stayp 2018/06/30
@property (nonatomic) CGFloat height;

@property (nonatomic, strong) SWLongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

//[ Modified by Stayp 2014/08/14
/*
@property (nonatomic, assign, getter = isShowingSelection) BOOL showingSelection; // YES if we are currently highlighting the cell for selection
*/
@property (nonatomic, assign) SWCellState cellState;
@property (nonatomic, strong) UIPanGestureRecognizer *tableViewPanGestureRecognizer;

- (void)selectCell;
- (void)deselectCell;
- (BOOL)shouldHighlight;
//] Added by Stayp 2014/08/14
@end

@implementation SWTableViewCell

#pragma mark Initializers

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier containingTableView:(UITableView *)containingTableView leftUtilityButtons:(NSArray *)leftUtilityButtons rightUtilityButtons:(NSArray *)rightUtilityButtons
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.height = containingTableView.rowHeight;
        [self initializer];
        self.containingTableView = containingTableView;
        self.rightUtilityButtons = rightUtilityButtons;
        self.leftUtilityButtons = leftUtilityButtons;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self initializer];
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self initializer];
    }
    
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        [self initializer];
    }
    
    return self;
}

- (void)initializer
{
    // Set up scroll view that will host our cell content
    SWCellScrollView *cellScrollView = [[SWCellScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.height)];
    cellScrollView.delegate = self;
    cellScrollView.showsHorizontalScrollIndicator = NO;
    cellScrollView.scrollsToTop = NO;
    cellScrollView.scrollEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(scrollViewUp:)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [cellScrollView addGestureRecognizer:tapGestureRecognizer];
    
    self.tapGestureRecognizer = tapGestureRecognizer;
    
    SWLongPressGestureRecognizer *longPressGestureRecognizer = [[SWLongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(scrollViewPressed:)];
    longPressGestureRecognizer.cancelsTouchesInView = NO;
    longPressGestureRecognizer.minimumPressDuration = kLongPressMinimumDuration;
    longPressGestureRecognizer.delegate = self;
    [cellScrollView addGestureRecognizer:longPressGestureRecognizer];
    
    self.longPressGestureRecognizer = longPressGestureRecognizer;
    
    self.cellScrollView = cellScrollView;
    
    // Create the content view that will live in our scroll view
    UIView *scrollViewContentView = [[UIView alloc] initWithFrame:CGRectMake([self leftUtilityButtonsWidth], 0, CGRectGetWidth(self.bounds), self.height)];
    scrollViewContentView.backgroundColor = [UIColor whiteColor];
    [self.cellScrollView addSubview:scrollViewContentView];
    self.scrollViewContentView = scrollViewContentView;
    
    // Add the cell scroll view to the cell
    UIView *contentViewParent = self;
    if (self.subviews.count > 0 && ![NSStringFromClass([[self.subviews objectAtIndex:0] class]) isEqualToString:kTableViewCellContentView])
    {
        // iOS 7
        contentViewParent = [self.subviews objectAtIndex:0];
    }
    NSArray *cellSubviews = [contentViewParent subviews];
    [self insertSubview:cellScrollView atIndex:0];
    for (UIView *subview in cellSubviews)
    {
        [self.scrollViewContentView addSubview:subview];
    }
//[ Modified by Stayp 2014/08/14
/*
    self.showingSelection = NO;
    self.highlighted = NO;
 */
    _cellState = kCellStateCenter;
//] Modified by Stayp 2014/08/14
}

- (void)setContainingTableView:(UITableView *)containingTableView
{
//[ Added by Stayp 2014/08/14
    [self removeOldTableViewPanObserver];
    _tableViewPanGestureRecognizer = containingTableView.panGestureRecognizer;
//] Added by Stayp 2014/08/14
    
    _containingTableView = containingTableView;
    // Check if the UITableView will display Indices on the right. If that's the case, add a padding
    if([_containingTableView.dataSource respondsToSelector:@selector(sectionIndexTitlesForTableView:)])
    {
        NSArray *indices = [_containingTableView.dataSource sectionIndexTitlesForTableView:_containingTableView];
        additionalRightPadding = indices == nil ? 0 : kSectionIndexWidth;
    }
    
    _containingTableView.directionalLockEnabled = YES;
    
    self.height = _containingTableView.rowHeight;
    [self.tapGestureRecognizer requireGestureRecognizerToFail:_containingTableView.panGestureRecognizer];
    
    [_tableViewPanGestureRecognizer addObserver:self forKeyPath:kTableViewPanState options:0 context:nil];  // Added by Stayp 2014/08/14
}

//[ Added by Stayp 2014/08/14

static NSString * const kTableViewPanState = @"state";

- (void)removeOldTableViewPanObserver
{
    [_tableViewPanGestureRecognizer removeObserver:self forKeyPath:kTableViewPanState];
}

- (void)dealloc
{
    [self removeOldTableViewPanObserver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:kTableViewPanState] && object == _tableViewPanGestureRecognizer)
    {
        if(_tableViewPanGestureRecognizer.state == UIGestureRecognizerStateBegan)
        {
            CGPoint locationInTableView = [_tableViewPanGestureRecognizer locationInView:_containingTableView];
            
            BOOL inCurrentCell = CGRectContainsPoint(self.frame, locationInTableView);
            if(!inCurrentCell && _cellState != kCellStateCenter)
            {
                if ([self.delegate respondsToSelector:@selector(swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:)])
                {
                    if([self.delegate swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:self])
                    {
                        [self hideUtilityButtonsAnimated:YES];
                    }
                }
            }
        }
    }
}
//] Added by Stayp 2014/08/14

- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    _cellState = kCellStateCenter;    // Commented by Stayp 2014/08/14
    
    self.cellScrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.height);
    self.cellScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + [self utilityButtonsPadding], self.height);
//[ Modified by Stayp 2014/08/14
//    self.cellScrollView.contentOffset = CGPointMake([self leftUtilityButtonsWidth], 0);
    switch (_cellState) {
        case kCellStateLeft:
            [self.cellScrollView setContentOffset:CGPointZero animated:NO];
            break;
        case kCellStateCenter:
            [self.cellScrollView setContentOffset:CGPointMake([self leftUtilityButtonsWidth], 0) animated:NO];
            break;
        case kCellStateRight:
            [self.cellScrollView setContentOffset:CGPointMake([self utilityButtonsPadding], 0) animated:NO];
            break;
        default:
            break;
    }
//] Modified by Stayp 2014/08/14
    self.scrollViewButtonViewLeft.frame = CGRectMake([self leftUtilityButtonsWidth], 0, 0, self.height);
    self.scrollViewButtonViewLeft.layer.masksToBounds = YES;
    self.scrollViewButtonViewRight.frame = CGRectMake(CGRectGetWidth(self.bounds), 0, 0, self.height);
    self.scrollViewButtonViewRight.layer.masksToBounds = YES;
    self.scrollViewContentView.frame = CGRectMake([self leftUtilityButtonsWidth], 0, CGRectGetWidth(self.bounds), self.height);
    self.tapGestureRecognizer.enabled = YES;
//[ Modified by Stayp 2014/08/14
/*
    self.showingSelection = NO;
    self.cellScrollView.scrollEnabled = self.selected;
 */
    [self scrollViewDidScroll:self.cellScrollView];
    self.cellScrollView.scrollEnabled = !self.isEditing;
//] Modified by Stayp 2014/08/14
}

#pragma mark - Properties
//[ Added by Stayp 2014/08/14
- (void)setLeftUtilityButtons:(NSArray *)rightUtilityButtons
{
    [self setLeftUtilityButtons:rightUtilityButtons WithButtonWidth:kUtilityButtonWidthDefault];
}

- (void)setRightUtilityButtons:(NSArray *)rightUtilityButtons
{
    [self setRightUtilityButtons:rightUtilityButtons WithButtonWidth:kUtilityButtonWidthDefault];
}

//] Added by Stayp 2014/08/14

//[ Modified by Stayp 2014/08/14
- (void)setLeftUtilityButtons:(NSArray *)leftUtilityButtons WithButtonWidth:(CGFloat)width
//] Modified by Stayp 2014/08/14
{
    _leftUtilityButtons = leftUtilityButtons;
    SWUtilityButtonView *departingLeftButtons = self.scrollViewButtonViewLeft;
    
//[ Modified by Stayp 2014/08/14
/*
    SWUtilityButtonView *scrollViewButtonViewLeft = [[SWUtilityButtonView alloc] initWithUtilityButtons:leftUtilityButtons
                                                                                             parentCell:self
                                                                                  utilityButtonSelector:@selector(leftUtilityButtonHandler:)];
 */
    SWUtilityButtonView *scrollViewButtonViewLeft =
    [[SWUtilityButtonView alloc] initWithUtilityButtons:leftUtilityButtons
                                             parentCell:self
                                  utilityButtonSelector:@selector(leftUtilityButtonHandler:)
                                        WithButtonWidth:width];
//] Modified by Stayp 2014/08/14
    
    self.scrollViewButtonViewLeft = scrollViewButtonViewLeft;
    [scrollViewButtonViewLeft setFrame:CGRectMake([self leftUtilityButtonsWidth], 0, [self leftUtilityButtonsWidth], self.height)];
    
    [self.cellScrollView insertSubview:scrollViewButtonViewLeft belowSubview:self.scrollViewContentView];

    [departingLeftButtons removeFromSuperview];
    [scrollViewButtonViewLeft populateUtilityButtons];
    
    [self setNeedsLayout];
}

//[ Modified by Stayp 2014/08/14
- (void)setRightUtilityButtons:(NSArray *)rightUtilityButtons WithButtonWidth:(CGFloat)width
//] Modified by Stayp 2014/08/14
{
    _rightUtilityButtons = rightUtilityButtons;
    SWUtilityButtonView *departingLeftButtons = self.scrollViewButtonViewRight;

//[ Modified by Stayp 2014/08/14
/*
    SWUtilityButtonView *scrollViewButtonViewRight = [[SWUtilityButtonView alloc] initWithUtilityButtons:rightUtilityButtons
                                                                                              parentCell:self
                                                                                   utilityButtonSelector:@selector(rightUtilityButtonHandler:)];
 */
    SWUtilityButtonView *scrollViewButtonViewRight =
    [[SWUtilityButtonView alloc] initWithUtilityButtons:rightUtilityButtons
                                             parentCell:self
                                  utilityButtonSelector:@selector(rightUtilityButtonHandler:)
                                        WithButtonWidth:width];
//] Modified by Stayp 2014/08/14

    self.scrollViewButtonViewRight = scrollViewButtonViewRight;
    [scrollViewButtonViewRight setFrame:CGRectMake(CGRectGetWidth(self.bounds), 0, [self rightUtilityButtonsWidth], self.height)];
    
    [self.cellScrollView insertSubview:scrollViewButtonViewRight belowSubview:self.scrollViewContentView];
    
    [departingLeftButtons removeFromSuperview];
    [scrollViewButtonViewRight populateUtilityButtons];
    
    [self setNeedsLayout];
}


#pragma mark Selection

//[ Modified by Stayp 2014/08/14
/*
- (void)scrollViewPressed:(id)sender
{
    SWLongPressGestureRecognizer *longPressGestureRecognizer = (SWLongPressGestureRecognizer *)sender;
    
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        // Gesture recognizer ended without failing so we select the cell
        [self selectCell];
        
        // Set back to deselected
        [self setSelected:NO];
    }
    else
    {
        // Handle the highlighting of the cell
        if (self.isHighlighted)
        {
            [self setHighlighted:NO];
        }
        else
        {
            [self highlightCell];
        }
    }
}

- (void)scrollViewUp:(id)sender
{
    if(_cellState == kCellStateCenter)
    {
        // Selection
        if ([self.containingTableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
        {
            NSIndexPath *cellIndexPath = [self.containingTableView indexPathForCell:self];
            self.showingSelection = YES;
            [self setSelected:YES];
            [self.containingTableView selectRowAtIndexPath:cellIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self.containingTableView.delegate tableView:self.containingTableView didSelectRowAtIndexPath:cellIndexPath];
        }
    }
    else
    {
        // Scroll back to center
        [self hideUtilityButtonsAnimated:YES];
    }
}

- (void)selectCell
{
    if (_cellState == kCellStateCenter)
    {
        if ([self.containingTableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
        {
            NSIndexPath *cellIndexPath = [self.containingTableView indexPathForCell:self];
            [self.containingTableView selectRowAtIndexPath:cellIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self.containingTableView.delegate tableView:self.containingTableView didSelectRowAtIndexPath:cellIndexPath];
            [self.containingTableView deselectRowAtIndexPath:cellIndexPath animated:NO];
        }
    }
}

- (void)highlightCell
{
    if (_cellState == kCellStateCenter)
    {
        [self setHighlighted:YES];
    }
}

- (void)timerEndCellHighlight:(id)sender
{
    self.showingSelection = NO;
    [self setSelected:NO];
}
 */

- (void)scrollViewPressed:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan && !self.isHighlighted && self.shouldHighlight)
    {
        [self setHighlighted:YES animated:NO];
    }
    
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [self setHighlighted:NO animated:NO];
        [self scrollViewUp:gestureRecognizer];
    }
    
    else if (gestureRecognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self setHighlighted:NO animated:NO];
    }
}

- (void)scrollViewUp:(UIGestureRecognizer *)gestureRecognizer
{
    if (_cellState == kCellStateCenter)
    {
        BOOL scollOther = FALSE;
        if ([self.delegate respondsToSelector:@selector(swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:)])
        {
            for (SWTableViewCell *cell in [self.containingTableView visibleCells]) {
                if (cell != self && [cell isKindOfClass:[SWTableViewCell class]] && [self.delegate swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:cell]) {
                    if (cell.cellState != kCellStateCenter)
                    {
                        scollOther = TRUE;
                        [cell hideUtilityButtonsAnimated:YES];
                    }
                }
            }
            if (scollOther)
            {
                return;
            }
        }
        
        if (self.isSelected)
        {
            [self deselectCell];
        }
        else if (self.shouldHighlight)
        {
            [self selectCell];
        }
    }
    else
    {
        [self hideUtilityButtonsAnimated:YES];
    }
}

- (void)selectCell
{
    if (_cellState == kCellStateCenter)
    {
        NSIndexPath *cellIndexPath = [self.containingTableView indexPathForCell:self];
        
        if ([self.containingTableView.delegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)])
        {
            cellIndexPath = [self.containingTableView.delegate tableView:self.containingTableView willSelectRowAtIndexPath:cellIndexPath];
        }
        
        if (cellIndexPath)
        {
            [self.containingTableView selectRowAtIndexPath:cellIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            if ([self.containingTableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
            {
                [self.containingTableView.delegate tableView:self.containingTableView didSelectRowAtIndexPath:cellIndexPath];
            }
        }
    }
}

- (void)deselectCell
{
    if (_cellState == kCellStateCenter)
    {
        NSIndexPath *cellIndexPath = [self.containingTableView indexPathForCell:self];
        
        if ([self.containingTableView.delegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)])
        {
            cellIndexPath = [self.containingTableView.delegate tableView:self.containingTableView willDeselectRowAtIndexPath:cellIndexPath];
        }
        
        if (cellIndexPath)
        {
            [self.containingTableView deselectRowAtIndexPath:cellIndexPath animated:NO];
            
            if ([self.containingTableView.delegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)])
            {
                [self.containingTableView.delegate tableView:self.containingTableView didDeselectRowAtIndexPath:cellIndexPath];
            }
        }
    }
}

- (BOOL)shouldHighlight
{
    BOOL shouldHighlight = YES;
    
    if ([self.containingTableView.delegate respondsToSelector:@selector(tableView:shouldHighlightRowAtIndexPath:)])
    {
        NSIndexPath *cellIndexPath = [self.containingTableView indexPathForCell:self];
        
        shouldHighlight = [self.containingTableView.delegate tableView:self.containingTableView shouldHighlightRowAtIndexPath:cellIndexPath];
    }
    
    return shouldHighlight;
}
//] Modified by Stayp 2014/08/14

#pragma mark UITableViewCell overrides

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    _scrollViewContentView.backgroundColor = backgroundColor;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateHighlight:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self updateHighlight:selected animated:animated];
}

#pragma mark - Highlighting methods

- (void)updateHighlight:(BOOL)highlight animated:(BOOL)animated;
{
    [self setHighlighted:highlight animated:animated];
}

#pragma mark -  Height methods

- (void)setCellHeight:(CGFloat)height
{
    _height = height;
    
    // update the utility button height
    [self.scrollViewButtonViewLeft setHeight:height];
    [self.scrollViewButtonViewRight setHeight:height];
    
    [self layoutSubviews];
}

#pragma mark - Utility buttons handling

- (void)rightUtilityButtonHandler:(id)sender
{
    SWUtilityButtonTapGestureRecognizer *utilityButtonTapGestureRecognizer = (SWUtilityButtonTapGestureRecognizer *)sender;
    NSUInteger utilityButtonIndex = utilityButtonTapGestureRecognizer.buttonIndex;
    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCell:didTriggerRightUtilityButtonWithIndex:)])
    {
        [self.delegate swipeableTableViewCell:self didTriggerRightUtilityButtonWithIndex:utilityButtonIndex];
    }
//[ Added by Stayp 2014/08/14
    else if ([self.delegate respondsToSelector:@selector(swipeableTableViewCell:didTriggerRightUtilityButtonWithGesture:)])
    {
        [self.delegate swipeableTableViewCell:self didTriggerRightUtilityButtonWithGesture:utilityButtonTapGestureRecognizer];
    }
//] Added by Stayp 2014/08/14
}

- (void)leftUtilityButtonHandler:(id)sender
{
    SWUtilityButtonTapGestureRecognizer *utilityButtonTapGestureRecognizer = (SWUtilityButtonTapGestureRecognizer *)sender;
    NSUInteger utilityButtonIndex = utilityButtonTapGestureRecognizer.buttonIndex;
    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCell:didTriggerLeftUtilityButtonWithIndex:)])
    {
        [self.delegate swipeableTableViewCell:self didTriggerLeftUtilityButtonWithIndex:utilityButtonIndex];
    }
//[ Added by Stayp 2014/08/14
    else if ([self.delegate respondsToSelector:@selector(swipeableTableViewCell:didTriggerRightUtilityButtonWithGesture:)])
    {
        [self.delegate swipeableTableViewCell:self didTriggerRightUtilityButtonWithGesture:utilityButtonTapGestureRecognizer];
    }
//] Added by Stayp 2014/08/14
}

- (void)hideUtilityButtonsAnimated:(BOOL)animated
{
    if (_cellState == kCellStateCenter)
        return;
    // Scroll back to center
    
    // Force the scroll back to run on the main thread because of weird scroll view bugs
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.cellScrollView setContentOffset:CGPointMake([self leftUtilityButtonsWidth], 0) animated:YES];
    });
    _cellState = kCellStateCenter;
    
    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCell:scrollingToState:)])
    {
        [self.delegate swipeableTableViewCell:self scrollingToState:kCellStateCenter];
    }
}


#pragma mark - Setup helpers

- (CGFloat)leftUtilityButtonsWidth
{
    return [self.scrollViewButtonViewLeft utilityButtonsWidth];
}

- (CGFloat)rightUtilityButtonsWidth
{
    return [self.scrollViewButtonViewRight utilityButtonsWidth] + additionalRightPadding;
}

- (CGFloat)utilityButtonsPadding
{
    return [self leftUtilityButtonsWidth] + [self rightUtilityButtonsWidth];
}

- (CGPoint)scrollViewContentOffset
{
    return CGPointMake([self.scrollViewButtonViewLeft utilityButtonsWidth], 0);
}

- (void)setAppearanceWithBlock:(void (^)())appearanceBlock force:(BOOL)force
{
    if (force)
    {
        appearanceBlock();
    }
    else
    {
        dispatch_once(&onceToken, ^{
            appearanceBlock();
        });
    }
}

#pragma mark UIScrollView helpers

- (void)scrollToRight:(inout CGPoint *)targetContentOffset
{
    targetContentOffset->x = [self utilityButtonsPadding];
    _cellState = kCellStateRight;
    
    self.longPressGestureRecognizer.enabled = NO;
    self.tapGestureRecognizer.enabled = NO;
    
    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCell:scrollingToState:)])
    {
        [self.delegate swipeableTableViewCell:self scrollingToState:kCellStateRight];
    }

    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:)])
    {
        for (SWTableViewCell *cell in [self.containingTableView visibleCells]) {
            if (cell != self && [cell isKindOfClass:[SWTableViewCell class]] && [self.delegate swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:cell]) {
                [cell hideUtilityButtonsAnimated:YES];
            }
        }
    }
}

- (void)scrollToCenter:(inout CGPoint *)targetContentOffset
{
    targetContentOffset->x = [self leftUtilityButtonsWidth];
    _cellState = kCellStateCenter;
    
    self.longPressGestureRecognizer.enabled = YES;
    self.tapGestureRecognizer.enabled = NO;

    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCell:scrollingToState:)])
    {
        [self.delegate swipeableTableViewCell:self scrollingToState:kCellStateCenter];
    }
}

- (void)scrollToLeft:(inout CGPoint *)targetContentOffset
{
    targetContentOffset->x = 0;
    _cellState = kCellStateLeft;
    
    self.longPressGestureRecognizer.enabled = NO;
    self.tapGestureRecognizer.enabled = NO;
    
    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCell:scrollingToState:)])
    {
        [self.delegate swipeableTableViewCell:self scrollingToState:kCellStateLeft];
    }
    
    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:)])
    {
        for (SWTableViewCell *cell in [self.containingTableView visibleCells]) {
            if (cell != self && [cell isKindOfClass:[SWTableViewCell class]] && [self.delegate swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:cell]) {
                [cell hideUtilityButtonsAnimated:YES];
            }
        }
    }
}

#pragma mark UIScrollViewDelegate

//[ Added by stayp 2014/08/13
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:)])
    {
        for (SWTableViewCell *cell in [self.containingTableView visibleCells]) {
            if (cell != self && [cell isKindOfClass:[SWTableViewCell class]] && [self.delegate swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:cell]) {
                [cell hideUtilityButtonsAnimated:YES];
            }
        }
    }
}
//] Added by stayp 2014/08/13

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    switch (_cellState)
    {
        case kCellStateCenter:
            if (velocity.x >= 0.5f)
            {
                [self scrollToRight:targetContentOffset];
            }
            else if (velocity.x <= -0.5f)
            {
                [self scrollToLeft:targetContentOffset];
            }
            else
            {
                CGFloat rightThreshold = [self utilityButtonsPadding] - ([self rightUtilityButtonsWidth] / 2);
                CGFloat leftThreshold = [self leftUtilityButtonsWidth] / 2;
                if (targetContentOffset->x > rightThreshold)
                    [self scrollToRight:targetContentOffset];
                else if (targetContentOffset->x < leftThreshold)
                    [self scrollToLeft:targetContentOffset];
                else
                    [self scrollToCenter:targetContentOffset];
            }
            break;
        case kCellStateLeft:
            if (velocity.x >= 0.5f)
            {
                [self scrollToCenter:targetContentOffset];
            }
            else if (velocity.x <= -0.5f)
            {
                // No-op
            }
            else
            {
                if (targetContentOffset->x >= ([self utilityButtonsPadding] - [self rightUtilityButtonsWidth] / 2))
                    [self scrollToRight:targetContentOffset];
                else if (targetContentOffset->x > [self leftUtilityButtonsWidth] / 2)
                    [self scrollToCenter:targetContentOffset];
                else
                    [self scrollToLeft:targetContentOffset];
            }
            break;
        case kCellStateRight:
            if (velocity.x >= 0.5f)
            {
                // No-op
            }
            else if (velocity.x <= -0.5f)
            {
                [self scrollToCenter:targetContentOffset];
            }
            else
            {
                if (targetContentOffset->x <= [self leftUtilityButtonsWidth] / 2)
                    [self scrollToLeft:targetContentOffset];
                else if (targetContentOffset->x < ([self utilityButtonsPadding] - [self rightUtilityButtonsWidth] / 2))
                    [self scrollToCenter:targetContentOffset];
                else
                    [self scrollToRight:targetContentOffset];
            }
            break;
        default:
            break;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.tapGestureRecognizer.enabled = NO;
    if (scrollView.contentOffset.x > [self leftUtilityButtonsWidth])
    {
        if ([self rightUtilityButtonsWidth] > 0)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(swipeableTableViewCell:canSwipeToState:)])
            {
                BOOL shouldScroll = [self.delegate swipeableTableViewCell:self canSwipeToState:kCellStateRight];
                if (!shouldScroll)
                {
                    scrollView.contentOffset = CGPointMake([self leftUtilityButtonsWidth], 0);
                    return;
                }
            }
            CGFloat scrollViewWidth = MIN(scrollView.contentOffset.x - [self leftUtilityButtonsWidth], [self rightUtilityButtonsWidth]);
            
            // Expose the right button view
            self.scrollViewButtonViewRight.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - scrollViewWidth), 0.0f, scrollViewWidth,self.height);
            
            CGRect scrollViewBounds = self.scrollViewButtonViewRight.bounds;
            scrollViewBounds.origin.x = MAX([self rightUtilityButtonsWidth] - scrollViewWidth, [self rightUtilityButtonsWidth] - scrollView.contentOffset.x);
            self.scrollViewButtonViewRight.bounds = scrollViewBounds;
        }
        else
        {
            [scrollView setContentOffset:CGPointMake([self leftUtilityButtonsWidth], 0)];
            self.tapGestureRecognizer.enabled = YES;
        }
    }
    else
    {
        // Expose the left button view
        if ([self leftUtilityButtonsWidth] > 0)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(swipeableTableViewCell:canSwipeToState:)])
            {
                BOOL shouldScroll = [self.delegate swipeableTableViewCell:self canSwipeToState:kCellStateLeft];
                if (!shouldScroll)
                {
                    scrollView.contentOffset = CGPointMake([self leftUtilityButtonsWidth], 0);
                    return;
                }
            }
            CGFloat scrollViewWidth = MIN(scrollView.contentOffset.x - [self leftUtilityButtonsWidth], [self leftUtilityButtonsWidth]);
            
            self.scrollViewButtonViewLeft.frame = CGRectMake([self leftUtilityButtonsWidth], 0.0f, scrollViewWidth, self.height);
        }
        else
        {
            [scrollView setContentOffset:CGPointMake(0, 0)];
            self.tapGestureRecognizer.enabled = YES;
        }
    }
}

//[ Added by Stayp 2014/09/24
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self setCellState];
        
        self.tapGestureRecognizer.enabled = YES;
    }
}
//] Added by Stayp 2014/09/24

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self setCellState];
    
    self.tapGestureRecognizer.enabled = YES;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self setCellState];
    
    // Called when setContentOffset in hideUtilityButtonsAnimated: is done
    self.tapGestureRecognizer.enabled = YES;
    if (_cellState == kCellStateCenter)
    {
        self.longPressGestureRecognizer.enabled = YES;
    }
}

#pragma mark - Cell State

- (void)setCellState
{
    if ([self.cellScrollView contentOffset].x == [self leftUtilityButtonsWidth])
        _cellState = kCellStateCenter;
    else if ([self.cellScrollView contentOffset].x == 0)
        _cellState = kCellStateLeft;
    else if ([self.cellScrollView contentOffset].x == [self utilityButtonsPadding])
        _cellState = kCellStateRight;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Return YES so the pan gesture of the containing table view is not cancelled by the long press recognizer
    return YES;
}

@end
