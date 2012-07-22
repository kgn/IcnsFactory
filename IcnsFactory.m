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

OSType osTypeForImage(NSImage *image){
    NSUInteger width = round(image.size.width);
    NSUInteger height = round(image.size.height);
    if(width != height){
        return NSNotFound;
    }
    switch(width){
        case 1024: return kIconServices1024PixelDataARGB;
        case 512: return kIconServices512PixelDataARGB;
        case 256: return kIconServices256PixelDataARGB;
    }
    return NSNotFound;
}

NSData *dataForImage(NSImage *image){
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    switch(osTypeForImage(image)){
        case kIconServices1024PixelDataARGB:
        case kIconServices512PixelDataARGB:
        case kIconServices256PixelDataARGB:
            return [bitmap representationUsingType:NSPNGFileType properties:nil];
    }
    return nil;
}

NSData *dataForValue(int value){
    // TODO: the values are in the enums, I'm just not sure how to get to them
    NSString *string = nil;
    switch(value){
        case kIconFamilyType:
            string = @"icns";
            break;
        case kIconServices1024PixelDataARGB:
            string = @"ic10";
            break;
        case kIconServices512PixelDataARGB:
            string = @"ic09";
            break;
        case kIconServices256PixelDataARGB:
            string = @"ic08";
            break;
            
        default:
            break;
    }
    return [string dataUsingEncoding:NSASCIIStringEncoding];
}

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
        NSData *imageData = dataForImage(image);
        if(imageData != nil){
            bodyLength += [imageData length];
            UInt32 length = flipUInt32(8 + (UInt32)[imageData length]);
            [bodyData appendData:dataForValue(osTypeForImage(image))];
            [bodyData appendBytes:&length length:4];
            [bodyData appendData:imageData];
        }
    }];
    
    NSMutableData *headerData = [NSMutableData data];
    UInt32 fileLength = flipUInt32(16 + (UInt32)bodyLength);
    [headerData appendData:dataForValue(kIconFamilyType)];
    [headerData appendBytes:&fileLength length:4];
	[handle writeData:headerData];
	[handle writeData:bodyData];
	[handle closeFile];
    return YES;
}

@end
