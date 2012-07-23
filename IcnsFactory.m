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
+ (NSData *)dataForOSType:(OSType)OSType;
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
    NSMutableData *bodyData = [NSMutableData data];
    [images enumerateObjectsUsingBlock:^(NSImage *image, NSUInteger idx, BOOL *stop){
        bodyLength += [self appendImage:image toBodyData:bodyData];
    }];
    
    NSMutableData *headerData = [NSMutableData data];
    UInt32 fileLength = flipUInt32(16 + (UInt32)bodyLength);
    [headerData appendData:[self dataForOSType:kIconFamilyType]];
    [headerData appendBytes:&fileLength length:4];
    [handle writeData:headerData];
    [handle writeData:bodyData];
    [handle closeFile];
    return YES;
}

+ (NSData *)dataForOSType:(OSType)OSType{
    CFStringRef cfstring = UTCreateStringForOSType(OSType);
    NSString *string = [NSString stringWithString:(__bridge NSString *)cfstring];
    CFRelease(cfstring);
    return [string dataUsingEncoding:NSASCIIStringEncoding];
}

+ (NSUInteger)appendImage:(NSImage *)image toBodyData:(NSMutableData *)bodyData{
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    NSInteger pixelsWide = [bitmap pixelsWide];
    NSInteger pixelsHigh = [bitmap pixelsHigh];
    if(pixelsWide != pixelsHigh){
        return 0;
    }
    
    if(pixelsWide == 1024 || pixelsWide == 512 || pixelsWide == 256 ||
       pixelsWide == 128 || pixelsWide == 48 || pixelsWide == 32 || pixelsWide == 16){
        NSData *imageData = [bitmap representationUsingType:NSPNGFileType properties:nil];
        UInt32 length = flipUInt32(8 + (UInt32)[imageData length]);
        if(pixelsWide == 1024){
            [bodyData appendData:[self dataForOSType:kIconServices1024PixelDataARGB]];
        }else if(pixelsWide == 512){
            [bodyData appendData:[self dataForOSType:kIconServices512PixelDataARGB]];
        }else if(pixelsWide == 256){
            [bodyData appendData:[self dataForOSType:kIconServices256PixelDataARGB]];
        }else{ // This works, though these sizes are suppose to be broken out in to RGB(32bit) and A(8bit)
            [bodyData appendData:[self dataForOSType:kThumbnail32BitData]];
        }
        [bodyData appendBytes:&length length:4];
        [bodyData appendData:imageData];
        return [imageData length];
    }
    
    return 0;
}

@end
