//
//  ProductOverviewViewController.m
//  Kite Print SDK
//
//  Created by Deon Botha on 03/01/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLProductOverviewViewController.h"
#import "OLProductOverviewPageContentViewController.h"
#import "OLProduct.h"
#import "OLOrderReviewViewController.h"
#import "OLPosterSizeSelectionViewController.h"
#import "OLWhiteSquare.h"
#import "OLKiteViewController.h"
#import "OLAnalytics.h"
#import "OLProductTypeSelectionViewController.h"
#import "OLSingleImageProductReviewViewController.h"
#import "OLPhotoSelectionViewController.h"
#import "OLFrameOrderReviewViewController.h"
#import "OLPostcardViewController.h"
#import "NSObject+Utils.h"
#import "NSDecimalNumber+CostFormatter.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLProductDetailsViewController.h"

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)dismiss;

@end

@interface OLProductOverviewViewController () <UIPageViewControllerDataSource, OLProductOverviewPageContentViewControllerDelegate>
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UIButton *callToActionButton;
@property (weak, nonatomic) IBOutlet UILabel *callToActionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *callToActionChevron;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsBoxTopCon;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsViewHeightCon;

@property (strong, nonatomic) OLProductDetailsViewController *productDetails;

@end

@implementation OLProductOverviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupDetailsView];
    
    if (self.product.productTemplate.templateUI == kOLTemplateUIPoster){
        self.title = NSLocalizedString(@"Posters", @"");
    }
    else if (self.product.productTemplate.templateUI == kOLTemplateUIFrame){
        self.title = NSLocalizedString(@"Frames", @"");
    }
    else{
        self.title = self.product.productTemplate.name;
    }
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageController.dataSource = self;
    self.pageController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height + 37);
    
    self.pageControl.numberOfPages = self.product.productPhotos.count;
    [self.pageController setViewControllers:@[[self viewControllerAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self addChildViewController:self.pageController];
    [self.view insertSubview:self.pageController.view belowSubview:self.pageControl];
    [self.pageController didMoveToParentViewController:self];
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    pageControl.backgroundColor = [UIColor clearColor];
    pageControl.frame = CGRectMake(0, -200, 100, 100);
    
    if ([OLKiteABTesting sharedInstance].hidePrice){
        [self.costLabel removeFromSuperview];
    }
    else{
        self.costLabel.text = self.product.unitCost;
    }
    
    UIViewController *vc = self.parentViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    if ([(OLKiteViewController *)vc printOrder]){
        if (![[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Overview-Review-Checkout"]){
            self.callToActionLabel.text = NSLocalizedString(@"Checkout", @"");
        }
        else{
            self.callToActionLabel.text = NSLocalizedString(@"Review", @"");
        }
    }
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackProductDescriptionScreenViewed:self.product.productTemplate.name hidePrice:[OLKiteABTesting sharedInstance].hidePrice];
#endif
    
    if ([[OLKiteABTesting sharedInstance].productTileStyle isEqualToString:@"B"]){
        [self.callToActionChevron removeFromSuperview];
        self.callToActionLabel.textAlignment = NSTextAlignmentCenter;
    }
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id context){
        self.detailsViewHeightCon.constant = size.height > size.width ? 450 : [self.productDetails recommendedDetailsBoxHeight];
        self.detailsBoxTopCon.constant = self.detailsBoxTopCon.constant != 0 ? self.detailsViewHeightCon.constant-100 : 0;
    }completion:NULL];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    if (index == NSNotFound || index >= self.product.productPhotos.count) {
        return nil;
    }
    
    OLProductOverviewPageContentViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ProductOverviewPageContentViewController"];
    vc.pageIndex = index;
    vc.product = self.product;
    vc.delegate = self;
    return vc;
}

- (void)setupDetailsView{
    self.productDetails = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductDetailsViewController"];
    self.productDetails.product = self.product;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:self.productDetails];
    nvc.navigationBarHidden = YES;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        
        UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIView *view = visualEffectView;
        [nvc.view addSubview:view];
        [nvc.view sendSubviewToBack:view];
        nvc.view.backgroundColor = [UIColor clearColor];
        
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[view]-0-|",
                             @"V:|-0-[view]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        
    }
    else{
        nvc.view.backgroundColor = [UIColor whiteColor];
    }
    
    [self addChildViewController:nvc];
    [self.detailsView addSubview:nvc.view];
    UIView *detailsVcView = nvc.view;
    
    detailsVcView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(detailsVcView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[detailsVcView]-0-|",
                         @"V:|-0-[detailsVcView]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [detailsVcView.superview addConstraints:con];
    
    CGSize size = self.view.frame.size;
    self.detailsViewHeightCon.constant = size.height > size.width ? 450 : [self.productDetails recommendedDetailsBoxHeight];
}

- (IBAction)onTapGestureRecognized:(UITapGestureRecognizer *)sender {
    [self onButtonStartClicked:nil];
}

- (IBAction)onLabelDetailsTapped:(UITapGestureRecognizer *)sender {
    self.detailsBoxTopCon.constant = self.detailsBoxTopCon.constant == 0 ? self.detailsViewHeightCon.constant-100 : 0;
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
        self.arrowImageView.transform = self.detailsBoxTopCon.constant == 0 ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
        [self.view layoutIfNeeded];
    }completion:^(BOOL finished){
        
    }];
    
}

- (IBAction)onButtonCallToActionClicked:(id)sender {
    [self onButtonStartClicked:sender];
}

- (IBAction)onButtonStartClicked:(id)sender {
    UIViewController *vc = self.parentViewController;
    OLPrintOrder *printOrder = nil;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            printOrder = [(OLKiteViewController *)vc printOrder];
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    if (printOrder){
        UIViewController *vc;
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Overview-Review-Checkout"]){
            BOOL photoSelection = ![self.delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)];
            if (!photoSelection){
                photoSelection = [self.delegate kiteControllerShouldAllowUserToAddMorePhotos:nil]; //TODO fix this on new payment branch
            }
            vc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:self.product photoSelectionScreen:photoSelection]];
        }
        else{
            [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
                if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Checkout"]){
                    [[vc navigationItem] setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:(OLKiteViewController *)vc action:@selector(dismiss)]];
                }
                [vc safePerformSelector:@selector(setUserEmail:) withObject:self.userEmail];
                [vc safePerformSelector:@selector(setUserPhone:) withObject:self.userPhone];
                [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
                [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
                [self.navigationController pushViewController:vc animated:YES];
            }];
            return;
        }
        [vc safePerformSelector:@selector(setUserEmail:) withObject:self.userEmail];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:self.userPhone];
        [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
        [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    
    vc = [self.storyboard instantiateViewControllerWithIdentifier:[OLKiteUtils reviewViewControllerIdentifierForProduct:self.product photoSelectionScreen:![self.delegate respondsToSelector:@selector(kiteControllerShouldAllowUserToAddMorePhotos:)] || [self.delegate kiteControllerShouldAllowUserToAddMorePhotos:[OLKiteUtils kiteViewControllerInNavStack:self.navigationController.viewControllers]]]];
    
    [vc safePerformSelector:@selector(setUserSelectedPhotos:) withObject:self.userSelectedPhotos];
    [vc safePerformSelector:@selector(setDelegate:) withObject:self.delegate];
    [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
    
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)userDidTapOnImage{
    if (self.detailsBoxTopCon.constant != 0){
        [self onLabelDetailsTapped:nil];
    }
    else{
        [self onButtonStartClicked:nil];
    }
}
- (IBAction)onPanGestureRecognized:(UIPanGestureRecognizer *)gesture {
    
    static CGFloat originalY;
    
    if (gesture.state == UIGestureRecognizerStateBegan){
        originalY = self.detailsBoxTopCon.constant;
        [self.view layoutIfNeeded];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged){
        CGPoint translate = [gesture translationInView:gesture.view.superview];
        self.detailsBoxTopCon.constant = MIN(originalY - translate.y, self.detailsViewHeightCon.constant);
        
        CGFloat percentComplete = self.detailsBoxTopCon.constant / (self.detailsViewHeightCon.constant-100.0);
        self.arrowImageView.transform = CGAffineTransformMakeRotation(M_PI * MIN(percentComplete, 1));
    }
    else if (gesture.state == UIGestureRecognizerStateEnded ||
             gesture.state == UIGestureRecognizerStateFailed ||
             gesture.state == UIGestureRecognizerStateCancelled){
        CGFloat percentComplete = self.detailsBoxTopCon.constant / (self.detailsViewHeightCon.constant-100.0);
        CGFloat time = [gesture velocityInView:gesture.view].y < 0 ? ABS(0.8 - (0.8 * percentComplete)) : ABS(0.8 * percentComplete);
        self.detailsBoxTopCon.constant = [gesture velocityInView:gesture.view].y < 0 ? self.detailsViewHeightCon.constant-100 : 0;
        [UIView animateWithDuration:time delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
            self.arrowImageView.transform = [gesture velocityInView:gesture.view].y > 0 ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
            [self.view layoutIfNeeded];
        }completion:^(BOOL finished){
            
        }];
    }
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    OLProductOverviewPageContentViewController *vc = (OLProductOverviewPageContentViewController *) viewController;
    vc.delegate = self;
    self.pageControl.currentPage = vc.pageIndex;
    NSUInteger index = vc.pageIndex - 1;
    if (vc.pageIndex == 0) {
        index = self.product.productPhotos.count - 1;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    OLProductOverviewPageContentViewController *vc = (OLProductOverviewPageContentViewController *) viewController;
    vc.delegate = self;
    self.pageControl.currentPage = vc.pageIndex;
    NSUInteger index = (vc.pageIndex + 1) % self.product.productPhotos.count;
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return self.product.productPhotos.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 1;
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}


@end