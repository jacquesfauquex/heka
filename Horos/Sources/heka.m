#import "heka.h"

@implementation Horos

@end

@implementation Horos (NSCalendarDate) // for now we are forwarding calls to the deprecated NSCalendarDate APIs

+ (NSDate *)dateWithString:(NSString *)str calendarFormat:(NSString *)format {
//    NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
//    df.dateFormat = format;
//    df.formatterBehavior = NSDateFormatterBehavior10_0;
//    return [df dateFromString:str];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [NSCalendarDate dateWithString:str calendarFormat:format];
#pragma clang diagnostic pop
}

+ (NSDate *)dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second timeZone:(nullable NSTimeZone *)aTimeZone {
//    NSDateComponents *dc = [[[NSDateComponents alloc] init] autorelease];
//    dc.year = year;
//    dc.day = day;
//    dc.hour = hour;
//    dc.minute = minute;
//    dc.second = second;
//    dc.timeZone = aTimeZone;
//    return [dc date];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [NSCalendarDate dateWithYear:year month:month day:day hour:hour minute:minute second:second timeZone:aTimeZone];
#pragma clang diagnostic pop
}

+ (NSDate *):(NSDate *)date dateByAddingYears:(NSInteger)years months:(NSInteger)months days:(NSInteger)days hours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds {
//    NSDateComponents *dc = [[[NSDateComponents alloc] init] autorelease];
//    dc.year = years;
//    dc.day = days;
//    dc.hour = hours;
//    dc.minute = minutes;
//    dc.second = seconds;
//    return [[NSCalendar currentCalendar] dateByAddingComponents:dc toDate:date options:0];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSCalendarDate dateWithTimeInterval:0 sinceDate:date] dateByAddingYears:years months:months days:days hours:hours minutes:minutes seconds:seconds];;
#pragma clang diagnostic pop
}

+ (void):(NSDate *)date years:(NSInteger *)years months:(NSInteger *)months days:(NSInteger *)days hours:(NSInteger *)hours minutes:(NSInteger *)minutes seconds:(NSInteger *)seconds sinceDate:(NSDate *)sinceDate {
//    NSCalendarUnit flags = 0;
//    if (years) flags |= NSCalendarUnitYear;
//    if (months) flags |= NSCalendarUnitMonth;
//    if (days) flags |= NSCalendarUnitDay;
//    if (hours) flags |= NSCalendarUnitHour;
//    if (minutes) flags |= NSCalendarUnitMinute;
//    if (seconds) flags |= NSCalendarUnitSecond;
//    NSDateComponents *dc = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] components:flags fromDate:sinceDate toDate:date options:0];
//    if (years) *years = dc.year;
//    if (months) *months = dc.month;
//    if (days) *days = dc.day;
//    if (hours) *hours = dc.hour;
//    if (minutes) *minutes = dc.minute;
//    if (seconds) *seconds = dc.second;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSCalendarDate dateWithTimeInterval:0 sinceDate:date] years:years months:months days:days hours:hours minutes:minutes seconds:seconds sinceDate:[NSCalendarDate dateWithTimeInterval:0 sinceDate:sinceDate]];
#pragma clang diagnostic pop
}

+ (NSDateComponents *)components:(NSCalendarUnit)flags fromDate:(NSDate *)date {
    return [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] components:flags fromDate:date];
}

+ (NSString *):(NSDate *)date descriptionWithCalendarFormat:(NSString *)format {
//    NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
//    df.formatterBehavior = NSDateFormatterBehavior10_0;
//    df.dateFormat = format;
//    return [df stringFromDate:date];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSCalendarDate dateWithTimeInterval:0 sinceDate:date] descriptionWithCalendarFormat:format];
#pragma clang diagnostic pop
}

+ (NSArray<NSString *> *)WeasisCustomizationPaths {
    return @[ [@"~/Library/Application Support/heka/Weasis" stringByExpandingTildeInPath], @"/Library/Application Support/heka/Weasis" ];
}

@end
