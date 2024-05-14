#import <Cocoa/Cocoa.h>
#import "NSFont_OpenGL.h"

#include "options.h"
#include "FVTiff.h"

int main(int argc, const char *argv[])
{	
    FVTIFFInitialize();
    return NSApplicationMain(argc, argv);
}
