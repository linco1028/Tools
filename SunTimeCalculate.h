//
//  SunTimeCalculate.h
//  ZJKeepDevelop
//
//  Created by  ios-yg on 2017/7/9.
//  Copyright © 2017年 Kedll. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SunString : NSObject
@property(nonatomic, strong) NSString *sunrise;
@property(nonatomic, strong) NSString *sunset;
@end

@interface SunTimeCalculate : NSObject
+ (void)sunrisetWithLongitude:(double)longitude andLatitude:(double)latitude andResponse:(void(^)(SunString *sunString))responseBlock;
@end
