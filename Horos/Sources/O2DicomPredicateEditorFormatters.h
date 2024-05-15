#import <Foundation/Foundation.h>

@interface O2DicomPredicateEditorAgeStringFormatter : NSFormatter

@end


@interface O2DicomPredicateEditorMultiplicityFormatter : NSFormatter {
    NSFormatter* _monoFormatter;
}

@property(retain) NSFormatter* monoFormatter;

@end
