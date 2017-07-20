//
//  SunTimeCalculate.m
//  ZJKeepDevelop
//
//  Created by  ios-yg on 2017/7/9.
//  Copyright © 2017年 Kedll. All rights reserved.
//

#define RADEG        ( 180.0 / M_PI )
#define sind(x)      sin((x)*DEGRAD)
#define cosd(x)      cos((x)*DEGRAD)
#define tand(x)      tan((x)*DEGRAD)

#define DEGRAD       ( M_PI / 180.0 )
#define atand( x )   (RADEG*atan(x))
#define asind(x)     (RADEG*asin(x))
#define acosd(x)     (RADEG*acos(x))
#define atan2d(y,x)  (RADEG*atan2(y,x))
#define days_since_2000_Jan_0(y,m,d) \
(367*(y)-((7*((y)+(((m)+9)/12)))/4)+((275*(m))/9)+(d)-730530)



#import "SunTimeCalculate.h"
#include <time.h>
#include <math.h>

@implementation SunString
@end

typedef void(^sunString)(SunString *sunStr);



@interface SunTimeCalculate ()

@property(nonatomic, assign) double sr;           //sun's distance
@property(nonatomic, assign) double sRA;          //sun's ecliptic longitude
@property(nonatomic, assign) double sdec;         //slant of the sun
@property(nonatomic, assign) double t;            //offset

@property(nonatomic, assign) double sunrise;
@property(nonatomic, assign) double sunset;

@property(nonatomic, assign) double lon;

@end



@implementation SunTimeCalculate

+ (void)sunrisetWithLongitude:(double)longitude andLatitude:(double)latitude andResponse:(void (^)(SunString *))responseBlock{
    // 初始化元素
    SunTimeCalculate * SunTimeCalculate = [[self alloc] init];
    SunString *sunString = [[SunString alloc] init];
    
    time_t t;
    t = time( NULL );
    struct tm *local = localtime( &t );
    int year = local->tm_year + 1900;
    int month = local->tm_mon + 1;
    int day = local->tm_mday;
    int hour = local->tm_hour;
    int minute;
    
    [SunTimeCalculate sunrisetWithLongitude:longitude andLatitude:latitude andYear:year andMonth:month andDay:day];
    
    struct tm *gmt = gmtime( &t );
    int zone = hour - gmt->tm_hour + (day - gmt->tm_mday)*24;
    
    //calcute sunrise and sunset time
    hour = SunTimeCalculate.sunrise + zone;
    minute = (SunTimeCalculate.sunrise - hour+zone)*60;
    if( hour > 24 ) hour -= 24;
    else if( hour < 0 ) hour += 24;
    if (minute < 0) {
        minute = minute + 60;
        hour = hour - 1;
        if (hour < 0) {
            hour = hour + 24;
        }
    }
    
    //    printf("sunrise:%2d:%2d\n", hour, minute);
    NSString *hourStr;
    NSString *minuteStr;
    if (hour < 10) {
        hourStr = [NSString stringWithFormat:@"0%d",hour];
    }else {
        hourStr = [NSString stringWithFormat:@"%d",hour];
    }
    if (minute < 10) {
        minuteStr = [NSString stringWithFormat:@"0%d",minute];
    }else {
        minuteStr = [NSString stringWithFormat:@"%d",minute];
    }
    sunString.sunrise = [NSString stringWithFormat:@"%@:%@",hourStr,minuteStr];
    
    hour = SunTimeCalculate.sunset+zone;
    minute = (SunTimeCalculate.sunset - hour+zone)*60;
    if( hour > 24 ) hour -= 24;
    else if( hour < 0 ) hour += 24;
    if (minute < 0) {
        minute = minute + 60;
        hour = hour - 1;
        if (hour < 0) {
            hour = hour + 24;
        }
    }
    //    printf("sunset: %2d:%2d\n", hour, minute);
    hourStr = nil;
    minuteStr = nil;
    if (hour < 10) {
        hourStr = [NSString stringWithFormat:@"0%d",hour];
    }else {
        hourStr = [NSString stringWithFormat:@"%d",hour];
    }
    if (minute < 10) {
        minuteStr = [NSString stringWithFormat:@"0%d",minute];
    }else {
        minuteStr = [NSString stringWithFormat:@"%d",minute];
    }
    sunString.sunset = [NSString stringWithFormat:@"%@:%@",hourStr,minuteStr];
    
    responseBlock(sunString);
}

// 计算日出日落时间
-(void)sunrisetWithLongitude:(double)longitude andLatitude:(double)latitude andYear:(int)year andMonth:(int)month andDay:(int)day{
    
    double d = days_since_2000_Jan_0(year, month, day) + 0.5 - longitude / 360.0;
    
    double sidtime = [self revolution:[self GMST0:d] + 180.0 + longitude ];
    
    double altit = -35.0 / 60.0;
    
    [self sun_RA_dec:d];
    
    double tsouth = 12.0 - [self rev180:(sidtime - self.sRA)/15.0];
    
    double sradius = 0.2666 / self.sr;
    
    altit -= sradius;
    
    double cost = ( sind(altit) - sind(latitude) * sind(self.sdec) )/( cosd(latitude) * cosd(self.sdec) );
    if ( cost >= 1.0 ) {
        self.t = 0.0;                //Sun always below altit
    }
    else if ( cost <= -1.0 ) {
        self.t = 12.0;               //Sun always above altit
    }
    else {
        self.t = acosd(cost)/15.0;   //The diurnal arc, hours
    }
    
    //Store rise and set times - in hours UT
    self.sunrise = tsouth - self.t;
    self.sunset  = tsouth + self.t;
}

-(void)sun_RA_dec:(double)d
{
    double lon;
    self.lon = lon;
    //  and:self.sRA and:self.sdec and:self.sr
    [self sunpos:d];
    
    double x = self.sr * cosd(self.lon);
    double y = self.sr * sind(self.lon);
    
    double obl_ecl = 23.4393 - 3.563E-7 * d;
    
    double z = y * sind(obl_ecl);
    y = y * cosd(obl_ecl);
    
    self.sRA = atan2d( y, x );
    self.sdec = atan2d( z, sqrt( x*x + y*y) );
}

-(void)sunpos:(double)d
{
    double M = [self revolution:( 356.0470 + 0.9856002585 * d )];  //anomaly
    double w = 282.9404 + 4.70935E-5 * d;                          //sun's ecliptic longitude
    double e = 0.016709 - 1.151E-9 * d;                            //earth's offset
    
    //Compute true longitude and radius vector
    double E = M + e * RADEG * sind(M) * ( 1.0 + e * cosd(M) );    //eccentric anomaly
    double x = cosd(E) - e;
    double y = sqrt( 1.0 - e*e ) * sind(E);                        //orbit coordinate
    self.sr = sqrt( x*x + y*y );                                   //Solar distance
    double v = atan2d( y, x );                                     //True anomaly
    self.lon = v + w;                                              //True solar longitude
    if ( self.lon >= 360.0 ) {
        self.lon -= 360.0;                                         //Make it 0..360 degrees
    }
}



-(double)revolution:(double)x
{
    return( x - 360.0 * floor( x / 360 ) );
}

-(double)rev180:(double)x
{
    return( x - 360.0 * floor( x / 360 + 0.5 ) );
}

-(double)GMST0:(double)d
{
    double sidtim0 = [self revolution:( 180.0 + 356.0470 + 282.9404 ) + ( 0.9856002585 + 4.70935E-5 ) * d];
    return sidtim0;
}
// floor 向下取整
@end
