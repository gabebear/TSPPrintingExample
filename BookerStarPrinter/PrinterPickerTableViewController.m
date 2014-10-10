//
//  PrinterPickerTableViewController.m
//  BookerStarPrinter
//
//  Created by Gabe Ghearing on 10/9/14.
//  Copyright (c) 2014 Booker Software Inc. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/
//

#import "PrinterPickerTableViewController.h"
#import "PrinterControlTableViewController.h"
#import "TSP100PrintingService.h"

@interface PrinterPickerTableViewController ()
@property(nonatomic,strong) NSArray *ipAddressList;
@property(nonatomic,strong) NSString *selectedIpAddress;
@end

@implementation PrinterPickerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.refreshControl beginRefreshing];
    [self refreshPrinterList:self.refreshControl];
}

- (IBAction)refreshPrinterList:(id)sender {
    self.ipAddressList = [NSArray array];
    [self.tableView reloadData];
    [TSP100PrintingService listPrintersInBlock:^(NSString *ipAddress) {
        self.ipAddressList = [self.ipAddressList arrayByAddingObject:ipAddress];
        [self.tableView reloadData];
    } completionBlock:^(NSError *error) {
        [self.refreshControl endRefreshing];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.ipAddressList count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if(indexPath.row==0){
        cell = [tableView dequeueReusableCellWithIdentifier:@"enterIPCell" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"printerCell" forIndexPath:indexPath];
        cell.textLabel.text = [self.ipAddressList objectAtIndex:indexPath.row-1];
        cell.detailTextLabel.text = @"Found";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row==0){
        UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Manual IP Entry"
                                                         message:@"Enter IP Address for Printer"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles: nil];
        [alert addButtonWithTitle:@"Conect"];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput
         ];
        [alert show];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        self.selectedIpAddress = [self.ipAddressList objectAtIndex:indexPath.row-1];
        [self performSegueWithIdentifier:@"ShowPrinterPage" sender:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) {
        self.selectedIpAddress = [alertView textFieldAtIndex:0].text;
        [self performSegueWithIdentifier:@"ShowPrinterPage" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    PrinterControlTableViewController *printerControlVC = segue.destinationViewController;
    printerControlVC.hostAddress = self.selectedIpAddress;
    
}

@end
