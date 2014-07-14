//
//  ZWayAboutController.m
//  ZWay
//
//  Created by Lucas von Hacht on 30/06/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayAboutController.h"

@interface ZWayAboutController ()

@end

@implementation ZWayAboutController
@synthesize textview;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setOpaque:YES];
    [self.tabBarController.tabBar setTranslucent:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    textview.text = NSLocalizedString(@"AboutSection", @"");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
