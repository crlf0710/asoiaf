//
//  CategoryViewController.h
//  A Song of Ice and Fire
//
//  Created by Vicent Tsai on 15/11/30.
//  Copyright © 2015年 HeZhi Corp. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CategoryMemberModel;

@interface CategoryViewController : UIViewController

@property (nonatomic, strong) CategoryMemberModel *category;

@end