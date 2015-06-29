//
//  OLPhotobookPageViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 4/17/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLPhotobookPageContentViewController.h"
#import "OLPrintPhoto.h"
#import "OLScrollCropViewController.h"

@interface OLPhotobookPageContentViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *pageBackground;

@property (assign, nonatomic) BOOL left;

@end

@implementation OLPhotobookPageContentViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [self loadImageWithCompletionHandler:NULL];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setPage:(self.pageIndex % 2 == 0)];
}

//- (void)setPageIndex:(NSInteger)pageIndex{
//    _pageIndex = pageIndex;
//    
//    [self setPage:(pageIndex % 2 == 0)];
//}

- (void)setPage:(BOOL)left{
    self.left = left;
    if (left){
        self.pageBackground.image = [UIImage imageNamed:@"page-left"];
        self.pageShadowLeft.hidden = NO;
        self.pageShadowRight.hidden = YES;
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;

    }
    else{
        self.pageBackground.image = [UIImage imageNamed:@"page-right"];
        self.pageShadowLeft.hidden = YES;
        self.pageShadowRight.hidden = NO;
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;
    }
}

- (NSInteger)imageIndexForPoint:(CGPoint)p{
    return self.pageIndex; //only one for now
}

- (void)unhighlightImageAtIndex:(NSInteger)index{
    UIView *selectedView = self.imageView; //only one for now
    
    selectedView.layer.borderColor = [UIColor clearColor].CGColor;
    selectedView.layer.borderWidth = 0;
}

- (void)highlightImageAtIndex:(NSInteger)index{
    UIView *selectedView = self.imageView; //only one for now
    
    selectedView.layer.borderColor = self.view.tintColor.CGColor;
    selectedView.layer.borderWidth = 3.0;
}

- (void)clearImage{
    self.pageShadowLeft2.hidden = YES;
    self.pageShadowRight2.hidden = YES;
    self.imageView.image = nil;
}

- (void)loadImageWithCompletionHandler:(void(^)(void))handler{
    OLPrintPhoto *printPhoto = [self.userSelectedPhotos objectAtIndex:self.pageIndex];
    if (printPhoto != (id)[NSNull null]){
        self.imageView.image = nil;
        [printPhoto setImageSize:self.imageView.frame.size cropped:YES completionHandler:^(UIImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
                if (self.left){
                    self.pageShadowLeft2.hidden = NO;
                }
                else{
                    self.pageShadowRight2.hidden = NO;
                }
                if (handler){
                    handler();
                }
            });
        }];
    }
    else{
        self.pageShadowLeft2.hidden = YES;
        self.pageShadowRight2.hidden = YES;
        self.imageView.image = nil;
        if (handler){
            handler();
        }
        
    }
}

@end
