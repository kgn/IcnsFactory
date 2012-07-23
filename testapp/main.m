//
//  main.m
//  IcnsFactory
//
//  Created by David Keegan on 7/22/12.
//  Copyright (c) 2012 David Keegan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IcnsFactory.h"

int main(int argc, char *argv[]){
    @autoreleasepool{
        NSString *testDirectory = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test"];
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:testDirectory error:nil];
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:[files count]];
        [files enumerateObjectsUsingBlock:^(NSString *file, NSUInteger idx, BOOL *stop){
            NSString *path = [testDirectory stringByAppendingPathComponent:file];
            [images addObject:[[NSImage alloc] initWithContentsOfFile:path]];
        }];
        
        NSString *desktop = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, NO)[0]
                             stringByExpandingTildeInPath];
        NSString *iconPath = [desktop stringByAppendingPathComponent:@"Icon.icns"];
        [IcnsFactory writeICNSToFile:iconPath withImages:images];
        [[NSWorkspace sharedWorkspace] openFile:iconPath];
    }
    return 0;
}
