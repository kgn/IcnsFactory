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

@interface IcnsFactory()
+ (NSData *)dataFromOSType:(OSType)OSType;
+ (NSUInteger)appendImage:(NSImage *)image toBodyData:(NSMutableData *)bodyData;
@end

@implementation IcnsFactory

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
        bodyLength += [self appendImage:image toBodyData:bodyData];
    }];
    
    NSMutableData *headerData = [NSMutableData data];
    UInt32 fileLength = flipUInt32(16 + (UInt32)bodyLength);
    [headerData appendData:[self dataFromOSType:kIconFamilyType]];
    [headerData appendBytes:&fileLength length:4];
	[handle writeData:headerData];
	[handle writeData:bodyData];
	[handle closeFile];
    return YES;
}

+ (NSData *)dataFromOSType:(OSType)OSType{
    NSString *string = (__bridge NSString *)UTCreateStringForOSType(OSType);
    return [string dataUsingEncoding:NSASCIIStringEncoding];
}

+ (NSUInteger)appendImage:(NSImage *)image toBodyData:(NSMutableData *)bodyData{
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    NSInteger pixelsWide = [bitmap pixelsWide];
    NSInteger pixelsHigh = [bitmap pixelsHigh];
    if(pixelsWide != pixelsHigh){
        return 0;
    }
    if(pixelsWide == 1024 || pixelsWide == 512 || pixelsWide == 256){
        NSData *imageData = [bitmap representationUsingType:NSPNGFileType properties:nil];
        UInt32 length = flipUInt32(8 + (UInt32)[imageData length]);
        if(pixelsWide == 1024){
            [bodyData appendData:[self dataFromOSType:kIconServices1024PixelDataARGB]];
        }else if(pixelsWide == 512){
            [bodyData appendData:[self dataFromOSType:kIconServices512PixelDataARGB]];
        }else if(pixelsWide == 256){
            [bodyData appendData:[self dataFromOSType:kIconServices256PixelDataARGB]];
        }
        [bodyData appendBytes:&length length:4];
        [bodyData appendData:imageData];
        return [imageData length];
    }
    
    BOOL isPlanar = [bitmap isPlanar];    
    NSInteger bitsPerSample = [bitmap bitsPerSample];
    NSInteger samplesPerPixel = [bitmap samplesPerPixel];
    NSInteger bitsPerPixel = [bitmap bitsPerPixel];
    NSInteger bytesPerRow = [bitmap bytesPerRow];
    
    if(isPlanar){
        NSLog(@"isPlanar == YES");
        return 0;
    }
    
    if(bitsPerSample != 8){
        NSLog(@"bitsPerSample != 8, bitsPerSample == %ld", bitsPerSample);
        return 0;
    }
    
//    unsigned char *bitmapData = [bitmap bitmapData];
    if(pixelsWide == 128){
        NSLog(@"%d %ld %ld %ld %ld", isPlanar, bitsPerSample, samplesPerPixel, bitsPerPixel, bytesPerRow);
    }
    return 0;
}

@end
