//
//  PrinterControlTableViewController.h
//  BookerStarPrinter
//
//  Created by Gabe Ghearing on 10/10/14.
//  Copyright (c) 2014 Booker Software Inc. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/
//

#import <UIKit/UIKit.h>

@interface PrinterControlTableViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic,strong) NSString *hostAddress;

@end
