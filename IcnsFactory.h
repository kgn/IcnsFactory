//
//  IcnsFactory.h
//  IcnsFactory
//
//  Created by David Keegan on 7/22/12.
//  Copyright (c) 2012 David Keegan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IcnsFactory : NSObject

+ (BOOL)writeICNSToFile:(NSString *)filePath withImages:(NSArray *)images;

@end
