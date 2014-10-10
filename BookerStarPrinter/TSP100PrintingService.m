//
//  TSP100PrintingService.m
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

#import "TSP100PrintingService.h"
#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"


@interface TSP100PrintingService ()
@property(nonatomic, strong) GCDAsyncSocket *tcpSocket;
@property(nonatomic, strong) UIImage *imageToPrint;
@property(nonatomic, assign) BOOL isCurrentlyPrinting;
@property(nonatomic, assign) BOOL shouldOpenDrawer;
@property(nonatomic, strong) void (^imageCompletionBlock)(NSError *error);
+ (TSP100PrintingService*)globalPrinterService;
@end

@implementation TSP100PrintingService

+ (TSP100PrintingService*)globalPrinterService {
    static TSP100PrintingService *global = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        global = [[TSP100PrintingService alloc] init];
    });
    
    return global;
}

+ (void)listPrintersInBlock:(void(^)(NSString *ipAddress))foundPrinterBlock
            completionBlock:(void(^)(NSError *error))completionBlock {
    GCDAsyncUdpSocket *udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    if ((![udpSocket bindToPort:0 error:&error]) || (![udpSocket beginReceiving:&error])) {
        [udpSocket close];
        completionBlock(error);
    }
    
    if (udpSocket && (!error)) {
        UInt8 askForPrinters[] = { 0x53, 0x54, 0x52, 0x5f, 0x42, 0x43, 0x41, 0x53, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x52, 0x51, 0x31, 0x2e, 0x30, 0x2e, 0x30, 0x00, 0x00, 0x1c, 0x64, 0x31 };
        UInt8 askForPrintersLength = 28;
        NSData *askForPrintersData = [NSData dataWithBytes:askForPrinters length:askForPrintersLength];
        
        [udpSocket enableBroadcast:YES error:nil];
        [udpSocket sendData:askForPrintersData
                     toHost:@"255.255.255.255"
                       port:22222
                withTimeout:-1
                        tag:0];
        
        [udpSocket setReceiveFilter:^BOOL(NSData *data, NSData *address, __autoreleasing id *context) {
            NSString *host = nil;
            uint16_t port = 0;
            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
            
            if (port == 22222) {
                // if it's a TSP100LAN, add it to the list
                if (NSNotFound != [data rangeOfData:[NSData dataWithBytes:"TSP100LAN" length:9] options:0 range:NSMakeRange(0, [data length])].location) {
                    foundPrinterBlock([host copy]);
                }
            }
            return YES;
        } withQueue:dispatch_get_main_queue()];
        
        // wait 6 seconds so printers have time to respond
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [udpSocket close];
            completionBlock(nil);
        });
    }
}

+ (void)popCashDrawerOnHostAddress:(NSString*)hostAddress
                   completionBlock:(void(^)(NSError *error))completionBlock {
    [self printImage:nil
     withHostAddress:hostAddress
       popCashDrawer:YES
     completionBlock:completionBlock];
}

+ (void) printImage:(UIImage*)image
    withHostAddress:(NSString*)hostAddress
      popCashDrawer:(BOOL)popCashDrawer
    completionBlock:(void(^)(NSError *error))completionBlock {
    TSP100PrintingService *printerService = [self globalPrinterService];
    [printerService printImage:image
               withHostAddress:hostAddress
                 popCashDrawer:popCashDrawer
               completionBlock:completionBlock];
}

- (void) printImage:(UIImage*)image
    withHostAddress:(NSString*)hostAddress
      popCashDrawer:(BOOL)popCashDrawer
    completionBlock:(void(^)(NSError *error))completionBlock  {
    if (!self.isCurrentlyPrinting) {
        [self openPrinterPortWithHost:hostAddress];
        self.shouldOpenDrawer = popCashDrawer;
        self.imageToPrint = image;
        self.isCurrentlyPrinting = YES;
        self.imageCompletionBlock = [completionBlock copy];
        
        UInt8 askForStatus[] = { 0x1b, 0x06, 0x01 };
        [self.tcpSocket writeData:[NSData dataWithBytes:askForStatus length:3] withTimeout:-1 tag:1];
        [self.tcpSocket readDataToLength:9 withTimeout:-1 tag:2];
        
        
        // when we get a status back we'll print the image or send error
        
        // wait 8 seconds, if we haven't gotten anything from the printer kill the connection
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSError *error = [NSError errorWithDomain:@"com.booker.iosapp"
                                                 code:1
                                             userInfo:[NSDictionary
                                                       dictionaryWithObject:@"Printer Connection Timed Out"
                                                       forKey:NSLocalizedDescriptionKey]];
            [self finishImagePrintWithError:error];
        });
    }
}

- (void)openPrinterPortWithHost:(NSString*)host {
    self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    [self.tcpSocket setAutoDisconnectOnClosedReadStream:YES];
    
    NSError *error = nil;
    if (![self.tcpSocket connectToHost:host
                                onPort:9100
                                 error:&error]) {
        NSLog(@"Error connecting: %@", error);
    }
}

- (void)closePrinterPort {
    [self.tcpSocket disconnectAfterWriting];
    //[self.tcpSocket setDelegate:nil];
    //self.tcpSocket = nil;
}

- (void)finishImagePrintWithError:(NSError*)error {
    [self closePrinterPort];
    self.imageToPrint = nil;
    if (self.imageCompletionBlock) {
        self.imageCompletionBlock(error);
    }
    self.imageCompletionBlock = nil;
    self.isCurrentlyPrinting = NO;
}

- (void)sendRasterHeader {
    UInt8 printStuffHeader[] = {
        0x1b, 0x1d, 0x03, // (start document, initialize)
        0x03, 0x00, 0x00,
        0x1b, 0x2a, 0x72, 0x41, // (enter raster mode)
        0x1b, 0x2a, 0x72, 0x54, // (set raster top margin)
        0x32, 0x00,
        0x1b, 0x2a, 0x72, 0x51, // (Set raster print quality)
        0x31, 0x00,
        0x1b, 0x2a, 0x72, 0x50, // (Set raster page length) [ASCII 0x30 = '0', so continuous]
        0x30, 0x00,
        0x1b, 0x2a, 0x72, 0x6d, 0x6c, // (Set raster left margin) [ASCII 0x30 = '0']
        0x30, 0x00,
        0x1b, 0x2a, 0x72, 0x6d, 0x72, // (Set raster right margin) [ASCII 0x30 = '0']
        0x30, 0x00,
        0x1b, 0x2a, 0x72, 0x45, // (Set raster EOT mode)
        0x39, 0x00,
        0x1b, 0x2a, 0x72, 0x46, // (Set raster FF mode)
        0x39, 0x00,
    };
    [self.tcpSocket writeData:[NSData dataWithBytes:printStuffHeader length:54] withTimeout:-1 tag:1];
}

- (void)sendRasterFooter {
    UInt8 printStuffFooter[] = {
        0x1b, 0x2a, 0x72, 0x42, // (Quit raster mode)
        0x1b, 0x1d, 0x03, // (end document, waits for printing to end, cancels any extra data)
        0x04, 0x00, 0x00,
        0x17, 0x17 // ETB * 2
    };
    [self.tcpSocket writeData:[NSData dataWithBytes:printStuffFooter length:12] withTimeout:-1 tag:1];
}

- (void)sendOpenDrawer1 {
    UInt8 openDrawerCmds[] = {
        0x1b, 0x2a, 0x72, 0x44, // pop the drawer
        0x31, 0x00, // drawer #1 0x31 = '1'
    };
    [self.tcpSocket writeData:[NSData dataWithBytes:openDrawerCmds length:6] withTimeout:-1 tag:1];
}

// this is untested... I don't have a second cash drawer
- (void)sendOpenDrawer2 {
    UInt8 openDrawerCmds[] = {
        0x1b, 0x2a, 0x72, 0x44, // pop the drawer
        0x32, 0x00, // drawer #1 0x32 = '2'
    };
    [self.tcpSocket writeData:[NSData dataWithBytes:openDrawerCmds length:6] withTimeout:-1 tag:1];
}

- (void)sendImage:(UIImage*)image {
    UInt8 printScanlineHeader[] = {
        0x62, // Send raster data (auto line feed)]
        0x48, // low bytes (0x48 so we get 576pixels(72bytes))
        0x00, // high bytes (always 0 on TSP100)
    };
    
    // get the raw image on a white background
    CGImageRef cgImage = [image CGImage];
    NSUInteger width = CGImageGetWidth(cgImage);
    NSUInteger height = CGImageGetHeight(cgImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    const CGFloat white[] = { 1.0f, 1.0f, 1.0f, 1.0f };
    CGContextSetFillColor(context, white);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);
    
    // push the Black & White scanlines to the TCP socket
    NSUInteger scanWidth = width;
    if (scanWidth > 576) {
        scanWidth = 576;
    }
    for (int line = 0; line < height; line++) {
        [self.tcpSocket writeData:[NSData dataWithBytes:printScanlineHeader length:3] withTimeout:-1 tag:1];
        Byte printStuffScanlineBody[72] = { 0x00 };
        for (NSUInteger scanPixel = 0; scanPixel < scanWidth; scanPixel++) {
            int byteIndex = (int)((bytesPerRow * line) + scanPixel * bytesPerPixel);
            if (rawData[byteIndex] + rawData[byteIndex + 1] + rawData[byteIndex + 2] < (160 * 3)) {
                printStuffScanlineBody[scanPixel / 8] |= 0x80 >> (scanPixel % 8);
            }
        }
        [self.tcpSocket writeData:[NSData dataWithBytes:printStuffScanlineBody length:72] withTimeout:-1 tag:1];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    //NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag {
    Byte *buffer = (Byte*)data.bytes;
    //NSLog(@"status: %@", data);
    if ((data.length >= 9) && (buffer[0] == 0x23)) {
        NSError *error = nil;
        if (buffer[2] & (1 << 5)) {
            NSLog(@"Error: printer cover open");
            error = [NSError errorWithDomain:@"com.booker.iosapp"
                                        code:1
                                    userInfo:[NSDictionary
                                              dictionaryWithObject:@"Printer Cover Open"
                                              forKey:NSLocalizedDescriptionKey]];
        } else if (buffer[2] & (1 << 3)) {
            NSLog(@"Error: printer offline");
            error = [NSError errorWithDomain:@"com.booker.iosapp"
                                        code:1
                                    userInfo:[NSDictionary
                                              dictionaryWithObject:@"Printer Offline"
                                              forKey:NSLocalizedDescriptionKey]];
        } else {
            // we got a good status! print the image!
            [self sendRasterHeader];
            if (self.shouldOpenDrawer) {
                [self sendOpenDrawer1];
            }
            if (self.imageToPrint) {
                [self sendImage:self.imageToPrint];
            }
            [self sendRasterFooter];
        }
        [self finishImagePrintWithError:error];
    } else if (data.length > 0) {
        NSString *output = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        if (nil != output) {
            NSLog(@"printer said: %@", output);
            self.isCurrentlyPrinting = NO; // we shouldn't get here... but probably not printing anymore if we do...
        }
    }
}

@end
