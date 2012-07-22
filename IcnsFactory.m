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

+ (BOOL)writeICNSToFile:(NSString *)filePath withImages:(NSArray *)images{
	if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
		[[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSData data] attributes:nil];
	}
	NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
	if(handle == nil){
		return NO;
	}
    
    NSMutableData *headerData = [NSMutableData data];
    NSMutableData *bodyData = [NSMutableData data];
    [images enumerateObjectsUsingBlock:^(NSImage *image, NSUInteger idx, BOOL *stop) {
        NSUInteger width = round(image.size.width);
        NSUInteger height = round(image.size.height);
        if(width == height && height == 512){
            NSDictionary *properties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
            NSData *jpeg2000Data = [rep representationUsingType:NSJPEG2000FileType properties:properties];
            
            // header
            UInt32 fileLength = flipUInt32(16 + (UInt32)[jpeg2000Data length]);
            [headerData appendData:[@"icns" dataUsingEncoding:NSASCIIStringEncoding]];
            [headerData appendBytes:&fileLength length:4];
            
            // body
            UInt32 elemLength = flipUInt32(8 + (UInt32)[jpeg2000Data length]);
            NSString *elemName = width == 256 ? @"ic08" : @"ic09";
            [bodyData appendData:[elemName dataUsingEncoding:NSASCIIStringEncoding]];
            [bodyData appendBytes:&elemLength length:4];
            [bodyData appendData:jpeg2000Data];            
        }
    }];
	[handle writeData:headerData];
	[handle writeData:bodyData];
	[handle closeFile];
    NSLog(@"%@", filePath);
    return YES;
}

@end
