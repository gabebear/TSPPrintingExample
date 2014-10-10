//
//  TSP100PrintingService.h
//  NativeiOSBooker
//
//  Created by Gabe Ghearing on 9/23/13.
//  Copyright (c) 2013 Booker Software. All rights reserved.
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/
//
//  This was figured out largely from http://www.star-m.jp/eng/service/usermanual/linemode_cm_en.pdf
//  TSP100 isn't actually mentioned there... but you can infer
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface TSP100PrintingService : NSObject<NSStreamDelegate>

+ (void)listPrintersInBlock:(void(^)(NSString *ipAddress))foundPrinterBlock
            completionBlock:(void(^)(NSError *error))completionBlock;

+ (void)popCashDrawerOnHostAddress:(NSString*)hostAddress
                   completionBlock:(void(^)(NSError *error))completionBlock;

+ (void) printImage:(UIImage*)image
    withHostAddress:(NSString*)hostAddress
      popCashDrawer:(BOOL)popCashDrawer
    completionBlock:(void(^)(NSError *error))completionBlock;


@end
