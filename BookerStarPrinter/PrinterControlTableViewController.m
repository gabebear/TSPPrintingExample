//
//  PrinterControlTableViewController.m
//  BookerStarPrinter
//
//  Created by Gabe Ghearing on 10/10/14.
//  Copyright (c) 2014 Booker Software Inc. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/
//

#import "PrinterControlTableViewController.h"
#import "TSP100PrintingService.h"

@interface PrinterControlTableViewController ()
@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end

@implementation PrinterControlTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row==0){
        [TSP100PrintingService popCashDrawerOnHostAddress:self.hostAddress completionBlock:^(NSError *error) {
            if(error) {
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:[error localizedDescription]
                                           delegate:nil
                                  cancelButtonTitle:@"Dismiss"
                                  otherButtonTitles:nil, nil] show];
            }
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
    } else {
        
        
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.delegate = self;
        self.imagePickerController = imagePickerController;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    CGSize newSize = CGSizeMake(576, (image.size.height/image.size.width)*576.0);
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    [TSP100PrintingService printImage:image
                      withHostAddress:self.hostAddress
                        popCashDrawer:NO
                      completionBlock:^(NSError *error) {
                          
                      }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
