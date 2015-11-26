//
//  WikiViewController.m
//  A Song of Ice and Fire
//
//  Created by Vicent Tsai on 15/11/12.
//  Copyright © 2015年 HeZhi Corp. All rights reserved.
//

#import "WikiViewController.h"

#import "WikipediaHelper.h"
#import "ParallaxHeaderView.h"
#import "GradientView.h"
#import "UIImageViewAligned.h"
#import "CubicSpinner.h"

#import "JTSImageViewController.h"
#import "OpenShareHeader.h"
#import "MBProgressHUD.h"

static NSInteger const kTITLE_LABEL_HEIGHT = 58;
static NSInteger const kBLUR_VIEW_OFFSET = 85;
static CGFloat const kHUD_SHOW_TIME = 2.18;
                 
@interface WikiViewController ()
<
WikipediaHelperDelegate,
UIWebViewDelegate,
UIScrollViewDelegate,
ParallaxHeaderViewDelegate,
UIGestureRecognizerDelegate
>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageViewAligned *imageView;
@property (nonatomic, strong) UIView *webBrowserView;
@property (nonatomic, strong) GradientView *blurView;
@property (nonatomic, strong) ParallaxHeaderView *parallaxHeaderView;
@property (nonatomic, strong) CubicSpinner *spinner;

@property (nonatomic, strong) WikipediaHelper *wikiHelper;
@property (nonatomic, assign) CGFloat originalHeight;

@end

@implementation WikiViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _wikiHelper = [[WikipediaHelper alloc] init];
        _wikiHelper.delegate = self;
        _spinner = [CubicSpinner spinner];

        NSMutableArray *rightButtons = [@[] mutableCopy];
        UIBarButtonItem *homeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                                                                    target:self
                                                                                    action:@selector(homeButtonPressed:)];
        [rightButtons addObject:homeButton];

        if ([OpenShare isWeixinInstalled]) {
            UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                         target:self
                                                                                         action:@selector(shareButtonPressed:)];
            [rightButtons addObject:shareButton];
        }

        self.navigationItem.rightBarButtonItems = [rightButtons copy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.delegate = self;
    self.webView.scrollView.delegate = self;
    self.webBrowserView = [[self.webView.scrollView subviews] objectAtIndex:0];

    self.spinner.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];

    [self setupParallaxHeaderView];
    [self setupGestures];

    // Start fetch article with page title
    [self.wikiHelper fetchArticle:self.title];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Views

- (void)resetView
{

    [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = \"\";"];
    [self.webView.scrollView setContentOffset:CGPointMake(0, -self.webView.scrollView.contentInset.top) animated:NO];

    self.imageView.image = nil;
    [self.titleLabel removeFromSuperview];
}

- (void)setupHeaderView
{
    self.imageView = [[UIImageViewAligned alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 223)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.imageView.frame.size.height - kTITLE_LABEL_HEIGHT,
                                                               self.imageView.frame.size.width, kTITLE_LABEL_HEIGHT)];

    self.titleLabel.text = self.title;
    self.titleLabel.backgroundColor = [UIColor colorWithRed:42/255.0 green:196/255.0 blue:234/255.0 alpha:0.7];
    self.titleLabel.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:21.0];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.shadowColor = [UIColor blackColor];
    self.titleLabel.shadowOffset = CGSizeMake(0, 1);
    self.titleLabel.textAlignment = UIControlContentHorizontalAlignmentLeft|UIControlContentVerticalAlignmentBottom;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.5;

    [self.imageView addSubview:self.titleLabel];

    CGRect f = self.webBrowserView.frame;
    f.origin.y = self.imageView.frame.size.height;
    self.webBrowserView.frame = f;

    [self.webView.scrollView addSubview:self.imageView];
}

- (void)setupParallaxHeaderView
{
    self.imageView = [[UIImageViewAligned alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 223)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;

    self.originalHeight = self.imageView.frame.size.height;

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.originalHeight - 80, self.imageView.frame.size.width - 30, 60)];

    self.titleLabel.text = [NSString stringWithFormat:@"  %@", self.title];
    self.titleLabel.text = [NSString stringWithFormat:@"  %@", self.title];
    self.titleLabel.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:21.0];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.shadowColor = [UIColor blackColor];
    self.titleLabel.shadowOffset = CGSizeMake(0, 1);
    self.titleLabel.textAlignment = UIControlContentHorizontalAlignmentLeft|UIControlContentVerticalAlignmentBottom;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.5;

    [self.imageView addSubview:self.titleLabel];

    self.blurView = [[GradientView alloc] initWithFrame:CGRectMake(0, -kBLUR_VIEW_OFFSET,
                                                                   self.view.frame.size.width, self.originalHeight + kBLUR_VIEW_OFFSET)
                                                   type:TransparentGradientTwiceType];
    
    [self.imageView addSubview:self.blurView];
    [self.imageView bringSubviewToFront:self.titleLabel];

    self.parallaxHeaderView = [ParallaxHeaderView parallaxWebHeaderViewWithSubView:self.imageView
                                                                           forSize:CGSizeMake(self.view.frame.size.width, 223)];
    self.parallaxHeaderView.delegate = self;

    // We set _parallaxHeaderView's origin.y as -20, and _imageView is subview of it,
    // so we should set _webBrowerView's origin.y is -20 smaller than it of _imageView.
    CGRect f = self.webBrowserView.frame;
    f.origin.y = self.imageView.frame.size.height - 20;
    self.webBrowserView.frame = f;
    
    [self.webView.scrollView addSubview:self.parallaxHeaderView];
}


#pragma mark - Setup Gestures

- (void)setupGestures
{
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.webView addGestureRecognizer:singleTap];
    singleTap.delegate = self;
    singleTap.cancelsTouchesInView = NO;
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    CGPoint pt = [sender locationInView:self.webView];
    NSString *imgURL = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", pt.x, pt.y];
    NSString *imageSource = [self.webView stringByEvaluatingJavaScriptFromString:imgURL];
    if (imageSource.length > 0) {
        // Create image info
        JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
        imageInfo.imageURL = [NSURL URLWithString:imageSource];

        imageInfo.referenceRect = self.webView.frame;
        imageInfo.referenceView = self.webView.superview;

        // Setup view controller
        JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                               initWithImageInfo:imageInfo
                                               mode:JTSImageViewControllerMode_Image
                                               backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled];

        // Present the view controller.
        [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
    }
}

#pragma mark - WikipediaHelperDelegate

- (void)dataLoaded:(NSString *)htmlPage withUrlMainImage:(NSString *)urlMainImage
{
    if(![urlMainImage isEqualToString:@""] && urlMainImage != nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // Perform long running process
            NSData *imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: urlMainImage]];
            UIImage *image = [UIImage imageWithData:imageData];

            /**
             * Check for imageView before dispatching to the main thread.
             * This avoids the main queue dispatch if the network request took a long time and
             * the imageView is no longer there for one reason or another.
             */
            if (!self.imageView) return;

            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the UI
                self.imageView.image = image;
            });
        });
    } else {
        /**
         * When use ParallaxHeaderView, we don't need to reset header view
         *
         * // Reset subviews of self.webView if there is no image in the wiki page
         *
         * // Remove UIImageView
         * [self.imageView removeFromSuperview];
         *
         * CGRect titleFrame = self.titleLabel.frame;
         * titleFrame.origin.y = 0;
         * self.titleLabel.frame = titleFrame;
         *
         * [self.webView.scrollView addSubview:self.titleLabel];
         *
         * // Restore UIWebBrowserView's position
         * [UIView animateWithDuration:1.0 animations:^{
         *     CGRect f = self.webBrowserView.frame;
         *     f.origin.y = TITLE_LABEL_HEIGHT;
         *     self.webBrowserView.frame = f;
         * }];
         *
         */
    }

    // When the article is loaded, hide and remove spinner from self.view
    [self.spinner stopAnimating];
    [self.spinner setHidden:YES];
    [self.spinner removeFromSuperview];

    [self.webView loadHTMLString:htmlPage baseURL:nil];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [[request URL] absoluteString];
    NSString *prefix = @"http://asoiaf.huiji.wiki/wiki/";

    if (navigationType == UIWebViewNavigationTypeLinkClicked && [url hasPrefix:@"http"]) {
        // Check if the clicked link is a image or not
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\.(jpg|gif|png)"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:url options:0 range:NSMakeRange(0, [url length])];

        // All internal links except IMAGE could create new wiki view controller
        if ([url hasPrefix:prefix] && !match) {
            WikiViewController *nextWikiVC = [[WikiViewController alloc] init];

            NSString *title = [[url substringFromIndex:[prefix length]] stringByRemovingPercentEncoding];
            nextWikiVC.title = title;

            [self.navigationController pushViewController:nextWikiVC animated:YES];
        }
        return NO;
    }

    return YES;
}

/* Disable UIWebView horizontal scrolling */
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [webView.scrollView setContentSize: CGSizeMake(webView.frame.size.width, webView.scrollView.contentSize.height)];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat incrementY = scrollView.contentOffset.y;
    if (incrementY < 0) {
        // 不断设置 titleLabel 以保证 frame 正确
        self.titleLabel.frame = CGRectMake(15, self.originalHeight - 80 - incrementY, self.view.frame.size.width - 30, 60);

        // 不断添加删除 blurView.layer.sublayers![0] 以保证 frame 正确
        self.blurView.frame = CGRectMake(0, -kBLUR_VIEW_OFFSET - incrementY,
                                         self.view.frame.size.width, self.originalHeight + kBLUR_VIEW_OFFSET);
        [self.blurView.layer.sublayers[0] removeFromSuperlayer];
        [self.blurView insertTwiceTransparentGradient];

        // 使 Label 不被遮挡
        [self.imageView bringSubviewToFront:self.titleLabel];
    }

    [self.parallaxHeaderView layoutWebHeaderViewForScrollViewOffset:scrollView.contentOffset];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - ParallaxHeaderViewDelegate

/**
 * 设置滑动极限
 * 修改该值需要一并更改 layoutWebHeaderViewForScrollViewOffset 中的对应值
 */
- (void)lockDirection
{
    CGPoint offset = self.webView.scrollView.contentOffset;
    self.webView.scrollView.contentOffset = CGPointMake(offset.x, -154);
}

#pragma mark - Control Action

- (void)homeButtonPressed:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)shareButtonPressed:(id)sender
{
    OSMessage *msg = [[OSMessage alloc] init];
    msg.title = [NSString stringWithFormat:@"冰与火之歌 - %@", self.title];
    msg.desc = self.title;
    msg.link = [NSString stringWithFormat:@"http://asoiaf.huiji.wiki/wiki/%@", self.title];

    UIImage *image = self.imageView.image;

    if (image) {
        msg.image = image;
    } else {
        msg.image = [UIImage imageNamed:@"Launch Background"];
    }

    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];

    [actionController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [self dismissViewControllerAnimated:YES completion:^{ }];
                                                           [hud hide:YES afterDelay:0];
                                                       }]];

    [actionController addAction:[UIAlertAction actionWithTitle:@"分享给微信好友"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [OpenShare shareToWeixinSession:msg Success:^(OSMessage *message) {
                                                               MBProgressHUD *hud = [self messageHUD:@"微信分享给朋友成功"];
                                                               [hud hide:YES afterDelay:kHUD_SHOW_TIME];
                                                           } Fail:^(OSMessage *message, NSError *error) {
                                                               MBProgressHUD *hud = [self messageHUD:@"微信分享给朋友失败"];
                                                               [hud hide:YES afterDelay:kHUD_SHOW_TIME];
                                                           }];
                                                       }]];

    [actionController addAction:[UIAlertAction actionWithTitle:@"分享到朋友圈"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [OpenShare shareToWeixinTimeline:msg Success:^(OSMessage *message) {
                                                               // ULog(@"微信分享到朋友圈成功：\n%@", message);
                                                               MBProgressHUD *hud = [self messageHUD:@"微信分享到朋友圈成功"];
                                                               [hud hide:YES afterDelay:kHUD_SHOW_TIME];
                                                           } Fail:^(OSMessage *message, NSError *error) {
                                                               // ULog(@"微信分享到朋友圈失败：\n%@\n%@", error, message);
                                                               MBProgressHUD *hud = [self messageHUD:@"微信分享到朋友圈失败"];
                                                               [hud hide:YES afterDelay:kHUD_SHOW_TIME];
                                                           }];
                                                       }]];

    /*
    [actionController addAction:[UIAlertAction actionWithTitle:@"分享到QQ"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [OpenShare shareToQQFriends:msg Success:^(OSMessage *message) {
                                                               MBProgressHUD *hud = [self messageHUD:@"分享到QQ成功"];
                                                               [hud hide:YES afterDelay:kHUD_SHOW_TIME];
                                                           } Fail:^(OSMessage *message, NSError *error) {
                                                               MBProgressHUD *hud = [self messageHUD:@"分享到QQ失败"];
                                                               [hud hide:YES afterDelay:kHUD_SHOW_TIME];
                                                           }];
                                                       }]];
     */

    [self presentViewController:actionController animated:YES completion:nil];
}

#pragma mark - Private Helper Function

- (MBProgressHUD *)messageHUD:(NSString *)message
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = message;

    return hud;
}

@end
