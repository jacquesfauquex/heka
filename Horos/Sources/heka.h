#import <Foundation/Foundation.h>

#ifdef __cplusplus
#define BEGIN_EXTERN_C extern "C" {
#define END_EXTERN_C }
#else
#define BEGIN_EXTERN_C
#define END_EXTERN_C
#endif

NS_ASSUME_NONNULL_BEGIN

@interface Horos : NSObject

@end

@interface Horos (NSCalendarDate) // NSCalendarDate is deprecated and these methods replace the used APIs

+ (NSDate *)dateWithString:(NSString *)str calendarFormat:(NSString *)format;
+ (NSDate *)dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second timeZone:(nullable NSTimeZone *)aTimeZone;
+ (NSDate *):(NSDate *)date dateByAddingYears:(NSInteger)year months:(NSInteger)month days:(NSInteger)day hours:(NSInteger)hour minutes:(NSInteger)minute seconds:(NSInteger)second;
+ (void):(NSDate *)date years:(nullable NSInteger *)years months:(nullable NSInteger *)months days:(nullable NSInteger *)days hours:(nullable NSInteger *)hours minutes:(nullable NSInteger *)minutes seconds:(nullable NSInteger *)seconds sinceDate:(NSDate *)sinceDate;
+ (NSDateComponents *)components:(NSCalendarUnit)flags fromDate:(NSDate *)date;
+ (NSString *):(NSDate *)date descriptionWithCalendarFormat:(NSString *)format;

+ (NSArray<NSString *> *)WeasisCustomizationPaths;

@end

NS_ASSUME_NONNULL_END
