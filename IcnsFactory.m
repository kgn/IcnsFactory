//
//  IcnsFactory.m
//  IcnsFactory
//
//  Created by David Keegan on 7/22/12.
//  Copyright (c) 2012 David Keegan. All rights reserved.
//

#import "IcnsFactory.h"

UInt32 flipUInt32(UInt32 littleEndian){
	UInt32 newNum = 0;
	char *newBuff = (char *)&newNum;
	const char *oldBuff = (const char *)&littleEndian;
	newBuff[3] = oldBuff[0];
	newBuff[2] = oldBuff[1];
	newBuff[1] = oldBuff[2];
	newBuff[0] = oldBuff[3];
	return newNum;
}

@implementation IcnsFactory

+ (NSDictionary *)iconSizes{
    static dispatch_once_t once;
    static NSDictionary *iconSizes;
    dispatch_once(&once, ^{
        iconSizes = @{@1024: @"ic10", @512: @"ic09", @256: @"ic08"};
    });
    return iconSizes;
}

+ (BOOL)writeICNSToFile:(NSString *)filePath withImages:(NSArray *)images{
	if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
	}
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSData data] attributes:nil];    
	NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
	if(handle == nil){
		return NO;
	}
    
    __block NSUInteger bodyLength = 0;
    __block NSMutableData *bodyData = [NSMutableData data];
    [images enumerateObjectsUsingBlock:^(NSImage *image, NSUInteger idx, BOOL *stop){
        NSUInteger width = round(image.size.width);
        NSUInteger height = round(image.size.height);
        if(width != height){
            return;
        }
        NSString *type = [[self iconSizes] objectForKey:[NSNumber numberWithInteger:round(image.size.width)]];
        if(type == nil){
            return;
        }
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
        NSData *pngData = [bitmap representationUsingType:NSPNGFileType properties:nil];
        bodyLength += [pngData length];
        
        UInt32 length = flipUInt32(8 + (UInt32)[pngData length]);
        [bodyData appendData:[type dataUsingEncoding:NSASCIIStringEncoding]];
        [bodyData appendBytes:&length length:4];
        [bodyData appendData:pngData];
    }];
    
    NSMutableData *headerData = [NSMutableData data];
    UInt32 fileLength = flipUInt32(16 + (UInt32)bodyLength);
    [headerData appendData:[@"icns" dataUsingEncoding:NSASCIIStringEncoding]];
    [headerData appendBytes:&fileLength length:4];
	[handle writeData:headerData];
	[handle writeData:bodyData];
	[handle closeFile];
    return YES;
}

@end
