#import "DCMPix.h"
#import "DicomImage.h"
#import "DicomSeries.h"
#import "DicomStudy.h"

#import <AVFoundation/AVFoundation.h>
#import "DCM.h"
#import "DCMAbstractSyntaxUID.h"
//#import "BrowserController.h"
//#import "BrowserControllerDCMTKCategory.h"
//#import "PluginManager.h"
#import "ROI.h"
#import "SRAnnotation.h"
#import "Notifications.h"
#import "N2Debug.h"
#import "NSUserDefaults+OsiriX.h"
#import "DicomDatabase.h"
#import "DicomFileDCMTKCategory.h"
#include <signal.h>
#import "DCMTKFileFormat.h"

#ifdef OSIRIX_VIEWER
#import "NSThread+N2.h"
#import "ThreadsManager.h"
#import "DCMUSRegion.h"   // US Regions
#endif

#import "DCMWaveform.h"

#import "DCMView.h"

#import "ThickSlabController.h"
#import "DicomFile.h"
#import "PluginFileFormatDecoder.h"



#include <Accelerate/Accelerate.h>
#include "AppController.h"
#include "NSFileManager+N2.h"
#import "Point3D.h"

#import "math.h"
#import "altivecFunctions.h"
#import "DICOMToNSString.h"

//#include "../Binaries/openjpeg/openjpeg.h"

#ifdef STATIC_DICOM_LIB
#define PREVIEWSIZE 512
#else
#define PREVIEWSIZE 68
#endif

/* From PapyTypeDef3.h
 Definition of the photometric interpretation */
enum EPhoto_Interpret    {MONOCHROME1, MONOCHROME2, PALETTE, RGB, HSV, ARGB, CMYK,
    YBR_FULL, YBR_FULL_422, YBR_PARTIAL_422, YBR_RCT, YBR_ICT, YUV_RCT, UNKNOWN_COLOR};

BOOL gUserDefaultsSet = NO;
BOOL gUseShutter = NO;
BOOL gDisplayDICOMOverlays = YES;
BOOL gUseVOILUT = NO;
BOOL gUseJPEGColorSpace = NO;
BOOL gUSEPAPYRUSDCMPIX = NO;
int gSUVAcquisitionTimeField = 0;
NSMutableDictionary *gCUSTOM_IMAGE_ANNOTATIONS = nil;
BOOL	runOsiriXInProtectedMode = NO;
BOOL	quicktimeRunning = NO;
NSLock	*quicktimeThreadLock = nil;

static NSMutableDictionary *cachedPapyGroups = nil;
static NSMutableDictionary *cachedDCMTKFileFormat = nil;
static NSMutableDictionary *cachedDCMFrameworkFiles = nil;
static NSMutableArray *nonLinearWLWWThreads = nil;
static NSMutableArray *minmaxThreads = nil;
static NSConditionLock *processorsLock = nil;
static NSConditionLock *purgeCacheLock = nil;
static float deg2rad = M_PI / 180.0;

static const int maxNumberOfOverlays = 16;

struct NSPointInt
{
    long x;
    long y;
};
typedef struct NSPointInt NSPointInt;

NSString* filenameWithDate( NSString *inputfile);

extern NSRecursiveLock *PapyrusLock;
//extern short Altivec;

void PapyrusLockFunction( int lock)
{
    if( lock)
        [PapyrusLock lock];
    else
        [PapyrusLock unlock];
}

void ConvertFloatToNative (float *theFloat)
{
    unsigned int		*myLongPtr;
    
    myLongPtr = (unsigned int *)theFloat;
    *myLongPtr = EndianU32_LtoN(*myLongPtr);
}

void SwitchFloat (float *theFloat)
{
    unsigned int		*myLongPtr;
    
    myLongPtr = (unsigned int *)theFloat;
    *myLongPtr = Endian32_Swap(*myLongPtr);
}


//void ConvertDoubleToNative (double *theFloat)
//{
//	unsigned long long		*myLongPtr;
//
//	myLongPtr = (unsigned long long*)theFloat;
//	*myLongPtr = EndianU64_LtoN(*myLongPtr);
//}

//uint64_t	MyGetTime( void)
//{
//	AbsoluteTime theTime = UpTime();
//
//	return ((uint64_t*) &theTime)[0];
//}
//
//double MySubtractTime( uint64_t endTime, uint64_t startTime)
//{
//	union
//	{
//		Nanoseconds	ns;
//		u_int64_t	i;
//	}time;
//
//	time.ns = AbsoluteToNanoseconds( SubAbsoluteFromAbsolute( ((AbsoluteTime*) &endTime)[0], ((AbsoluteTime*) &startTime)[0]));
//	return time.i * 1e-9;
//}

unsigned char* CreateIconFrom16 (float* image,  unsigned char*icon,  int height, int width, int iconWidth, long wl, long ww, BOOL isRGB)
// create an icon from an 12 or 16 bit image
{
    float				ratio;
    long				i, j;
    long				line, destWidth, destHeight;
    long				value;
    long				min, max, diff;
    
    min = wl - ww / 2; //if (min < 0) min = 0;
    max = wl + ww / 2;
    diff = max - min;
    
    if( diff <= 0)
    {
        diff = 1;
        max = min + 1;
    }
    if( (float) width / PREVIEWSIZE > (float) height / PREVIEWSIZE) ratio = (float) width / PREVIEWSIZE;
    else ratio = (float) height / PREVIEWSIZE;
    
    destWidth = (float) width / ratio;
    destHeight = (float) height / ratio;
    
    // allocate the memory for the icon
    
    if( diff)
    {
        unsigned char *iconPtr = nil;
        
        if( isRGB)
        {
            int x;
            unsigned char *rgbImage = (unsigned char*) image;
            int rowBytes = iconWidth*4;
            
            for (i = 0; i < destHeight; i++)  // lines
            {
                line = width * (long) (ratio * i)*4 ;   //ARGB
                iconPtr = icon + rowBytes*i;
                for (j = 0; j < destWidth; j++)         // columns
                {
                    for (x = 1; x< 4;x++, iconPtr++)		// Dont take alpha channel
                    {
                        value = *( rgbImage + line + x + (long) (j * ratio)*4); //ARGB
                        
                        if( value > max) value = max;
                        else if( value < min) value = min;
                        
                        *iconPtr = (((value-min) * 255L) / diff);
                    }
                }
            }
        }
        else
        {
            int rowBytes = iconWidth;
            for (i = 0; i < destHeight; i++)  // lines
            {
                line = width * (long) (ratio * i) ;
                iconPtr = icon + rowBytes*i;
                for (j = 0; j < destWidth; j++, iconPtr++)         // columns
                {
                    value = *( image + line + (long) (j * ratio));
                    
                    if( value > max) value = max;
                    else if( value < min) value = min;
                    
                    *iconPtr = (((value-min) * 255L) / diff);
                }
            }
        }
    }
    
    return icon;
}

// POLY CLIP

#define MAXVERTICAL     100000

#define INIT_DELTAS dx=V2.x-V1.x;  dy=V2.y-V1.y;
#define INIT_CLIP INIT_DELTAS if(dx)m=dy/dx;

static inline void CLIP_Left(NSPointInt *Polygon, long *count, NSPointInt V1, NSPointInt V2, NSPointInt UpLeft)
{
    float   dx,dy, m=1;
    INIT_CLIP
    
    // ************OK************
    if ( (V1.x>=UpLeft.x) && (V2.x>=UpLeft.x))
        Polygon[(*count)++]=V2;
    // *********LEAVING**********
    if ( (V1.x>=UpLeft.x) && (V2.x<UpLeft.x))
    {
        Polygon[(*count)].x=UpLeft.x;
        Polygon[(*count)++].y=V1.y+m*(UpLeft.x-V1.x);
    }
    // ********ENTERING*********
    if ( (V1.x<UpLeft.x) && (V2.x>=UpLeft.x))
    {
        Polygon[(*count)].x=UpLeft.x;
        Polygon[(*count)++].y=V1.y+m*(UpLeft.x-V1.x);
        Polygon[(*count)++]=V2;
    }
}

static inline void CLIP_Right(NSPointInt *Polygon, long *count, NSPointInt V1, NSPointInt V2, NSPointInt DownRight)
{
    float dx,dy, m=1;
    INIT_CLIP
    // ************OK************
    if ( (V1.x<=DownRight.x) && (V2.x<=DownRight.x))
        Polygon[(*count)++]=V2;
    // *********LEAVING**********
    if ( (V1.x<=DownRight.x) && (V2.x>DownRight.x))
    {
        Polygon[(*count)].x=DownRight.x;
        Polygon[(*count)++].y=V1.y+m*(DownRight.x-V1.x);
    }
    // ********ENTERING*********
    if ( (V1.x>DownRight.x) && (V2.x<=DownRight.x))
    {
        Polygon[(*count)].x=DownRight.x;
        Polygon[(*count)++].y=V1.y+m*(DownRight.x-V1.x);
        Polygon[(*count)++]=V2;
    }
}
/*
 =================
 CLIP_Top
 =================
 */
static inline void CLIP_Top(NSPointInt *Polygon,long *count, NSPointInt V1,NSPointInt V2, NSPointInt UpLeft)
{
    float   dx,dy, m=1;
    INIT_CLIP
    // ************OK************
    if ( (V1.y>=UpLeft.y) && (V2.y>=UpLeft.y))
        Polygon[(*count)++]=V2;
    // *********LEAVING**********
    if ( (V1.y>=UpLeft.y) && (V2.y<UpLeft.y))
    {
        if(dx)
            Polygon[(*count)].x=V1.x+(UpLeft.y-V1.y)/m;
        else
            Polygon[(*count)].x=V1.x;
        Polygon[(*count)++].y=UpLeft.y;
    }
    // ********ENTERING*********
    if ( (V1.y<UpLeft.y) && (V2.y>=UpLeft.y))
    {
        if(dx)
            Polygon[(*count)].x=V1.x+(UpLeft.y-V1.y)/m;
        else
            Polygon[(*count)].x=V1.x;
        Polygon[(*count)++].y=UpLeft.y;
        Polygon[(*count)++]=V2;
    }
}
static inline void CLIP_Bottom(NSPointInt *Polygon,long *count, NSPointInt V1,NSPointInt V2, NSPointInt DownRight)
{
    float dx,dy, m=1;
    INIT_CLIP
    // ************OK************
    if ( (V1.y<=DownRight.y) && (V2.y<=DownRight.y))
        Polygon[(*count)++]=V2;
    // *********LEAVING**********
    if ( (V1.y<=DownRight.y) && (V2.y>DownRight.y))
    {
        if(dx)
            Polygon[(*count)].x=V1.x+(DownRight.y-V1.y)/m;
        else
            Polygon[(*count)].x=V1.x;
        Polygon[(*count)++].y=DownRight.y;
    }
    // ********ENTERING*********
    if ( (V1.y>DownRight.y) && (V2.y<=DownRight.y))
    {
        if(dx)
            Polygon[(*count)].x=V1.x+(DownRight.y-V1.y)/m;
        else
            Polygon[(*count)].x=V1.x;
        Polygon[(*count)++].y=DownRight.y;
        Polygon[(*count)++]=V2;
    }
}

static NSPointInt *TmpPoly = nil;
static NSString *CLIP_PolygonSync = @"CLIP_PolygonSync";

void CLIP_Polygon(NSPointInt *inPoly, long inCount, NSPointInt *outPoly, long *outCount, NSPoint clipMin, NSPoint clipMax)
{
    @synchronized( CLIP_PolygonSync)
    {
        int	d;
        
        if( TmpPoly == nil)
            TmpPoly = malloc( MAXVERTICAL * sizeof( NSPointInt));
        
        long TmpCount;
        NSPointInt DownRight, UpLeft;
        
        UpLeft.x = clipMin.x;
        UpLeft.y = clipMin.y;
        DownRight.x = clipMax.x-1;
        DownRight.y = clipMax.y-1;
        
        *outCount = 0;
        TmpCount=0;
        
        for( int v=0; v<inCount; v++)
        {
            d=v+1;
            if(d==inCount)d=0;
            CLIP_Left( TmpPoly, &TmpCount, inPoly[v],inPoly[d], UpLeft);
            
            //            if( v > MAXVERTICAL || d > MAXVERTICAL)
            //                NSLog( @"( v || d > MAXVERTICAL)");
        }
        for( int v=0; v<TmpCount; v++)
        {
            d=v+1;
            if(d==TmpCount)d=0;
            CLIP_Right(outPoly, outCount, TmpPoly[v],TmpPoly[d], DownRight);
            
            //            if( v > MAXVERTICAL || d > MAXVERTICAL)
            //                NSLog( @"( v || d > MAXVERTICAL)");
        }
        TmpCount=0;
        for( int v=0; v<*outCount; v++)
        {
            d=v+1;
            if(d==*outCount)d=0;
            CLIP_Top( TmpPoly, &TmpCount, outPoly[v],outPoly[d], UpLeft);
            
            //            if( v > MAXVERTICAL || d > MAXVERTICAL)
            //                NSLog( @"( v || d > MAXVERTICAL)");
        }
        *outCount=0;
        for( int v=0; v<TmpCount; v++)
        {
            d=v+1;
            if(d==TmpCount)d=0;
            CLIP_Bottom(outPoly, outCount, TmpPoly[v],TmpPoly[d], DownRight);
            
            //            if( v > MAXVERTICAL || d > MAXVERTICAL)
            //                NSLog( @"( v || d > MAXVERTICAL)");
        }
    }
}

// POLY FILL

struct edge
{
    struct edge *next;
    long yTop, yBot;
    long xNowWhole, xNowNum, xNowDen, xNowDir;
    long xNowNumStep;
};

static inline long sgn( long x)
{
    if( x > 0) return 1;
    else if( x < 0) return -1;
    
    return 0;
}

static inline void FillEdges( NSPointInt *p, long no, struct edge *edgeTable[])
{
    int n = (int)no;
    
    memset( edgeTable, 0, sizeof(char*) * MAXVERTICAL);
    
    for ( int i = 0; i < n; i++)
    {
        NSPointInt *p1, *p2, *p3;
        struct edge *e;
        p1 = &p[ i];
        p2 = &p[ (i + 1) % n];
        if (p1->y == p2->y)
            continue;   /* Skip horiz. edges */
        /* Find next vertex not level with p2 */
        for ( int j = (i + 2) % n; ; j = (j + 1) % n)
        {
            p3 = &p[ j];
            if (p2->y != p3->y)
                break;
        }
        e = malloc( sizeof( struct edge));
        e->xNowNumStep = ABS(p1->x - p2->x);
        if ( p2->y > p1->y)
        {
            e->yTop = p1->y;
            e->yBot = p2->y;
            e->xNowWhole = p1->x;
            e->xNowDir = sgn( p2->x - p1->x);
            e->xNowDen = e->yBot - e->yTop;
            e->xNowNum = (e->xNowDen >> 1);
            if ( p3->y > p2->y)
                e->yBot--;
        }
        else
        {
            e->yTop = p2->y;
            e->yBot = p1->y;
            e->xNowWhole = p2->x;
            e->xNowDir = sgn((p1->x) - (p2->x));
            e->xNowDen = e->yBot - e->yTop;
            e->xNowNum = (e->xNowDen >> 1);
            if ((p3->y) < (p2->y))
            {
                e->yTop++;
                e->xNowNum += e->xNowNumStep;
                while (e->xNowNum >= e->xNowDen)
                {
                    e->xNowWhole += e->xNowDir;
                    e->xNowNum -= e->xNowDen;
                }
            }
        }
        e->next = edgeTable[ e->yTop];
        edgeTable[ e->yTop] = e;
    }
}

/*
 * UpdateActive first removes any edges which curY has entirely
 * passed by.  The removed edges are freed.
 * It then removes any edges from the edge table at curY and
 * places them on the active list.
 */

struct edge *UpdateActive( struct edge *active, struct edge *edgeTable[], long curY)
{
    struct edge *e, **ep;
    for (ep = &active, e = *ep; e != NULL; e = *ep)
        if (e->yBot < curY)
        {
            *ep = e->next;
            free(e);
        } else
            ep = &e->next;
    *ep = edgeTable[ curY];
    return active;
}

/*
 * DrawRuns first uses an insertion sort to order the X
 * coordinates of each active edge.  It updates the X coordinates
 * for each edge as it does this.
 * Then it draws a run between each pair of coordinates,
 * using the specified fill pattern.
 *
 * This routine is very slow and it would not be that
 * difficult to speed it way up.
 */

static DCMPix **restoreImageCache = nil;

static inline void DrawRuns(	struct edge *active,
                            long curY,
                            float *pix,
                            long w,
                            long h,
                            float min,
                            float max,
                            BOOL outside,
                            float newVal,
                            BOOL addition,
                            BOOL RGB,
                            BOOL compute,
                            float *imax,
                            float *imin,
                            long *count,
                            float *itotal,
                            float *idev,
                            float imean,
                            long orientation,
                            long stackNo,	// Only if X/Y orientation : for 3D VR scissor in any direction
                            BOOL restore,
                            float *values,
                            float *locations)
{
    long xCoords[ 4096];
    float *curPix = nil, val = 0, temp = 0;
    long numCoords = 0;
    long start, end, ims = w * h;
    float *ivalues = nil;
    float *ilocations = nil;
    
    if( compute && orientation == 2) // standard orientation
    {
        ivalues = values;
        ilocations = locations;
    }
    
    for ( struct edge *e = active; e != NULL; e = e->next)
    {
        long i;
        for ( i = numCoords; i > 0 &&
             xCoords[i - 1] > e->xNowWhole; i--)
            xCoords[i] = xCoords[i - 1];
        xCoords[i] = e->xNowWhole;
        numCoords++;
        e->xNowNum += e->xNowNumStep;
        while (e->xNowNum >= e->xNowDen)
        {
            e->xNowWhole += e->xNowDir;
            e->xNowNum -= e->xNowDen;
        }
    }
    
    if (numCoords % 2) { /* Protect from degenerate polygons */
        xCoords[numCoords] = xCoords[numCoords - 1];
        numCoords++;
    }
    
    for( long i = 0; i < numCoords; i += 2)
    {
        // ** COMPUTE
        if( compute)
        {
            start = xCoords[i];		if( start < 0) start = 0;		if( start >= w) start = w;
            end = xCoords[i + 1];	if( end < 0) end = 0;			if( end >= w) end = w;
            
            switch( orientation)
            {
                case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];			break;
                case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		break;
                case 2:		curPix = &pix[ (curY * w) + start];							break;
            }
            
            long x = end - start;
            long xx = 0;
            if( RGB == NO)
            {
                while( x-- >= 0)
                {
                    val = *curPix;
                    
                    if( imax && val > *imax) *imax = val;
                    if( imin && val < *imin) *imin = val;
                    if( itotal) *itotal += val;
                    if( count) (*count)++;
                    if( values) (*ivalues++) = val;
                    if( ilocations)
                    {
                        (*ilocations++) = start + xx++;
                        (*ilocations++) = curY;
                    }
                    
                    if( idev)
                    {
                        temp = imean - val;
                        temp *= temp;
                        *idev += temp;
                    }
                    
                    if( orientation) curPix ++;
                    else curPix += w;
                }
            }
            else
            {
                while( x-- >= 0)
                {
                    unsigned char* curPixRGB = (unsigned char*) curPix;
                    
                    val = (curPixRGB[ 1] + curPixRGB[ 2] + curPixRGB[ 3]) / 3.;
                    
                    if( imax && val > *imax) *imax = val;
                    if( imin && val < *imin) *imin = val;
                    if( itotal) *itotal += val;
                    if( count) (*count)++;
                    if( values) (*ivalues++) = val;
                    if( ilocations)
                    {
                        (*ilocations++) = start + xx++;
                        (*ilocations++) = w;
                    }
                    
                    if( idev)
                    {
                        temp = imean - val;
                        temp *= temp;
                        *idev += temp;
                    }
                    
                    if( orientation) curPix ++;
                    else curPix += w;
                }
            }
        }
        
        // ** DRAW
        else
        {
            if( outside)	// OUTSIDE
            {
                if( i == 0)
                {
                    start = 0;			if( start < 0) start = 0;		if( start >= w) start = w;
                    end = xCoords[i];	if( end < 0) end = 0;			if( end >= w) end = w;
                    i--;
                }
                else
                {
                    start = xCoords[i]+1;		if( start < 0) start = 0;		if( start >= w) start = w;
                    
                    if( i == numCoords-1)
                    {
                        end = w;
                    }
                    else end = xCoords[i+1];
                    
                    if( end < 0) end = 0;			if( end >= w) end = w;
                }
                
                if( RGB == NO)
                {
                    switch( orientation)
                    {
                        case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];		break;
                        case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		break;
                        case 2:		curPix = &pix[ (curY * w) + start];							break;
                    }
                    
                    long x = end - start;
                    
                    if( addition)
                    {
                        while( x-- > 0)
                        {
                            if( *curPix >= min && *curPix <= max) *curPix += newVal;
                            
                            if( orientation) curPix ++;
                            else curPix += w;
                        }
                    }
                    else
                    {
                        while( x-- > 0)
                        {
                            if( *curPix >= min && *curPix <= max) *curPix = newVal;
                            
                            if( orientation) curPix ++;
                            else curPix += w;
                        }
                    }
                }
                else
                {
                    switch( orientation)
                    {
                        case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];		break;
                        case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		break;
                        case 2:		curPix = &pix[ (curY * w) + start];							break;
                    }
                    
                    long x = end - start;
                    
                    while( x-- > 0)
                    {
                        unsigned char*  rgbPtr = (unsigned char*) curPix;
                        
                        if( addition)
                        {
                            if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] += newVal;
                            if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] += newVal;
                            if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] += newVal;
                        }
                        else
                        {
                            if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] = newVal;
                            if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] = newVal;
                            if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] = newVal;
                        }
                        
                        if( orientation) curPix ++;
                        else curPix += w;
                    }
                }
            }
            else		// INSIDE
            {
                float	*restorePtr = nil;
                
                start = xCoords[i];		if( start < 0) start = 0;		if( start >= w) start = w;
                end = xCoords[i + 1];	if( end < 0) end = 0;			if( end >= w) end = w;
                
                switch( orientation)
                {
                    case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		if( restore && restoreImageCache) restorePtr = &[restoreImageCache[ curY] fImage][(start * w) + stackNo];			break;
                    case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];			if( restore && restoreImageCache) restorePtr = &[restoreImageCache[ curY] fImage][start + stackNo *w];				break;
                    case 2:		curPix = &pix[ (curY * w) + start];							if( restore && restoreImageCache) restorePtr = &[restoreImageCache[ stackNo] fImage][(curY * w) + start];			break;
                }
                
                long x = end - start;
                
                if( x >= 0)
                {
                    if( restore && restoreImageCache)
                    {
                        if( RGB == NO)
                        {
                            if( orientation)
                            {
                                while( x-- >= 0)
                                {
                                    *curPix = *restorePtr;
                                    
                                    curPix ++;
                                    restorePtr ++;
                                }
                            }
                            else
                            {
                                while( x-- >= 0)
                                {
                                    *curPix = *restorePtr;
                                    
                                    curPix += w;
                                    restorePtr += w;
                                }
                            }
                        }
                        else
                        {
                            if( orientation)
                            {
                                while( x-- >= 0)
                                {
                                    unsigned char*  rgbPtr = (unsigned char*) curPix;
                                    
                                    rgbPtr[ 1] = restorePtr[ 1];
                                    rgbPtr[ 2] = restorePtr[ 2];
                                    rgbPtr[ 3] = restorePtr[ 3];
                                    
                                    curPix ++;
                                    restorePtr ++;
                                }
                            }
                            else
                            {
                                while( x-- >= 0)
                                {
                                    unsigned char*  rgbPtr = (unsigned char*) curPix;
                                    
                                    rgbPtr[ 1] = restorePtr[ 1];
                                    rgbPtr[ 2] = restorePtr[ 2];
                                    rgbPtr[ 3] = restorePtr[ 3];
                                    
                                    curPix += w;
                                    restorePtr += w;
                                }
                            }
                        }
                    }
                    else
                    {
                        if( RGB == NO)
                        {
                            if( addition)
                            {
                                while( x-- >= 0)
                                {
                                    if( *curPix >= min && *curPix <= max) *curPix += newVal;
                                    
                                    if( orientation) curPix ++;
                                    else curPix += w;
                                }
                            }
                            else
                            {
                                while( x-- >= 0)
                                {
                                    if( *curPix >= min && *curPix <= max) *curPix = newVal;
                                    
                                    if( orientation) curPix ++;
                                    else curPix += w;
                                }
                            }
                        }
                        else
                        {
                            while( x-- >= 0)
                            {
                                unsigned char*  rgbPtr = (unsigned char*) curPix;
                                
                                if( addition)
                                {
                                    if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] += newVal;
                                    if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] += newVal;
                                    if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] += newVal;
                                }
                                else
                                {
                                    if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] = newVal;
                                    if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] = newVal;
                                    if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] = newVal;
                                }
                                
                                if( orientation) curPix ++;
                                else curPix += w;
                            }
                        }
                    }
                }
            }
        }
    }
}

void ras_FillPolygon( NSPointInt *p,
                     long no,
                     float *pix,
                     long w,
                     long h,
                     long s,
                     float min,
                     float max,
                     BOOL outside,
                     float newVal,
                     BOOL addition,
                     BOOL RGB,
                     BOOL compute,
                     float *imax,
                     float *imin,
                     long *count,
                     float *itotal,
                     float *idev,
                     float imean,
                     long orientation,
                     long stackNo,
                     BOOL restore,
                     float *values,
                     float *locations)
{
    struct edge **edgeTable = (struct edge **) malloc( MAXVERTICAL * sizeof( struct edge *));
    struct edge *active = nil;
    long curY = 0;
    
    //	float test;
    //
    //	test = -FLT_MAX;
    //	if( test != -FLT_MAX)
    //		NSLog( @"******* test != -FLT_MAX");
    //
    //	test = FLT_MAX;
    //	if( test != FLT_MAX)
    //		NSLog( @"******* test != FLT_MAX");
    
    if( edgeTable == nil)
        return;
    
    FillEdges(p, no, edgeTable);
    
    for ( curY = 0; edgeTable[ curY] == NULL; curY++)
    {
        if (curY == MAXVERTICAL - 1)
        {
            free( edgeTable);
            return;     /* No edges in polygon */
        }
    }
    
    float *ivalues = nil;
    float *ilocations = nil;
    
    if( count)
    {
        ivalues = values;
        ilocations = locations;
    }
    
    for (active = NULL; (active = UpdateActive(active, edgeTable, curY)) != NULL; curY++)
    {
        if( active)
        {
            DrawRuns(active, curY, pix, w, h, min, max, outside, newVal, addition, RGB, compute, imax, imin, count, itotal, idev, imean, orientation, stackNo, restore, ivalues, ilocations);
            
            if( ivalues)
                ivalues = values + *count;
            
            if( ilocations)
                ilocations = locations + *count * 2;
        }
    }
    
    free( edgeTable);
}

static inline long pnpoly( NSPoint *p, long count, float x, float y)
{
    long	c = 0;
    
    for ( int i = 0, j = (int)count-1; i < count; j = i++)
    {
        if ((((p[i].y <= y) && (y < p[j].y)) ||
             ((p[j].y <= y) && (y < p[i].y))) &&
            (x < (p[j].x - p[i].x) * (y - p[i].y) / (p[j].y - p[i].y) + p[i].x))
            c = !c;
    }
    return c;
}

inline long pnpolyInt( struct NSPointInt *p, long count, long x, long y)
{
    long	c = 0;
    
    for ( int i = 0, j = (int)count-1; i < count; j = i++)
    {
        if ((((p[i].y <= y) && (y < p[j].y)) ||
             ((p[j].y <= y) && (y < p[i].y))) &&
            (x < (p[j].x - p[i].x) * (y - p[i].y) / (p[j].y - p[i].y) + p[i].x))
            c = !c;
    }
    return c;
}

#define SetPixel(x,y,c) FrameBuffer[y*WIDTH+x]=c;

long BresLine(int Ax, int Ay, int Bx, int By,long **xBuffer, long **yBuffer)
{
    long	size = 0;
    long	maxVal = (abs(Ax - Bx)+abs(Ay - By)) + 2;
    
    *xBuffer = malloc( maxVal*sizeof(long));
    *yBuffer = malloc( maxVal*sizeof(long));
    
    int dX = abs(Bx-Ax);	// store the change in X and Y of the line endpoints
    int dY = abs(By-Ay);
    
    //------------------------------------------------------------------------
    // DETERMINE "DIRECTIONS" TO INCREMENT X AND Y (REGARDLESS OF DECISION)
    //------------------------------------------------------------------------
    int Xincr, Yincr;
    if (Ax > Bx) { Xincr=-1; } else { Xincr=1; }	// which direction in X?
    if (Ay > By) { Yincr=-1; } else { Yincr=1; }	// which direction in Y?
    
    //------------------------------------------------------------------------
    // DETERMINE INDEPENDENT VARIABLE (ONE THAT ALWAYS INCREMENTS BY 1 (OR -1))
    // AND INITIATE APPROPRIATE LINE DRAWING ROUTINE (BASED ON FIRST OCTANT
    // ALWAYS). THE X AND Y'S MAY BE FLIPPED IF Y IS THE INDEPENDENT VARIABLE.
    //------------------------------------------------------------------------
    if (dX >= dY)	// if X is the independent variable
    {
        int dPr 	= dY<<1;           // amount to increment decision if right is chosen (always)
        int dPru 	= dPr - (dX<<1);   // amount to increment decision if up is chosen
        int P 		= dPr - dX;  // decision variable start value
        
        for (; dX>=0; dX--)            // process each point in the line one at a time (just use dX)
        {
            (*xBuffer)[ size] = Ax;
            (*yBuffer)[ size] = Ay;
            size++;
            
            if (P > 0)               // is the pixel going right AND up?
            {
                Ax+=Xincr;	       // increment independent variable
                Ay+=Yincr;         // increment dependent variable
                P+=dPru;           // increment decision (for up)
            }
            else                     // is the pixel just going right?
            {
                Ax+=Xincr;         // increment independent variable
                P+=dPr;            // increment decision (for right)
            }
        }
    }
    else              // if Y is the independent variable
    {
        int dPr 	= dX<<1;           // amount to increment decision if right is chosen (always)
        int dPru 	= dPr - (dY<<1);   // amount to increment decision if up is chosen
        int P 		= dPr - dY;  // decision variable start value
        
        for (; dY>=0; dY--)            // process each point in the line one at a time (just use dY)
        {
            (*xBuffer)[ size] = Ax;
            (*yBuffer)[ size] = Ay;
            size++;
            
            if (P > 0)               // is the pixel going up AND right?
            {
                Ax+=Xincr;         // increment dependent variable
                Ay+=Yincr;         // increment independent variable
                P+=dPru;           // increment decision (for up)
            }
            else                     // is the pixel just going up?
            {
                Ay+=Yincr;         // increment independent variable
                P+=dPr;            // increment decision (for right)
            }
        }
    }
    
    if( maxVal < size)
    {
        NSLog( @"MAJOR BUG");
    }
    
    return size;
}

void erase_outside_circle(char *buf, int width, int height, int cx, int cy, int rad, char blackIndex)
{
    int		x,y;
    int		xsqr;
    int		inw = rad*2;
    int		radsqr = (inw*inw)/4;
    
    if( cx < 0 || cx >= width) return;
    if( cy < 0 || cy >= height) return;
    
    cx -= rad;
    cy -= rad;
    
    // top
    for(y = 0; y <= cy; y++)
    {
        for(x = 0; x < width; x++)
        {
            if( y >= 0 && y < height) buf[ x + y*width] = blackIndex;
        }
    }
    
    // bottom
    for(y = cy+inw; y < height; y++)
    {
        for(x = 0; x < width; x++)
        {
            if( y >= 0 && y < height) buf[ x + y*width] = blackIndex;
        }
    }
    
    // left + right
    for(y = cy; y < cy+inw; y++)
    {
        for(x = 0; x <= cx; x++)
        {
            if( x < width && y >= 0 && y < height)
                buf[ x + y*width] = blackIndex;
        }
        
        for(x = cx+inw; x < width; x++)
        {
            if( x >= 0 && y >= 0 && y < height)
                buf[ x + y*width] = blackIndex;
        }
    }
    
    for(x = 0; x < rad; x++)
    {
        xsqr = x*x;
        for( y = 0 ; y < rad; y++)
        {
            char draw;
            
            if((xsqr + y*y) < radsqr)
            {
                draw = 0;
            }
            else
            {
                draw = 1;
            }
            
            if( draw)
            {
                int xx, yy;
                
                xx = rad+x+cx;	yy = rad+y+cy;
                if( xx >= 0 && xx < width && yy >= 0 && yy < height) buf[ xx + yy*width] = blackIndex;
                
                xx = rad-x+cx;	yy = rad+y+cy;
                if( xx >= 0 && xx < width && yy >= 0 && yy < height) buf[ xx + yy*width] = blackIndex;
                
                xx = rad+x+cx;	yy = rad-y+cy;
                if( xx >= 0 && xx < width && yy >= 0 && yy < height) buf[ xx + yy*width] = blackIndex;
                
                xx = rad-x+cx;	yy = rad-y+cy;
                if( xx >= 0 && xx < width && yy >= 0 && yy < height) buf[ xx + yy*width] = blackIndex;
            }
        }
    }
}

//void (*signal(int signum, void (*sighandler)(int)))(int);
//
//static sigjmp_buf mark;
//
//void signal_EXC_ARITHMETIC(int sig_num)
//{
//    NSLog( @"******** Signal %d - DCMPix / EXC_ARITHMETIC / divide by zero exception in JPEG decoder? Catch the exception and resume function", sig_num);
//
//    siglongjmp( mark, -1 );
//}

@interface PixThread : NSObject
{
}
@end

@implementation PixThread

- (void) computeMax:(float*) fResult pos:(int) pos threads:(int) threads object: (DCMPix*) o
{
    float *fNext = NULL;
    long from, to, size = [o pheight] * [o pwidth];
    
    from = (pos * size) / threads;
    to = ((pos+1) * size) / threads;
    size = to - from;
    
    NSArray *p = o.pixArray;
    int ppos = o.pixPos;
    int stack = o.stack;
    int stackDirection = o.stackDirection;
    int stackMode = o.stackMode;
    
    for( int i = 1; i < stack; i++)
    {
        int res;
        if( stackDirection) res = ppos-i;
        else res = ppos+i;
        
        if( res < p.count && res >= 0)
        {
            fNext = [[p objectAtIndex: res] fImage];
            if( fNext)
            {
                if( stackMode == 2) vDSP_vmax( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
                else if( stackMode == 1)
                {
                    vDSP_vadd( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
                    if( from == 0) o.countstackMean++;
                }
                else vDSP_vmin( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
            }
        }
    }
    
    [processorsLock lock];
    [processorsLock unlockWithCondition: [processorsLock condition]-1];
}

- (void)computeMaxThread: (NSDictionary*)dict
{
    @autoreleasepool
    {
        [NSThread currentThread].name = @"Compute Pixels thread";
        
        NSConditionLock *threadLock = [dict valueForKey:@"threadLock"];
        
        int numberOfThreadsForCompute = [DCMPix maxProcessors];
        
        do
        {
            @autoreleasepool
            {
                [threadLock lockWhenCondition: 1];
                
                @try {
                    if( [[dict valueForKey:@"fResult"] pointerValue])
                        [self computeMax: [[dict valueForKey:@"fResult"] pointerValue] pos: [[dict valueForKey:@"pos"] intValue] threads: numberOfThreadsForCompute object: [dict valueForKey:@"self"]];
                }
                @catch (NSException *exception) {
                    N2LogException( exception);
                }
                
                [threadLock unlockWithCondition: 0];
            }
        }
        while( 1);
    }
}

- (void)applyNonLinearWLWWThread: (NSDictionary*)dict
{
    @autoreleasepool
    {
        NSConditionLock *threadLock = [dict valueForKey:@"threadLock"];
        
        do
        {
            @autoreleasepool
            {
                [threadLock lockWhenCondition: 1];
                
                @try
                {
                    DCMPix *o = [dict valueForKey:@"self"];
                    
                    if( o)
                    {
                        int startLine = [[dict valueForKey:@"start"] intValue];
                        int endLine = [[dict valueForKey:@"end"] intValue];
                        
                        int			ii = (endLine - startLine) * (int)[o pwidth];
                        unsigned char	*dst8Ptr = (unsigned char*) [o baseAddr] + startLine * [o pwidth];
                        float			*src32Ptr = (float*) [[dict valueForKey:@"src"] pointerValue];
                        float			from = [o wl] - [o ww]/2.;
                        float			ratio = 4096. / [o ww];
                        float			*tfPtr = [o transferFunctionPtr];
                        
                        src32Ptr += startLine * [o pwidth];
                        
                        if( tfPtr)
                        {
                            while( ii-- > 0)
                            {
                                int value = ratio * (*src32Ptr++ - from);
                                
                                if( value < 0) value = 0;
                                else if( value >= 4095) value = 4095;
                                
                                *dst8Ptr++ = 255.*tfPtr[ value];
                            }
                        }
                    }
                }
                @catch (NSException *exception) {
                    N2LogException( exception);
                }
                
                [processorsLock lock];
                [processorsLock unlockWithCondition: [processorsLock condition]-1];
                
                [threadLock unlockWithCondition: 0];
            }
        }
        while( 1);
    }
}
@end


@interface DCMPix ()

@property(strong) DCMWaveform *waveform;

@end


@implementation DCMPix

@synthesize countstackMean, stackDirection, needToCompute8bitRepresentation, subtractedfImage, modalityString;
@synthesize full32bitPipeline;
@synthesize frameNo, notAbleToLoadImage, shutterPolygonal, SOPClassUID, frameofReferenceUID;
@synthesize minValueOfSeries, maxValueOfSeries, factorPET2SUV, slope, offset;
@synthesize isRGB, pwidth = width, pheight = height, checking, shutterRect;
@synthesize pixelRatio, transferFunction, subPixOffset, isOriginDefined, shutterEnabled;
@synthesize imageType, waveform, VOILUTApplied, VOILUT_table, dcmtkDcmFileFormat;

@synthesize repetitiontime, echotime;

@synthesize flipAngle, laterality, viewPosition, patientPosition;

@synthesize serieNo, pixArray, pixPos, transferFunctionPtr;
@synthesize stackMode, generated, generatedName, imageObjectID;

@synthesize srcFile = _srcFile;

@synthesize annotationsDictionary, annotationsDBFields, yearOld, yearOldAcquisition;

// US Regions
@synthesize usRegions;

// SUV properties
@synthesize philipsFactor, patientsWeight;
@synthesize halflife, radionuclideTotalDose;
@synthesize radionuclideTotalDoseCorrected, acquisitionTime, acquisitionDate, rescaleType;
@synthesize radiopharmaceuticalStartTime, SUVConverted;
@synthesize hasSUV, decayFactor;
@synthesize units, decayCorrection, displaySUVValue;

@synthesize isLUT12Bit;

@synthesize referencedSOPInstanceUID;

- (DicomImage*) imageObj
{
#ifdef NDEBUG
#else
    if( [NSThread isMainThread] == NO)
        NSLog( @"******************* warning this object should be used only on the main thread. Create your own Context !");
#endif
    return nil;
}

- (DicomSeries*) seriesObj
{
#ifdef NDEBUG
#else
    if( [NSThread isMainThread] == NO)
        NSLog( @"******************* warning this object should be used only on the main thread. Create your own Context !");
#endif
    return nil;
}

- (DicomStudy*) studyObj
{
#ifdef NDEBUG
#else
    if( [NSThread isMainThread] == NO)
        NSLog( @"******************* warning this object should be used only on the main thread. Create your own Context !");
#endif
    return nil;
}

+(int) maxProcessors
{
    int numberOfThreadsForCompute = (int)[[NSProcessInfo processInfo] processorCount];
    if( numberOfThreadsForCompute > 12)
        numberOfThreadsForCompute = 12;
    
    return numberOfThreadsForCompute;
}

+ (BOOL) IsPoint:(NSPoint) x inPolygon:(NSPoint*) pts size:(int) no
{
    if( pnpoly( pts, no, x.x, x.y))
        return YES;
    
    return NO;
}

+ (void) resetUserDefaults
{
    gUserDefaultsSet = NO;
}

+ (void) checkUserDefaults: (BOOL) update
{
    // Why this? NSUserDefaults performances are poor if not in main thread
    
    if( update)
        gUserDefaultsSet = NO;
    
    if( gUserDefaultsSet == NO)
    {
        gUserDefaultsSet = YES;
        
        gUseShutter = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseShutter"];
        gDisplayDICOMOverlays = [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayDICOMOverlays"];
        gUseVOILUT = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseVOILUT"];
        
        gUSEPAPYRUSDCMPIX = NO; //[[NSUserDefaults standardUserDefaults] boolForKey:@"USEPAPYRUSDCMPIX4"];
        gUseJPEGColorSpace = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseJPEGColorSpace"];
        gSUVAcquisitionTimeField = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"SUVAcquisitionTimeField"];
        
        if( gCUSTOM_IMAGE_ANNOTATIONS == nil)
            gCUSTOM_IMAGE_ANNOTATIONS = [[NSMutableDictionary alloc] init];
        
        @synchronized( gCUSTOM_IMAGE_ANNOTATIONS)
        {
            [gCUSTOM_IMAGE_ANNOTATIONS removeAllObjects];
            [gCUSTOM_IMAGE_ANNOTATIONS addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CUSTOM_IMAGE_ANNOTATIONS"]];
        }
        
#ifdef OSIRIX_LIGHT
        gUSEPAPYRUSDCMPIX = NO;
#endif
        
#if __LP64__
        gUSEPAPYRUSDCMPIX = NO;
#endif
        
#ifdef STATIC_DICOM_LIB
        gUSEPAPYRUSDCMPIX = NO;
        gUseShutter = NO;
        gDisplayDICOMOverlays = NO;
        gUseJPEGColorSpace = NO;
        gSUVAcquisitionTimeField = 0;
#endif
        
        if( gUseVOILUT == YES && gUSEPAPYRUSDCMPIX == NO)
        {
            [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"UseVOILUT"];
            gUseVOILUT = NO; // VOILUT is not supported with DCMFramework
            
            NSLog( @"**** VOILUT is not supported with DCMFramework -> It will be turned off");
        }
    }
}

+ (void) setRunOsiriXInProtectedMode:(BOOL) v
{
    runOsiriXInProtectedMode = v;
}

+ (BOOL) isRunOsiriXInProtectedModeActivated
{
    return runOsiriXInProtectedMode;
}

+ (NSPoint) originDeltaBetween:(DCMPix*) pix1 And:(DCMPix*) pix2
{
    // DICOM Origin is the CENTER of the first pixel !
    
    double destPixelSpacingX = [pix1 pixelSpacingX];
    double destPixelSpacingY = [pix1 pixelSpacingY];
    double senderPixelSpacingX = [pix2 pixelSpacingX];
    double senderPixelSpacingY = [pix2 pixelSpacingY];
    
    double pix1Origin[ 3] = {[pix1  originX], [pix1  originY], [pix1  originZ]};
    double pix2Origin[ 3] = {[pix2  originX], [pix2  originY], [pix2  originZ]};
    
    pix1Origin[ 0] -= destPixelSpacingX/2.;
    pix1Origin[ 1] -= destPixelSpacingY/2.;
    
    pix2Origin[ 0] -= senderPixelSpacingX/2.;
    pix2Origin[ 1] -= senderPixelSpacingY/2.;
    
    if( destPixelSpacingX == 0 || destPixelSpacingY == 0 || senderPixelSpacingX == 0 || senderPixelSpacingY == 0)
    {
        return NSMakePoint( 0, 0);
    }
    
    double destWidth = [pix1 pwidth];
    double destHeight =[pix1 pheight];
    double vectorP1[ 9];
    double destOrigin[ 3];
    
    [pix1 orientationDouble: vectorP1];
    destOrigin[ 0] = pix1Origin[ 0] * vectorP1[ 0] + pix1Origin[ 1] * vectorP1[ 1] + pix1Origin[ 2] * vectorP1[ 2];
    destOrigin[ 1] = pix1Origin[ 0] * vectorP1[ 3] + pix1Origin[ 1] * vectorP1[ 4] + pix1Origin[ 2] * vectorP1[ 5];
    destOrigin[ 2] = pix1Origin[ 0] * vectorP1[ 6] + pix1Origin[ 1] * vectorP1[ 7] + pix1Origin[ 2] * vectorP1[ 8];
    
    double vectorP2[ 9];
    double senderOrigin[ 3];
    
    [pix2 orientationDouble: vectorP2];
    senderOrigin[ 0] = pix2Origin[ 0] * vectorP2[ 0] + pix2Origin[ 1] * vectorP2[ 1] + pix2Origin[ 2] * vectorP2[ 2];
    senderOrigin[ 1] = pix2Origin[ 0] * vectorP2[ 3] + pix2Origin[ 1] * vectorP2[ 4] + pix2Origin[ 2] * vectorP2[ 5];
    senderOrigin[ 2] = pix2Origin[ 0] * vectorP2[ 6] + pix2Origin[ 1] * vectorP2[ 7] + pix2Origin[ 2] * vectorP2[ 8];
    
    NSPoint offset;
    
    offset.x = destOrigin[ 0] + destPixelSpacingX * destWidth/2 - (senderOrigin[ 0] + senderPixelSpacingX * [pix2 pwidth]/2);
    offset.y = destOrigin[ 1] + destPixelSpacingY * destHeight/2 - (senderOrigin[ 1] + senderPixelSpacingY * [pix2 pheight]/2);
    
    offset.x /= senderPixelSpacingX;
    offset.y /= senderPixelSpacingY;
    
    offset.y *= [pix2 pixelRatio];
    
    return offset;
}

- (NSRect) rectCoordinates
{
    if( self.pixelSpacingX && self.pixelSpacingY)
        return NSMakeRect( self.originX, self.originY, self.pixelSpacingX*self.pwidth, self.pixelSpacingY*self.pheight);
    else
        return NSMakeRect( self.originX, self.originY, self.pwidth, self.pheight);
}

+ (NSPoint) originCorrectedAccordingToOrientation: (DCMPix*) pix1
{
    double destOrigin[ 2];
    double vectorP1[ 9];
    
    [pix1 orientationDouble: vectorP1];
    
    destOrigin[ 0] = [pix1  originX] * vectorP1[ 0] + [pix1  originY] * vectorP1[ 1] + [pix1  originZ] * vectorP1[ 2];
    destOrigin[ 1] = [pix1  originX] * vectorP1[ 3] + [pix1  originY] * vectorP1[ 4] + [pix1  originZ] * vectorP1[ 5];
    
    return NSMakePoint( destOrigin[ 0], destOrigin[ 1]);
}

+ (NSImage*) resizeIfNecessary:(NSImage*) currentImage dcmPix: (DCMPix*) dcmPix
{
    NSRect sourceRect = NSMakeRect(0.0, 0.0, [currentImage size].width, [currentImage size].height);
    NSRect imageRect;
    
    if(	[currentImage size].width > 512 &&
       [currentImage size].height > 512)
    {
        // Rescale image if resolution is too high, compared to the original resolution
        
        @try
        {
            float MAXSIZE = 1.8;
            
            int minWidth = [dcmPix pwidth]*MAXSIZE;
            int minHeight = [dcmPix pheight]*MAXSIZE;
            
            if( minWidth < 1024) MAXSIZE = 1024 / [dcmPix pwidth];
            if( minHeight < 1024) MAXSIZE = 1024 / [dcmPix pheight];
            
            minWidth = [dcmPix pwidth]*MAXSIZE;
            minHeight = [dcmPix pheight]*MAXSIZE;
            
            if( [currentImage size].width > minWidth && [currentImage size].height > minHeight)
            {
                if( [currentImage size].width/[dcmPix pwidth] < [currentImage size].height / [dcmPix pheight])
                {
                    float ratio = [currentImage size].width / (minWidth);
                    imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
                }
                else
                {
                    float ratio = [currentImage size].height / (minHeight);
                    imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
                }
                
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [currentImage setScalesWhenResized:YES];
#pragma clang diagnostic pop
                
                NSImage *compositingImage = [[NSImage alloc] initWithSize: imageRect.size];
                
                if( [compositingImage size].width > 0 && [compositingImage size].height > 0)
                {
                    [compositingImage lockFocus];
                    //		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationDefault];
                    [currentImage drawInRect: imageRect fromRect: sourceRect operation: NSCompositeCopy fraction: 1.0];
                    [compositingImage unlockFocus];
                }
                
                //				NSLog( @"New Size: %f %f", [compositingImage size].width, [compositingImage size].height);
                
                return [compositingImage autorelease];
            }
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
    }
    
    return currentImage;
}

// US Regions
-(BOOL) hasUSRegions {
    return (usRegions && [usRegions count] > 0);
}

- (float) maxValueOfSeries
{
    if( maxValueOfSeries == 0)
    {
        float tmaxValueOfSeries = -100000;
        
        for( DCMPix* pix in pixArray)
        {
            if( tmaxValueOfSeries < [pix fullwl] + [pix fullww]/2)
                tmaxValueOfSeries = [pix fullwl] + [pix fullww]/2;
        }
        
        for( DCMPix* pix in pixArray)
        {
            [pix setMaxValueOfSeries: tmaxValueOfSeries];
        }
    }
    
    return maxValueOfSeries;
}

- (float) minValueOfSeries
{
    if( minValueOfSeries == 0)
    {
        float tminValueOfSeries = 100000;
        
        for( DCMPix* pix in pixArray)
        {
            if( tminValueOfSeries > [pix fullwl] - [pix fullww]/2) tminValueOfSeries = [pix fullwl] - [pix fullww]/2;
        }
        
        for( DCMPix* pix in pixArray)
        {
            [pix setMinValueOfSeries: tminValueOfSeries];
        }
    }
    
    return minValueOfSeries;
}

- (NSImage*) image
{
    unsigned char		*buf = nil;
    long				i;
    NSImage				*imageRep = nil;
    NSBitmapImageRep	*rep;
    
    [self compute8bitRepresentation];
    
    @try {
        if( [self isRGB] == YES)
        {
            i = width * height * 3;
            buf = malloc( i);
            if( buf)
            {
                unsigned char *dst = buf, *src = (unsigned char*) [self baseAddr];
                i = width * height;
                
                // CONVERT ARGB TO RGB
                while( i-- > 0)
                {
                    src++;
                    *dst++ = *src++;
                    *dst++ = *src++;
                    *dst++ = *src++;
                }
                
                rep = [[[NSBitmapImageRep alloc]
                        initWithBitmapDataPlanes:nil
                        pixelsWide:width
                        pixelsHigh:height
                        bitsPerSample:8
                        samplesPerPixel:3
                        hasAlpha:NO
                        isPlanar:NO
                        colorSpaceName:NSCalibratedRGBColorSpace
                        bytesPerRow:width*3
                        bitsPerPixel:24] autorelease];
                
                if( rep)
                {
                    memcpy( [rep bitmapData], buf, height*width*3);
                    
                    imageRep = [[[NSImage alloc] init] autorelease];
                    [imageRep addRepresentation:rep];
                }
                
                free( buf);
            }
        }
        else
        {
            rep = [[[NSBitmapImageRep alloc]
                    initWithBitmapDataPlanes:nil
                    pixelsWide:width
                    pixelsHigh:height
                    bitsPerSample:8
                    samplesPerPixel:1
                    hasAlpha:NO
                    isPlanar:NO
                    colorSpaceName:NSCalibratedWhiteColorSpace
                    bytesPerRow:width
                    bitsPerPixel:8] autorelease];
            
            if( rep)
            {
                memcpy( [rep bitmapData], [self baseAddr], height*width);
                
                imageRep = [[[NSImage alloc] init] autorelease];
                [imageRep addRepresentation:rep];
            }
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
    return imageRep;
}

- (unsigned char *) ConvertYbrToRgb: (unsigned char *) ybrImage :(int) w :(int) h :(long) theKind :(char) planarConfig
{
    long			loop, size;
    unsigned char		*pYBR, *pRGB;
    unsigned char		*theRGB;
    int			y, y1, r, x, yy;
    
    
    // the planar configuration should be set to 0 whenever
    // YBR_FULL_422 or YBR_PARTIAL_422 is used
    if (theKind != YBR_FULL && planarConfig == 1)
        return NULL;
    
    // allocate room for the RGB image
    theRGB = (unsigned char *) malloc ((long) w * (long) h * 3L);
    if (theRGB == NULL) return NULL;
    pRGB = theRGB;
    size = (long) w * (long) h;
    
    int32_t R, G, B;
    uint8_t a;
    uint8_t b;
    uint8_t c;
    
    
    switch (planarConfig)
    {
        case 0 : // all pixels stored one after the other
            
            switch (theKind)
        {
            case YBR_FULL :		// YBR_FULL
                // loop on the pixels of the image
                for (loop = 0, pYBR = ybrImage; loop < size; loop++, pYBR += 3)
                {
                    // get the Y, B and R channels from the original image
                    //            y = (int) pYBR [0];
                    //            b = (int) pYBR [1];
                    //            r = (int) pYBR [2];
                    
                    a = (int) pYBR [0];
                    b = (int) pYBR [1];
                    c = (int) pYBR [2];
                    
                    R = 38142 *(a-16) + 52298 *(c -128);
                    G = 38142 *(a-16) - 26640 *(c -128) - 12845 *(b -128);
                    B = 38142 *(a-16) + 66093 *(b -128);
                    
                    R = (R+16384)>>15;
                    G = (G+16384)>>15;
                    B = (B+16384)>>15;
                    
                    if (R < 0)   R = 0;
                    if (G < 0)   G = 0;
                    if (B < 0)   B = 0;
                    if (R > 255) R = 255;
                    if (G > 255) G = 255;
                    if (B > 255) B = 255;
                    
                    
                    // red
                    *pRGB = R;	//(unsigned char) (y + (1.402 *  r));
                    pRGB++;	// move the ptr to the Green
                    
                    // green
                    *pRGB = G;	//(unsigned char) (y - (0.344 * b) - (0.714 * r));
                    pRGB++;	// move the ptr to the Blue
                    
                    // blue
                    *pRGB = B;	//(unsigned char) (y + (1.772 * b));
                    pRGB++;	// move the ptr to the next Red
                    
                } // for ...loop on the elements of the image to convert
                break; // YBR_FULL
                
            case YBR_FULL_422 :	// YBR_FULL_422
                // loop on the pixels of the image
                pYBR = ybrImage;
                
                for( yy = 0; yy < h; yy++)
                {
                    unsigned char	*rr = pRGB;
                    unsigned char	*rr2 = pRGB+3*w;
                    
                    for( x = 0; x < w; x++)
                    {
                        y  = (int) pYBR [0];
                        b = (int) pYBR [1];
                        r = (int) pYBR [2];
                        
                        *(rr) = y;
                        *(rr+1) = b;
                        *(rr+2) = r;
                        
                        //				*(rr2) = y;
                        //				*(rr2+1) = b;
                        //				*(rr2+2) = r;
                        
                        pYBR += 3;
                        rr += 3;
                        rr2 += 3;
                    }
                    
                    //			pRGB += 2*w*3;
                    pRGB += w*3;
                }
                break;
                
            case YBR_PARTIAL_422 :	// YBR_PARTIAL_422
                // loop on the pixels of the image
                for (loop = 0, pYBR = ybrImage; loop < (size / 2); loop++)
                {
                    // get the Y, B and R channels from the original image
                    y  = (int) pYBR [0];
                    y1 = (int) pYBR [1];
                    // the Cb and Cr values are sampled horizontally at half the Y rate
                    b = (int) pYBR [2];
                    r = (int) pYBR [3];
                    
                    // ***** first pixel *****
                    // red 1
                    *pRGB = (unsigned char) ((1.1685 * y) + (0.0389 * b) + (1.596 * r));
                    pRGB++;	// move the ptr to the Green
                    
                    // green 1
                    *pRGB = (unsigned char) ((1.1685 * y) - (0.401 * b) - (0.813 * r));
                    pRGB++;	// move the ptr to the Blue
                    
                    // blue 1
                    *pRGB = (unsigned char) ((1.1685 * y) + (2.024 * b));
                    pRGB++;	// move the ptr to the next Red
                    
                    
                    // ***** second pixel *****
                    // red 2
                    *pRGB = (unsigned char) ((1.1685 * y1) + (0.0389 * b) + (1.596 * r));
                    pRGB++;	// move the ptr to the Green
                    
                    // green 2
                    *pRGB = (unsigned char) ((1.1685 * y1) - (0.401 * b) - (0.813 * r));
                    pRGB++;	// move the ptr to the Blue
                    
                    // blue 2
                    *pRGB = (unsigned char) ((1.1685 * y1) + (2.024 * b));
                    pRGB++;	// move the ptr to the next Red
                    
                    // the Cb and Cr values are sampled horizontally at half the Y rate
                    pYBR += 4;
                    
                } // for ...loop on the elements of the image to convert
                break; // YBR_FULL_422 and YBR_PARTIAL_422
                
            default :
                // none...
                break;
        } // switch ...kind of YBR
            break;
            
        case 1 : // each plane is stored separately (only allowed for YBR_FULL)
        {
            unsigned char *pY, *pB, *pR;	// ptr to Y, Cb and Cr channels of the original image
            
            // points to the begining of each channel in memory
            pY = ybrImage;
            pB = (unsigned char *) (pY + size);
            pR = (unsigned char *) (pB + size);
            
            // loop on the pixels of the image
            for (loop = 0; loop < size; loop++, pY++, pB++, pR++)
            {
                a = (int) *pY;
                b = (int) *pB;
                c = (int) *pR;
                
                R = 38142 *(a-16) + 52298 *(c -128);
                G = 38142 *(a-16) - 26640 *(c -128) - 12845 *(b -128);
                B = 38142 *(a-16) + 66093 *(b -128);
                
                R = (R+16384)>>15;
                G = (G+16384)>>15;
                B = (B+16384)>>15;
                
                if (R < 0)   R = 0;
                if (G < 0)   G = 0;
                if (B < 0)   B = 0;
                if (R > 255) R = 255;
                if (G > 255) G = 255;
                if (B > 255) B = 255;
                
                
                // red
                *pRGB = R;	//(unsigned char) ((int) *pY + (1.402 *  (int) *pR) - 179.448);
                pRGB++;	// move the ptr to the Green
                
                // green
                *pRGB = G;	//(unsigned char) ((int) *pY - (0.344 * (int) *pB) - (0.714 * (int) *pR) + 135.45);
                pRGB++;	// move the ptr to the Blue
                
                // blue
                *pRGB = B;	//(unsigned char) ((int) *pY + (1.772 * (int) *pB) - 226.8);
                pRGB++;	// move the ptr to the next Red
                
            } // for ...loop on the elements of the image to convert
        } // case 1
            break;
            
        default :
            // none
            break;
            
    } // switch
    
    return theRGB;
    
} // endof ConvertYbrToRgb

- (float*) getLineROIValue :(long*) numberOfValues :(ROI*) roi
{
    long			count = 0, no, size;
    float			*values;
    long			*xPoints, *yPoints;
    NSPoint			upleft, downright;
    NSPoint			*pts;
    NSMutableArray  *ptsTemp = roi.points;
    
    [self CheckLoad];
    
    pts = (NSPoint*) malloc( ptsTemp.count * sizeof(NSPoint));
    no = [ptsTemp count];
    for( long i = 0; i < no; i++)
    {
        pts[ i] = [[ptsTemp objectAtIndex: i] point];
        //	pts[ i].x+=1.5;
        //	pts[ i].y+=1.5;
    }
    
    upleft = downright = [[ptsTemp objectAtIndex:0] point];
    
    for( long i = 0; i < [ptsTemp count]; i++)
    {
        if( upleft.x > [[ptsTemp objectAtIndex:i] x]) upleft.x = [[ptsTemp objectAtIndex:i] x];
        if( upleft.y > [[ptsTemp objectAtIndex:i] y]) upleft.y = [[ptsTemp objectAtIndex:i] y];
        
        if( downright.x < [[ptsTemp objectAtIndex:i] x]) downright.x = [[ptsTemp objectAtIndex:i] x];
        if( downright.y < [[ptsTemp objectAtIndex:i] y]) downright.y = [[ptsTemp objectAtIndex:i] y];
    }
    
    if( upleft.x < 0) upleft.x = 0;
    if( downright.x < 0) downright.x = 0;
    if( upleft.x > width) upleft.x = width;
    if( downright.x > width) downright.x = width;
    
    if( upleft.y < 0) upleft.y = 0;
    if( downright.y < 0) downright.y = 0;
    if( upleft.y > height) upleft.y = height;
    if( downright.y > height) downright.y = height;
    
    size = BresLine(	[[ptsTemp objectAtIndex:0] x],
                    [[ptsTemp objectAtIndex:0] y],
                    [[ptsTemp objectAtIndex:1] x],
                    [[ptsTemp objectAtIndex:1] y],
                    &xPoints,
                    &yPoints);
    
    values = (float*) malloc( size * sizeof(float));
    if( values)
    {
        count = 0;
        for( long i = 0; i < size; i++)
        {
            if( yPoints[ i] >= 0 && yPoints[ i] < height && xPoints[ i] >= 0 && xPoints[ i] < width)
            {
                values[ count] = [self getPixelValueX: xPoints[ i] Y: yPoints[ i]];
            }
            else values[ count] = 0;
            
            count++;
        }
    }
    *numberOfValues = count;
    
    if( roi) free( pts);
    
    free( xPoints);
    free( yPoints);
    
    return values;
}

- (float*) getROIValue: (long*)numberOfValues : (ROI*)roi : (float**)locations
{
    long count = 0, no;
    float *values = nil;
    long upleftx, uplefty, downrightx, downrighty;
    
    BOOL isComputefImageRGB = isRGB;
    float *computedfImage = nil;
    
    @try
    {
        if( [self thickSlabVRActivated])
            isComputefImageRGB = YES;
        else
            computedfImage = [self computefImage];
        
        if( isComputefImageRGB)
            computedfImage = (float*) self.baseAddr;
        
        if( roi.type == tPlain)
        {
            long textWidth = roi.textureWidth, textHeight = roi.textureHeight;
            long textureUpLeftCornerX = roi.textureUpLeftCornerX, textureUpLeftCornerY = roi.textureUpLeftCornerY;
            unsigned char *buf = roi.textureBuffer;
            
            values = (float*) malloc( textHeight*textWidth* sizeof(float));
            if( locations) *locations = (float*) malloc( textHeight*textWidth*2* sizeof(float));
            
            if( values)
            {
                for( long y = 0; y < textHeight; y++)
                {
                    for( long x = 0; x < textWidth; x++)
                    {
                        if( buf [ x + y * textWidth] != 0)
                        {
                            long xx = (x + textureUpLeftCornerX);
                            long yy = (y + textureUpLeftCornerY);
                            
                            if( xx >= 0 && xx < width && yy >= 0 && yy < height)
                            {
                                if( isComputefImageRGB)
                                {
                                    unsigned char*  rgbPtr = (unsigned char*) &computedfImage[ (yy * width) + xx];
                                    float val = rgbPtr[ 0] + rgbPtr[ 1] + rgbPtr[2] / 3;
                                    
                                    values[ count] = val;
                                    
                                    if( locations)
                                    {
                                        if( *locations)
                                        {
                                            (*locations)[ count*2] = xx;
                                            (*locations)[ count*2 + 1] = yy;
                                        }
                                    }
                                    count++;
                                }
                                else
                                {
                                    float *curPix = &computedfImage[ (yy * width) + xx];
                                    values[ count] = *curPix;
                                    
                                    if( locations)
                                    {
                                        if( *locations)
                                        {
                                            (*locations)[ count*2] = xx;
                                            (*locations)[ count*2 + 1] = yy;
                                        }
                                    }
                                    count++;
                                }
                            }
                        }
                    }
                }
            }
        }
        else
        {
            NSMutableArray *ptsTemp = [roi splinePoints];
            
            if( [ptsTemp count] == 0) return nil;
            
            [self CheckLoad];
            
            NSPointInt *pts = (NSPointInt*) malloc( ptsTemp.count * sizeof(NSPointInt));
            if( pts)
            {
                no = ptsTemp.count;
                for( int i = 0; i < no; i++)
                {
                    pts[ i].x = [[ptsTemp objectAtIndex: i] point].x;
                    pts[ i].y = [[ptsTemp objectAtIndex: i] point].y;
                }
                
                // Need to clip?
                BOOL clip = NO;
                
                for( int i = 0; i < no && clip == NO; i++)
                {
                    if( pts[ i].x < 0) clip = YES;
                    if( pts[ i].y < 0) clip = YES;
                    if( pts[ i].x >= width) clip = YES;
                    if( pts[ i].y >= height) clip = YES;
                }
                
                if( no == 1)
                {
                    values = (float*) malloc( sizeof(float));
                    if( locations) *locations = (float*) malloc( 2 * sizeof(float));
                    
                    if( clip)
                    {
                        values[ count] = 0;
                        
                        if( locations && *locations)
                        {
                            (*locations)[ count*2] = pts[ 0].x;
                            (*locations)[ count*2 + 1] = pts[ 0].y;
                        }
                        count++;
                    }
                    else
                    {
                        if( isComputefImageRGB)
                        {
                            unsigned char *rgbPtr = (unsigned char*) &computedfImage[ (pts[ 0].y * width) + pts[ 0].x];
                            
                            float val = rgbPtr[ 0] + rgbPtr[ 1] + rgbPtr[2] / 3;
                            
                            values[ count] = val;
                            
                            if( locations && *locations)
                            {
                                (*locations)[ count*2] = pts[ 0].x;
                                (*locations)[ count*2 + 1] = pts[ 0].y;
                            }
                            count++;
                        }
                        else
                        {
                            float *curPix = &computedfImage[ (pts[ 0].y * width) + pts[ 0].x];
                            
                            float val = *curPix;
                            
                            values[ count] = val;
                            
                            if( locations && *locations)
                            {
                                (*locations)[ count*2] = pts[ 0].x;
                                (*locations)[ count*2 + 1] = pts[ 0].y;
                            }
                            count++;
                        }
                    }
                }
                else
                {
                    if( clip)
                    {
                        long newNo;
                        
                        NSPointInt *pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
                        if( pTemp)
                        {
                            CLIP_Polygon( pts, no, pTemp, &newNo, NSMakePoint( 0, 0), NSMakePoint( width, height));
                            
                            free( pts);
                            pts = pTemp;
                            no = newNo;
                            
                            //                            // Need to clip?
                            //                            NSPointInt *pTemp;
                            //                            BOOL clip = NO;
                            //
                            //                            for( int i = 0; i < no && clip == NO; i++)
                            //                            {
                            //                                if( pts[ i].x < 0) clip = YES;
                            //                                if( pts[ i].y < 0) clip = YES;
                            //                                if( pts[ i].x >= width) clip = YES;
                            //                                if( pts[ i].y >= height) clip = YES;
                            //                            }
                            //
                            //                            if( clip)
                            //                                NSLog( @"arggg");
                        }
                        else
                            no = 0;
                    }
                    
                    if( no > 2)
                    {
                        [self computeROIBoundsFromPoints: pts count: no upleftx: &upleftx uplefty:&uplefty downrightx: &downrightx downrighty: &downrighty];
                        
                        long size = ((downrightx-upleftx)+2)*((downrighty-uplefty)+2);
                        values = (float*) malloc( size*sizeof(float));
                        
                        float *ilocations = nil;
                        if( locations)
                            *locations = ilocations = (float*) malloc( size * 2 * sizeof(float));
                        
                        if( values)
                            ras_FillPolygon( pts, no, computedfImage, width, height, pixArray.count, 0, 0, NO, 0, NO, isComputefImageRGB, YES, nil, nil, &count, nil, nil, 0, 2, 0, NO, values, ilocations);
                    }
                }
                
                free( pts);
            }
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    @finally
    {
        if( computedfImage && isComputefImageRGB == NO)
        {
            if( computedfImage != self.fImage)
                free( computedfImage);
        }
    }
    
    *numberOfValues = count;
    
    return values;
}

- (BOOL)isInROI: (ROI*)roi : (NSPoint)pt
{
    BOOL			result = NO;
    long			minx, maxx, miny, maxy;
    NSPoint			*pts;
    
    [self CheckLoad];
    
    if( roi)
    {
        if( roi.type == tPlain)
        {
            unsigned char *buf = roi.textureBuffer;
            
            if( pt.x >= roi.textureUpLeftCornerX && pt.x < roi.textureUpLeftCornerX + roi.textureWidth &&
               pt.y >= roi.textureUpLeftCornerY && pt.y < roi.textureUpLeftCornerY + roi.textureHeight)
            {
                int pos = pt.x - roi.textureUpLeftCornerX + (pt.y - roi.textureUpLeftCornerY) * roi.textureWidth;
                if( buf[ pos]) return YES;
                else return NO;
            }
            else return NO;
        }
        else
        {
            NSMutableArray  *ptsTemp = [roi splinePoints];
            
            minx = maxx = [[ptsTemp objectAtIndex: 0] x];
            miny = maxy = [[ptsTemp objectAtIndex: 0] y];
            
            // Find the max rectangle of the ROI
            for( MyPoint *pt in ptsTemp)
            {
                if( minx > [pt x]) minx = [pt x];
                if( maxx < [pt x]) maxx = [pt x];
                if( miny > [pt y]) miny = [pt y];
                if( maxy < [pt y]) maxy = [pt y];
            }
            
            if( pt.x < minx || pt.x > maxx) return NO;
            if( pt.y < miny || pt.y > maxy) return NO;
            
            if( roi.type == tROI) return YES;
            
            int no = (int)ptsTemp.count;
            pts = (NSPoint*) malloc( no * sizeof(NSPoint));
            int i = 0;
            for( MyPoint *pt in ptsTemp) pts[ i++] = [pt point];
            
            long x = pt.x;
            long y = pt.y;
            
            if( pnpoly( pts, no, x, y))	result = YES;
            
            free( pts);
        }
    }
    
    return result;
}

- (void) prepareRestore
{
    if( restoreImageCache)
        [self freeRestore];
    
    restoreImageCache = (DCMPix**) malloc( [pixArray count] * sizeof(DCMPix*));
    
    if( restoreImageCache)
    {
        for( int i = 0; i < [pixArray count]; i++)
        {
            DCMPix	*s = [pixArray objectAtIndex:i];
            
            restoreImageCache[ i ] = [[DCMPix alloc] initWithPath: s.srcFile : i : pixArray.count : nil : s.frameNo : 0];
        }
        
        NSLog( @"prepare Restore cache");
    }
    else NSLog( @"prepare Restore cache - FAILED");
}

- (void) freeRestore
{
    if( restoreImageCache)
    {
        for( int i = 0; i < pixArray.count; i++)
            [restoreImageCache[ i] release];
        
        free( restoreImageCache);
        restoreImageCache = nil;
        
        NSLog( @"free Restore cache");
    }
}

- (unsigned char*) getMapFromPolygonROI:(ROI*) roi size:(NSSize*) size origin:(NSPoint*) ROIorigin
{
    return [DCMPix getMapFromPolygonROI: roi size: size origin: ROIorigin];
}

+ (unsigned char*) getMapFromPolygonROI:(ROI*) roi size:(NSSize*) size origin:(NSPoint*) ROIorigin
{
    unsigned char*	map = nil;
    float*			tempImage = nil;
    
    if( [roi type] == tCPolygon || [roi type] == tOPolygon || [roi type] == tPencil)
    {
        NSArray *ptsTemp = [roi points];
        
        int no = (int)ptsTemp.count;
        struct NSPointInt *ptsInt = (struct NSPointInt*) malloc( no * sizeof(struct NSPointInt));
        
        if( no == 0) NSLog( @"******** ERROR no == 0 getMapFromPolygonROI");
        
        int minX,maxX,minY,maxY;
        
        for( int i = 0; i < no; i++)
        {
            ptsInt[ i].x = [[ptsTemp objectAtIndex: i] point].x;
            ptsInt[ i].y = [[ptsTemp objectAtIndex: i] point].y;
            
            if( i == 0)
            {
                minX = (int)ptsInt[0].x;
                maxX = (int)ptsInt[0].x;
                minY = (int)ptsInt[0].y;
                maxY = (int)ptsInt[0].y;
            }
            else
            {
                if (ptsInt[ i].x < minX) minX = (int)ptsInt[i].x;
                if (ptsInt[ i].x > maxX) maxX = (int)ptsInt[i].x;
                if (ptsInt[ i].y < minY) minY = (int)ptsInt[i].y;
                if (ptsInt[ i].y > maxY) maxY = (int)ptsInt[i].y;
            }
        }
        
        for( int i = 0; i < no; i++)
        {
            ptsInt[ i].x -= minX;
            ptsInt[ i].y -= minY;
        }
        
        size->width = maxX-minX+2;
        size->height = maxY-minY+2;
        
        ROIorigin->x = minX;
        ROIorigin->y = minY;
        
        map = malloc( (5 + size->height) * (5+size->width));
        tempImage = calloc( 1, (5 + size->height) * (5+size->width) * sizeof(float));
        
        // Need to clip?
        int yIm = size->height, xIm = size->width;
        
        if( ptsInt != nil && no > 1)
        {
            BOOL restore = NO, addition = NO, outside = NO;
            
            ras_FillPolygon( ptsInt, no, tempImage, size->width, size->height, 1, -FLT_MAX, FLT_MAX, outside, 255, addition, NO, NO, nil, nil, nil, nil, nil, 0, 2, 0, restore, nil, nil);
        }
        
        // Convert float to char
        int i = yIm * xIm;
        while ( i-- > 0)
            map[ i] = tempImage[ i];
        
        // Keep a free box around the image
        for( int i = 0 ; i < xIm; i++)
        {
            map[ i] = 0;
            map[ (yIm-1)*xIm +i] = 0;
        }
        
        for( int i = 0 ; i < yIm; i++)
        {
            map[ i*xIm] = 0;
            map[ i*xIm + xIm-1] = 0;
        }
        
        free( tempImage);
        free( ptsInt);
    }
    
    return map;
}

- (void) fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition;
{
#ifdef OSIRIX_VIEWER
    return [self fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition spline: [roi isSpline]];
#else
    return [self fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition spline: NO];
#endif
}

- (void) fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition spline:(BOOL) spline;
{
    return [self fillROI: roi newVal: newVal minValue: minValue maxValue: maxValue outside: outside orientationStack:orientationStack stackNo: stackNo restore: restore addition: addition spline: spline clipMin: NSMakePoint(0, 0) clipMax: NSMakePoint(0, 0)];
}

- (void) fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition spline:(BOOL) spline clipMin: (NSPoint) clipMin clipMax: (NSPoint) clipMax;
{
    long				no = 0;
    long				y;
    long				uplefty, downrighty, ims = width * height;
    struct NSPointInt	*ptsInt = nil;
    NSMutableArray		*ptsTemp = nil;
    float				*fTempImage;
    BOOL				clip;
    
    [self CheckLoad];
    
    if( stackNo < 0 && restore)	{
        NSLog( @"error !!!! stackNo < 0 && restore");
        restore = NO;
    }
    
    if( clipMin.x == 0 && clipMax.x == 0 && clipMin.y == 0 && clipMax.y == 0)
    {
        switch( orientationStack)
        {
            case 0:	clipMin = NSMakePoint( 0, 0);   clipMax = NSMakePoint( height, pixArray.count); break;
            case 1:	clipMin = NSMakePoint( 0, 0);   clipMax = NSMakePoint( width, pixArray.count); break;
            case 2:	clipMin = NSMakePoint( 0, 0);   clipMax = NSMakePoint( width, height); break;
        }
    }
    
    if( clipMin.x < 0)
        clipMin.x = 0;
    if( clipMin.y < 0)
        clipMin.y = 0;
    
    
    switch( orientationStack)
    {
        case 0:	if( clipMax.x > height) clipMax.x = height; if( clipMax.y > pixArray.count) clipMax.y = pixArray.count; break;
        case 1:	if( clipMax.x > width) clipMax.x = width; if( clipMax.y > pixArray.count) clipMax.y = pixArray.count; break;
        case 2:	if( clipMax.x > width) clipMax.x = width; if( clipMax.y > height) clipMax.y = height; break;
    }
    
    if( roi)
    {
        if( roi.type == tPlain)
        {
            if( orientationStack != 2)
            {
                N2LogStackTrace( @"Unsupported orientation");
                return;
            }
            
            long			textWidth = roi.textureWidth;
            long			textHeight = roi.textureHeight;
            long			textureUpLeftCornerX = roi.textureUpLeftCornerX;
            long			textureUpLeftCornerY = roi.textureUpLeftCornerY;
            unsigned char	*buf = roi.textureBuffer;
            
            // *** INSIDE
            
            if( outside == NO)
            {
                for( y = textureUpLeftCornerY; y < textureUpLeftCornerY + textHeight; y++)
                {
                    if( isRGB)
                    {
                        
                        unsigned char *rgbPtr = (unsigned char*) (fImage + textureUpLeftCornerX + y*width);
                        unsigned char *fTempRestore = nil;
                        if( restore) fTempRestore = (unsigned char*) &[restoreImageCache[ stackNo] fImage][textureUpLeftCornerX + y*width];
                        
                        for( long x = textureUpLeftCornerX; x < textureUpLeftCornerX + textWidth; x++)
                        {
                            if( *buf++)
                            {
                                if( x >= clipMin.x && x < clipMax.x && y >= clipMin.y && y < clipMax.y)
                                {
                                    if( restore)
                                    {
                                        rgbPtr[ 1] = fTempRestore[ 1];
                                        rgbPtr[ 2] = fTempRestore[ 2];
                                        rgbPtr[ 3] = fTempRestore[ 3];
                                    }
                                    else if( addition)
                                    {
                                        if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] += newVal;
                                        if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] += newVal;
                                        if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] += newVal;
                                    }
                                    else
                                    {
                                        if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
                                        if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
                                        if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
                                    }
                                }
                            }
                            rgbPtr += 4;
                        }
                    }
                    else
                    {
                        float *fTempImage = fImage + textureUpLeftCornerX + y*width;
                        float *fTempRestore = nil;
                        if( restore) fTempRestore = &[restoreImageCache[ stackNo] fImage][textureUpLeftCornerX + y*width];
                        
                        for( long x = textureUpLeftCornerX; x < textureUpLeftCornerX + textWidth; x++)
                        {
                            if( *buf++)
                            {
                                if( x >= clipMin.x && x < clipMax.x && y >= clipMin.y && y < clipMax.y)
                                {
                                    if( restore) *fTempImage = *fTempRestore;
                                    else if( addition)
                                    {
                                        if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage += newVal;
                                    }
                                    else
                                    {
                                        if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
                                    }
                                }
                            }
                            fTempImage++;
                            fTempRestore++;
                        }
                    }
                }
            }
            
            // *** OUTSIDE
            
            else
            {
                for( long y = clipMin.y; y < clipMax.y; y++)
                {
                    for( long x = clipMin.x; x < clipMax.x; x++)
                    {
                        BOOL doit = NO;
                        
                        if( x >= textureUpLeftCornerX && x < textureUpLeftCornerX + textWidth && y >= textureUpLeftCornerY && y < textureUpLeftCornerY + textHeight)
                        {
                            if( !buf [ x - textureUpLeftCornerX + (y - textureUpLeftCornerY) * textWidth]) doit = YES;
                        }
                        else doit = YES;
                        
                        if( doit)
                        {
                            long	xx = x;
                            long	yy = y;
                            
                            if( isRGB)
                            {
                                unsigned char*  rgbPtr = (unsigned char*) &fImage[ (yy * width) + xx];
                                
                                if( addition)
                                {
                                    if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] += newVal;
                                    if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] += newVal;
                                    if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] += newVal;
                                }
                                else
                                {
                                    if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
                                    if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
                                    if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
                                }
                            }
                            else
                            {
                                float	*fTempImage = &fImage[ (yy * width) + xx];
                                
                                if( addition)
                                {
                                    if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage += newVal;
                                }
                                else
                                {
                                    if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
                                }
                            }
                        }
                    }
                }
            }
            
            return;
        }
        else
        {
            if( spline) ptsTemp = [roi splinePoints];
            else ptsTemp = [roi points];
            
            no = ptsTemp.count;
            
            ptsInt = (struct NSPointInt*) malloc( no * sizeof( struct NSPointInt));
            
            for( long i = 0; i < no; i++)
            {
                ptsInt[ i].x = [[ptsTemp objectAtIndex: i] point].x;
                ptsInt[ i].y = [[ptsTemp objectAtIndex: i] point].y;
            }
            
            // Need to clip?
            NSPointInt *pTemp;
            long yIm, xIm;
            
            switch( orientationStack)
            {
                case 0:	yIm = pixArray.count;		xIm = width;	break;
                case 1:	yIm = pixArray.count;		xIm = height;	break;
                case 2:	yIm = height;				xIm = width;	break;
            }
            
            clip = NO;
            switch( orientationStack)
            {
                case 2:
                    for( long i = 0; i < no && clip == NO; i++)
                    {
                        if( ptsInt[ i].x < clipMin.x) clip = YES;
                        if( ptsInt[ i].y < clipMin.y) clip = YES;
                        if( ptsInt[ i].x >= clipMax.x) clip = YES;
                        if( ptsInt[ i].y >= clipMax.y) clip = YES;
                    }
                    
                    if( clip)
                    {
                        long newNo;
                        
                        pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
                        
                        CLIP_Polygon( ptsInt, no, pTemp, &newNo, clipMin, clipMax);
                        
                        free( ptsInt);
                        ptsInt = pTemp;
                        
                        no = newNo;
                    }
                    break;
                    
                case 0:
                    for( long i = 0; i < no && clip == NO; i++)
                    {
                        if( ptsInt[ i].x < clipMin.x) clip = YES;
                        if( ptsInt[ i].y < clipMin.y) clip = YES;
                        if( ptsInt[ i].x >= clipMax.x) clip = YES;
                        if( ptsInt[ i].y >= clipMax.y) clip = YES;
                    }
                    
                    if( clip)
                    {
                        long newNo;
                        
                        pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
                        CLIP_Polygon( ptsInt, no, pTemp, &newNo, clipMin, clipMax);
                        
                        free( ptsInt);
                        ptsInt = pTemp;
                        no = newNo;
                    }
                    break;
                    
                case 1:
                    for( long i = 0; i < no && clip == NO; i++)
                    {
                        if( ptsInt[ i].x < clipMin.x) clip = YES;
                        if( ptsInt[ i].y < clipMin.y) clip = YES;
                        if( ptsInt[ i].x >= clipMax.x) clip = YES;
                        if( ptsInt[ i].y >= clipMax.y) clip = YES;
                    }
                    
                    if( clip)
                    {
                        long newNo;
                        
                        pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
                        CLIP_Polygon( ptsInt, no, pTemp, &newNo, clipMin, clipMax);
                        
                        free( ptsInt);
                        ptsInt = pTemp;
                        no = newNo;
                    }
                    break;
            }
        }
    }
    else ptsInt = nil;
    
    if( outside)
    {
        long yIm, xIm;
        
        switch( orientationStack)
        {
            case 0:	yIm = pixArray.count;		xIm = width;	break;
            case 1:	yIm = pixArray.count;		xIm = height;	break;
            case 2:	yIm = height;				xIm = width;	break;
        }
        
        if( roi) uplefty = downrighty = ptsInt[0].y;
        else
        {
            uplefty = 0;
            downrighty = yIm;
        }
        
        for( long i = 0; i < no; i++)
        {
            if( uplefty > ptsInt[i].y) uplefty = ptsInt[i].y;
            if( downrighty < ptsInt[i].y) downrighty = ptsInt[i].y;
        }
        
        if( uplefty < 0) uplefty = 0;
        if( uplefty >= yIm) uplefty = yIm-1;
        
        if( downrighty < 0) downrighty = 0;
        if( downrighty >= yIm) downrighty = yIm-1;
        
        
        if( isRGB)
        {
            for( long y = 0; y < uplefty ; y++)
            {
                switch( orientationStack)
                {
                    case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
                    case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
                    case 2:		fTempImage = fImage + width*y;							break;
                }
                
                for( long x = 0; x < width ; x++)
                {
                    unsigned char*  rgbPtr = (unsigned char*) fTempImage;
                    
                    if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
                    if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
                    if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
                    
                    if( orientationStack) fTempImage++;
                    else fTempImage += width;
                }
            }
            
            for( long y = downrighty; y < yIm ; y++)
            {
                switch( orientationStack)
                {
                    case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
                    case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
                    case 2:		fTempImage = fImage + width*y;							break;
                }
                
                for( long x = 0; x < width ; x++)
                {
                    unsigned char*  rgbPtr = (unsigned char*) fTempImage;
                    
                    if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
                    if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
                    if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
                    
                    if( orientationStack) fTempImage ++;
                    else fTempImage += width;
                }
            }
        }
        else
        {
            for( long y = 0; y < uplefty ; y++)
            {
                switch( orientationStack)
                {
                    case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
                    case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
                    case 2:		fTempImage = fImage + width*y;							break;
                }
                
                for( long x = 0; x < width ; x++)
                {
                    if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
                    
                    if( orientationStack) fTempImage ++;
                    else fTempImage += width;
                }
            }
            
            for( long y = downrighty; y < yIm ; y++)
            {
                switch( orientationStack)
                {
                    case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
                    case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
                    case 2:		fTempImage = fImage + width*y;							break;
                }
                
                for( long x = 0; x < width ; x++)
                {
                    if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
                    
                    if( orientationStack) fTempImage ++;
                    else fTempImage += width;
                }
            }
        }
    }
    
    if( ptsInt != nil && no > 1)
    {
        ras_FillPolygon( ptsInt, no, fImage, width, height, pixArray.count, minValue, maxValue, outside, newVal, addition, isRGB, NO, nil, nil, nil, nil, nil, 0, orientationStack, stackNo, restore, nil, nil);
    }
    else
    {	// Fill the image that contains no ROI :
        if( outside)
        {
            long yIm, xIm;
            
            switch( orientationStack)
            {
                case 0:	yIm = pixArray.count;		xIm = width;	break;
                case 1:	yIm = pixArray.count;		xIm = height;	break;
                case 2:	yIm = height;				xIm = width;	break;
            }
            
            if( isRGB)
            {
                for( long y = 0; y < yIm ; y++)
                {
                    switch( orientationStack)
                    {
                        case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
                        case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
                        case 2:		fTempImage = fImage + width*y;							break;
                    }
                    
                    for( long x = 0; x < xIm ; x++)
                    {
                        unsigned char*  rgbPtr = (unsigned char*) fTempImage;
                        
                        if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
                        if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
                        if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
                        
                        if( orientationStack) fTempImage ++;
                        else fTempImage += width;
                    }
                }
            }
            else
            {
                for( long y = 0; y < yIm ; y++)
                {
                    switch( orientationStack)
                    {
                        case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
                        case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
                        case 2:		fTempImage = fImage + width*y;							break;
                    }
                    
                    for( long x = 0; x < xIm ; x++)
                    {
                        if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
                        
                        if( orientationStack) fTempImage ++;
                        else fTempImage += width;
                    }
                }
            }
        }
    }
    
    //	for( DCMPix* pix in pixArray)
    //	{
    //		[self computePixMinPixMax];
    //		pix.minValueOfSeries = 0;
    //		pix.maxValueOfSeries = 0;
    //	}
    
    if( roi) free( ptsInt);
}

- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientationStack :(long) stackNo
{
    return [self fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientationStack :(long) stackNo :NO];
}

- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientationStack :(long) stackNo :(BOOL) restore
{
    [self fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue:(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) NO];
}

- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside
{
    [self fillROI:roi :newVal :minValue :maxValue :outside :2 :-1];
}

- (int)calciumCofactorForROI:(ROI *)roi threshold:(int)threshold{
    int cf1Count = 0;
    int cf2Count = 0;
    int cf3Count = 0;
    int cf4Count = 0;
    int count = 0;
    [self CheckLoad];
    
    if( roi.type == tPlain)
    {
        long			textWidth = roi.textureWidth;
        long			textHeight = roi.textureHeight;
        long			textureUpLeftCornerX = roi.textureUpLeftCornerX;
        long			textureUpLeftCornerY = roi.textureUpLeftCornerY;
        unsigned char	*buf = roi.textureBuffer;
        float			*fImageTemp;
        
        for( int y = 0; y < textHeight; y++)
        {
            fImageTemp = fImage + ((y + textureUpLeftCornerY) * width) + textureUpLeftCornerX;
            
            for( int x = 0; x < textWidth; x++, fImageTemp++)
            {
                if( *buf++ != 0)
                {
                    long	xx = (x + textureUpLeftCornerX);
                    long	yy = (y + textureUpLeftCornerY);
                    
                    if( xx >= 0 && xx < width && yy >= 0 && yy < height)
                    {
                        if( isRGB == NO)
                        {
                            float	val = *fImageTemp;
                            
                            count++;
                            //NSLog(@"x: %d  y: %d Calcium %f",xx, yy,  val);
                            if(val > threshold) cf1Count++;
                            if(val > 200) cf2Count++;
                            if(val > 300) cf3Count++;
                            if(val > 400) cf4Count++;
                        }
                    }
                }
            }
        }
        if (cf4Count > 2) return 4;
        if (cf3Count > 2) return 3;
        if (cf2Count > 2) return 2;
        return 1;
    }
    else
        return 0;
}

+ (double) moment: (float *) x length:(long) length mean: (double) mean order: (int) order
{
    if (x == nil || order == 1)
        return 0.;
    else
    {
        double mu = mean;
        double sum = 0;
        for (int i = 0; i < length; i++)
        {
            sum += pow((x[i] - mu), order);
        }
        return (sum / ( length - 1));
    }
}

/**
 * This method calculates the skewness of a data set. Skewness is the third central moment divided by the third
 * power of the standard deviation.
 */

+ (double) skewness: (float*) data length: (long) length mean: (double) mean
{
    if (data == nil || length < 2)
        return 0.;
    else
    {
        double m3 = [DCMPix moment: data length: length mean: mean order: 3];
        double sm2 = sqrt([DCMPix moment: data length: length mean: mean order: 2]);
        return (m3 / (sm2*sm2*sm2));
    }
}

/**
 * This method calculates the kurtosis of a data set. Kurtosis is the fourth central moment divided by the fourth
 * power of the standard deviation.
 */
+ (double) kurtosis: (float*) data length: (long) length mean: (double) mean
{
    if (data == nil || length < 2)
        return 0.;
    else
    {
        double m4 = [DCMPix moment: data length: length mean: mean order: 4];
        double sm2 = sqrt( [DCMPix moment: data length: length mean: mean order: 2]);
        return (m4 / (sm2*sm2*sm2*sm2)) - 3.; /* makes kurtosis zero for a Gaussian */
    }
}

- (void) computeROIBoundsFromPoints: (NSPointInt*) pts count: (long) count upleftx:(long*) upleftx uplefty:(long*)uplefty downrightx:(long*)downrightx downrighty:(long*) downrighty
{
    if( count == 0)
    {
        NSLog( @"******** computeROIBoundsFromPoints pts.count == 0 !!!!!!");
        return;
    }
    *upleftx = *downrightx = pts[0].x;
    *uplefty = *downrighty = pts[0].y;
    
    for( long i = 0; i < count; i++)
    {
        if( *upleftx > pts[i].x) *upleftx = pts[i].x;
        if( *uplefty > pts[i].y) *uplefty = pts[i].y;
        
        if( *downrightx < pts[i].x) *downrightx = pts[i].x;
        if( *downrighty < pts[i].y) *downrighty = pts[i].y;
    }
    
    if( *upleftx < 0)
        *upleftx = 0;
    if( *downrightx < 0)
        *downrightx = 0;
    if( *upleftx > width)
        *upleftx = width;
    if( *downrightx > width)
        *downrightx = width;
    
    if( *uplefty < 0)
        *uplefty = 0;
    if( *downrighty < 0)
        *downrighty = 0;
    if( *uplefty > height)
        *uplefty = height;
    if( *downrighty > height)
        *downrighty = height;
}

- (void) computeROI:(ROI*) roi :(float*) mean :(float *)total :(float *)dev :(float *)min :(float *)max
{
    return [self computeROI: roi :mean :total :dev :min :max :nil :nil];
}

- (void) computeROI:(ROI*) roi :(float*) mean :(float *)total :(float *)dev :(float *)min :(float *)max :(float *)skewness :(float*) kurtosis
{
    //    if( total)
    //        *total = rand();
    //    return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ROIComputeSkewnessAndKurtosis"] == NO)
    {
        if( skewness)
            *skewness = 0;
        if( kurtosis)
            *kurtosis = 0;
        
        skewness = nil;
        kurtosis = nil;
    }
    
    long count;
    double imax, imin, itotal, idev, imean;
    
    count = 0;
    itotal = 0;
    imean = 0;
    idev = 0;
    imin = FLT_MAX;
    imax = -FLT_MAX;
    
    float *values = [self getROIValue: &count :roi :nil];
    
    //    if( total)
    //        *total = rand();
    //    return;
    
    for( long i = 0; i < count; i++)
    {
        float val = values[ i];
        
        itotal += val;
        
        if( imin > val) imin = val;
        if( imax < val) imax = val;
    }
    
    if( count != 0)
        imean = itotal / count;
    
    if( dev)
    {
        idev = 0;
        
        for( long i = 0; i < count; i++)
        {
            float temp = imean - values[ i];
            temp *= temp;
            idev += temp;
        }
        
        *dev = idev;
        *dev = *dev / (count-1);
        *dev = sqrt(*dev);
    }
    
    if( max) *max = imax;
    if( min) *min = imin;
    if( total) *total = itotal;
    if( mean) *mean = imean;
    
    if( max && *max == -FLT_MAX) *max = 0;
    if( min && *min == FLT_MAX) *min = 0;
    
    
    if( kurtosis)
        *kurtosis = [DCMPix kurtosis: values length: count mean: imean];
    
    if( skewness)
        *skewness = [DCMPix skewness: values length: count mean: imean];
    
    
    if( values)
        free( values);
}

- (void) setRGB:(BOOL) b
{
    isRGB = b;
}

- (void) freefImageWhenDone:(BOOL) b
{
    [checking lock];
    
    if( b)
        fExternalOwnedImage = nil;
    else
        fExternalOwnedImage = fImage;
    
    [checking unlock];
}

-(void) setfImage:(float*) ptr
{
    [checking lock];
    
    if( fExternalOwnedImage == nil)
    {
        if( fImage != nil)
        {
            free(fImage);
            fImage = nil;
        }
    }
    
    [self kill8bitsImage];
    
    fImage = ptr;
    
    if( fExternalOwnedImage)
        fExternalOwnedImage = fImage;
    
    [checking unlock];
}

- (BOOL) isLoaded
{
    BOOL isLoaded = NO;
    
    if( [checking tryLock])
    {
        if( fImage)
            isLoaded = YES;
        
        [checking unlock];
    }
    
    return isLoaded;
}

- (float*) fImage
{
    [self CheckLoad];
    return fImage;
}

- (double) pixelRatio { [self CheckLoad]; return pixelRatio; }

- (double) pixelSpacingY { [self CheckLoad]; return pixelSpacingY; }
- (double) pixelSpacingX { [self CheckLoad]; return pixelSpacingX; }

- (void) setPixelX: (int) x Y:(int) y value:(float) v
{
    [self CheckLoad];
    
    *(fImage + x + (y*width)) = v;
}

- (void) setPixelSpacingX :(double) s
{
    if( isnan( s) || s < 0.00001 || s > 1000)
    {
        NSLog( @"***** setPixelSpacingX with value : %lf", s);
        s = 1;
    }
    
    [self CheckLoad];
    pixelSpacingX = s;
    if( pixelSpacingX) pixelRatio = pixelSpacingY / pixelSpacingX;
}

- (void) setPixelSpacingY :(double) s
{
    if( isnan( s) || s < 0.00001 || s > 1000)
    {
        NSLog( @"***** setPixelSpacingY with value : %lf", s);
        s = 1;
    }
    
    [self CheckLoad];
    pixelSpacingY = s;
    if( pixelSpacingX) pixelRatio = pixelSpacingY / pixelSpacingX;
}

- (double) originX { [self CheckLoad]; return originX;}
- (double) originY { [self CheckLoad]; return originY;}
- (double) originZ { [self CheckLoad]; return originZ;}

- (void) origin: (float*)o
{
    [self CheckLoad];
    o[ 0] = originX;
    o[ 1] = originY;
    o[ 2] = originZ;
}
- (void) originDouble: (double*)o
{
    [self CheckLoad];
    o[ 0] = originX;
    o[ 1] = originY;
    o[ 2] = originZ;
}
- (void) setOrigin: (float*)o
{
    originX = o[ 0];
    originY = o[ 1];
    originZ = o[ 2];
}
- (void) setOriginDouble: (double*)o
{
    originX = o[ 0];
    originY = o[ 1];
    originZ = o[ 2];
};
- (double) sliceLocation{ [self CheckLoad]; return sliceLocation;}
- (void) setSliceLocation: (double)l { [self CheckLoad]; sliceLocation = l;}
- (void) computeSliceLocation
{
    float centerPix[ 3];
    [self convertPixX: width/2 pixY: height/2 toDICOMCoords: centerPix];
    
    if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
        sliceLocation = centerPix[ 0];
    
    if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
        sliceLocation = centerPix[ 1];
    
    if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
        sliceLocation = centerPix[ 2];
}
- (double) sliceThickness { [self CheckLoad]; return sliceThickness;}
- (void) setSliceThickness: (double)l
{
    [self CheckLoad];
    sliceThickness = l;
}
- (double) spacingBetweenSlices { [self CheckLoad]; return spacingBetweenSlices;}

- (double) sliceInterval { [self CheckLoad]; return sliceInterval; }
- (void) setSliceInterval: (double)s { [self CheckLoad]; sliceInterval = s; }

- (float) slope { [self CheckLoad]; return slope; }
- (float) offset { [self CheckLoad]; return offset; }

// WW & WL
- (float) ww { [self CheckLoad]; return ww; }
- (float) wl { [self CheckLoad]; return wl; }

- (float) fullww
{
    if( fullww == 0 && fullwl == 0) [self computePixMinPixMax];
    return fullww;
}

- (float) fullwl
{
    if( fullww == 0 && fullwl == 0) [self computePixMinPixMax];
    return fullwl;
}

- (float) savedWL { [self CheckLoad]; return savedWL; }
- (float) savedWW { [self CheckLoad]; return savedWW; }
- (void) setSavedWL: (float)l { [self CheckLoad]; savedWL = l; }
- (void) setSavedWW: (float)w { [self CheckLoad]; savedWW = w; }

-(float) cineRate {[self CheckLoad]; return cineRate;}

-(id) myinitEmpty
{
    @synchronized( [DCMPix class])
    {
        if( cachedPapyGroups == nil)
            cachedPapyGroups = [NSMutableDictionary new];
        
        if( cachedDCMFrameworkFiles == nil)
            cachedDCMFrameworkFiles = [NSMutableDictionary new];
        
        if( cachedDCMTKFileFormat == nil)
            cachedDCMTKFileFormat = [NSMutableDictionary new];
    }
    
    checking = [[NSRecursiveLock alloc] init];
    decayFactor = 1.0;
    
    orientation[ 0] = 1;
    orientation[ 1] = 0;
    orientation[ 2] = 0;
    orientation[ 3] = 0;
    orientation[ 4] = 1;
    orientation[ 5] = 0;
    // Compute normal vector
    orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
    orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
    orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
    self.srcFile = nil;
    generated = YES;
    self.rescaleType = @"";
    
    return [super init];
}


-(void) setArrayPix :(NSArray*) array :(short) i
{
    pixArray = array;
    pixPos = i;
    
    if( [array objectAtIndex:i] != self)
    {
        NSLog(@"Beuh... Pix != Pix...");
    }
}

- (void) initParameters
{
    [DCMPix checkUserDefaults: NO];
    
    @synchronized( [DCMPix class])
    {
        if( cachedPapyGroups == nil)
            cachedPapyGroups = [NSMutableDictionary new];
        
        if( cachedDCMFrameworkFiles == nil)
            cachedDCMFrameworkFiles = [NSMutableDictionary new];
        
        if( cachedDCMTKFileFormat == nil)
            cachedDCMTKFileFormat = [NSMutableDictionary new];
    }
    
    needToCompute8bitRepresentation = YES;
    
    //---------------------------------various
    pixelRatio = 1.0;
    checking = [[NSRecursiveLock alloc] init];
    stack = 2;
    decayFactor = 1.0;
    slope = 1.0;
    self.rescaleType = @"";
    //----------------------------------angio
    subtractedfPercent = 1.0;
    subtractedfZ = 0.8;
    subtractedfZero = 0.8;
    subtractedfGamma = 2.0;
    
    factorPET2SUV = 1.0;
    maskID = 1;
    
    //----------------------------------orientation
    orientation[ 0] = 1;
    orientation[ 1] = 0;
    orientation[ 2] = 0;
    orientation[ 3] = 0;
    orientation[ 4] = 1;
    orientation[ 5] = 0;
    // Compute normal vector
    orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
    orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
    orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
    
    
}

- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ :(BOOL) volSize
{
    return [self initWithData :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ :(BOOL) volSize];
}

- (id) initWithData :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ :(BOOL) volSize
{
    //if( pixelSize != 32) NSLog( @"Only floating images are supported...");
    if( self = [super init])
    {
        [self initParameters];
        
        annotationsDictionary = [[NSMutableDictionary alloc] init];
        needToCompute8bitRepresentation = YES;
        generated = YES;
        imTot = 1;
        
        height = yDim;
        width = xDim;
        pixelSpacingX = xSpace;
        pixelSpacingY = ySpace;
        
        if( isnan( pixelSpacingX) || pixelSpacingX < 0.00001 || pixelSpacingX > 1000)
            NSLog( @"****** DCMPix initWithData");
        
        if( isnan( pixelSpacingY) || pixelSpacingY < 0.00001 || pixelSpacingY > 1000)
            NSLog( @"****** DCMPix initWithData");
        
        if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
        else pixelRatio = 1.0;
        
        if( volSize)
        {
            fExternalOwnedImage = im;
            fImage = im;
            
            if( im == nil)
                NSLog( @"DCMPix initWithData ERROR im == nil");
        }
        else
        {
            switch( pixelSize)
            {
                case 7:		// ARGB
                    isRGB = YES;
                case 32:	// FLOAT
                    fImage = malloc(width*height*sizeof(float));
                    long i;
                    
                    if( fImage)
                    {
                        if( im)
                        {
                            if( xDim != width)
                            {
                                //	NSLog(@"Allocate a new fImage");
                                for( i =0; i < height; i++)
                                {
                                    memcpy( fImage + i*width, im + i*xDim, width*sizeof(float));
                                }
                            }
                            else memcpy( fImage, im, width*height*sizeof(float));
                        }
                    }
                    else N2LogStackTrace( @"*** Not enough memory - malloc failed");
                    break;
                    
                case 8:		// RGBA -> argb
                    fImage = malloc(width*height*4);
                    
                    if( fImage)
                    {
                        if( im)
                        {
                            unsigned char *src = (unsigned char*) im, *dst = (unsigned char*) fImage;
                            
                            for( i =0; i < height*width*4; i+= 4)
                            {
                                dst[ i] = src[ i+3];
                                dst[ i+1] = src[ i];
                                dst[ i+2] = src[ i+1];
                                dst[ i+3] = src[ i+2];
                            }
                        }
                    }
                    else N2LogStackTrace( @"*** Not enough memory - malloc failed");
                    
                    isRGB = YES;
                    break;
            }
        }
        
        originX = oX;
        originY = oY;
        originZ = oZ;
        
        isOriginDefined = YES;
        
        ww = 0;
        wl = 0;
        
        sliceLocation = 0;
        sliceThickness = 0;
        
        memset( orientation, 0, sizeof orientation);
    }
    return self;
}

- (id) initWithData :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ
{
    return [self initWithData: im :pixelSize :xDim :yDim :xSpace :ySpace :oX :oY :oZ :NO];
}

- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ
{
    return [self initWithData: im :pixelSize :xDim :yDim :xSpace :ySpace :oX :oY :oZ :NO];
}

+ (id) dcmPixWithImageObj: (DicomImage*) image
{
    return  [[[DCMPix alloc] initWithImageObj: image] autorelease];
}

- (id) initWithImageObj: (DicomImage *) image
{
    return  [self initWithPath: image.completePath :0 :1 :nil :[image.frameID intValue] :[image.series.id intValue] isBonjour:NO imageObj: image];
}

- (id)initWithContentsOfFile: (NSString *)file
{
    return  [self initWithPath:file :0 :1 :nil :0 :0 isBonjour:NO imageObj: nil];
}

- (id) initWithPath:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss isBonjour:(BOOL) hello imageObj: (NSManagedObject*) iO
{
    // doesn't load pix data, only initializes instance variables
    if( hello == NO && s != nil)
        if( [[NSFileManager defaultManager] fileExistsAtPath:s] == NO) return nil;
    
    //#if NDEBUG
    //#else
    //    if( [NSThread isMainThread] == NO)
    //        NSLog( @"***** Warning: DCMPix initWithPath should be created in the main thread");
    //#endif
    
    if( self = [super init])
    {
        //-------------------------received parameters
        self.srcFile = s;
        
        [iO.managedObjectContext lock];
        @try
        {
            imageObjectID = [[iO objectID] retain];
            
            URIRepresentationAbsoluteString =  [[[[[iO valueForKeyPath:@"series.study"] objectID] URIRepresentation] absoluteString] retain];
            fileTypeHasPrefixDICOM = [[iO valueForKey:@"fileType"] hasPrefix:@"DICOM"];
            numberOfFrames = [[iO valueForKey: @"numberOfFrames"] intValue];
            self->modalityString = [[NSString stringWithString:[iO valueForKeyPath:@"series.modality"]] retain];
            
            if( [iO valueForKeyPath: @"series.study.dateOfBirth"])
                self.yearOld = [iO valueForKeyPath: @"series.study.yearOld"];
            
            if( [iO valueForKeyPath: @"series.study.dateOfBirth"] && [iO valueForKeyPath: @"series.study.date"])
                self.yearOldAcquisition = [iO valueForKeyPath: @"series.study.yearOldAcquisition"];
/*
#ifdef OSIRIX_VIEWER
            [self loadCustomImageAnnotationsDBFields: (DicomImage*) iO];
#endif
*/
            savedHeightInDB = [[iO valueForKey:@"height"] intValue];
            savedWidthInDB = [[iO valueForKey:@"width"] intValue];
        }
        @catch ( NSException *e)
        {
            N2LogExceptionWithStackTrace( e);
        }
        @finally
        {
            [iO.managedObjectContext unlock];
        }
        
        imID = pos;
        imTot = tot;
        fExternalOwnedImage = ptr;
        frameNo = f;
        serieNo = ss;
        isBonjour = hello;
        
        [self initParameters];
        
        annotationsDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss isBonjour:(BOOL) hello imageObj: (NSManagedObject*) iO
{
    return [self initWithPath: (NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss isBonjour:(BOOL) hello imageObj: (NSManagedObject*) iO];
}

- (id) initWithPath:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss
{
    return [self initWithPath: s :pos :tot :ptr :f :ss isBonjour:NO imageObj: nil];
}

- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss
{
    return [self initWithPath: s :pos :tot :ptr :f :ss isBonjour:NO imageObj: nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    DCMPix *copy = [[DCMPix allocWithZone:zone] init];
    if (!copy)
        return nil;
    
    copy->_srcFile = [self->_srcFile retain];
    copy->imageObjectID = [self->imageObjectID retain];
    copy->URIRepresentationAbsoluteString = [self->URIRepresentationAbsoluteString retain];
    copy->fileTypeHasPrefixDICOM = self->fileTypeHasPrefixDICOM;
    copy->yearOld = [self->yearOld retain];
    copy->yearOldAcquisition = [self->yearOldAcquisition retain];
    copy->imID = self->imID;
    copy->imTot = self->imTot;
    copy->fExternalOwnedImage = self->fExternalOwnedImage;
    copy->frameNo = self->frameNo;
    copy->serieNo = self->serieNo;
    copy->isBonjour = self->isBonjour;
    copy->numberOfFrames = self->numberOfFrames;
    
    [copy initParameters];
    
    copy->fImage = self->fImage;	// Don't load the image!
    copy->height = self->height;
    copy->width = self->width;
    copy->wl = self->wl;
    copy->ww = self->ww;
    copy->sliceInterval = self->sliceInterval;
    copy->spacingBetweenSlices = self->spacingBetweenSlices;
    copy->pixelSpacingX = self->pixelSpacingX;
    copy->pixelSpacingY = self->pixelSpacingY;
    copy->sliceLocation = self->sliceLocation;
    copy->sliceThickness = self->sliceThickness;
    copy->pixelRatio = self->pixelRatio;
    copy->originX  = self->originX;
    copy->originY = self->originY;
    copy->originZ = self->originZ;
    
    memcpy( copy->orientation, self->orientation, sizeof orientation);
    
    copy.frameofReferenceUID = self.frameofReferenceUID;
    
    copy->isRGB = self->isRGB;
    copy->cineRate = self->cineRate;
    copy->savedWL = self->savedWL;
    copy->savedWW = self->savedWW;
    
    copy->echotime = [self->echotime retain];
    copy->flipAngle = [self->flipAngle retain];
    copy->laterality = [self->laterality retain];
    copy->repetitiontime = [self->repetitiontime retain];
    copy->viewPosition = [self->viewPosition retain];
    copy->patientPosition = [self->patientPosition retain];
    copy.annotationsDictionary = self.annotationsDictionary;
    copy.annotationsDBFields = self.annotationsDBFields;
    copy->usRegions = [self->usRegions retain];
    copy->waveform = [self->waveform retain];
    
    copy->patientsWeight = self->patientsWeight;
    copy->SUVConverted = self->SUVConverted;
    copy->factorPET2SUV = self->factorPET2SUV;
    copy->slope = self->slope;
    copy->offset = self->offset;
    
    copy->units = [self->units retain];
    copy->decayCorrection = [self->decayCorrection retain];
    copy->radionuclideTotalDose = self->radionuclideTotalDose;
    copy->radionuclideTotalDoseCorrected = self->radionuclideTotalDoseCorrected;
    copy->acquisitionTime = [self->acquisitionTime retain];
    copy->acquisitionDate = [self->acquisitionDate retain];
    copy->rescaleType = [self->rescaleType retain];
    copy->radiopharmaceuticalStartTime = [self->radiopharmaceuticalStartTime retain];
    copy->displaySUVValue = self->displaySUVValue;
    copy->decayFactor = self->decayFactor;
    copy->halflife = self->halflife;
    copy->philipsFactor = self->philipsFactor;
    
    copy->shutterRect = self->shutterRect;
    copy->shutterEnabled = self->shutterEnabled;
    
    copy->generated = YES;
    
    copy->maxValueOfSeries = self->maxValueOfSeries;
    copy->minValueOfSeries = self->minValueOfSeries;
    copy->isOriginDefined = self->isOriginDefined;
    copy->modalityString = [[NSString stringWithString:self->modalityString] retain];
    
    return copy;
}


- (void) computeTotalDoseCorrected
{
    float timebetween = -[radiopharmaceuticalStartTime timeIntervalSinceDate: acquisitionTime];
    
    if( halflife > 0 && timebetween > 0)
        radionuclideTotalDoseCorrected = radionuclideTotalDose * exp( -timebetween * logf( 2) / halflife);
}

- (void)createROIsFromRTSTRUCT: (DCMObject*)dcmObject
{
    /*
#ifdef OSIRIX_VIEWER
    
    
    NSLog( @"createROIsFromRTSTRUCT");
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject: dcmObject forKey: @"dcmObject"];
    
    NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(createROIsFromRTSTRUCTThread:) object: dict] autorelease];
    
    t.name = NSLocalizedString( @"Converting RTSTRUCT in ROIs...", nil);
    t.supportsCancel = NO;
    t.status = NSLocalizedString( @"Reading...", nil);
    [[ThreadsManager defaultManager] addThreadAndStart: t];
    
#endif
     */
}

- (void)createROIsFromRTSTRUCTThread: (NSDictionary*)dict
{
    /*
#ifdef OSIRIX_VIEWER
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  // Cuz this is run as a detached thread.
    
    DCMObject *dcmObject = [dict objectForKey: @"dcmObject"];
    DicomDatabase *database = BrowserController.currentBrowser.database.independentDatabase;
    
    @try
    {
        // Get all referenced images up front.
        // This is better than running a Fetch Request for EVERY ROI since
        // executeFetchRequest is expensive.
        
        DCMSequenceAttribute *refFrameSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"ReferencedFrameofReferenceSequence"];
        
        if ( refFrameSequence == nil)
            [NSException raise: @"RTStruct" format: @"ReferencedFrameofReferenceSequence not found"];
        
        NSMutableArray *refSeriesUIDPredicates = [NSMutableArray array];
        
        [NSThread currentThread].progress = 0;
        
        for ( DCMObject *refFrameSeqItem in [refFrameSequence sequence])
        {
            DCMSequenceAttribute *refStudySeq = (DCMSequenceAttribute *)[refFrameSeqItem attributeWithName: @"RTReferencedStudySequence"];
            
            for ( DCMObject *refStudySeqItem in refStudySeq.sequence)
            {
                DCMSequenceAttribute *refSeriesSeq = (DCMSequenceAttribute *)[refStudySeqItem attributeWithName: @"RTReferencedSeriesSequence"];
                
                for ( DCMObject *refSeriesSeqItem in refSeriesSeq.sequence)
                {
                    
                    NSString *refSeriesUID = [refSeriesSeqItem attributeValueWithName: @"SeriesInstanceUID"];
                    NSPredicate *pred = [NSPredicate predicateWithFormat: @"series.seriesDICOMUID == %@", refSeriesUID];
                    [refSeriesUIDPredicates addObject: pred];
                    
                     //DCMSequenceAttribute *contourImgSeq = (DCMSequenceAttribute *)[refSeriesSeqItem attributeWithName: @"ContourImageSequence"];
                     //NSEnumerator *contourImgSeqEnum = [[contourImgSeq sequence] objectEnumerator];
                     //DCMObject *contourImgSeqItem;
                     
                     //while ( contourImgSeqItem = [contourImgSeqEnum nextObject]) {
                     //NSString *refImgUID = [contourImgSeqItem attributeValueWithName: @"ReferencedSOPInstanceUID"];
                     //NSPredicate *pred = [NSPredicate predicateWithFormat: @"sopInstanceUID like %@", refImgUID];
                     //[refImgUIDPredicates addObject: pred];
                     //}
                }
            }
        }
        
        [NSThread currentThread].progress = 0.1;
        
        if( refSeriesUIDPredicates.count == 0)
            [NSException raise: @"RTStruct" format: @"No reference series found."];
        
        NSError *error = nil;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: @"Image"];
        request.predicate = [NSCompoundPredicate orPredicateWithSubpredicates: refSeriesUIDPredicates];
        
        NSArray *imgObjects = nil;
        @try
        {
            imgObjects = [database.managedObjectContext executeFetchRequest: request error: &error];
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        
        if ( imgObjects.count == 0)
            [NSException raise: @"RTStruct" format: @"No images in Series"];
        
        // Put all images in a dictionary for quick lookup based on SOP Instance UID
        
        NSMutableDictionary *imgDict = [NSMutableDictionary dictionaryWithCapacity: imgObjects.count];
        NSMutableArray *dcmImgObjects = [NSMutableArray arrayWithCapacity: imgObjects.count];
        
        for ( DicomImage *imgObj in imgObjects)
        {
            [imgDict setObject: imgObj forKey: [imgObj valueForKey: @"sopInstanceUID"]];
            [dcmImgObjects addObject: [DCMObject objectWithContentsOfFile: [imgObj completePath] decodingPixelData: NO]];
        }
        
        DCMSequenceAttribute *roiSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"StructureSetROISequence"];
        
        if ( roiSequence == nil)
            [NSException raise: @"RTStruct" format: @"StructureSetROISequence not found"];
        
        NSMutableDictionary *roiNames = [NSMutableDictionary dictionary];
        
        for ( DCMObject *sequenceItem in [roiSequence sequence])
        {
            [roiNames setValue: [sequenceItem attributeValueWithName: @"ROIName"]
                        forKey: [sequenceItem attributeValueWithName: @"ROINumber"]];
        }
        
        DCMSequenceAttribute *roiContourSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"ROIContourSequence"];
        
        if ( roiContourSequence == nil)
            [NSException raise: @"RTStruct" format: @"ROIContourSequence not found"];
        
        int numStructs = roiContourSequence.sequence.count;
        unsigned int iStruct = 0;
        
        NSMutableArray *roiArray[ imgObjects.count ];  // Array of ROIs for each defined 'image' referenced by the RTSTRUCT
        
        for ( unsigned int i = 0; i < imgObjects.count; i++) roiArray[ i ] = [NSMutableArray array];
        
        for ( DCMObject *sequenceItem in [roiContourSequence sequence])
        {
            
            float
            pixSpacingX,
            pixSpacingY;
            
            NSArray *rgbArray = [sequenceItem attributeArrayWithName: @"ROIDisplayColor"];
            
            RGBColor color =
            {
                [[rgbArray objectAtIndex: 0] floatValue] * 65535 / 256.0,
                [[rgbArray objectAtIndex: 1] floatValue] * 65535 / 256.0,
                [[rgbArray objectAtIndex: 2] floatValue] * 65535 / 256.0 };
            
            NSString *roiName = [roiNames valueForKey: [sequenceItem attributeValueWithName: @"ReferencedROINumber"]];
            
            NSLog( @"roiName = %@", roiName);
            DCMSequenceAttribute *contourSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"ContourSequence"];
            if ( roiContourSequence == nil)
                [NSException raise: @"RTStruct" format: @"contourSequence not found"];
            
            for ( DCMObject *contourItem in [contourSequence sequence])
            {
                
                //				DCMSequenceAttribute *contourImageSequence = (DCMSequenceAttribute*)[contourItem attributeWithName: @"ContourImageSequence"];
                //				if ( contourImageSequence == nil) {
                //					NSLog( @"contourImageSequence not found");
                //					@throw;
                //				}
                
                NSString *contourType = [contourItem attributeValueWithName: @"ContourGeometricType"];
                
                if( [contourType isEqualToString: @"CLOSED_PLANAR"] == NO && [contourType isEqualToString: @"INTERPOLATED_PLANAR"] == NO && [contourType isEqualToString: @"POINT"] == NO)
                {
                    NSLog( @"Contour type %@ is not supported at this time.", contourType);
                    continue;
                }
                
                ToolMode type = tCPolygon;
                
                NSArray *dcmPoints = [contourItem attributeArrayWithName: @"ContourData"];
                
                // Loop over all slices to determine if slice "contains" the ROI based on distance criterion of FIRST point
                // This of course assumes that ALL the points in the contour are in the same slice.
                // Not considering at this time the possibility that the contour intersects multiple slices.
                
                for ( unsigned int imgIndex = 0; imgIndex < imgObjects.count; imgIndex++)
                {
                    DicomImage *img = [imgObjects objectAtIndex: imgIndex];
                    
                    DCMObject *imgObject = [dcmImgObjects objectAtIndex: imgIndex];
                    
                    if ( imgObject == nil)
                        [NSException raise: @"RTStruct" format: @"Error opening referenced image file"];
                    
                    NSArray *pixSpacings = [imgObject attributeArrayWithName: @"PixelSpacing"];
                    NSArray *position = [imgObject attributeArrayWithName: @"ImagePositionPatient"];
                    
                    float posX = [[position objectAtIndex: 0] floatValue];
                    float posY = [[position objectAtIndex: 1] floatValue];
                    float posZ = [[position objectAtIndex: 2] floatValue];
                    
                    pixSpacingX = [[pixSpacings objectAtIndex: 0] floatValue];
                    pixSpacingY = [[pixSpacings objectAtIndex: 1] floatValue];
                    
                    if ( pixSpacingX == 0.0f || pixSpacingY == 0.0f) continue;  // Bad slice?
                    
                    float pixSpacingXrecip = 1.0f / pixSpacingX;
                    float pixSpacingYrecip = 1.0f / pixSpacingY;
                    
                    // Convert ROI points from DICOM space to ROI space
                    
                    NSArray *imageOrientation = [imgObject attributeArrayWithName: @"ImageOrientationPatient"];
                    
                    float orients[ 9 ];
                    
                    for ( unsigned int i = 0; i < 6; i++)
                    {
                        orients[ i ] = [[imageOrientation objectAtIndex: i] floatValue];
                    }
                    
                    // Normal vector
                    orients[6] = orients[1]*orients[5] - orients[2]*orients[4];
                    orients[7] = orients[2]*orients[3] - orients[0]*orients[5];
                    orients[8] = orients[0]*orients[4] - orients[1]*orients[3];
                    
                    float temp[ 3 ];
                    
                    temp[ 0 ] = [[dcmPoints objectAtIndex: 0] floatValue] - posX;
                    temp[ 1 ] = [[dcmPoints objectAtIndex: 1] floatValue] - posY;
                    temp[ 2 ] = [[dcmPoints objectAtIndex: 2] floatValue] - posZ;
                    
                    float distToSlice = fabs( temp[ 0 ] * orients[ 6 ] + temp[ 1 ] * orients[ 7 ] + temp[ 2 ] * orients[ 8 ]);
                    float distCriterion = [[imgObject attributeValueWithName: @"SliceThickness"] floatValue] * 0.4;
                    if ( distCriterion <= 0.0f) distCriterion = 0.1f;  // mm
                    
                    if ( distToSlice < distCriterion)
                    {
                        float sliceCoords[ 2 ];
                        
                        sliceCoords[ 0 ] = temp[ 0 ] * orients[ 0 ] + temp[ 1 ] * orients[ 1 ] + temp[ 2 ] * orients[ 2 ];
                        sliceCoords[ 1 ] = temp[ 0 ] * orients[ 3 ] + temp[ 1 ] * orients[ 4 ] + temp[ 2 ] * orients[ 5 ];
                        sliceCoords[ 0 ] *= pixSpacingXrecip;
                        sliceCoords[ 1 ] *= pixSpacingYrecip;
                        
                        int numPoints = [[contourItem attributeValueWithName: @"NumberofContourPoints"] intValue];
                        NSMutableArray *pointsArray = [NSMutableArray arrayWithCapacity: numPoints];
                        
                        [pointsArray addObject: [MyPoint point:NSMakePoint( sliceCoords[ 0 ], sliceCoords[ 1 ])]];
                        
                        if( numPoints > 1)
                        {
                            // Convert rest of points in contour to sliceCoord space
                            for ( unsigned int pointIndex = 1; pointIndex < numPoints; pointIndex++)
                            {
                                temp[ 0 ] = [[dcmPoints objectAtIndex: 3 * pointIndex] floatValue] - posX;
                                temp[ 1 ] = [[dcmPoints objectAtIndex: 3 * pointIndex + 1] floatValue] - posY;
                                temp[ 2 ] = [[dcmPoints objectAtIndex: 3 * pointIndex + 2] floatValue] - posZ;
                                
                                sliceCoords[ 0 ] = temp[ 0 ] * orients[ 0 ] + temp[ 1 ] * orients[ 1 ] + temp[ 2 ] * orients[ 2 ];
                                sliceCoords[ 1 ] = temp[ 0 ] * orients[ 3 ] + temp[ 1 ] * orients[ 4 ] + temp[ 2 ] * orients[ 5 ];
                                sliceCoords[ 0 ] *= pixSpacingXrecip;
                                sliceCoords[ 1 ] *= pixSpacingYrecip;
                                [pointsArray addObject: [MyPoint point:NSMakePoint( sliceCoords[ 0 ], sliceCoords[ 1 ])]];
                            }
                        }
                        else
                            type = t2DPoint;
                        
                        ROI *roi = [[[ROI alloc] initWithType: type
                                                             : pixSpacingX
                                                             : pixSpacingY
                                                             : NSMakePoint( posX, posY)] autorelease];
                        
                        roi.name = roiName;
                        roi.rgbcolor = color;
                        
                        if( type == t2DPoint)
                            roi.ROIRect = NSMakeRect( [pointsArray.lastObject x], [pointsArray.lastObject y], 1, 1);
                        else
                            roi.points = pointsArray;
                        roi.opacity = 1.0;
                        roi.thickness = 1.0;
                        roi.isSpline = NO;
                        
                        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"RSTRUCTConvertToBrush"])
                        {
                            ROI *theNewROI = nil;
                            
                            if( roi.type == tOval)
                            {
                                NSMutableArray *points = roi.points;
                                if( roi.type == tROI)
                                    roi.isSpline = NO;
                                
                                roi.type = tCPolygon;
                                roi.points = points;
                            }
                            
                            if( roi.type == tCPolygon || roi.type == tOPolygon || roi.type == tPencil)
                            {
                                NSSize s;
                                NSPoint o;
                                unsigned char* texture = [DCMPix getMapFromPolygonROI: roi size: &s origin: &o];
                                
                                if( texture)
                                {
                                    theNewROI = [[ROI alloc]		initWithTexture: texture
                                                                    textWidth: s.width
                                                                   textHeight: s.height
                                                                     textName: roi.name
                                                                    positionX: o.x
                                                                    positionY: o.y
                                                                     spacingX: pixSpacingX
                                                                     spacingY: pixSpacingY
                                                                  imageOrigin: NSMakePoint( posX, posY)];
                                    if( [theNewROI reduceTextureIfPossible] == NO)	// NO means that the ROI is NOT empty
                                    {
                                        theNewROI.rgbcolor = roi.rgbcolor;
                                        theNewROI.opacity = 0.5;
                                    }
                                    else
                                    {
                                        [theNewROI release];
                                        theNewROI = nil;
                                    }
                                    
                                    free( texture);
                                }
                            }
                            
                            if( theNewROI)
                                roi = [theNewROI autorelease];
                        }
                        
                        [roiArray[[imgObjects indexOfObject: img]] addObject: roi];
                    }
                    
                } // End loop over images in series (looking for containing slices)
                
            } // Loop over ContourSequence
            
            iStruct++;
            
            float percentComplete = ( iStruct / (float)numStructs) * 90.0f + 10.0f;
            
            [NSThread currentThread].progress = percentComplete / 100.;
            
        }  // Loop over ROIContourSequence
        
        // Write ROIs to disk and update DB
        
        NSMutableArray	*newDICOMSR = [NSMutableArray array];
        
        for( unsigned int i = 0; i < imgObjects.count; i++)
        {
            if( roiArray[i].count == 0) continue;  // Nothing to see, move on.
            
            DicomImage *img = [imgObjects objectAtIndex: i];
            
            NSString *str = [img.series.study roiPathForImage: img inArray: nil];
            
            if (str == nil)
                str = [database uniquePathForNewDataFileWithExtension:@"dcm"];
            else
            {
                // Get any pre-existing ROIs and add them to the roiArray
                NSData *data = [SRAnnotation roiFromDICOM: str];
                if( data)
                {
                    NSMutableArray *array = [NSUnarchiver unarchiveObjectWithData: data];
                    if( array)
                        [roiArray[ i] addObjectsFromArray: array];
                }
            }
            
            // Write out the concatenated roiArray
            
            [SRAnnotation archiveROIsAsDICOM: roiArray[ i ] toPath: str forImage: img];
            [newDICOMSR addObject: str];
        }
        
        if( newDICOMSR.count)
            [database addFilesAtPaths: newDICOMSR postNotifications:YES dicomOnly:YES rereadExistingItems:YES generatedByOsiriX:YES];
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
    [pool release];
#endif
*/
} // end createROIsFromRTSTRUCT


- (void) setVOILUT:(int) first
            number:(unsigned int) number
             depth:(unsigned int) depth
             table:(unsigned int *) table
             image:(unsigned short*) src
          isSigned:(BOOL) isSigned
{
    int i, index;
    BOOL atLeastOnePixel = NO;
    
    if( isSigned)
    {
        short *signedSrc = (short*) src;
        
        i = (int)(width * height);
        while( i-- > 0)
        {
            index = signedSrc[ i] - first;
            if( index <= 0) index = 0;
            else if( index >= number) index = number -1;
            else atLeastOnePixel = YES;
            
            src[ i] = table[ index];
        }
    }
    else
    {
        i = (int)(width * height);
        while( i-- > 0)
        {
            index = src[ i] - first;
            if( index <= 0) index = 0;
            else if( index >= number) index = number -1;
            else atLeastOnePixel = YES;
            
            src[ i] = table[ index];
        }
    }
    
    if( atLeastOnePixel == NO)
    {
        gUseVOILUT = NO;
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"UseVOILUT"];
        NSLog( @"***** VOI LUT seems corrupted ! -> It will be turned OFF");
    }
    else
        VOILUTApplied = YES;
}

#pragma mark-

- (void) reloadAnnotations
{
#ifdef OSIRIX_VIEWER
    [PapyrusLock lock];
    [annotationsDictionary removeAllObjects];
    [PapyrusLock unlock];
#endif
}

- (void) dcmFrameworkLoad0x0018: (DCMObject*) dcmObject
{
    if( [dcmObject attributeValueWithName:@"PatientsWeight"]) patientsWeight = [[dcmObject attributeValueWithName:@"PatientsWeight"] floatValue];
    
    if( [dcmObject attributeValueWithName:@"SliceThickness"]) sliceThickness = [[dcmObject attributeValueWithName:@"SliceThickness"] doubleValue];
    if( [dcmObject attributeValueWithName:@"SpacingBetweenSlices"]) spacingBetweenSlices = [[dcmObject attributeValueWithName:@"SpacingBetweenSlices"] doubleValue];
    if( [dcmObject attributeValueWithName:@"RepetitionTime"])
    {
        [repetitiontime release];
        repetitiontime = [[dcmObject attributeValueWithName:@"RepetitionTime"] retain];
    }
    if( [dcmObject attributeValueWithName:@"EchoTime"])
    {
        [echotime release];
        echotime = [[dcmObject attributeValueWithName:@"EchoTime"] retain];
    }
    if( [dcmObject attributeValueWithName:@"FlipAngle"])
    {
        [flipAngle release];
        flipAngle = [[dcmObject attributeValueWithName:@"FlipAngle"] retain];
    }
    if( [dcmObject attributeValueWithName:@"ViewPosition"])
    {
        [viewPosition release];
        viewPosition = [[dcmObject attributeValueWithName:@"ViewPosition"] retain];
    }
    if( [dcmObject attributeValueWithName:@"PositionerPrimaryAngle"])
    {
        [positionerPrimaryAngle release];
        positionerPrimaryAngle = [[dcmObject attributeValueWithName:@"PositionerPrimaryAngle"] retain];
    }
    if( [dcmObject attributeValueWithName:@"PositionerSecondaryAngle"])
    {
        [positionerSecondaryAngle release];
        positionerSecondaryAngle = [[dcmObject attributeValueWithName:@"PositionerSecondaryAngle"] retain];
    }
    if( [dcmObject attributeValueWithName:@"EstimatedRadiographicMagnificationFactor"])
        estimatedRadiographicMagnificationFactor = [[dcmObject attributeValueWithName:@"EstimatedRadiographicMagnificationFactor"] doubleValue];
    if( [dcmObject attributeValueWithName:@"PatientPosition"])
    {
        [patientPosition release];
        patientPosition = [[dcmObject attributeValueWithName:@"PatientPosition"] retain];
    }
    if( [dcmObject attributeValueWithName:@"RecommendedDisplayFrameRate"]) cineRate = [[dcmObject attributeValueWithName:@"RecommendedDisplayFrameRate"] floatValue];
    if( !cineRate && [dcmObject attributeValueWithName:@"CineRate"]) cineRate = [[dcmObject attributeValueWithName:@"CineRate"] floatValue];
    if (!cineRate && [dcmObject attributeValueWithName:@"FrameDelay"])
    {
        if( [[dcmObject attributeValueWithName:@"FrameDelay"] floatValue] > 0)
            cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameDelay"] floatValue];
    }
    if (!cineRate && [dcmObject attributeValueWithName:@"FrameTime"])
    {
        if( [[dcmObject attributeValueWithName:@"FrameTime"] floatValue] > 0)
            cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameTime"] floatValue];
    }
    if (!cineRate && [dcmObject attributeValueWithName:@"FrameTimeVector"])
    {
        if( [[dcmObject attributeValueWithName:@"FrameTimeVector"] floatValue] > 0)
            cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameTimeVector"] floatValue];
    }
    
    if ( gUseShutter)
    {
        if( [dcmObject attributeValueWithName:@"ShutterShape"])
        {
            NSArray *shutterArray = [dcmObject attributeArrayWithName:@"ShutterShape"];
            
            for( NSString *shutter in shutterArray)
            {
                if ( [shutter isEqualToString:@"RECTANGULAR"])
                {
                    shutterEnabled = YES;
                    
                    shutterRect.origin.x = [[dcmObject attributeValueWithName:@"ShutterLeftVerticalEdge"] floatValue];
                    shutterRect.size.width = [[dcmObject attributeValueWithName:@"ShutterRightVerticalEdge"] floatValue] - shutterRect.origin.x;
                    shutterRect.origin.y = [[dcmObject attributeValueWithName:@"ShutterUpperHorizontalEdge"] floatValue];
                    shutterRect.size.height = [[dcmObject attributeValueWithName:@"ShutterLowerHorizontalEdge"] floatValue] - shutterRect.origin.y;
                }
                else if( [shutter isEqualToString:@"CIRCULAR"])
                {
                    shutterEnabled = YES;
                    
                    NSArray *centerArray = [dcmObject attributeArrayWithName:@"CenterofCircularShutter"];
                    
                    if( centerArray.count == 2)
                    {
                        shutterCircular.x = [[centerArray objectAtIndex:0] intValue];
                        shutterCircular.y = [[centerArray objectAtIndex:1] intValue];
                    }
                    
                    shutterCircular_radius = [[dcmObject attributeValueWithName:@"RadiusofCircularShutter"] floatValue];
                }
                else if( [shutter isEqualToString:@"POLYGONAL"])
                {
                    shutterEnabled = YES;
                    
                    NSArray *locArray = [dcmObject attributeArrayWithName:@"VerticesofthePolygonalShutter"];
                    
                    if( shutterPolygonal) free( shutterPolygonal);
                    
                    shutterPolygonalSize = 0;
                    shutterPolygonal = malloc( [locArray count] * sizeof( NSPoint) / 2);
                    for( unsigned int i = 0, x = 0; i < [locArray count]; i+=2, x++)
                    {
                        shutterPolygonal[ x].x = [[locArray objectAtIndex: i] intValue];
                        shutterPolygonal[ x].y = [[locArray objectAtIndex: i+1] intValue];
                        shutterPolygonalSize++;
                    }
                }
                else NSLog( @"Shutter not supported: %@", shutter);
            }
        }
    }
}

- (void) dcmFrameworkLoad0x0020: (DCMObject*) dcmObject
{
    //orientation
    
    NSArray *ipp = [dcmObject attributeArrayWithName:@"ImagePositionPatient"];
    if( ipp && [ipp count] >= 3)
    {
        originX = [[ipp objectAtIndex:0] doubleValue];
        originY = [[ipp objectAtIndex:1] doubleValue];
        originZ = [[ipp objectAtIndex:2] doubleValue];
        isOriginDefined = YES;
    }
    else
    {
        NSArray *ipv = [dcmObject attributeArrayWithName:@"ImagePositionVolume"];
        if( ipv)
        {
            originX = [[ipv objectAtIndex:0] doubleValue];
            originY = [[ipv objectAtIndex:1] doubleValue];
            originZ = [[ipv objectAtIndex:2] doubleValue];
            isOriginDefined = YES;
        }
    }
    
    
    NSArray *iop = [dcmObject attributeArrayWithName:@"ImageOrientationPatient"];
    if( iop)
    {
        for ( int j = 0; j < iop.count; j++)
            orientation[ j ] = [[iop objectAtIndex:j] doubleValue];
    }
    else
    {
        NSArray *iov = [dcmObject attributeArrayWithName:@"ImageOrientationVolume"];
        if( iov)
        {
            for ( int j = 0; j < iov.count; j++)
                orientation[ j ] = [[iov objectAtIndex:j] doubleValue];
        }
    }
    
    if( [dcmObject attributeValueWithName:@"ImageLaterality"])
    {
        [laterality release];
        laterality = [[dcmObject attributeValueWithName:@"ImageLaterality"] retain];
    }
    if( laterality == nil)
    {
        [laterality release];
        laterality = [[dcmObject attributeValueWithName:@"Laterality"] retain];
    }
    
    self.frameofReferenceUID = [dcmObject attributeValueWithName: @"FrameofReferenceUID"];
}

- (void) dcmFrameworkLoad0x0028: (DCMObject*) dcmObject
{
    // Group 0x0028
    
    if( [dcmObject attributeValueWithName:@"PixelRepresentation"]) fIsSigned = [[dcmObject attributeValueWithName:@"PixelRepresentation"] intValue];
    if( [dcmObject attributeValueWithName:@"BitsAllocated"]) bitsAllocated = [[dcmObject attributeValueWithName:@"BitsAllocated"] intValue];
    
    short __bitsStored = [[dcmObject attributeValueWithName:@"BitsStored"] intValue];
    
    if (__bitsStored != 0 && self->numberOfFrames > 1)
    {
        self->bitsStored = __bitsStored;
    }
    else if (self->numberOfFrames <= 1)
    {
        self->bitsStored = __bitsStored;
    }
        
    if( bitsStored == 8 && bitsAllocated == 16 && [[dcmObject attributeValueWithName:@"PhotometricInterpretation"] isEqualToString:@"RGB"])
        bitsAllocated = 8;
    
    if ([dcmObject attributeValueWithName:@"RescaleIntercept"]) offset = [[dcmObject attributeValueWithName:@"RescaleIntercept"] floatValue];
    if ([dcmObject attributeValueWithName:@"RescaleSlope"])
    {
        slope = [[dcmObject attributeValueWithName:@"RescaleSlope"] floatValue];
        if( slope == 0) slope = 1.0;
    }
    
    // image size
    if( [dcmObject attributeValueWithName:@"Rows"])
    {
        height = [[dcmObject attributeValueWithName:@"Rows"] intValue];
    }
    
    if( [dcmObject attributeValueWithName:@"Columns"])
    {
        width =  [[dcmObject attributeValueWithName:@"Columns"] intValue];
    }

    /*
#ifdef OSIRIX_VIEWER
    NSManagedObjectContext *iContext = nil;
    
    if( savedHeightInDB != 0 && savedHeightInDB != height)
    {
        if( savedHeightInDB != OsirixDicomImageSizeUnknown)
            NSLog( @"******* [[imageObj valueForKey:@'height'] intValue] != height - %d versus %d", (int)savedHeightInDB, (int)height);
        
        if( iContext == nil)
            iContext = ([[NSThread currentThread] isMainThread] ? [[[BrowserController currentBrowser] database] managedObjectContext] : [[[BrowserController currentBrowser] database] independentContext]);
        
        [[iContext existingObjectWithID: imageObjectID error: nil] setValue: [NSNumber numberWithInt: height] forKey: @"height"];
        
        if( height > savedHeightInDB && fExternalOwnedImage)
            height = savedHeightInDB;
    }
    
    if( savedWidthInDB != 0 && savedWidthInDB != width)
    {
        if( savedWidthInDB != OsirixDicomImageSizeUnknown)
            NSLog( @"******* [[imageObj valueForKey:@'width'] intValue] != width - %d versus %d", (int)savedWidthInDB, (int)width);
        
        if( iContext == nil)
            iContext = ([[NSThread currentThread] isMainThread] ? [[[BrowserController currentBrowser] database] managedObjectContext] : [[[BrowserController currentBrowser] database] independentContext]);
        
        [[iContext existingObjectWithID: imageObjectID error: nil] setValue: [NSNumber numberWithInt: width] forKey: @"width"];
        
        if( width > savedWidthInDB && fExternalOwnedImage)
            width = savedWidthInDB;
    }
    [iContext save: nil];
#endif
    */
    if( shutterRect.size.width == 0) shutterRect.size.width = width;
    if( shutterRect.size.height == 0) shutterRect.size.height = height;
    
    //window level & width
    if ([dcmObject attributeValueWithName:@"WindowCenter"] && isRGB == NO) savedWL = (float)[[dcmObject attributeValueWithName:@"WindowCenter"] floatValue];
    if ([dcmObject attributeValueWithName:@"WindowWidth"] && isRGB == NO) savedWW =  (float) [[dcmObject attributeValueWithName:@"WindowWidth"] floatValue];
    if(  savedWW < 0) savedWW =-savedWW;
    
    if( [[dcmObject attributeValueWithName:@"RescaleType"] isEqualToString: @"US"] == NO)
    {
        self.rescaleType = [dcmObject attributeValueWithName:@"RescaleType"];
        if (self.rescaleType == nil)
            self.rescaleType = @"";
        
        if( [self.rescaleType.lowercaseString isEqualToString: @"houndsfield unit"])
            self.rescaleType = @"HU";
    }
    //planar configuration
    if( [dcmObject attributeValueWithName:@"PlanarConfiguration"])
        fPlanarConf = [[dcmObject attributeValueWithName:@"PlanarConfiguration"] intValue];
    
    //pixel Spacing
    if( pixelSpacingFromUltrasoundRegions == NO)
    {
        NSArray *pixelSpacing = [dcmObject attributeArrayWithName:@"PixelSpacing"];
        if(pixelSpacing.count >= 2)
        {
            pixelSpacingY = [[pixelSpacing objectAtIndex:0] doubleValue];
            pixelSpacingX = [[pixelSpacing objectAtIndex:1] doubleValue];
        }
        else if(pixelSpacing.count >= 1)
        {
            pixelSpacingY = [[pixelSpacing objectAtIndex:0] doubleValue];
            pixelSpacingX = [[pixelSpacing objectAtIndex:0] doubleValue];
        }
        else
        {
            NSArray *pixelSpacing = [dcmObject attributeArrayWithName:@"ImagerPixelSpacing"];
            if(pixelSpacing.count >= 2)
            {
                pixelSpacingY = [[pixelSpacing objectAtIndex:0] doubleValue];
                pixelSpacingX = [[pixelSpacing objectAtIndex:1] doubleValue];
            }
            else if(pixelSpacing.count >= 1)
            {
                pixelSpacingY = [[pixelSpacing objectAtIndex:0] doubleValue];
                pixelSpacingX = [[pixelSpacing objectAtIndex:0] doubleValue];
            }
        }
    }
    
    DCMSequenceAttribute* seq = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"SequenceofUltrasoundRegions"];
    
    if (seq)
    {
        // US Regions		BOOL spacingFound = NO;
        [usRegions release];
        usRegions = [[NSMutableArray array] retain];
        
#ifdef OSIRIX_VIEWER
        for ( DCMObject *sequenceItem in seq.sequence)
        {
            /* US Regions --->
             if( spacingFound == NO)
             {
             int physicalUnitsX = 0;
             int physicalUnitsY = 0;
             int spatialFormat = 0;
             
             physicalUnitsX = [[sequenceItem attributeValueWithName:@"PhysicalUnitsXDirection"] intValue];
             physicalUnitsY = [[sequenceItem attributeValueWithName:@"PhysicalUnitsYDirection"] intValue];
             spatialFormat = [[sequenceItem attributeValueWithName:@"RegionSpatialFormat"] intValue];
             
             if( physicalUnitsX == 3 && physicalUnitsY == 3 && spatialFormat == 1)	// We want only cm !
             {
             double xxx = 0, yyy = 0;
             
             xxx = [[sequenceItem attributeValueWithName:@"PhysicalDeltaX"] doubleValue];
             yyy = [[sequenceItem attributeValueWithName:@"PhysicalDeltaY"] doubleValue];
             
             if( xxx && yyy)
             {
             pixelSpacingX = fabs( xxx) * 10.;	// These are in cm !
             pixelSpacingY = fabs( yyy) * 10.;
             spacingFound = YES;
             
             pixelSpacingFromUltrasoundRegions = YES;
             }
             }
             }
             <--- US Regions */
            // US Regions --->
            
            // Read US Region Calibration Attributes
            DCMUSRegion *usRegion = [[[DCMUSRegion alloc] init] autorelease];
            
            [usRegion setRegionSpatialFormat:[[sequenceItem attributeValueWithName:@"RegionSpatialFormat"] intValue]];
            [usRegion setRegionDataType: [[sequenceItem attributeValueWithName:@"RegionDataType"] intValue]];
            [usRegion setRegionFlags: [[sequenceItem attributeValueWithName:@"RegionFlags"] intValue]];
            [usRegion setRegionLocationMinX0: [[sequenceItem attributeValueWithName:@"RegionLocationMinX0"] intValue]];
            [usRegion setRegionLocationMinY0: [[sequenceItem attributeValueWithName:@"RegionLocationMinY0"] intValue]];
            [usRegion setRegionLocationMaxX1: [[sequenceItem attributeValueWithName:@"RegionLocationMaxX1"] intValue]];
            [usRegion setRegionLocationMaxY1: [[sequenceItem attributeValueWithName:@"RegionLocationMaxY1"] intValue]];
            [usRegion setReferencePixelX0: [[sequenceItem attributeValueWithName:@"ReferencePixelX0"] intValue]];
            [usRegion setIsReferencePixelX0Present:([sequenceItem attributeValueWithName:@"ReferencePixelX0"] != nil)];
            [usRegion setReferencePixelY0: [[sequenceItem attributeValueWithName:@"ReferencePixelY0"] intValue]];
            [usRegion setIsReferencePixelY0Present:([sequenceItem attributeValueWithName:@"ReferencePixelY0"] != nil)];
            [usRegion setPhysicalUnitsXDirection: [[sequenceItem attributeValueWithName:@"PhysicalUnitsXDirection"] intValue]];
            [usRegion setPhysicalUnitsYDirection: [[sequenceItem attributeValueWithName:@"PhysicalUnitsYDirection"] intValue]];
            [usRegion setRefPixelPhysicalValueX: [[sequenceItem attributeValueWithName:@"ReferencePixelPhysicalValueX"] doubleValue]];
            [usRegion setRefPixelPhysicalValueY: [[sequenceItem attributeValueWithName:@"ReferencePixelPhysicalValueY"] doubleValue]];
            [usRegion setPhysicalDeltaX: [[sequenceItem attributeValueWithName:@"PhysicalDeltaX"] doubleValue]];
            [usRegion setPhysicalDeltaY: [[sequenceItem attributeValueWithName:@"PhysicalDeltaY"] doubleValue]];
            [usRegion setDopplerCorrectionAngle: [[sequenceItem attributeValueWithName:@"DopplerCorrectionAngle"] doubleValue]];
            
            if ([usRegion physicalUnitsXDirection] == 3 && [usRegion physicalUnitsYDirection] == 3 && [usRegion regionSpatialFormat] == 1) {
                // We want only cm, for 2D images
                if ([usRegion physicalDeltaX] && [usRegion physicalDeltaY])
                {
                    pixelSpacingX = fabs([usRegion physicalDeltaX]) * 10.;	// These are in cm !
                    pixelSpacingY = fabs([usRegion physicalDeltaY]) * 10.;
                    pixelSpacingFromUltrasoundRegions = YES;
                }
            }
            
            // Adds current US Region Calibration Attributes to usRegions collection
            [usRegions addObject:usRegion];
            
            //NSLog (@"dcmFrameworkLoad0x0028 - US REGION is [%@]", [usRegion toString]);
            // <--- US Regions
        }
#endif
    }
    
    //PixelAspectRatio
    if( pixelSpacingFromUltrasoundRegions == NO)
    {
        NSArray *par = [dcmObject attributeArrayWithName:@"PixelAspectRatio"];
        if ( par.count >= 2)
        {
            double ratiox = 1, ratioy = 1;
            ratiox = [[par objectAtIndex:0] doubleValue];
            ratioy = [[par objectAtIndex:1] doubleValue];
            
            if( ratioy != 0)
            {
                pixelRatio = ratiox / ratioy;
            }
        }
        else if( pixelSpacingX != pixelSpacingY)
        {
            if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
        }
    }
    
    //PhotoInterpret
    if ([[dcmObject attributeValueWithName:@"PhotometricInterpretation"] rangeOfString:@"PALETTE"].location != NSNotFound)
    {
        // palette conversions done by dcm Object
        isRGB = YES;
    }
}

- (void) dcmFrameworkLoadOphthalmic: (DCMObject*) dcmObject
{
    if( [dcmObject attributeValueWithName:@"ReferencedSOPInstanceUID"])
        self.referencedSOPInstanceUID = [dcmObject attributeValueWithName:@"ReferencedSOPInstanceUID"];
    
    if( [dcmObject attributeValueWithName:@"ReferenceCoordinates"])
    {
        NSArray *coor = [dcmObject attributeValueWithName:@"ReferenceCoordinates"];
        
        if ( coor.count >= 4)
        {
            referenceCoordinates[ 0] = [[coor objectAtIndex: 0] floatValue];
            referenceCoordinates[ 1] = [[coor objectAtIndex: 1] floatValue];
            
            referenceCoordinates[ 2] = [[coor objectAtIndex: 2] floatValue];
            referenceCoordinates[ 3] = [[coor objectAtIndex: 3] floatValue];
        }
    }
}

- (BOOL)loadDICOMDCMFramework
{
    // Memory test: DCMFramework requires a lot of memory...
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.srcFile error:NULL] fileSize];
    fileSize *= 1.5;
    
    void *memoryTest = malloc( fileSize);
    if( memoryTest == nil)
    {
        NSLog( @"------ loadDICOMDCMFramework memory test failed -> return");
        return NO;
    }
    free( memoryTest);
    
    /////////////////////////
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL returnValue = YES;
    DCMObject *dcmObject = 0L;
    
    if( purgeCacheLock == nil)
        purgeCacheLock = [[NSConditionLock alloc] initWithCondition: 0];
    
    [purgeCacheLock lock];
    [purgeCacheLock unlockWithCondition: [purgeCacheLock condition]+1];
    
    [PapyrusLock lock];
    
    @try
    {
        if( [cachedDCMFrameworkFiles objectForKey:self.srcFile])
        {
            NSMutableDictionary *dic = [cachedDCMFrameworkFiles objectForKey:self.srcFile];
            
            dcmObject = [dic objectForKey: @"dcmObject"];
            
            if( retainedCacheGroup != nil)
                NSLog( @"******** DCMPix : retainedCacheGroup 3 != nil ! %@", self.srcFile);
            
            [dic setValue: [NSNumber numberWithInt: [[dic objectForKey: @"count"] intValue]+1] forKey: @"count"];
            retainedCacheGroup = dic;
        }
        else
        {
            dcmObject = [DCMObject objectWithContentsOfFile:self.srcFile decodingPixelData:NO];
            
            if( dcmObject)
            {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                
                [dic setValue: dcmObject forKey: @"dcmObject"];
                if( retainedCacheGroup != nil)
                    NSLog( @"******** DCMPix : retainedCacheGroup 4 != nil ! %@", self.srcFile);
                
                [dic setValue: [NSNumber numberWithInt: 1] forKey: @"count"];
                retainedCacheGroup = dic;
                
                [cachedDCMFrameworkFiles setObject:dic forKey:self.srcFile];
            }
        }
    }
    @catch (NSException *e)
    {
        NSLog( @"******** loadDICOMDCMFramework exception : %@", e);
        dcmObject = nil;
    }
    
    [PapyrusLock unlock];
    
    if(dcmObject == nil)
    {
        NSLog( @"******** loadDICOMDCMFramework - no DCMObject at srcFile address, nothing to do");
        [purgeCacheLock lock];
        [purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
        [pool release];
        return NO;
    }
    
    self.SOPClassUID = [dcmObject attributeValueWithName:@"SOPClassUID"];
    self.referencedSOPInstanceUID = [dcmObject attributeValueWithName:@"ReferencedSOPInstanceUID"];
    //-----------------------common----------------------------------------------------------
    
    self.imageType = [[dcmObject attributeArrayWithName:@"ImageType"] componentsJoinedByString:@"\\"];
    
    short maxFrame = 1;
    short imageNb = frameNo;
    
#pragma mark *pdf
    if ([SOPClassUID isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]])
    {
        NSData *pdfData = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
        
        NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData: pdfData];
        [rep setCurrentPage: frameNo];
        
        NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
        [pdfImage addRepresentation: rep];
        
        [self getDataFromNSImage: pdfImage];
        
        
        [purgeCacheLock lock];
        [purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
        [pool release];
        return YES;
    } // end encapsulatedPDF
    else if ([SOPClassUID isEqualToString:[DCMAbstractSyntaxUID cdaStorageClassUID]])
    {
        
        [purgeCacheLock lock];
        [purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
        [pool release];
        return YES;
    }
    else if( [SOPClassUID hasPrefix: @"1.2.840.10008.5.1.4.1.1.88"]) // DICOM SR
    {
        [self getDataFromNSImage: [NSImage imageNamed: @"NSIconViewTemplate"]];
    }
    else if ( [DCMAbstractSyntaxUID isNonImageStorage: SOPClassUID])
    {
        if( fExternalOwnedImage)
            fImage = fExternalOwnedImage;
        else
            fImage = malloc( 128 * 128 * 4);
        
        height = 128;
        width = 128;
        isRGB = NO;
        
        for( int i = 0; i < 128*128; i++)
            fImage[ i ] = i%2;
        
        [purgeCacheLock lock];
        [purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
        [pool release];
        return YES;
    }
    
    @try
    {
        pixelSpacingX = 0;
        pixelSpacingY = 0;
        estimatedRadiographicMagnificationFactor = 0;
        offset = 0.0;
        slope = 1.0;
        
        originX = 0;	originY = 0;	originZ = 0;
        orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
        orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
        
        [self dcmFrameworkLoad0x0018: dcmObject];
        [self dcmFrameworkLoad0x0020: dcmObject];
        [self dcmFrameworkLoad0x0028: dcmObject];
        
#pragma mark *MR/CT/US functional multiframe
        
        // Is it a new MR/CT/US multi-frame exam?
        DCMSequenceAttribute *sharedFunctionalGroupsSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"SharedFunctionalGroupsSequence"];
        if (sharedFunctionalGroupsSequence)
        {
            for ( DCMObject *sequenceItem in sharedFunctionalGroupsSequence.sequence)
            {
                DCMSequenceAttribute *MRTimingAndRelatedParametersSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"MRTimingAndRelatedParametersSequence"];
                DCMObject *MRTimingAndRelatedParametersObject = [[MRTimingAndRelatedParametersSequence sequence] objectAtIndex:0];
                if( MRTimingAndRelatedParametersObject)
                    [self dcmFrameworkLoad0x0020: MRTimingAndRelatedParametersObject];
                
                DCMSequenceAttribute *planeOrientationSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PlaneOrientationSequence"];
                DCMObject *planeOrientationObject = [[planeOrientationSequence sequence] objectAtIndex:0];
                if( planeOrientationObject)
                    [self dcmFrameworkLoad0x0020: planeOrientationObject];
                
                DCMSequenceAttribute *planePositionSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PlanePositionVolumeSequence"];
                DCMObject *planePositionObject = [[planePositionSequence sequence] objectAtIndex:0];
                if( planePositionObject)
                    [self dcmFrameworkLoad0x0020: planePositionObject];
                
                DCMSequenceAttribute *pixelMeasureSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PixelMeasuresSequence"];
                DCMObject *pixelMeasureObject = [[pixelMeasureSequence sequence] objectAtIndex:0];
                //  This sequence has only one item, comprising SliceThickness and PixelSpacing (DICOM spec 2015a)
                if(pixelMeasureObject)
                {
                    //It seems @brizolara didn't solve this entirely - restoring original behavior for non multi-frame datasets and adding working around for multi-frame
                    if( numberOfFrames <= 1)
                    {
                        [self dcmFrameworkLoad0x0018: pixelMeasureObject];
                        [self dcmFrameworkLoad0x0028: pixelMeasureObject];
                    }
                    else
                    {
                        [self dcmFrameworkLoad0x0018: pixelMeasureObject];
                        [self dcmFrameworkLoad0x0028: pixelMeasureObject];
                        
                        if( [pixelMeasureObject attributeValueWithName:@"SliceThickness"])
                            sliceThickness = [[pixelMeasureObject attributeValueWithName:@"SliceThickness"] doubleValue];
                        if( [pixelMeasureObject attributeArrayWithName:@"PixelSpacing"])
                        {
                            NSArray *pixelSpacing = [pixelMeasureObject attributeArrayWithName:@"PixelSpacing"];
                            if(pixelSpacing.count >= 2)
                            {
                                pixelSpacingY = [[pixelSpacing objectAtIndex:0] doubleValue];
                                pixelSpacingX = [[pixelSpacing objectAtIndex:1] doubleValue];
                            }
                            else if(pixelSpacing.count == 1)
                            {
                                pixelSpacingY = [[pixelSpacing objectAtIndex:0] doubleValue];
                                pixelSpacingX = [[pixelSpacing objectAtIndex:0] doubleValue];
                            }
                        }
                    }
                }
                
                DCMSequenceAttribute *pixelTransformationSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PixelValueTransformationSequence"];
                DCMObject *pixelTransformationSequenceObject = [[pixelTransformationSequence sequence] objectAtIndex:0];
                //  This sequence has only one item, comprising RescaleIntercept/Slope/Type (DICOM spec 2015a)
                if( pixelTransformationSequenceObject)
                {
                    //It seems @brizolara didn't solve this entirely - restoring original behavior for non multi-frame datasets and adding working around for multi-frame
                    if( numberOfFrames <= 1)
                    {
                        [self dcmFrameworkLoad0x0028: pixelTransformationSequenceObject];
                    }
                    else
                    {
                        [self dcmFrameworkLoad0x0028: pixelTransformationSequenceObject];
                        
                        if ([pixelTransformationSequenceObject attributeValueWithName:@"RescaleIntercept"])
                            offset = [[pixelTransformationSequenceObject attributeValueWithName:@"RescaleIntercept"] floatValue];
                        if ([pixelTransformationSequenceObject attributeValueWithName:@"RescaleSlope"])
                        {
                            slope = [[pixelTransformationSequenceObject attributeValueWithName:@"RescaleSlope"] floatValue];
                            if( slope == 0) slope = 1.0;
                        }
                        
                        if( [[pixelTransformationSequenceObject attributeValueWithName:@"RescaleType"] isEqualToString: @"US"] == NO)
                        {
                            self.rescaleType = [pixelTransformationSequenceObject attributeValueWithName:@"RescaleType"];
                            if (self.rescaleType == nil)
                                self.rescaleType = @"";
                            
                            if( [self.rescaleType.lowercaseString isEqualToString: @"houndsfield unit"])
                                self.rescaleType = @"HU";
                        };
                    }
                }
            }
        }
        
        
#pragma mark *per frame
        
        // ****** ****** ****** ************************************************************************
        // PER FRAME
        // ****** ****** ****** ************************************************************************
        
        //long frameCount = 0;
        DCMSequenceAttribute *perFrameFunctionalGroupsSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"Per-frameFunctionalGroupsSequence"];
        
        //NSLog(@"perFrameFunctionalGroupsSequence: %@", [perFrameFunctionalGroupsSequence description]);
        if( perFrameFunctionalGroupsSequence)
        {
            if( perFrameFunctionalGroupsSequence.sequence.count > imageNb && imageNb >= 0)
            {
                DCMObject *sequenceItem = [[perFrameFunctionalGroupsSequence sequence] objectAtIndex:imageNb];
                if( sequenceItem)
                {
                    DCMSequenceAttribute* seq;
                    DCMObject* object;
                    
                    if ((seq = (DCMSequenceAttribute*)[sequenceItem attributeWithName:@"ImageType"]) && [seq isKindOfClass:[DCMSequenceAttribute class]])
                    {
                        self.imageType = [[seq sequence] componentsJoinedByString:@"\\"];
                    }
                    
                    if ((seq = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"MREchoSequence"]) && [seq isKindOfClass:[DCMSequenceAttribute class]])
                    {
                        if ((object = [[seq sequence] objectAtIndex:0]))
                            [self dcmFrameworkLoad0x0018:object];   //  NOTE - this may lead to problems here in multi-frame... we should see which items are allowed in MREchoSequence and load just them
                    }
                    
                    if ((seq = (DCMSequenceAttribute*)[sequenceItem attributeWithName:@"PixelMeasuresSequence"]) && [seq isKindOfClass:[DCMSequenceAttribute class]])
                    {
                        if ((object = [[seq sequence] objectAtIndex:0])) {
                            [self dcmFrameworkLoad0x0018:object];   //  NOTE - this may lead to problems here in multi-frame... we should see which items are allowed in PixelMeasuresSequence and load just them
                            [self dcmFrameworkLoad0x0028:object];
                        }
                    }
                    
                    if ((seq = (DCMSequenceAttribute*)[sequenceItem attributeWithName:@"PlanePositionSequence"]) && [seq isKindOfClass:[DCMSequenceAttribute class]])
                    {
                        //  This sequence has only one item, comprising Origin (DICOM spec 2015a)
                        if ((object = [[seq sequence] objectAtIndex:0]))
                        {
                            //It seems @brizolara didn't solve this entirely - restoring original behavior for non multi-frame datasets and adding working around for multi-frame
                            if( numberOfFrames <= 1)
                            {
                                [self dcmFrameworkLoad0x0020:object];
                                [self dcmFrameworkLoad0x0028:object];
                            }
                            else
                            {
                                [self dcmFrameworkLoad0x0020:object];
                                [self dcmFrameworkLoad0x0028:object];
                                
                                NSArray *ipp = [dcmObject attributeArrayWithName:@"ImagePositionPatient"];
                                if( ipp && [ipp count] >= 3)
                                {
                                    originX = [[ipp objectAtIndex:0] doubleValue];
                                    originY = [[ipp objectAtIndex:1] doubleValue];
                                    originZ = [[ipp objectAtIndex:2] doubleValue];
                                    isOriginDefined = YES;
                                }
                            }
                        }
                    }
                    
                    if ((seq = (DCMSequenceAttribute*)[sequenceItem attributeWithName:@"PlaneOrientationSequence"]) && [seq isKindOfClass:[DCMSequenceAttribute class]])
                    {
                        if ((object = [[seq sequence] objectAtIndex:0]))
                            [self dcmFrameworkLoad0x0020:object];
                    }
                    
                    if ((seq = (DCMSequenceAttribute*)[sequenceItem attributeWithName:@"PlanePositionVolumeSequence"]) && [seq isKindOfClass:[DCMSequenceAttribute class]])
                    {
                        if ((object = [[seq sequence] objectAtIndex:0]))
                            [self dcmFrameworkLoad0x0020:object];
                    }
                    
                    if ((seq = (DCMSequenceAttribute*)[sequenceItem attributeWithName:@"PixelValueTransformationSequence"]) && [seq isKindOfClass:[DCMSequenceAttribute class]])
                    {
                        if ((object = [[seq sequence] objectAtIndex:0]))
                            [self dcmFrameworkLoad0x0028:object];
                    }
                    
                    if ((seq = (DCMSequenceAttribute*)[sequenceItem attributeWithName:@"OphthalmicFrameLocationSequence"]) && [seq isKindOfClass:[DCMSequenceAttribute class]])
                    {
                        if ((object = [[seq sequence] objectAtIndex:0]))
                            [self dcmFrameworkLoadOphthalmic: object];
                    }
                }
            }
            else
            {
                NSLog(@"No Frame %d in preFrameFunctionalGroupsSequence", imageNb);
            }
        }
        
#pragma mark *tag group 6000

        memset(overlaysChannelON, false, 16*sizeof(bool));
        NSString *DICOMTag;
        for(int i=0; i<maxNumberOfOverlays; i++)
        {
            DICOMTag = [NSString stringWithFormat:@"%4X,3000", 0x6000+i*2]; //  These are the OverlayData fields
            if([dcmObject attributeArrayForKey:DICOMTag]) {
                overlaysChannelON[i] = true;
            }
            else {
                continue;
            }
            
            @try
            {
                DICOMTag = [NSString stringWithFormat:@"%4X,0010", 0x6000+i*2];
                if ([dcmObject attributeValueForKey: DICOMTag]) //  OverlayRows
                    if ([[dcmObject attributeValueForKey: DICOMTag] isKindOfClass:[NSNumber class]])
                        oRows[i] = [[dcmObject attributeValueForKey: DICOMTag] intValue];
                
                DICOMTag = [NSString stringWithFormat:@"%4X,0011", 0x6000+i*2];
                if ([dcmObject attributeValueForKey: DICOMTag])  //  OverlayColumns
                    if ([[dcmObject attributeValueForKey: DICOMTag] isKindOfClass:[NSNumber class]])
                        oColumns[i] = [[dcmObject attributeValueForKey: DICOMTag] intValue];
                
                DICOMTag = [NSString stringWithFormat:@"%4X,0040", 0x6000+i*2];
                if ([dcmObject attributeValueForKey: DICOMTag]) //  OverlayType
                    if ([[dcmObject attributeValueForKey: DICOMTag] isKindOfClass:[NSString class]])
                        oType[i] = [[dcmObject attributeValueForKey: DICOMTag] characterAtIndex: 0];
                
                DICOMTag = [NSString stringWithFormat:@"%4X0050", 0x6000+i*2];
                if ([dcmObject attributeValueForKey: DICOMTag] && //  OverlayOrigin
                    [[dcmObject attributeValueForKey: DICOMTag] isKindOfClass:[NSArray class]] &&
                    [[dcmObject attributeValueForKey: DICOMTag] count] >= 2)
                {
                    oOrigin[i][ 0] = [[[dcmObject attributeArrayForKey: DICOMTag] objectAtIndex: 0] intValue] -1;
                    oOrigin[i][ 1] = [[[dcmObject attributeArrayForKey: DICOMTag] objectAtIndex: 1] intValue] -1;
                }
                
                DICOMTag = [NSString stringWithFormat:@"%4X,0100", 0x6000+i*2];
                if ([dcmObject attributeValueForKey: DICOMTag])    //  OverlayBitsAllocated
                    if ([[dcmObject attributeValueForKey: DICOMTag] isKindOfClass:[NSNumber class]])
                        oBits[i] = [[dcmObject attributeValueForKey: DICOMTag] intValue];
                
                DICOMTag = [NSString stringWithFormat:@"%4X,0102", 0x6000+i*2];
                if ([dcmObject attributeValueForKey: DICOMTag])  //  OverlayBitPosition
                    if ([[dcmObject attributeValueForKey: DICOMTag] isKindOfClass:[NSNumber class]])
                        oBitPosition[i] = [[dcmObject attributeValueForKey: DICOMTag] intValue];
                
                DICOMTag = [NSString stringWithFormat:@"%4X,3000", 0x6000+i*2];
                NSData	*data = [dcmObject attributeValueForKey: DICOMTag]; //  OverlayData
                
                if (data && oBits[i] == 1 && oBitPosition[i] == 0)
                {
                    if( oData[i]) free( oData[i]);
                    oData[i] = calloc( oRows[i]*oColumns[i], 1);
                    if( oData[i])
                    {
                        unsigned short *pixels = (unsigned short*) [data bytes];
                        unsigned char *oD = oData[i];
                        char mask = 1;
                        long t = oColumns[i]*oRows[i]/16;
                        
                        while( t-->0)
                        {
                            unsigned short	octet = *pixels++;
                            int x = 16;
                            while( x-->0)
                            {
                                char v = octet & mask ? 1 : 0;
                                octet = octet >> 1;
                                
                                if( v)
                                    *oD = 0xFF;
                                
                                oD++;
                            }
                        }
                    }
                }
            }
            @catch (NSException *e)
            {
                N2LogExceptionWithStackTrace(e/*, @"overlays dcmframework"*/);
            }
        }
        
#pragma mark *SUV
        
        // Get values needed for SUV calcs:
        if( [dcmObject attributeValueWithName:@"PatientsWeight"]) patientsWeight = [[dcmObject attributeValueWithName:@"PatientsWeight"] floatValue];
        else patientsWeight = 0.0;
        
        [units release];
        units = [[dcmObject attributeValueWithName:@"Units"] retain];
        
        [decayCorrection release];
        decayCorrection = [[dcmObject attributeValueWithName:@"DecayCorrection"] retain];
        
        //	if( [dcmObject attributeValueWithName:@"DecayFactor"])
        //		decayFactor = [[dcmObject attributeValueWithName:@"DecayFactor"] floatValue];
        
        decayFactor = 1.0;
        
        DCMSequenceAttribute *radiopharmaceuticalInformationSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"RadiopharmaceuticalInformationSequence"];
        if( radiopharmaceuticalInformationSequence && radiopharmaceuticalInformationSequence.sequence.count > 0)
        {
            DCMObject *radionuclideTotalDoseObject = [radiopharmaceuticalInformationSequence.sequence objectAtIndex:0];
            radionuclideTotalDose = [[radionuclideTotalDoseObject attributeValueWithName:@"RadionuclideTotalDose"] floatValue];
            halflife = [[radionuclideTotalDoseObject attributeValueWithName:@"RadionuclideHalfLife"] floatValue];
            
            NSArray *priority = nil;
            
            if( gSUVAcquisitionTimeField == 0) // Prefer SeriesTime
                priority = [NSArray arrayWithObjects: @"SeriesDate", @"SeriesTime", @"AcquisitionDate", @"AcquisitionTime", @"ContentDate", @"ContentTime", @"StudyDate", @"StudyTime", nil];
            
            if( gSUVAcquisitionTimeField == 1) // Prefer AcquisitionTime
                priority = [NSArray arrayWithObjects: @"AcquisitionDate", @"AcquisitionTime", @"SeriesDate", @"SeriesTime", @"ContentDate", @"ContentTime", @"StudyDate", @"StudyTime", nil];
            
            if( gSUVAcquisitionTimeField == 2) // Prefer ContentTime
                priority = [NSArray arrayWithObjects: @"ContentDate", @"ContentTime", @"SeriesDate", @"SeriesTime", @"AcquisitionDate", @"AcquisitionTime", @"StudyDate", @"StudyTime", nil];
            
            if( gSUVAcquisitionTimeField == 3) // Prefer StudyTime
                priority = [NSArray arrayWithObjects: @"StudyDate", @"StudyTime", @"SeriesDate", @"SeriesTime", @"AcquisitionDate", @"AcquisitionTime", @"ContentDate", @"ContentTime", nil];
            
            NSString *preferredTime = nil;
            NSString *preferredDate = nil;
            
            for( int v = 0; v < priority.count;)
            {
                NSString *value;
                
                if( preferredDate == nil && (value = [[dcmObject attributeValueWithName: [priority objectAtIndex: v]] dateString])) preferredDate = value;
                v++;
                
                if( preferredTime == nil && (value = [[dcmObject attributeValueWithName: [priority objectAtIndex: v]] timeString])) preferredTime = value;
                v++;
            }
            
            NSString *radioTime = [[radionuclideTotalDoseObject attributeValueWithName:@"RadiopharmaceuticalStartTime"] timeString];
            
            if( preferredDate && preferredTime && radioTime)
            {
                if( [preferredTime length] >= 6)
                {
                    radiopharmaceuticalStartTime = [[NSCalendarDate alloc] initWithString:[preferredDate stringByAppendingString:radioTime] calendarFormat:@"%Y%m%d%H%M%S"];
                    acquisitionTime = [[NSCalendarDate alloc] initWithString:[preferredDate stringByAppendingString:preferredTime] calendarFormat:@"%Y%m%d%H%M%S"];
                }
                else
                {
                    radiopharmaceuticalStartTime = [[NSCalendarDate alloc] initWithString:[preferredDate stringByAppendingString:radioTime] calendarFormat:@"%Y%m%d%H%M"];
                    acquisitionTime = [[NSCalendarDate alloc] initWithString:[preferredDate stringByAppendingString:preferredTime] calendarFormat:@"%Y%m%d%H%M"];
                }
            }
            
            [self computeTotalDoseCorrected];
        }
        
        DCMSequenceAttribute *detectorInformationSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"DetectorInformationSequence"];
        if( detectorInformationSequence && detectorInformationSequence.sequence.count > 0)
        {
            DCMObject *detectorInformation = [detectorInformationSequence.sequence objectAtIndex:0];
            
            NSArray *ipp = [detectorInformation attributeArrayWithName:@"ImagePositionPatient"];
            if( ipp && [ipp count] >= 3)
            {
                originX = [[ipp objectAtIndex:0] doubleValue];
                originY = [[ipp objectAtIndex:1] doubleValue];
                originZ = [[ipp objectAtIndex:2] doubleValue];
                isOriginDefined = YES;
            }
            
            if( spacingBetweenSlices)
                originZ += frameNo * spacingBetweenSlices;
            else
                originZ += frameNo * sliceThickness;
            
            orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
            orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
            
            NSArray *iop = [detectorInformation attributeArrayWithName:@"ImageOrientationPatient"];
            if( iop)
            {
                BOOL equalZero = YES;
                
                for ( int j = 0; j < iop.count; j++)
                    if( [[iop objectAtIndex:j] floatValue] != 0)
                        equalZero = NO;
                
                if( equalZero == NO)
                {
                    for ( int j = 0; j < iop.count; j++)
                        orientation[ j ] = [[iop objectAtIndex:j] doubleValue];
                }
                else // doesnt the root Image Orientation contains valid data? if not use the normal vector
                {
                    equalZero = YES;
                    for ( int j = 0; j < 6; j++)
                        if( orientation[ j] != 0)
                            equalZero = NO;
                    
                    if( equalZero)
                    {
                        orientation[ 0] = 1;	orientation[ 1] = 0;	orientation[ 2] = 0;
                        orientation[ 3] = 0;	orientation[ 4] = 1;	orientation[ 5] = 0;
                    }
                }
            }
        }
        
        if( [dcmObject attributeValueForKey: @"7053,1000"])
        {
            @try
            {
                philipsFactor = [[dcmObject attributeValueForKey: @"7053,1000"] floatValue];
            }
            @catch ( NSException *e)
            {
                NSLog( @"philipsFactor exception");
                NSLog( @"%@", [e description]);
            }
            //NSLog( @"philipsFactor = %f", philipsFactor);
        }
        
        // End SUV
        
#pragma mark *compute normal vector
        // Compute normal vector
        
        orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
        orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
        orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
        
        [self computeSliceLocation];
        
#pragma mark READ PIXEL DATA
        
        maxFrame = [[dcmObject attributeValueWithName:@"NumberofFrames"] intValue];
        if( maxFrame == 0) maxFrame = 1;
        if( pixArray == nil) maxFrame = 1;
        //pixelAttr contains the whole PixelData attribute of every frames. Hence needs to be before the loop
        if ([dcmObject attributeValueWithName:@"PixelData"])
        {
            DCMPixelDataAttribute *pixelAttr = (DCMPixelDataAttribute *)[dcmObject attributeWithName:@"PixelData"];
            
            //=====================================================================
            
#pragma mark *loading a frame
            
            if ( [[dcmObject attributeValueWithName:@"Modality"] isEqualToString: @"RTDOSE"])
            {  // Set Z value for each frame
                NSArray *gridFrameOffsetArray = [dcmObject attributeArrayWithName: @"GridFrameOffsetVector"];  //List of Z values
                
                originZ += [[gridFrameOffsetArray objectAtIndex: imageNb] doubleValue];
                
                [self computeSliceLocation];
            }
            
            if( gUseShutter && imageNb != frameNo && maxFrame > 1)
            {
                if( shutterPolygonalSize)
                {
                    self->shutterPolygonal = malloc( shutterPolygonalSize * sizeof( NSPoint));
                    memcpy( self->shutterPolygonal, shutterPolygonal, shutterPolygonalSize * sizeof( NSPoint));
                }
            }
            
            //get PixelData
            short *oImage = nil;
            NSData *pixData = [pixelAttr decodeFrameAtIndex:imageNb];
            if( [pixData length] > 0)
            {
                oImage =  malloc( [pixData length]);	//pointer to a memory zone where each pixel of the data has a short value reserved
                if( oImage)
                    [pixData getBytes:oImage];
                else
                    NSLog( @"----- Major memory problems 1...");
            }
            
            if( oImage == nil) //there was no data for this frame -> create empty image
            {
                //NSLog(@"image size: %d", ( height * width * 2));
                oImage = malloc( height * width * 2);
                if( oImage)
                {
                    long yo = 0;
                    for( unsigned long i = 0 ; i < height * width; i++)
                    {
                        oImage[ i] = yo++;
                        if( yo>= width) yo = 0;
                    }
                }
                else
                    NSLog( @"----- Major memory problems 2...");
            }
            
            //-----------------------frame data already loaded in (short) oImage --------------
            
            isRGB = NO;
            inverseVal = NO;
            
            NSString *colorspace = [dcmObject attributeValueWithName:@"PhotometricInterpretation"];
            if ([colorspace rangeOfString:@"MONOCHROME1"].location != NSNotFound)
            {
                if( [[dcmObject attributeValueWithName:@"Modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpacityTableNM"] == YES && [[dcmObject attributeValueWithName:@"Modality"] isEqualToString:@"NM"]))
                {
                    
                }
                else
                    inverseVal = YES; savedWL = -savedWL;
            }
            /*else if ( [colorspace hasPrefix:@"MONOCHROME2"])	{inverseVal = NO; savedWL = savedWL;} */
            if ( [colorspace hasPrefix:@"YBR"]) isRGB = YES;
            if ( [colorspace hasPrefix:@"PALETTE"])	{ bitsAllocated = 8; isRGB = YES; NSLog(@"Palette depth conveted to 8 bit");}
            if ([colorspace rangeOfString:@"RGB"].location != NSNotFound) isRGB = YES;
            /******** dcm Object will do this *******convertYbrToRgb -> planar is converted***/
            if ([colorspace rangeOfString:@"YBR"].location != NSNotFound)
            {
                fPlanarConf = 0;
                isRGB = YES;
            }
            
            if (isRGB == YES)
            {
                unsigned char   *ptr, *tmpImage;
                int loop = (int) height * (int) width;
                tmpImage = malloc (loop * 4L);
                ptr = tmpImage;
                
                if( bitsAllocated > 8)
                {
                    if( [pixData length] < height*width*2*3)
                    {
                        NSLog( @"************* [pixData length] < height*width*2*3");
                        loop = [pixData length]/6;
                    }
                    
                    // RGB_FFF
                    unsigned short   *bufPtr;
                    bufPtr = (unsigned short*) oImage;
                    while( loop-- > 0)
                    {		//unsigned short=16 bit, then I suppose A should be 65535
                        *ptr++	= 255;			//ptr++;
                        *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                        *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                        *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                    }
                }
                else
                {
                    if( [pixData length] < height*width*3)
                    {
                        NSLog( @"************* [pixData length] < height*width*3");
                        loop = [pixData length]/3;
                    }
                    
                    // RGB_888
                    unsigned char   *bufPtr;
                    bufPtr = (unsigned char*) oImage;
                    
                    while( loop-- > 0)
                    {
                        *ptr++	= 255;			//ptr++;
                        *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                        *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                        *ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
                    }
                    
                }
                free(oImage);
                oImage = (short*) tmpImage;
            }
            else
            {
                if( fIsSigned && bitsAllocated != bitsStored) //We have to move the signing bit
                {
                    if( bitsAllocated == 16)
                    {
                        short *bufPtr = (short*) oImage, *tmpImage;
                        long loop;//, totSize;
                        const int shift = bitsAllocated - bitsStored;
                        
                        tmpImage = malloc( height * width * 2L);
                        short *ptr = tmpImage;
                        
                        loop = height * width;
                        short div = pow( 2, shift);
                        while( loop-- > 0)
                            *ptr++ = ((short)(*(bufPtr++) << shift))/div;
                        
                        free(oImage);
                        oImage =  (short*) tmpImage;
                    }
                }
                
                if( bitsAllocated == 8)
                {
                    // Planar 8
                    //-> 16 bits image
                    unsigned char   *bufPtr;
                    short			*ptr, *tmpImage;
                    int			loop, totSize;
                    
                    totSize = (int) ((int) height * (int) width * 2L);
                    tmpImage = malloc( totSize);
                    
                    bufPtr = (unsigned char*) oImage;
                    ptr    = tmpImage;
                    
                    loop = totSize/2;
                    
                    if( [pixData length] < loop)
                    {
                        NSLog( @"************* [pixData length] < height * width");
                        loop = [pixData length];
                    }
                    
                    while( loop-- > 0)
                    {
                        *ptr++ = *bufPtr++;
                    }
                    free(oImage);
                    oImage =  (short*) tmpImage;
                }
            }
            
            
            //***********
            
            if( isRGB)
            {
                if( fExternalOwnedImage)
                {
                    fImage = fExternalOwnedImage;
                    memcpy( fImage, oImage, width*height*sizeof(float));
                    free(oImage);
                }
                else fImage = (float*) oImage;
                oImage = nil;
                
                if(gDisplayDICOMOverlays)
                {
                    for(int i=0; i<maxNumberOfOverlays; i++)
                    {
                        if(overlaysChannelON[i])
                        {
                            unsigned char	*rgbData = (unsigned char*) fImage;
                            
                            for( int y = 0; y < oRows[i]; y++)
                            {
                                for( int x = 0; x < oColumns[i]; x++)
                                {
                                    if (oData[i] && oData[i][y * oColumns[i] + x])
                                    {
                                        if( (x + oOrigin[i][ 0]) >= 0 && (x + oOrigin[i][ 0]) < width &&
                                           (y + oOrigin[i][ 1]) >= 0 && (y + oOrigin[i][ 1]) < height)
                                        {
                                            rgbData[ (y + oOrigin[i][ 1]) * width*4 + (x + oOrigin[i][ 0])*4 + 1] = 0xFF;
                                            rgbData[ (y + oOrigin[i][ 1]) * width*4 + (x + oOrigin[i][ 0])*4 + 2] = 0xFF;
                                            rgbData[ (y + oOrigin[i][ 1]) * width*4 + (x + oOrigin[i][ 0])*4 + 3] = 0xFF;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                if( bitsAllocated == 32) // 32-bit float or 32-bit integers
                {
                    if( fExternalOwnedImage)
                        fImage = fExternalOwnedImage;
                    else
                        fImage = malloc(width*height*sizeof(float) + 100);
                    
                    if( fImage)
                    {
                        memcpy( fImage, oImage, height * width * sizeof( float));
                        
                        if( slope != 1.0 || offset != 0 || [[NSUserDefaults standardUserDefaults] boolForKey: @"32bitDICOMAreAlwaysIntegers"])
                        {
                            unsigned int *usint = (unsigned int*) oImage;
                            int *sint = (int*) oImage;
                            float *tDestF = fImage;
                            double dOffset = offset, dSlope = slope;
                            
                            if( fIsSigned > 0)
                            {
                                unsigned long x = height * width;
                                while( x-- > 0)
                                    *tDestF++ = ((double) (*sint++)) * dSlope + dOffset;
                            }
                            else
                            {
                                unsigned long x = height * width;
                                while( x-- > 0)
                                    *tDestF++ = ((double) (*usint++)) * dSlope + dOffset;
                            }
                        }
                    }
                    else
                        N2LogStackTrace( @"*** Not enough memory - malloc failed");
                    
                    free(oImage);
                    oImage = nil;
                }
                else
                {
                    vImage_Buffer src16, dstf;
                    dstf.height = src16.height = height;
                    dstf.width = src16.width = width;
                    src16.rowBytes = width*2;
                    dstf.rowBytes = width*sizeof(float);
                    
                    src16.data = oImage;
                    
                    if( fExternalOwnedImage)
                        fImage = fExternalOwnedImage;
                    else
                        fImage = malloc(width*height*sizeof(float) + 100);
                    
                    dstf.data = fImage;
                    
                    if( dstf.data)
                    {
                        if( bitsAllocated == 16 && [pixData length] < height*width*2)
                        {
                            NSLog( @"************* [pixData length] < height * width");
                            
                            if( [pixData length] == height*width) // 8 bits??
                            {
                                NSLog( @"************* [[pixData length] == height*width : 8 bits? but declared as 16 bits...");
                                
                                unsigned long x = height * width;
                                float *tDestF = (float*) dstf.data;
                                unsigned char *oChar = (unsigned char*) oImage;
                                while( x-- > 0)
                                    *tDestF++ = *oChar++;
                            }
                            else
                                memset( dstf.data, 0, width*height*sizeof(float));
                        }
                        else
                        {
                            if( fIsSigned > 0)
                                vImageConvert_16SToF( &src16, &dstf, offset, slope, 0);
                            else
                                vImageConvert_16UToF( &src16, &dstf, offset, slope, 0);
                        }
                        
                        if( inverseVal)
                        {
                            float neg = -1;
                            vDSP_vsmul( fImage, 1, &neg, fImage, 1, height * width);
                        }
                    }
                    else N2LogStackTrace( @"*** Not enough memory - malloc failed");
                    
                    free(oImage);
                    oImage = nil;
                }
                
                if(gDisplayDICOMOverlays && fImage)
                {
                    float maxValue = 0;
                    
                    if( inverseVal)
                        maxValue = -offset;
                    else
                    {
                        maxValue = pow( 2, bitsStored);
                        maxValue *= slope;
                        maxValue += offset;
                    }
                    
                    for(int i=0; i<maxNumberOfOverlays; i++)
                    {
                        if(overlaysChannelON[i])
                        {
                            for( int y = 0; y < oRows[i]; y++)
                            {
                                for( int x = 0; x < oColumns[i]; x++)
                                {
                                    if (oData[i] && oData[i][y * oColumns[i] + x])
                                    {
                                        if( (x + oOrigin[i][ 0]) >= 0 && (x + oOrigin[i][ 0]) < width &&
                                           (y + oOrigin[i][ 1]) >= 0 && (y + oOrigin[i][ 1]) < height)
                                        {
                                            fImage[ (y + oOrigin[i][ 1]) * width + x + oOrigin[i][ 0]] = maxValue;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            wl = 0;
            ww = 0; //Computed later, only if needed
            
            if( savedWW != 0)
            {
                wl = savedWL;
                ww = savedWW;
            }
            
#pragma mark *after loading a frame
            
        }//end of if ([dcmObject attributeValueWithName:@"PixelData"])
        
        if( pixelSpacingY != 0)
        {
            if( fabs(pixelSpacingX) / fabs(pixelSpacingY) > 10000 || fabs(pixelSpacingX) / fabs(pixelSpacingY) < 0.0001)
            {
                pixelSpacingX = 1;
                pixelSpacingY = 1;
            }
        }
        
        if( pixelSpacingX < 0) pixelSpacingX = -pixelSpacingX;
        if( pixelSpacingY < 0) pixelSpacingY = -pixelSpacingY;
        if( pixelSpacingY != 0 && pixelSpacingX != 0)
        {
            if( estimatedRadiographicMagnificationFactor)
            {
                pixelSpacingX /= estimatedRadiographicMagnificationFactor;
                pixelSpacingY /= estimatedRadiographicMagnificationFactor;
            }
            
            pixelRatio = pixelSpacingY / pixelSpacingX;
        }
    }
    @catch (NSException *e)
    {
        NSLog( @"******** loadDICOMDCMFramework exception 2: %@", e);
        returnValue = NO;
    }
    
    [purgeCacheLock lock];
    [purgeCacheLock unlockWithCondition: [purgeCacheLock condition]-1];
    [pool release];
    
    return returnValue;
}

+ (void) purgeCachedDictionaries
{
    if( [NSThread isMainThread] == NO)
    {
        [DCMPix performSelectorOnMainThread: @selector(purgeCachedDictionaries) withObject: nil waitUntilDone: NO];
        return;
    }
    
    if( purgeCacheLock == nil)
        purgeCacheLock = [[NSConditionLock alloc] initWithCondition: 0];
    
    if( [purgeCacheLock lockWhenCondition: 0 beforeDate: [NSDate dateWithTimeIntervalSinceNow: 10]])
    {
        [PapyrusLock lock];
        
        @try
        {
            [cachedDCMFrameworkFiles removeAllObjects];
        }
        @catch (NSException * e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
        }
        
        [PapyrusLock unlock];
        [purgeCacheLock unlock];
    }
    else NSLog( @"****** failed to acquire lock on purgeCacheLock during 10 secs : purgeCacheLock condition: %d", (int) [purgeCacheLock condition]);
}

- (void) clearCachedDCMFrameworkFiles
{
    [PapyrusLock lock];
    
    @try
    {
        if( fImage)
        {
            NSMutableDictionary *cachedGroupsForThisFile = [cachedDCMFrameworkFiles valueForKey:self.srcFile];
            
            if( cachedGroupsForThisFile && retainedCacheGroup == cachedGroupsForThisFile)
            {
                [cachedGroupsForThisFile setValue: [NSNumber numberWithInt: [[cachedGroupsForThisFile objectForKey: @"count"] intValue]-1] forKey: @"count"];
                retainedCacheGroup = nil;
                
                if( [[cachedGroupsForThisFile objectForKey: @"count"] intValue] <= 0)
                {
                    [cachedDCMFrameworkFiles removeObjectForKey:self.srcFile];
                }
            }
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [PapyrusLock unlock];
}

- (void) clearCachedPapyGroups
{
    [PapyrusLock lock];
    
    @try
    {
        NSMutableDictionary *cachedGroupsForThisFile = [cachedPapyGroups valueForKey:self.srcFile];
        if( cachedGroupsForThisFile && retainedCacheGroup == cachedGroupsForThisFile)
        {
            [cachedGroupsForThisFile setValue: [NSNumber numberWithInt: [[cachedGroupsForThisFile objectForKey: @"count"] intValue]-1] forKey: @"count"];
            retainedCacheGroup = nil;
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [PapyrusLock unlock];
}

- (BOOL) loadDICOMPapyrus
{
    return NO;
}

- (BOOL) isDICOMFile:(NSString *) file
{
    BOOL readable = YES;
    
#ifdef OSIRIX_VIEWER
    if( imageObjectID)
    {
        if( fileTypeHasPrefixDICOM == NO) readable = NO;
    }
    else
#endif
    {
        readable = [DicomFile isDICOMFile: file];
    }
    
    return readable;
}

- (void) getDataFromNSImage:(NSImage*) otherImage
{
    @autoreleasepool
    {
        @try
        {
            CGImageRef cgRef = [otherImage CGImageForProposedRect:NULL context:nil hints:nil];
            NSBitmapImageRep *r = [[[NSBitmapImageRep alloc] initWithCGImage:cgRef] autorelease];
            [r setSize: otherImage.size];
            
            NSBitmapImageRep *TIFFRep = [NSBitmapImageRep imageRepWithData: [r TIFFRepresentation]];
            
            if( TIFFRep)
            {
                height = TIFFRep.pixelsHigh;
                width = TIFFRep.pixelsWide;
/*
#ifdef OSIRIX_VIEWER
                NSManagedObjectContext *iContext = nil;
                
                if( savedHeightInDB != 0 && savedHeightInDB != height)
                {
                    if( savedHeightInDB != OsirixDicomImageSizeUnknown)
                        NSLog( @"******* [[imageObj valueForKey:@'height'] intValue] != height. New: %d / DB: %d", (int)height, (int)savedHeightInDB);
                    
                    if( iContext == nil)
                        iContext = ([[NSThread currentThread] isMainThread] ? [[[BrowserController currentBrowser] database] managedObjectContext] : [[[BrowserController currentBrowser] database] independentContext]);
                    
                    [[iContext existingObjectWithID: imageObjectID error: nil] setValue: [NSNumber numberWithInt: height] forKey: @"height"];
                }
                
                if( height > savedHeightInDB && fExternalOwnedImage)
                    height = savedHeightInDB;
                
                if( savedWidthInDB != 0 && savedWidthInDB != width)
                {
                    if( savedWidthInDB != OsirixDicomImageSizeUnknown)
                        NSLog( @"******* [[imageObj valueForKey:@'width'] intValue] != width. New: %d / DB: %d", (int)width, (int)savedWidthInDB);
                    
                    if( iContext == nil)
                        iContext = ([[NSThread currentThread] isMainThread] ? [[[BrowserController currentBrowser] database] managedObjectContext] : [[[BrowserController currentBrowser] database] independentContext]);
                    
                    [[iContext existingObjectWithID: imageObjectID error: nil] setValue: [NSNumber numberWithInt: width] forKey: @"width"];
                }
                
                if( width > savedWidthInDB && fExternalOwnedImage)
                    width = savedWidthInDB;
                
                [iContext save: nil];
#endif
 */
                unsigned char *srcImage = [TIFFRep bitmapData];
                
                unsigned char *argbImage = nil, *srcPtr = nil, *tmpPtr = nil;
                
                int totSize = (int)(height * width * 4);
                if( fExternalOwnedImage)
                    argbImage =	(unsigned char*) fExternalOwnedImage;
                else
                    argbImage = malloc( totSize);
                
                if( srcImage != nil && argbImage != nil)
                {
                    int x, y;
                    
                    switch( [TIFFRep bitsPerPixel])
                    {
                        case 8:
                            tmpPtr = argbImage;
                            for( y = 0 ; y < height; y++)
                            {
                                srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                                
                                x = (int)width;
                                while( x-->0)
                                {
                                    tmpPtr++;
                                    *tmpPtr++ = *srcPtr;
                                    *tmpPtr++ = *srcPtr;
                                    *tmpPtr++ = *srcPtr;
                                    srcPtr++;
                                }
                            }
                            break;
                            
                        case 32:
                            tmpPtr = argbImage;
                            for( y = 0 ; y < height; y++)
                            {
                                srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                                
                                x = (int)width;
                                while( x-->0)
                                {
                                    unsigned char alpha = srcPtr[ 3];
                                    
                                    if( alpha != 255) // -> white background
                                    {
                                        *tmpPtr++ = 255;
                                        *tmpPtr++ = (255 - alpha) + (alpha * *srcPtr++ / 255);
                                        *tmpPtr++ = (255 - alpha) + (alpha * *srcPtr++ / 255);
                                        *tmpPtr++ = (255 - alpha) + (alpha * *srcPtr++ / 255);
                                        srcPtr++;
                                    }
                                    else
                                    {
                                        *tmpPtr++ = 255;
                                        *tmpPtr++ = *srcPtr++;
                                        *tmpPtr++ = *srcPtr++;
                                        *tmpPtr++ = *srcPtr++;
                                        srcPtr++;
                                    }
                                }
                            }
                            break;
                            
                        case 24:
                            tmpPtr = argbImage;
                            for( y = 0 ; y < height; y++)
                            {
                                srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                                
                                x = (int)width;
                                while( x-->0)
                                {
                                    tmpPtr++;
                                    
                                    *((short*)tmpPtr) = *((short*)srcPtr);
                                    tmpPtr+=2;
                                    srcPtr+=2;
                                    
                                    *tmpPtr++ = *srcPtr++;
                                }
                            }
                            break;
                            
                        case 48:
                            tmpPtr = argbImage;
                            for( y = 0 ; y < height; y++)
                            {
                                srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                                
                                x = (int)width;
                                while( x-->0)
                                {
                                    tmpPtr++;
                                    *tmpPtr++ = *srcPtr;	srcPtr += 2;
                                    *tmpPtr++ = *srcPtr;	srcPtr += 2;
                                    *tmpPtr++ = *srcPtr;	srcPtr += 2;
                                }
                            }
                            break;
                            
                        default:
                            NSLog(@"Error - Unknow bitsPerPixel ...");
                            break;
                    }
                    
                    fImage = (float*) argbImage;
                    isRGB = YES;
                }
            }
        }
        @catch (NSException* e)
        {
            N2LogExceptionWithStackTrace(e);
        }
    }
}

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void) CheckLoadIn
{
    
    if( fImage == nil)
    {
        BOOL success = NO;
        short *oImage = nil;
        
        VOILUTApplied = NO;
        
        needToCompute8bitRepresentation = YES;
        
        if( runOsiriXInProtectedMode) return;
        
        if (!self.srcFile) return;
        
//JF DCKV instead of papyrus
        if( [self isDICOMFile:self.srcFile])
        {
            // PLEASE, KEEP BOTH FUNCTIONS FOR TESTING PURPOSE. THANKS
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            @try
            {
                if( gUSEPAPYRUSDCMPIX)
                {
                    success = [self loadDICOMPapyrus]; //JF always fail because pap3 static lib not present
                }
                else
                {
                    success = [self loadDICOMDCMFramework];
                    
                    if (success == NO &&
                        [DCMObject isDICOM:[NSData dataWithContentsOfFile:self.srcFile]]) {
                        success = [self loadDICOMPapyrus];
                    }
                }
                
                if( numberOfFrames <= 1)
                    [self clearCachedPapyGroups];
            }
            
            @catch ( NSException *e)
            {
                NSLog( @"CheckLoadIn Exception");
                NSLog( @"%@", [e description]);
                NSLog( @"Exception for this file: %@", self.srcFile);
                success = NO;
            }
            
            [self checkSUV];
            
            [pool release];
        }
/*
        if( success == NO)	// Is it a NON-DICOM IMAGE ??
        {
            NSImage		*otherImage = nil;
            NSString	*extension = [[self.srcFile pathExtension] lowercaseString];
            
            id fileFormatBundle;
            if ((fileFormatBundle = [[PluginManager fileFormatPlugins] objectForKey:[self.srcFile pathExtension]]))
            {
                PluginFileFormatDecoder *decoder = [[[fileFormatBundle principalClass] alloc] init];
                
 //JF               [PluginManager startProtectForCrashWithFilter: decoder];
                
                fImage = [decoder checkLoadAtPath:self.srcFile];
                //NSLog(@"decoder width %d", [decoder width]);
                width = [[decoder width] intValue];
                //width = 832;
                //NSLog(@"width %d : %d", width, [decoder width]);
                height = [[decoder height] intValue];
                //NSLog(@"height %d : %d", height, [decoder height]);
                isRGB = [decoder isRGB];
                [decoder release];
                
//JF                [PluginManager endProtectForCrash];
            }
            else
                
                if( [extension isEqualToString:@"zip"])
                {
                    // the ZIP icon
                    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:self.srcFile];
                    // make it big
                    [icon setSize:NSMakeSize(128,128)];
                    
                    NSBitmapImageRep *TIFFRep = [[NSBitmapImageRep alloc] initWithData: [icon TIFFRepresentation]];
                    
                    // size of the image
                    height = [TIFFRep pixelsHigh];
                    
                    width = [TIFFRep pixelsWide];
                    
                    
                    long totSize;
                    totSize = height * width * 4;
                    
                    unsigned char *argbImage;
                    if( fExternalOwnedImage)
                    {
                        argbImage =	(unsigned char*) fExternalOwnedImage;
                    }
                    else
                    {
                        argbImage = malloc( totSize);
                    }
                    
                    unsigned char *srcImage = [TIFFRep bitmapData];
                    unsigned char *tmpPtr = argbImage, *srcPtr;
                    
                    long x, y;
                    for( y = 0 ; y < height; y++)
                    {
                        srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                        x = width;
                        while( x-->0)
                        {
                            tmpPtr++;
                            *tmpPtr++ = *srcPtr++;
                            *tmpPtr++ = *srcPtr++;
                            *tmpPtr++ = *srcPtr++;
                            srcPtr++;
                        }
                    }
                    
                    fImage = (float*) argbImage;
                    isRGB = YES;
                    [TIFFRep release];
                }
                else if( [extension isEqualToString:@"jpg"] ||
                        [extension isEqualToString:@"jp2"] ||
                        [extension isEqualToString:@"jpeg"] ||
                        [extension isEqualToString:@"pdf"] ||
                        [extension isEqualToString:@"pct"] ||
                        [extension isEqualToString:@"png"] ||
                        [extension isEqualToString:@"gif"])
                {
                    otherImage = [[NSImage alloc] initWithContentsOfFile: self.srcFile];
                }
            
            if( otherImage != nil)
            {
                    [otherImage setBackgroundColor: [NSColor whiteColor]];
                    
                    if( [extension isEqualToString:@"pdf"])
                    {
                        id tempID = [otherImage bestRepresentationForDevice:nil];
                        
                        if( [tempID isKindOfClass: [NSPDFImageRep class]])
                        {
                            NSPDFImageRep *pdfRepresentation = tempID;
                            
                            [pdfRepresentation setCurrentPage:frameNo];
                        }
                    }
                    
                    [self getDataFromNSImage: otherImage];
                
                [otherImage release];
            }
            else	// It's a Movie ??
            {
                if( [extension isEqualToString:@"mov"] ||
                   [extension isEqualToString:@"mpg"] ||
                   [extension isEqualToString:@"mpeg"] ||
                   [extension isEqualToString:@"avi"])
                {
                    NSError *error = nil;
                    AVAsset *asset = [AVAsset assetWithURL: [NSURL fileURLWithPath: self.srcFile]];
                    AVAssetReader *asset_reader = [[[AVAssetReader alloc] initWithAsset: asset error: &error] autorelease];
                    
                    NSArray* video_tracks = [asset tracksWithMediaType: AVMediaTypeVideo];
                    if( video_tracks.count)
                    {
                        AVAssetTrack* video_track = [video_tracks objectAtIndex:0];
                        
                        NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
                        [dictionary setObject: [NSNumber numberWithInt: kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
                        
                        AVAssetReaderTrackOutput* asset_reader_output = [[[AVAssetReaderTrackOutput alloc] initWithTrack:video_track outputSettings:dictionary] autorelease];
                        [asset_reader addOutput:asset_reader_output];
                        
                        [asset_reader startReading];
                        
                        long curFrame = 0;
                        while( [asset_reader status] == AVAssetReaderStatusReading)
                        {
                            CMSampleBufferRef sampleBufferRef = [asset_reader_output copyNextSampleBuffer];
                            
                            if( curFrame == frameNo && sampleBufferRef)
                            {
                                CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
                                
                                CVPixelBufferLockBaseAddress(pixelBuffer,0);
                                //Get information about the image
                                uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
                                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
                                size_t w = CVPixelBufferGetWidth(pixelBuffer);
                                size_t h = CVPixelBufferGetHeight(pixelBuffer);
                                
                                NSLog(@"Display Frame : %zu %zu %zu", w, h, bytesPerRow);
                                
                                unsigned char *argbImage, *tmpPtr, *srcPtr, *srcImage = baseAddress;
                                long totSize;
                                
                                height = h;
                                width = w;
                                
                                totSize = height * width * 4;
                                
                                if ( fExternalOwnedImage)
                                    argbImage =	(unsigned char*) fExternalOwnedImage;
                                else
                                    argbImage = malloc( totSize);
                                
                                tmpPtr = argbImage;
                                for( long y = 0 ; y < height; y++)
                                {
                                    srcPtr = srcImage + y * bytesPerRow;
                                    memcpy( tmpPtr, srcPtr, width*4);
                                    tmpPtr += width*4;
                                }
                                
                                fImage = (float*) argbImage;
                                isRGB = YES;
                                
                                //We unlock the  image buffer
                                CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
                            }
                            
                            if( sampleBufferRef)
                            {
                                CMSampleBufferInvalidate(sampleBufferRef);
                                CFRelease(sampleBufferRef);
                            }
                            
                            curFrame++;
                        }
                    }
                }
            }
            
        }
*/
        if( fImage == nil)
        {
            NSLog(@"not able to load the image : %@", self.srcFile);
            
            if( fExternalOwnedImage)
                fImage = fExternalOwnedImage;
            else
                fImage = malloc( 128 * 128 * 4);
            
            height = 128;
            width = 128;
            oImage = nil;
            isRGB = NO;
            notAbleToLoadImage = YES;
            
            for( int i = 0; i < 128*128; i++)
                fImage[ i ] = i;
        }
        
        if( isRGB)	// COMPUTE ALPHA MASK = ALPHA = R+G+B/3
        {
            unsigned char *argbPtr = (unsigned char*) fImage;
            long ss = width * height;
            
            while( ss-->0)
            {
                *argbPtr = (*(argbPtr+1) + *(argbPtr+2) + *(argbPtr+3)) / 3;
                argbPtr+=4;
            }
        }
    }
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

-(void) CheckLoadFromThread:(NSThread*) loadingThread
{
    @autoreleasepool
    {
        @synchronized(loadingThread)
        {
            if ([loadingThread isExecuting] == NO || [loadingThread isCancelled] || [loadingThread isFinished])
                return;
        }
        
        // uses DCMPix class variable NSString *sourceFile to load (CheckLoadIn method), for the first time or again, an fImage or oImage....
        
        [checking lock];
        
        @try
        {
            [self CheckLoadIn];
        }
        @catch (NSException *ne)
        {
            NSLog( @"CheckLoad Exception");
            NSLog( @"Exception : %@", [ne description]);
            NSLog( @"Exception for this file: %@", self.srcFile);
        }
        @finally {
            [checking unlock];
        }
    }
}



-(void) CheckLoad
{
    @autoreleasepool
    {
        // uses DCMPix class variable NSString *sourceFile to load (CheckLoadIn method), for the first time or again, an fImage or oImage....
        
        [checking lock];
        
        @try
        {
            [self CheckLoadIn];
        }
        @catch (NSException *ne)
        {
            NSLog( @"CheckLoad Exception");
            NSLog( @"Exception : %@", [ne description]);
            NSLog( @"Exception for this file: %@", self.srcFile);
        }
        @finally {
            [checking unlock];
        }
    }
}

- (void)setBaseAddr: (char*) ptr
{
    if( baseAddr) free( baseAddr);
    baseAddr = ptr;
}

- (char*)baseAddr
{
    [self CheckLoad];
    
    if( baseAddr == nil)
        [self allocate8bitRepresentation];
    
    if( needToCompute8bitRepresentation)
        [self compute8bitRepresentation];
    
    return baseAddr;
}

- (void)setLUT12baseAddr: (unsigned char*) ptr
{
    if( ptr != LUT12baseAddr)
    {
        if(LUT12baseAddr) free(LUT12baseAddr);
        LUT12baseAddr = ptr;
    }
}

- (unsigned char*)LUT12baseAddr;
{
    [self CheckLoad];
    if( LUT12baseAddr == nil)
        [self allocate8bitRepresentation];
    return LUT12baseAddr;
}

# pragma mark-

+ (NSPoint) rotatePoint:(NSPoint)pt aroundPoint:(NSPoint)c angle:(float)a;
{
    NSPoint rot;
    
    pt.x -= c.x;
    pt.y -= c.y;
    
    rot.x = cos(a)*pt.x - sin(a)*pt.y;
    rot.y = sin(a)*pt.x + cos(a)*pt.y;
    
    rot.x += c.x;
    rot.y += c.y;
    
    return rot;
}

- (void) drawImage: (vImage_Buffer*) src inImage: (vImage_Buffer*) dst offset:(NSPoint) oo background:(float) b transparency: (BOOL) t
{
    if( t == NO)
    {
        float *f = (float*) dst->data;
        int i = (int)(dst->height * dst->width);
        while( i-->0) *f++ = b;
    }
    
    int ox = oo.x;
    int oy = oo.y;
    
    NSRect dstRect = NSMakeRect( 0, 0, dst->width, dst->height);
    NSRect srcRect = NSMakeRect( ox, oy, src->width, src->height);
    
    NSRect unionRect = NSIntersectionRect( dstRect, srcRect);
    
    int y1 = unionRect.origin.y;
    int y2 = unionRect.origin.y+unionRect.size.height;
    int x1 = unionRect.origin.x;
    int x2 = unionRect.origin.x+unionRect.size.width;
    
    int lineBytes = (x2-x1)*sizeof( float);
    
    float *srcData = (float*) src->data;
    float *dstData = (float*) dst->data;
    
    if( t == NO)
    {
        for( int y = y1; y < y2; y++)
        {
            memcpy( dstData + (y*dst->width + x1), srcData +((y-oy)*src->width + (x1-ox)), lineBytes);
        }
    }
    else
    {
        for( int y = y1; y < y2; y++)
        {
            for( int x = x1; x < x2; x++)
            {
                float *d = dstData + (y*dst->width + x);
                float *s = srcData +((y-oy)*src->width + (x-ox));
                
                int diff = *s - b;
                
                if( diff > 900)
                    *d = *s;
            }
        }
    }
}

- (void) drawImage: (vImage_Buffer*) src inImage: (vImage_Buffer*) dst offset:(NSPoint) oo background:(float) b
{
    return [self drawImage:  src inImage:  dst offset: oo background: b transparency:  NO];
}

-(DCMPix*) mergeWithDCMPix:(DCMPix*) o offset:(NSPoint) oo
{
    if( o == nil) return nil;
    if( [o isRGB]) return nil;
    if( [self isRGB]) return nil;
    
    DCMPix *newPix = nil;
    
    @try
    {
        int ox = oo.x;
        int oy = oo.y;
        
        NSRect dstRect = NSMakeRect( 0, 0, [self pwidth], [self pheight]);
        
        NSPoint center = NSMakePoint( [self pwidth]/2 - [o pwidth]/2, [self pheight]/2 - [o pheight]/2);
        NSRect srcRect = NSMakeRect( ox + center.x, oy + center.y, [o pwidth], [o pheight]);
        
        NSRect unionRect = NSUnionRect( dstRect, srcRect);
        
        vImage_Buffer src;
        vImage_Buffer dst;
        
        dst.height = unionRect.size.height;
        dst.width = unionRect.size.width;
        dst.rowBytes = dst.width * 4;
        dst.data = malloc( dst.height * dst.rowBytes);
        
        // Draw first image
        src.height = [self pheight];
        src.width = [self pwidth];
        src.rowBytes = [self pwidth]*4;
        src.data = [self fImage];
        
        [self drawImage:&src inImage:&dst offset:NSMakePoint( -unionRect.origin.x, -unionRect.origin.y) background: [self minValueOfSeries]-1024 transparency: NO];
        
        // Adapt the window level
        
        if( [self wl] != [o wl])
        {
            long i = dst.height * dst.width;
            float *ptr = dst.data;
            float diffww = [o ww]/[self ww];
            float diffwl = ([o wl] - [self wl])*diffww;
            
            while (i-- > 0)
            {
                *ptr  += diffwl;
                *ptr++ *= diffww;
            }
        }
        
        src.height = [o pheight];
        src.width = [o pwidth];
        src.rowBytes = [o pwidth]*4;
        src.data = [o fImage];
        
        [self drawImage:&src inImage:&dst offset:NSMakePoint( ox+center.x-unionRect.origin.x, oy+center.y-unionRect.origin.y) background: [self minValueOfSeries]-1024 transparency: YES];
        
        // Create final DCMPix
        newPix = [[self copy] autorelease];
        
        [newPix freefImageWhenDone: NO];
        [newPix setfImage: dst.data];
        [newPix freefImageWhenDone: YES];
        
        newPix.pheight = dst.height;
        newPix.pwidth = dst.width;
        
        // New origin
        float or[ 3];
        [newPix convertPixX: unionRect.origin.x pixY: unionRect.origin.y toDICOMCoords: or pixelCenter: NO];
        [newPix setOrigin: or];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    return newPix;
}

- (void) orientationCorrected:(float*) correctedOrientation rotation:(float) rotation xFlipped: (BOOL) xFlipped yFlipped: (BOOL) yFlipped
{
#ifdef OSIRIX_VIEWER
    float	o[ 9];
    float   yRot = -1, xRot = -1;
    float	rot = rotation;
    
    [self orientation: o];
    
    if( yFlipped && xFlipped)
    {
        rot = rot + 180;
    }
    else
    {
        if( yFlipped)
        {
            xRot *= -1;
            yRot *= -1;
            
            o[ 3] *= -1;
            o[ 4] *= -1;
            o[ 5] *= -1;
        }
        
        if( xFlipped)
        {
            xRot *= -1;
            yRot *= -1;
            
            o[ 0] *= -1;
            o[ 1] *= -1;
            o[ 2] *= -1;
        }
    }
    
    // Compute normal vector
    o[6] = o[1]*o[5] - o[2]*o[4];
    o[7] = o[2]*o[3] - o[0]*o[5];
    o[8] = o[0]*o[4] - o[1]*o[3];
    
    XYZ vector, rotationVector;
    
    rotationVector.x = o[ 6];	rotationVector.y = o[ 7];	rotationVector.z = o[ 8];
    
    vector.x = o[ 0];	vector.y = o[ 1];	vector.z = o[ 2];
    vector =  ArbitraryRotate(vector, xRot*rot*deg2rad, rotationVector);
    o[ 0] = vector.x;	o[ 1] = vector.y;	o[ 2] = vector.z;
    
    vector.x = o[ 3];	vector.y = o[ 4];	vector.z = o[ 5];
    vector =  ArbitraryRotate(vector, yRot*rot*deg2rad, rotationVector);
    o[ 3] = vector.x;	o[ 4] = vector.y;	o[ 5] = vector.z;
    
    // Compute normal vector
    o[6] = o[1]*o[5] - o[2]*o[4];
    o[7] = o[2]*o[3] - o[0]*o[5];
    o[8] = o[0]*o[4] - o[1]*o[3];
    
    memcpy( correctedOrientation, o, sizeof o);
#endif
}

- (NSRect) usefulRectWithRotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF
{
    int newHeight;
    int newWidth;
    
    float rot = r*deg2rad;
    
    // Apply scale
    newWidth = [self pwidth] * scale;
    newHeight = [self pheight] * scale * pixelRatio;
    
    // Apply rotation
    NSPoint pt[ 4];
    NSPoint centerPt = NSMakePoint( newWidth/2., newHeight/2.);
    NSPoint zeroPt = NSMakePoint( 0, 0);
    
    pt[ 0] = [DCMPix rotatePoint: zeroPt aroundPoint: centerPt angle: rot];
    pt[ 1] = [DCMPix rotatePoint: NSMakePoint( zeroPt.x+newWidth, zeroPt.y) aroundPoint: centerPt angle: rot];
    pt[ 2] = [DCMPix rotatePoint: NSMakePoint( zeroPt.x+newWidth, zeroPt.y+newHeight) aroundPoint: centerPt angle: rot];
    pt[ 3] = [DCMPix rotatePoint: NSMakePoint( zeroPt.x, zeroPt.y+newHeight) aroundPoint: centerPt angle: rot];
    
    float minX, maxX, minY, maxY;
    
    minX = maxX = pt[ 0].x;
    minY = maxY = pt[ 0].y;
    
    for( int i = 0; i < 4; i++)
    {
        minX = minX > pt[ i].x ? pt[ i].x : minX;
        maxX = maxX < pt[ i].x ? pt[ i].x : maxX;
        minY = minY > pt[ i].y ? pt[ i].y : minY;
        maxY = maxY < pt[ i].y ? pt[ i].y : maxY;
    }
    
    NSRect newRect = NSMakeRect( minX, minY, maxX - minX, maxY - minY);
    
    return newRect;
}

- (DCMPix*) renderWithRotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF
{
    return [self renderWithRotation: r scale: scale xFlipped: xF yFlipped: yF backgroundOffset: -1024];
}

- (DCMPix*) renderWithRotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF backgroundOffset: (float) bgO
{
    if( [self isRGB]) return nil;
    
    NSRect dstRect = [self usefulRectWithRotation: r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF];
    
    float rot = r*deg2rad;
    int newHeight;
    int newWidth;
    
    // Apply scale
    newWidth = [self pwidth] * scale;
    newHeight = [self pheight] * scale * pixelRatio;
    NSPoint centerPt = NSMakePoint( newWidth/2., newHeight/2.);
    
    int newW = (dstRect.size.width);
    int newH = (dstRect.size.height);
    
    vImage_Buffer src;
    vImage_Buffer dst;
    
    if( [self isRGB] == NO)
    {
        src.height = [self pheight];
        src.width = [self pwidth];
        src.rowBytes = [self pwidth]*4;
        src.data = [self computefImage];
        
        if(self.shutterEnabled &&
           shutterRect.size.width > 0 &&
           shutterRect.size.height > 0)
        {
            shutterRect.origin.y = roundf( shutterRect.origin.y);
            shutterRect.origin.x = roundf( shutterRect.origin.x);
            shutterRect.size.width = roundf( shutterRect.size.width);
            shutterRect.size.height = roundf( shutterRect.size.height);
            
            if( shutterRect.origin.x < 0) { shutterRect.size.width += shutterRect.origin.x; shutterRect.origin.x = 0;}
            if( shutterRect.origin.y < 0) { shutterRect.size.height += shutterRect.origin.y; shutterRect.origin.y = 0;}
            
            if( shutterRect.origin.x + shutterRect.size.width > [self pwidth]) shutterRect.size.width = [self pwidth] - shutterRect.origin.x;
            
            if( shutterRect.origin.y + shutterRect.size.height > [self pheight]) shutterRect.size.height = [self pheight] - shutterRect.origin.y;
            
            float *tempMem = malloc( [self pwidth] * [self pheight] * sizeof(float));
            
            if( tempMem)
            {
                float *s = tempMem, m = [self minValueOfSeries]-1024;
                
                long i = [self pwidth] * [self pheight];
                
                while (i-- > 0)
                    *s++ = m;
                
                s = src.data;
                s += (long) ((shutterRect.origin.y * [self pwidth]) + shutterRect.origin.x);
                float *d = tempMem + (long) ((shutterRect.origin.y * [self pwidth]) + shutterRect.origin.x);
                
                i = shutterRect.size.height;
                while( i-- > 0)
                {
                    memcpy( d, s, shutterRect.size.width*4);
                    
                    d += [self pwidth];
                    s += [self pwidth];
                }
                
                if( src.data != [self fImage]) free( src.data);
                src.data = tempMem;
            }
        }
        
        // Flipping X-Y
        if( xF)
        {
            dst = src;
            dst.data = malloc( dst.height * dst.rowBytes);
            if( dst.data && src.data)
                vImageHorizontalReflect_PlanarF ( &src, &dst, 0);
            
            if( src.data != [self fImage]) free( src.data);
            if( dst.data == nil) return nil;
            src = dst;
            
            rot *= -1.;
        }
        
        if( yF)
        {
            dst = src;
            dst.data = malloc( dst.height * dst.rowBytes);
            if( dst.data && src.data)
                vImageVerticalReflect_PlanarF ( &src, &dst, 0);
            
            if( src.data != [self fImage]) free( src.data);
            if( dst.data == nil) return nil;
            src = dst;
            
            rot *= -1.;
        }
        
        // Scaling
        
        dst.height = [self pheight]*scale * pixelRatio;
        dst.width = [self pwidth]*scale;
        dst.rowBytes = dst.width*4;
        dst.data = malloc( dst.height * dst.rowBytes);
        if( dst.data && src.data)
            vImageScale_PlanarF( &src, &dst, nil, kvImageHighQualityResampling);
        
        // Rotation
        if( src.data != [self fImage])
            free( src.data);
        if( dst.data == nil) return nil;
        
        src = dst;
        
        dst.height = newH;
        dst.width = newW;
        dst.rowBytes = newW*4;
        dst.data = malloc( dst.height * dst.rowBytes);
        
        if( dst.data && src.data)
        {
            int v = r;
            if( v % 90 == 0)
                vImageRotate_PlanarF( &src, &dst, nil, -rot, [self minValueOfSeries], kvImageHighQualityResampling);
            else
                vImageRotate_PlanarF( &src, &dst, nil, -rot, [self minValueOfSeries] + bgO, kvImageHighQualityResampling+kvImageBackgroundColorFill);
        }
        
        if( src.data != [self fImage]) free( src.data);
        if( dst.data == nil) return nil;
    }
    
    DCMPix *newPix = [[self copy] autorelease];
    
    [newPix freefImageWhenDone: NO];
    [newPix setfImage: dst.data];
    [newPix freefImageWhenDone: YES];
    
    newPix.pheight = dst.height;
    newPix.pwidth = dst.width;
    newPix.pixelSpacingX = pixelSpacingX / scale;
    newPix.pixelSpacingY = pixelSpacingX / scale;
    
    // New orientation
    float v[ 9];
    [newPix orientationCorrected: v rotation: r xFlipped: xF yFlipped: yF];
    [newPix setOrientation: v];
    
    // New origin
    float o[ 3];
    NSPoint a = NSMakePoint( dstRect.origin.x, dstRect.origin.y);
    a = [DCMPix rotatePoint: a aroundPoint: centerPt angle: -rot];
    if( xF) a.x = newWidth - a.x -1;
    if( yF) a.y = newHeight - a.y -1;
    [self convertPixX: a.x/scale pixY: a.y/scale toDICOMCoords: o pixelCenter: NO];
    [newPix setOrigin: o];
    
    return newPix;
}

- (DCMPix*) renderInRectSize:(NSSize) rectSize atPosition:(NSPoint) oo rotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF;
{
    return [self renderInRectSize: rectSize atPosition: oo rotation: r scale: scale xFlipped: xF yFlipped:  yF smartCrop: YES];
}

- (DCMPix*) renderInRectSize:(NSSize) rectSize atPosition:(NSPoint) oo rotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF smartCrop: (BOOL) smartCrop;
{
    if( [self isRGB]) return nil;
    
    DCMPix *newPix = [self renderWithRotation: r scale: scale xFlipped: xF yFlipped:  yF backgroundOffset: 0];
    if( newPix == nil) return nil;
    
    vImage_Buffer src;
    vImage_Buffer dst;
    
    src.height = [newPix pheight];
    src.width = [newPix pwidth];
    src.rowBytes = src.width*4;
    src.data = [newPix fImage];
    
    if( xF) oo.x = - oo.x;
    if( yF) oo.y = - oo.y;
    
    oo = [DCMPix rotatePoint: oo aroundPoint:NSMakePoint( 0, 0) angle: -r*deg2rad];
    
    // zero coordinate is in the center of the view
    NSPoint cov = NSMakePoint( rectSize.width/2 + oo.x - [newPix pwidth]/2, rectSize.height/2 - oo.y - [newPix pheight]/2);
    
    if( smartCrop)	// remove the black part of the image
    {
        NSRect usefulRect;
        
        usefulRect.origin = cov;
        usefulRect.size.width = [newPix pwidth];
        usefulRect.size.height = [newPix pheight];
        
        NSRect frameRect;
        
        frameRect.size = rectSize;
        frameRect.origin.x = frameRect.origin.y = 0;
        
        NSRect smartRect = NSIntersectionRect( frameRect, usefulRect);
        
        rectSize.height = smartRect.size.height;
        rectSize.width = smartRect.size.width;
        
        cov.x -= smartRect.origin.x;
        cov.y -= smartRect.origin.y;
    }
    
    cov.x = (int) cov.x;
    cov.y = (int) cov.y;
    
    dst.height = round( rectSize.height);
    dst.width = round( rectSize.width);
    dst.rowBytes = dst.width*4;
    dst.data = malloc( dst.height * dst.rowBytes);
    
    if( dst.data)
        [self drawImage: &src inImage: &dst offset: cov background: [self minValueOfSeries]-1024];
    else return nil;
    
    DCMPix *rPix = [[newPix copy] autorelease];
    
    [rPix freefImageWhenDone: NO];
    [rPix setfImage: dst.data];
    [rPix freefImageWhenDone: YES];
    
    rPix.pheight = dst.height;
    rPix.pwidth = dst.width;
    
    // New origin
    float o[ 3];
    [rPix convertPixX: -cov.x pixY: -cov.y toDICOMCoords: o pixelCenter: NO];
    [rPix setOrigin: o];
    
    return rPix;
}

- (NSImage*) renderNSImageInRectSize:(NSSize) rectSize atPosition:(NSPoint) oo rotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF
{
    if( [self isRGB]) return nil;
    
    DCMPix *newPix = [self renderInRectSize: rectSize atPosition: oo rotation: r scale: scale xFlipped: xF yFlipped: yF];
    
    [newPix changeWLWW: [newPix wl] :[newPix ww]];
    
    return [newPix image];
}

-(void) orientationDouble:(double*) c
{
    [self CheckLoad];
    
    for( int i = 0 ; i < 9; i ++) c[ i] = orientation[ i];
}

-(BOOL) identicalOrientationTo:(DCMPix*) c
{
    double o[ 9];
    
    [c orientationDouble: o];
    
    for( int i = 0 ; i < 9; i ++)
    {
        if( fabs( o[ i] - orientation[ i]) > ORIENTATION_SENSIBILITY) return NO;
    }
    
    return YES;
}

-(void) orientation:(float*) c
{
    [self CheckLoad];
    
    for( int i = 0 ; i < 9; i ++) c[ i] = orientation[ i];
}

-(void) setOrientationDouble:(double*) c
{
    for( int i = 0 ; i < 6; i ++) orientation[ i] = c[ i];
    
    double length = sqrt(orientation[0]*orientation[0] + orientation[1]*orientation[1] + orientation[2]*orientation[2]);
    
    if( length)
    {
        orientation[0] = orientation[ 0] / length;
        orientation[1] = orientation[ 1] / length;
        orientation[2] = orientation[ 2] / length;
    }
    
    length = sqrt(orientation[3]*orientation[3] + orientation[4]*orientation[4] + orientation[5]*orientation[5]);
    
    if( length)
    {
        orientation[3] = orientation[ 3] / length;
        orientation[4] = orientation[ 4] / length;
        orientation[5] = orientation[ 5] / length;
    }
    
    // Compute normal vector
    orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
    orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
    orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
    
    length = sqrt(orientation[6]*orientation[6] + orientation[7]*orientation[7] + orientation[8]*orientation[8]);
    
    if( length)
    {
        orientation[6] = orientation[ 6] / length;
        orientation[7] = orientation[ 7] / length;
        orientation[8] = orientation[ 8] / length;
    }
}

-(void) setOrientation:(float*) c
{
    double d[ 6];
    
    for( int i = 0 ; i < 6; i ++) d[ i] = c[ i];
    
    [self setOrientationDouble: d];
}

- (BOOL) is3DPlane
{
    if( orientation[6] != 0 || orientation[7] != 0 || orientation[8] != 0)
        return  YES;
    else
        return NO;
}

-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d pixelCenter: (BOOL) pixelCenter
{
    if( pixelCenter)
    {
        x -= 0.5;
        y -= 0.5;
    }
    
    if( orientation[6] != 0 || orientation[7] != 0 || orientation[8] != 0)
    {
        d[0] = originX + y*orientation[3]*pixelSpacingY + x*orientation[0]*pixelSpacingX;
        d[1] = originY + y*orientation[4]*pixelSpacingY + x*orientation[1]*pixelSpacingX;
        d[2] = originZ + y*orientation[5]*pixelSpacingY + x*orientation[2]*pixelSpacingX;
    }
    else
    {
        d[0] = originX + x*pixelSpacingX;
        d[1] = originY + y*pixelSpacingY;
        d[2] = originZ;
    }
}

-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d
{
    [self convertPixX: x pixY: y toDICOMCoords: d pixelCenter: YES];
}

-(void) convertPixDoubleX: (double) x pixY: (double) y toDICOMCoords: (double*) d pixelCenter: (BOOL) pixelCenter
{
    if( pixelCenter)
    {
        x -= 0.5;
        y -= 0.5;
    }
    
    if( orientation[6] != 0 || orientation[7] != 0 || orientation[8] != 0)
    {
        d[0] = originX + y*orientation[3]*pixelSpacingY + x*orientation[0]*pixelSpacingX;
        d[1] = originY + y*orientation[4]*pixelSpacingY + x*orientation[1]*pixelSpacingX;
        d[2] = originZ + y*orientation[5]*pixelSpacingY + x*orientation[2]*pixelSpacingX;
    }
    else
    {
        d[0] = originX + x*pixelSpacingX;
        d[1] = originY + y*pixelSpacingY;
        d[2] = originZ;
    }
}

-(void) convertPixDoubleX: (double) x pixY: (double) y toDICOMCoords: (double*) d
{
    [self convertPixDoubleX: x pixY: y toDICOMCoords: d pixelCenter: YES];
}

-(void) convertDICOMCoords: (float*) dc toSliceCoords: (float*) sc pixelCenter:(BOOL) pixelCenter
{
    float temp[ 3 ];
    
    temp[ 0 ] = dc[ 0 ] - originX;
    temp[ 1 ] = dc[ 1 ] - originY;
    temp[ 2 ] = dc[ 2 ] - originZ;
    
    sc[ 0 ] = temp[ 0 ] * orientation[ 0 ] + temp[ 1 ] * orientation[ 1 ] + temp[ 2 ] * orientation[ 2 ];
    sc[ 1 ] = temp[ 0 ] * orientation[ 3 ] + temp[ 1 ] * orientation[ 4 ] + temp[ 2 ] * orientation[ 5 ];
    sc[ 2 ] = temp[ 0 ] * orientation[ 6 ] + temp[ 1 ] * orientation[ 7 ] + temp[ 2 ] * orientation[ 8 ];
    
    if( pixelCenter)
    {
        sc[ 0 ] += pixelSpacingX /2.;	// The center of the pixel
        sc[ 1 ] += pixelSpacingY /2.;	// The center of the pixel
    }
}

- (void) getSliceCenter3DCoords: (float*) center
{
    if( center == nil)
        return;
    
    [self convertPixX: self.pwidth/2 pixY: self.pheight/2 toDICOMCoords: center];
}

- (void) convertDICOMCoords: (float*) dc toSliceCoords: (float*) sc
{
    [self convertDICOMCoords: dc toSliceCoords:  sc pixelCenter: YES];
}

- (void) convertDICOMCoordsDouble: (double*) dc toSliceCoords: (double*) sc pixelCenter:(BOOL) pixelCenter
{
    double temp[ 3 ];
    
    temp[ 0 ] = dc[ 0 ] - originX;
    temp[ 1 ] = dc[ 1 ] - originY;
    temp[ 2 ] = dc[ 2 ] - originZ;
    
    sc[ 0 ] = temp[ 0 ] * orientation[ 0 ] + temp[ 1 ] * orientation[ 1 ] + temp[ 2 ] * orientation[ 2 ];
    sc[ 1 ] = temp[ 0 ] * orientation[ 3 ] + temp[ 1 ] * orientation[ 4 ] + temp[ 2 ] * orientation[ 5 ];
    sc[ 2 ] = temp[ 0 ] * orientation[ 6 ] + temp[ 1 ] * orientation[ 7 ] + temp[ 2 ] * orientation[ 8 ];
    
    if( pixelCenter)
    {
        sc[ 0 ] += pixelSpacingX /2.;	// The center of the pixel
        sc[ 1 ] += pixelSpacingY /2.;	// The center of the pixel
    }
}

- (void) convertDICOMCoordsDouble: (double*) dc toSliceCoords: (double*) sc
{
    [self convertDICOMCoordsDouble: dc toSliceCoords: sc pixelCenter: YES];
}

+(int) nearestSliceInPixelList: (NSArray*)pixList withDICOMCoords: (float*)dicomCoords sliceCoords: (float*)nearestSliceCoords
{
    
    unsigned int count = (unsigned int)pixList.count, nearestSliceIndx = 0;
    
    float minDist = MAXFLOAT;
    
    for ( unsigned int i = 0; i < count; i++)
    {
        float sliceCoords[ 3 ];
        DCMPix *pix = [pixList objectAtIndex: i];
        [pix convertDICOMCoords: dicomCoords toSliceCoords: sliceCoords];
        if ( fabs( sliceCoords[ 2 ]) < minDist)
        {
            minDist = fabs( sliceCoords[ 2 ]);
            memcpy( nearestSliceCoords, sliceCoords, sizeof sliceCoords);
            nearestSliceIndx = i;
        }
    }
    
    return nearestSliceIndx;
}


- (void)computePixMinPixMax
{
    float pixmin, pixmax;
    
    if( fImage == nil || width * height <= 0) return;
    
    [checking lock];
    
    @try
    {
        if( isRGB)
        {
            pixmax = 255;
            pixmin = 0;
        }
        else
        {
            float fmin, fmax;
            
            vDSP_minv ( fImage,  1, &fmin, width * height);
            vDSP_maxv ( fImage , 1, &fmax, width * height);
            
            pixmax = fmax;
            pixmin = fmin;
            
            if( pixmin == pixmax)
            {
                pixmax = pixmin + 20;
            }
        }
        
        fullwl = pixmin + (pixmax - pixmin)/2;
        fullww = (pixmax - pixmin);
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [checking unlock];
}

- (short)stack{ if( stackMode == 0) return 1; return stack; }

- (void)setFusion: (short)m : (short)s : (short)direction
{
    if( s >= 0) stack = s;
    if( m >= 0) stackMode = m;
    if( direction >= 0) stackDirection = direction;
    
    updateToBeApplied = YES;
    needToCompute8bitRepresentation = YES;
}

- (void)setSourceFile:(NSString *)s {
    self.srcFile = s;
}

- (NSString *)sourceFile {
    return self.srcFile;
}

- (void) ConvertToBW:(long) mode
{
    if( isRGB == NO) return;
    
    long			i;
    float			*dstPtr = malloc( height * width * 4);
    
    if( dstPtr)
    {
        unsigned char   *srcPtr = (unsigned char*) [self fImage];
        
        // Set this image as the Red Composant
        switch( mode)
        {
            case 0: // RED
                i = height * width;
                while( i-- > 0) dstPtr[ i] = srcPtr[ i*4 + 1];
                break;
                
            case 1: // GREEN
                i = height * width;
                while( i-- > 0) dstPtr[ i] = srcPtr[ i*4 + 2];
                break;
                
            case 2: // BLUE
                i = height * width;
                while( i-- > 0) dstPtr[ i] = srcPtr[ i*4 + 3];
                break;
                
            case 3: // RGB
                i = height * width;
                while( i-- > 0) dstPtr[ i] = ((float) srcPtr[ i*4 + 1] + (float) srcPtr[ i*4 + 2] + (float) srcPtr[ i*4 + 3]) / 3.;
                break;
        }
        
        [self setBaseAddr: malloc( [self pwidth] * [self pheight])];
        
        [self setRGB: NO];
        
        memcpy( fImage, dstPtr, height * width * 4);
        
        [self changeWLWW:wl :ww];
        
        free( dstPtr);
    }
}



- (void)ConvertToRGB:(long) mode :(long) cwl :(long) cww
{
    vImage_Buffer		srcf, dst8, dst8888;
    
    if( isRGB) return;
    
    srcf.height = [self pheight];
    srcf.width = [self pwidth];
    srcf.rowBytes =  [self pwidth]*sizeof(float);
    srcf.data =  [self fImage];
    
    dst8.height = [self pheight];
    dst8.width = [self pwidth];
    dst8.rowBytes = [self pwidth];
    dst8.data = malloc( [self pheight] * [self pwidth]);
    
    long i;
    long min = cwl - cww / 2;
    long max = cwl + cww / 2;
    
    vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, max, min, 0);					// FLOAT TO 8 bit
    
    unsigned char*  srcPtr = (unsigned char*) dst8.data;
    unsigned char*  dstPtr = (unsigned char*) [self fImage];
    
    // Set this image as the Red Composant
    switch( mode)
    {
        case 0: // RED
            memset( [self fImage], 0, dst8.height * dst8.width * 4);
            i = dst8.height * dst8.width;
            while( i-- > 0) dstPtr[ i*4 + 1] = srcPtr[ i];
            break;
            
        case 1: // GREEN
            memset( [self fImage], 0, dst8.height * dst8.width * 4);
            i = dst8.height * dst8.width;
            while( i-- > 0) dstPtr[ i*4 + 2] = srcPtr[ i];
            break;
            
        case 2: // BLUE
            memset( [self fImage], 0, dst8.height * dst8.width * 4);
            i = dst8.height * dst8.width;
            while( i-- > 0) dstPtr[ i*4 + 3] = srcPtr[ i];
            break;
            
        case 3: // RGB
            dst8888 = dst8;
            dst8888.rowBytes = [self pwidth]*4;
            dst8888.data =[self fImage];
            
            vImageConvert_Planar8toARGB8888(&dst8, &dst8, &dst8, &dst8, &dst8888, 0);
            break;
    }
    
    [self setBaseAddr: malloc( [self pwidth] * [self pheight] * 4)];
    
    [self setRGB: YES];
    
    [self changeWLWW:127 :256];
    
    free( dst8.data);
    
    if( isRGB)
    {
        unsigned char*	argbPtr = (unsigned char*) fImage;
        long			ss = width * height;
        
        while( ss-->0)
        {
            *argbPtr = (*(argbPtr+1) + *(argbPtr+2) + *(argbPtr+3)) / 3;
            argbPtr+=4;
        }
    }
}

-(BOOL) thickSlabVRActivated
{
    return thickSlabVRActivated;
}

- (void) setThickSlabController:( ThickSlabController*) ts
{
    thickSlab = ts;
}

-(void) setFixed8bitsWLWW:(BOOL) f
{
    fixed8bitsWLWW = f;
}

- (float) getPixelValueX: (long) x Y:(long) y
{
    float val = 0;
    
    if( x < 0 || x >= width || y < 0 || y >= height) return 0;
    if( fImage == nil) return 0;
    
    if( (stackMode == 1 || stackMode == 2 || stackMode == 3) && stack >= 1)
    {
        float   *fNext = nil;
        long	countstack = 0;
        
        val = fImage[ x + (y * width)];
        countstack++;
        
        for( long i = 1; i < stack; i++)
        {
            long next;
            if( stackDirection) next = pixPos-i;
            else next = pixPos+i;
            
            if( next < pixArray.count && next >= 0)
            {
                fNext = [[pixArray objectAtIndex: next] fImage];
                if( fNext)
                {
                    if( isRGB == NO)
                    {
                        switch( stackMode)
                        {
                            case 1:		val += fNext[ x + (y * width)];										break;
                            case 2:		if( fNext[ x + (y * width)] > val) val = fNext[ x + (y * width)];	break;
                            case 3:		if( fNext[ x + (y * width)] < val) val = fNext[ x + (y * width)];	break;
                        }
                    }
                    else
                    {
                        unsigned char *rgbPtr = (unsigned char*) (&fNext[ x + (y * width)]);
                        
                        float meanRGBValue = (rgbPtr[ 1] + rgbPtr[ 2] + rgbPtr[ 3])/3.;
                        
                        switch( stackMode)
                        {
                            case 1:		val += meanRGBValue;                        break;
                            case 2:		if( meanRGBValue > val) val = meanRGBValue;	break;
                            case 3:		if( meanRGBValue < val) val = meanRGBValue;	break;
                        }
                    }
                    countstack++;
                }
            }
        }
        
        if( stackMode == 1) val /= countstack;
    }
    else
    {
        if( isRGB == NO)
            val = fImage[ x + (y * width)];
        else
        {
            unsigned char *rgbPtr = (unsigned char*) (&fImage[ x + (y * width)]);
            val = (rgbPtr[ 1] + rgbPtr[ 2] + rgbPtr[ 3])/3.;
        }
    }
    
    return val;
}

#pragma mark-
#pragma mark subtraction and changeWLWW

-(void) imageArithmeticMultiplication:(DCMPix*) sub
{
    float   *temp;	
    temp = [self multiplyImages: fImage :[sub fImage]];	
    memcpy( fImage, temp, height * width * sizeof(float));	
    free( temp);
}

-(float*) multiplyImages :(float*) input :(float*) subfImage
{
    long	i = height * width;
    float   *result = malloc( height * width * sizeof(float));
    
    if( subPixOffset.x == 0 && subPixOffset.y == 0)
    {
#if __ppc__ || __ppc64__
        if( Altivec) vmultiply( (vector float *)input, (vector float *)subfImage, (vector float *)result, i);
        else
#endif
            vmultiplyNoAltivec(input, subfImage, result, i);
    }
    else
    {
        long	x, y;
        long	offsetX = subPixOffset.x, offsetY = -subPixOffset.y;
        long	startheight, subheight, startwidth, subwidth;
        float   *tempIn, *tempOut, *tempResult;
        
        if( offsetY > 0)
        { startheight = offsetY;   subheight = height;}
        else { startheight = 0; subheight = height + offsetY;}
        
        if( offsetX > 0)
        { startwidth = offsetX;   subwidth = width;}
        else { startwidth = 0; subwidth = width + offsetX;}
        
        for( y = startheight; y < subheight; y++)
        {
            tempResult = result + y*width;
            tempIn = input + y*width;
            tempOut = subfImage + (y-offsetY)*width - offsetX;
            x = subwidth - startwidth;
            while( x-->0)
            {
                *tempResult++ = *tempIn++ * *tempOut++;
            }
        }
    }
    return result;
}

-(void) imageArithmeticSubtraction:(DCMPix*) sub
{
    [self imageArithmeticSubtraction: sub absolute: NO];
}

-(void) imageArithmeticSubtraction:(DCMPix*) sub absolute:(BOOL) abs
{
    //	float   *temp = [sub fImage];
    //	vDSP_vsub (temp,1,fImage,1,fImage,1,height * width * sizeof(float));
    float   *temp;	
    temp = [self arithmeticSubtractImages: fImage :[sub fImage] absolute: abs];
    memcpy( fImage, temp, height * width * sizeof(float));	
    free( temp);
}

-(float*) arithmeticSubtractImages :(float*) input :(float*) subfImage
{
    return [self arithmeticSubtractImages: input : subfImage absolute: NO];
}

-(float*) arithmeticSubtractImages :(float*) input :(float*) subfImage absolute:(BOOL) abs
{
    long	i = height * width;
    float   *result = malloc( height * width * sizeof(float));
    
    if( subPixOffset.x == 0 && subPixOffset.y == 0)
    {
#if __ppc__ || __ppc64__
        if( Altivec)
        {
            if (abs)
                vsubtractAbs( (vector float *)input, (vector float *)subfImage, (vector float *)result, i);
            else
                vsubtract( (vector float *)input, (vector float *)subfImage, (vector float *)result, i);
        }
        else
#endif
        {
            if (abs)
                vsubtractNoAltivecAbs(input, subfImage, result, i);
            else
                vsubtractNoAltivec(input, subfImage, result, i);
        }
    }
    else
    {
        long	offsetX = subPixOffset.x, offsetY = -subPixOffset.y;
        long	startheight, subheight, startwidth, subwidth;
        float   *tempIn, *tempOut, *tempResult;
        
        if( offsetY > 0)
        { startheight = offsetY;   subheight = height;}
        else { startheight = 0; subheight = height + offsetY;}
        
        if( offsetX > 0)
        { startwidth = offsetX;   subwidth = width;}
        else { startwidth = 0; subwidth = width + offsetX;}
        
        if( abs)
        {
            for( long y = startheight; y < subheight; y++)
            {
                tempResult = result + y*width;
                tempIn = input + y*width;
                tempOut = subfImage + (y-offsetY)*width - offsetX;
                long x = subwidth - startwidth;
                while ( x-- > 0)
                {
                    *tempResult++ = fabsf(*tempIn++ - *tempOut++);
                }
            }
        }
        else
        {
            for( long y = startheight; y < subheight; y++)
            {
                tempResult = result + y*width;
                tempIn = input + y*width;
                tempOut = subfImage + (y-offsetY)*width - offsetX;
                long x = subwidth - startwidth;
                while ( x-- > 0)
                {
                    *tempResult++ = *tempIn++ - *tempOut++;
                }
            }
        }
    }
    return result;
}


//----------------------------Subtraction parameters copied to each Pix---------------------------

- (void)setSubSlidersPercent: (float)p gamma: (float)g zero: (float)z
{
    subtractedfPercent = p;
    subtractedfZ = z;
    subtractedfZero = subtractedfZ - 0.8 + (p*0.8);
    subtractedfGamma = g;
    
    if( subGammaFunction) vImageDestroyGammaFunction( subGammaFunction);
    
    subGammaFunction = vImageCreateGammaFunction( subtractedfGamma, kvImageGamma_UseGammaValue_half_precision, 0);	
    
    updateToBeApplied = YES;
}

- (void) setSubSlidersPercent: (float) p
{
    [self setSubSlidersPercent: p gamma: subtractedfGamma zero: subtractedfZ];
}

- (void)setSubPixOffset:(NSPoint) subOffset
{
    subPixOffset = subOffset;
    updateToBeApplied = YES;
}

//----- Min and Max of the subtracted result of all the Pix of the series for a given subfImage------

-(NSPoint) subMinMax:(float*)input :(float*)subfImage
{
    long			i			= height * width;	
    float			*result		= malloc( i * sizeof(float));
    float			r;
    
    vDSP_vsub (subfImage,1,input,1,result,1,i);		//mask - frame
    vDSP_minv (result,1,&r,i);						//black pixel
    subMinMax.x = r;
    vDSP_maxv (result,1,&r,i);						//white pixel
    subMinMax.y = r;
    
    free( result);
    
    return subMinMax;
}

- (void) setSubtractedfImage:(float*)mask :(NSPoint)smm
{
    subtractedfImage = mask;
    subMinMax = smm;	
    updateToBeApplied = YES;
}

//------------------------------------------subtraction--------------------------------------------

-(float*) subtractImages:(float*)input :(float*)subfImage
{
    long	firstPixel = subPixOffset.y * width - subPixOffset.x;			
    long	firstPixelAbs = labs((int)subPixOffset.y * width) + labs((int)subPixOffset.x);
    float	*firstSourcePixel = subfImage + (firstPixelAbs + firstPixel)/2;
    long	i = height * width;	
    float	*result = malloc( i * sizeof(float));
    
    if (result == nil) return input;
    
    float	*firstResultPixel = result + (firstPixelAbs - firstPixel)/2;
    long	lengthToBeCopied = i - firstPixelAbs;
    
    //preparing mask: the following command registers it in function of the pixel shift, and multiplies it by % 
    vDSP_vsmul (firstSourcePixel,1,&subtractedfPercent,firstResultPixel,1,lengthToBeCopied);//result= % mask	
    
    vDSP_vsub (result,1,input,1,result,1,lengthToBeCopied);				//mask - frame
    
    float ratio = fabs(subMinMax.y-subMinMax.x);						//Max difference in subtraction without pixel shift
    if( ratio == 0) ratio = 1;
    vDSP_vsdiv (result,1,&ratio,result,1,i);							//normalize result [-1...1]
    vDSP_vsadd (result,1,&subtractedfZero,result,1,i);					//normalize result [0...n]
    
    if( input != fImage) free( input);
    
    return result;
}

-(void) fImageTime:(float)newTime {fImageTime = newTime;}
-(float) fImageTime {return fImageTime;}
-(void) maskID:(long)newID {maskID = newID;}
-(long) maskID {return maskID;}
-(void) maskTime:(float)newMaskTime {maskTime = newMaskTime;}
-(float) maskTime {return maskTime;}

-(void) positionerPrimaryAngle:(NSNumber*)newPositionerPrimaryAngle
{
    if( positionerPrimaryAngle != newPositionerPrimaryAngle)
    {
        [positionerPrimaryAngle release];
        positionerPrimaryAngle = [newPositionerPrimaryAngle retain];
    }
}
-(NSNumber*) positionerPrimaryAngle{return positionerPrimaryAngle;}
-(void) positionerSecondaryAngle:(NSNumber*)newPositionerSecondaryAngle
{
    if( positionerSecondaryAngle != newPositionerSecondaryAngle)
    {
        [positionerSecondaryAngle release];
        positionerSecondaryAngle = [newPositionerSecondaryAngle retain];
    }
}
-(NSNumber*) positionerSecondaryAngle{return positionerSecondaryAngle;}

-(void) setShutterRect:(NSRect) s
{
    shutterRect  = s;
    
    if( shutterPolygonal)
    {
        free( shutterPolygonal);
        shutterPolygonal = nil;
    }
}

-(void) setShutterEnabled:(BOOL) v
{
    shutterEnabled = v;
    updateToBeApplied = YES;
}

- (void) setBlackIndex:(int) i
{
    blackIndex = i;
}

-(void) applyShutter
{
    if (shutterEnabled == NSOnState)
    {
        if( shutterRect.origin.x < 0) { shutterRect.size.width += shutterRect.origin.x; shutterRect.origin.x = 0;}
        if( shutterRect.origin.y < 0) { shutterRect.size.height += shutterRect.origin.y; shutterRect.origin.y = 0;}
        
        if( shutterRect.size.width + shutterRect.origin.x > width) shutterRect.size.width = width - shutterRect.origin.x;
        if( shutterRect.size.height + shutterRect.origin.y > height) shutterRect.size.height = height - shutterRect.origin.y;
        
        shutterRect.origin.y = roundf( shutterRect.origin.y);
        shutterRect.origin.x = roundf( shutterRect.origin.x);
        shutterRect.size.width = roundf( shutterRect.size.width);
        shutterRect.size.height = roundf( shutterRect.size.height);
        
        if( isRGB == YES || thickSlabVRActivated == YES)
        {
            char*	tempMem = calloc( 1, height * width * 4 * sizeof(char));
            
            if( tempMem)
            {
                int i = shutterRect.size.height;
                
                char*	src = baseAddr + (long) ((shutterRect.origin.y * width*4) + shutterRect.origin.x*4);
                char*	dst = tempMem + (long) ((shutterRect.origin.y * width*4) + shutterRect.origin.x*4);
                
                while( i-- > 0)
                {
                    memcpy( dst, src, shutterRect.size.width*4);
                    
                    dst += width*4;
                    src += width*4;
                }
                
                memcpy(baseAddr, tempMem, height * width * 4*sizeof(char));
                
                free( tempMem);
            }
        }
        else
        {
            char*	tempMem = malloc( height * width * sizeof(char));
            
            if( tempMem)
            {
                memset( tempMem, blackIndex, height * width * sizeof(char));
                
                int i = shutterRect.size.height;
                
                char*	src = baseAddr + (long) ((shutterRect.origin.y * width) + shutterRect.origin.x);
                char*	dst = tempMem + (long) ((shutterRect.origin.y * width) + shutterRect.origin.x);
                
                while( i-- > 0)
                {
                    memcpy( dst, src, shutterRect.size.width);
                    
                    dst += width;
                    src += width;
                }
                
                if( shutterCircular_radius)
                {
                    erase_outside_circle(tempMem, (int)width, (int)height, shutterCircular.x, shutterCircular.y, (int)shutterCircular_radius, blackIndex);
                }
                
                if( shutterPolygonal)
                {
                    int		x, y;
                    
                    for( y = 0 ; y < height; y++)
                    {
                        for( x = 0 ; x < width; x++)
                        {
                            if( pnpoly( shutterPolygonal, shutterPolygonalSize, x, y) == 0)
                            {
                                tempMem[ x + y*width] = blackIndex;
                            }
                        }
                    }
                }
                
                memcpy(baseAddr, tempMem, height * width * sizeof(char));
                
                free( tempMem);
            }
        }
    }
}

- (float*) applyConvolutionOnImage:(float*) src RGB:(BOOL) color
{
    float *result = src;
    
    @try
    {
        [self CheckLoad]; 
        
        vImage_Buffer dstf, srcf;
        
        dstf.height = height;
        dstf.width = width;
        dstf.rowBytes = width*sizeof(float);
        dstf.data = src;
        
        srcf = dstf;
        srcf.data = result = malloc( height*width*sizeof(float));
        if( srcf.data && dstf.data)
        {
            short err;
            
            if( color)
            {
                int16_t intKernel[ 25];
                
                for( int i = 0; i < kernelsize*kernelsize; i++)
                    intKernel[ i] = kernel[ i];
                
                err = vImageConvolve_ARGB8888( &dstf, &srcf, 0, 0, 0, intKernel, kernelsize, kernelsize, normalization, 0, kvImageDoNotTile + kvImageLeaveAlphaUnchanged + kvImageEdgeExtend);
            }
            else
            {
                float  fkernel[25], m;
                int i;
                
                if( normalization != 0)
                    for( i = 0; i < 25; i++) fkernel[ i] = (float) kernel[ i] / (float) normalization; 
                else
                    for( i = 0; i < 25; i++) fkernel[ i] = (float) kernel[ i]; 
                
                m = *src;
                err = vImageConvolve_PlanarF( &dstf, &srcf, 0, 0, 0, fkernel, kernelsize, kernelsize, 0, kvImageDoNotTile + kvImageEdgeExtend);
                
                // check the first line to avoid nan value....
                
                float *ptr = result;
                int x = (int)width;
                while( x-- > 0)
                    *ptr++ = m;
            }
            
            if( err) NSLog(@"Error applyConvolutionOnImage = %d", err);
            
            if( src != fImage)
                free( src);
        }
        
        
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    return result;
}

- (void) applyConvolutionOnSourceImage
{
    [self CheckLoad];
    
    float *result = [self applyConvolutionOnImage: fImage RGB: isRGB];
    
    if( result != fImage)
    {
        memcpy( fImage, result, height*width*sizeof(float));
        free( result);
    }
}

- (float*) computeThickSlabRGB
{
    //	long			diff;
    float			*fNext = NULL;
    float			*fResult = malloc( height * width * sizeof(float));
    long			next;
    float			min, max, iwl, iww;
    
    if( fResult == nil)
        return nil;
    
    if( fixed8bitsWLWW)	{
        iww = 256;
        iwl = 127;
    }
    else {
        iww = ww;
        iwl = wl;
    }
    
    min = iwl - iww / 2; 
    max = iwl + iww / 2;
    //	diff = max - min;
    
    switch( stackMode)
    {
        case 4:		// Volume Rendering
        case 5:
            memcpy( fResult, fImage, height * width * sizeof(float));
            break;
            
        case 1:		// Mean
            memcpy( fResult, fImage, height * width * sizeof(float));
            break;
            
        case 2:		// Maximum IP
        case 3:		// Minimum IP
            if( stackDirection) next = pixPos-1;
            else next = pixPos+1;
            
            if( next < pixArray.count  && next >= 0)
            {
                fNext = [[pixArray objectAtIndex: next] fImage];
                if( fNext)
                {
#if __arm64__
                    if( stackMode == 2) vmax8ARM( (vUInt8*) fNext, (vUInt8*) fImage, (vUInt8*) fResult, height * width);
                    else vmin8ARM( (vUInt8*) fNext, (vUInt8*) fImage, (vUInt8*) fResult, height * width);
#else
                    if( stackMode == 2) vmax8Intel( (vUInt8*) fNext, (vUInt8*) fImage, (vUInt8*) fResult, height * width);
                    else vmin8Intel( (vUInt8*) fNext, (vUInt8*) fImage, (vUInt8*) fResult, height * width);
#endif
                }
                
                for( long i = 2; i < stack; i++)
                {
                    long res;
                    if( stackDirection) res = pixPos-i;
                    else res = pixPos+i;
                    
                    if( res < pixArray.count)
                    {
                        long res;
                        if( stackDirection) res = pixPos-i;
                        else res = pixPos+i;
                        
                        if( res < pixArray.count && res >= 0)
                        {
                            fNext = [[pixArray objectAtIndex: res] fImage];
                            if( fNext)
                            {
#if __arm64__
                                if( stackMode == 2) vmax8ARM( (vUInt8*) fNext, (vUInt8*) fImage, (vUInt8*) fResult, height * width);
                                else vmin8ARM( (vUInt8*) fNext, (vUInt8*) fImage, (vUInt8*) fResult, height * width);
#else
                                if( stackMode == 2) vmax8Intel( (vUInt8*) fResult, (vUInt8*) fNext, (vUInt8*) fResult, height * width);
                                else vmin8Intel( (vUInt8*) fResult, (vUInt8*) fNext, (vUInt8*) fResult, height * width);
#endif
                            }
                        }
                    }
                }
            }
            else
            {
                memcpy( fResult, fImage, height * width * sizeof(float));
            }
            break;			
    } //end of switch
    
    return fResult;
}

- (float*) computeThickSlab
{
    long			stacksize;
    unsigned char   *rgbaImage;
    float			iwl, iww;
    float			*fResult = nil;
    
    if( fixed8bitsWLWW)
    {
        iww = 256;
        iwl = 127;
    }
    else
    {
        iww = ww;
        iwl = wl;
    }
    
    //	min = iwl - iww / 2;
    //	max = iwl + iww / 2;
    
    switch( stackMode)
    {
        case 4:		// Volume Rendering
        case 5:		// Volume Rendering
            if( thickSlab)
            {											
                if( stackDirection)
                {
                    if( pixPos-stack < 0) stacksize = pixPos+1; 
                    else stacksize = stack+1;
                }
                else
                {
                    if( pixPos+stack < [pixArray count]) stacksize = stack; 
                    else stacksize = [pixArray count] - pixPos;
                }
                
                if( stackDirection) [thickSlab setImageSource: fImage - (stacksize-1)*height * width :stacksize];
                else [thickSlab setImageSource: fImage :stacksize];
                [thickSlab setWLWW: iwl: iww];
                
                rgbaImage = [thickSlab renderSlab];
                
                thickSlabVRActivated = YES;
                
                [self setBaseAddr: (char*) rgbaImage];
            }
            break;
            
            // ------------------------------------------------------------------------------------------------
        case 1:		// Mean
        case 2:		// Maximum IP
        case 3:		// Minimum IP
            countstackMean = 1;
            
            fResult = malloc( height * width * sizeof(float));
            memcpy( fResult, fImage, height * width * sizeof(float));
            
            if( processorsLock == nil)
                processorsLock = [[NSConditionLock alloc] init];
            
            int numberOfThreadsForCompute = [DCMPix maxProcessors];
            
            if( minmaxThreads == nil)
            {
                minmaxThreads = [[NSMutableArray array] retain];
                
                for( int i = 0; i < numberOfThreadsForCompute; i++)
                {
                    [minmaxThreads addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [[NSConditionLock alloc] initWithCondition: 0], @"threadLock", nil]];
                    
                    [NSThread detachNewThreadSelector: @selector(computeMaxThread:) toTarget: [[PixThread alloc] init] withObject: [minmaxThreads lastObject]];
                }
                
                [NSThread sleepForTimeInterval: 0.01];
            }
            
            [processorsLock lock];
            [processorsLock unlockWithCondition: numberOfThreadsForCompute];
            
            for( int i = 0; i < numberOfThreadsForCompute; i++)
            {
                NSMutableDictionary *d = [minmaxThreads objectAtIndex: i];
                
                [d setObject: [NSValue valueWithPointer: fResult] forKey: @"fResult"];
                [d setObject: [NSNumber numberWithInt: i] forKey: @"pos"];
                [d setObject: self forKey: @"self"];
                
                [[d objectForKey: @"threadLock"] lock];
                [[d objectForKey: @"threadLock"] unlockWithCondition: 1];
            }
            
            [processorsLock lockWhenCondition: 0];
            for( int i = 0; i < numberOfThreadsForCompute; i++)
            {
                NSMutableDictionary *d = [minmaxThreads objectAtIndex: i];
                [d setObject: [NSValue valueWithPointer: nil] forKey: @"fResult"];
            }
            [processorsLock unlock];
            
            if( countstackMean > 1)
            {
                float   invCount = 1.0f / countstackMean;
                
                vDSP_vsmul( fResult, 1, &invCount, fResult, 1, height * width);
            }
            //-----------------------------------
            break;
    }
    
    return fResult;
}

- (float*)computefImage
{
    float *result;
    
    thickSlabVRActivated = NO;
    
    // = STACK IMAGES thickslab
    if( stackMode > 0 && stack >= 1 && [pixArray count] > 1)
    {
        result = [self computeThickSlab];
    }
    else result = fImage;
    
    if( convolution)
        result = [self applyConvolutionOnImage: result RGB: NO];
    
    return result;
}

- (void)setTransferFunction:(NSData*) tf
{
    if( transferFunction != tf)
    {
        [transferFunction release];
        transferFunction = [tf retain];
        
        transferFunctionPtr = (float*) [transferFunction bytes];
        
        updateToBeApplied = YES;
    }
}

- (void) compute8bitRepresentation
{
    float			iwl, iww;
    
    if( fixed8bitsWLWW)
    {
        iww = 256;
        iwl = 127;
    }
    else
    {
        iww = ww;
        iwl = wl;
    }
    
    if( baseAddr)
    {
        [self CheckLoad];
        
        needToCompute8bitRepresentation = NO;
        
        updateToBeApplied = NO;
        
        float  min, max;
        
        min = iwl - iww / 2; 
        max = iwl + iww / 2;
        
        // ***** ***** ***** ***** ***** 
        // ***** SOURCE IMAGE IS 32 BIT FLOAT
        // ***** ***** ***** ***** *****
        
        if( isRGB == NO) //fImage case
        {
            vImage_Buffer	srcf, dst8;
            
            srcf.data = [self computefImage];
            
            if( srcf.data == nil) return;
            
            // CONVERSION TO 8-BIT for displaying
            
            if( thickSlabVRActivated == NO)
            {
                dst8.height = height;
                dst8.width = width;
                dst8.rowBytes = width;					
                dst8.data = baseAddr;
                
                srcf.height = height;
                srcf.width = width;
                srcf.rowBytes = width*sizeof(float);
                
                if( subtractedfImage)
                {
                    if( wl < 2) wl = 2;
                    if( ww < 2) ww = 2;
                    if( wl > 512) wl = 512;
                    if( ww > 512) ww = 512;
                    
                    iww = ww;
                    iwl = wl;
                    
                    float gamma = 2. * (iww / 256.);
                    float zero = 1.6 - 0.8 * (iwl / 128.);
                    
                    [self setSubSlidersPercent:subtractedfPercent gamma: gamma zero: zero];
                    
                    srcf.data = [self subtractImages: srcf.data :subtractedfImage];
                    
                    vImageGamma_PlanarFtoPlanar8 (&srcf, &dst8, subGammaFunction, 0);
                }
                else
                {
                    if( transferFunctionPtr == nil)	// LINEAR
                    {
                        vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, max, min, 0);
                    }
                    else
                    {
                        if( processorsLock == nil)
                            processorsLock = [[NSConditionLock alloc] init];
                        
                        int numberOfThreadsForCompute = [DCMPix maxProcessors];
                        
                        if( nonLinearWLWWThreads == nil)
                        {
                            nonLinearWLWWThreads = [[NSMutableArray array] retain];
                            
                            for( int i = 0; i < numberOfThreadsForCompute; i++)
                            {
                                [nonLinearWLWWThreads addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [[[NSConditionLock alloc] initWithCondition: 0] autorelease], @"threadLock", nil]];
                                [NSThread detachNewThreadSelector: @selector(applyNonLinearWLWWThread:) toTarget:[[PixThread alloc] init] withObject: [nonLinearWLWWThreads lastObject]];
                            }
                        } 
                        
                        NSValue *srcNSValue = [NSValue valueWithPointer: srcf.data];
                        
                        int start;
                        int end;
                        
                        [processorsLock lock];
                        [processorsLock unlockWithCondition: numberOfThreadsForCompute];
                        
                        for( int i = 0; i < numberOfThreadsForCompute; i++)
                        {
                            start = i * (int) (height / numberOfThreadsForCompute);
                            end = (i+1) * (int) (height / numberOfThreadsForCompute);
                            
                            NSMutableDictionary *d = [nonLinearWLWWThreads objectAtIndex: i];
                            
                            [d setObject: [NSNumber numberWithInt: start] forKey: @"start"];
                            [d setObject: [NSNumber numberWithInt: end] forKey: @"end"];
                            [d setObject: self forKey: @"self"];
                            [d setObject: srcNSValue forKey: @"src"];
                            
                            [[d objectForKey: @"threadLock"] lock];
                            [[d objectForKey: @"threadLock"] unlockWithCondition: 1];
                        }
                        
                        [processorsLock lockWhenCondition: 0];
                        for( int i = 0; i < numberOfThreadsForCompute; i++)
                            [[nonLinearWLWWThreads objectAtIndex: i] removeObjectForKey: @"self"];
                        
                        [processorsLock unlock];
                    }
                    
#ifdef OSIRIX_VIEWER
                    if(isLUT12Bit && [AppController canDisplay12Bit])
                    {
                        NSInvocation *fill12BitBufferInvocation = [AppController fill12BitBufferInvocation];
                        [fill12BitBufferInvocation setArgument:&self atIndex:2];
                        NSValue *srcNSValue = [NSValue valueWithPointer: srcf.data];
                        [fill12BitBufferInvocation setArgument:&srcNSValue atIndex:3];
                        [fill12BitBufferInvocation setArgument:&transferFunctionPtr atIndex:4];
                        [fill12BitBufferInvocation invoke];
                    }
#endif
                }
                
                if( srcf.data != fImage) free( srcf.data);
            }
        }	
        
        // ***** ***** ***** ***** ***** 
        // ***** SOURCE IMAGE IS RGBA
        // ***** ***** ***** ***** *****
        
        if( isRGB)
        {
            vImage_Buffer   src, dst;
            Pixel_8			convTable[256];
            long			diff = max - min, val;
            
            if( stackMode > 0 && stack >= 1 && [pixArray count] > 1)
            {
                src.data = [self computeThickSlabRGB];
            }
            else src.data = fImage;
            
            if( convolution)
                src.data = [self applyConvolutionOnImage: src.data RGB: YES];
            
            // APPLY WINDOW LEVEL TO RGB IMAGE
            
            if( transferFunctionPtr == nil)	// LINEAR
            {
                for( long i = 0; i < 256; i++)
                {
                    val = (((i-min) * 255L) / diff);
                    if( val < 0) val = 0;
                    else if( val > 255) val = 255;
                    convTable[i] = val;
                }
            }
            else
            {
                for( long i = 0; i < 256; i++)
                {
                    val = (((i-min) * 255L) / diff);
                    if( val < 0) val = 0;
                    else if( val > 255) val = 255;
                    
                    val = 255.*transferFunctionPtr[ val*16];	// 4096 value table
                    if( val < 0) val = 0;
                    else if( val > 255) val = 255;
                    convTable[i] = val;
                }
            }
            
            src.height = height;
            src.width = width;
            src.rowBytes = width*4;
            
            dst.height = height;
            dst.width = width;
            dst.rowBytes = width*4;
            dst.data = baseAddr;
            
            vImageTableLookUp_ARGB8888 ( &src,  &dst,  convTable,  convTable,  convTable,  convTable,  0);
            
            if( src.data != fImage) free( src.data);
        }
        
        [self applyShutter];		
    }
}

- (void) changeWLWW:(float)newWL :(float)newWW
{
    if( baseAddr == nil)
    {
        [self checkImageAvailble:newWW :newWL];
        return;
    }
    
    [self CheckLoad]; 
    
    if( newWW !=0 || newWL != 0)   // new values to be applied
    {
        if( fullww > 256)
        {
            if( newWW < 1) newWW = 2;
            
            if( newWL - newWW/2 == 0)
            {
                //				newWW = (int) newWW;
                //				newWL = (int) newWL;
                
                newWL = newWW/2;
            }
            else
            {
                newWW = (int) newWW;
                newWL = (int) newWL;
            }
        }
        
        if( newWW < 0.001 * slope) newWW = 0.001 * slope;
        
        ww = newWW;
        wl = newWL;
    }
    else                          // need to compute best values... problem with subtraction performed afterwards
    {
        [self computePixMinPixMax];
        
        ww = fullww;
        wl = fullwl;
    }
    
    // ----------------------------------------------------------- iww, iwl contain computMinPixMax or newWW, newWL
    
    if( baseAddr)
    {
        needToCompute8bitRepresentation = YES;
    }
}

#pragma mark-

- (void) kill8bitsImage
{
    needToCompute8bitRepresentation = YES;
    if( baseAddr) free( baseAddr);
    baseAddr = nil;
}

- (void)checkImageAvailble: (float)newWW : (float)newWL
{
    [self CheckLoad];
    
    ww = newWW;
    wl = newWL;
    
    if( baseAddr == nil)
        [self allocate8bitRepresentation];
}

- (NSImage*) generateThumbnailImageWithWW: (float)newWW WL: (float)newWL
{
    int destWidth, destHeight;
    NSImage *image = nil;
    float ratio;
    
    [self CheckLoad];
    
    if( (float) width / PREVIEWSIZE > (float) height / PREVIEWSIZE) ratio = (float) width / PREVIEWSIZE;
    else ratio = (float) height / PREVIEWSIZE;
    
    destWidth = (float) width / ratio;
    destHeight = (float) height / ratio;
    
    NSBitmapImageRep *bitmapRep = nil;
    
    if( isRGB)
    {
        bitmapRep = [[[NSBitmapImageRep alloc] 
                      initWithBitmapDataPlanes: nil
                      pixelsWide:destWidth
                      pixelsHigh:destHeight
                      bitsPerSample:8
                      samplesPerPixel:3
                      hasAlpha:NO
                      isPlanar:NO
                      colorSpaceName:NSCalibratedRGBColorSpace
                      bytesPerRow:destWidth*4
                      bitsPerPixel:24
                      ] autorelease];
    }
    else
    {
        bitmapRep = [[[NSBitmapImageRep alloc] 
                      initWithBitmapDataPlanes: nil
                      pixelsWide:destWidth
                      pixelsHigh:destHeight
                      bitsPerSample:8
                      samplesPerPixel:1  // 1-3 // RGB
                      hasAlpha:NO
                      isPlanar:NO
                      colorSpaceName:NSCalibratedWhiteColorSpace
                      bytesPerRow:destWidth
                      bitsPerPixel:8 // 8 - 24 -32
                      ] autorelease];
    }
    
    if( bitmapRep)
    {
        if( newWW == 0 && newWL == 0)
        {
            if( ww == 0 && wl == 0)
            {
                [self computePixMinPixMax];
                ww = fullww;
                wl = fullwl;
            }
            newWW = ww;
            newWL = wl;
        }
        
        CreateIconFrom16( fImage, [bitmapRep bitmapData], (int)height, (int)width, destWidth, newWL, newWW, isRGB);
        
        image = [[[NSImage alloc] initWithSize:NSMakeSize(destWidth, destHeight)] autorelease];
        [image addRepresentation:bitmapRep];
    }
    else NSLog(@"Memory error... not enough RAM");
    
    return image;
}

- (void) allocate8bitRepresentation
{
    [self CheckLoad];
    
    if( baseAddr) free( baseAddr);
    baseAddr = nil;
    
    if( isRGB)
        baseAddr = calloc( (width + 4) * (height + 4) * 4, 1);
    else
        baseAddr = calloc( (width + 4) * (height + 4), 1);
    
    if( baseAddr)
        [self changeWLWW: wl : ww];
    else
        NSLog( @"****** allocate8bitRepresentation calloc failed: %d %d", (int)width, (int)height);
}

- (long)ID { return imID; }
- (void)setID: (long)i { imID = i; }

- (long)Tot {
    [self CheckLoad];
    return imTot;
}

-(void)setTot: (long) tot
{
    [self CheckLoad];
    imTot = tot;
}

-(long)pwidth
{
    [self CheckLoad];
    return width;
}

-(long)pheight
{
    [self CheckLoad];
    return height;
}

- (void)setUpdateToApply { updateToBeApplied = YES; }

-(BOOL) updateToApply { return updateToBeApplied;}

- (float) normalization
{
    return normalization;
}

- (short) kernelsize
{
    return kernelsize;
}

- (float*) kernel
{
    return kernel;
}

-(void) setConvolutionKernel:(float*)val :(short) size :(float) norm
{
    
    if( val)
    {
        kernelsize = size;
        convolution = YES;
        normalization = norm;
        for( long i = 0; i < kernelsize*kernelsize; i++) kernel[i] = val[i];
    }
    else
    {
        convolution = NO;
    }
    
    updateToBeApplied = YES;
}

- (void) revert
{
    [self revert: YES];
}

- (void) revert:(BOOL) reloadAnnotations
{
    if( fImage == nil) return;
    
    [checking lock];
    
    @try 
    {
        SUVConverted = NO;
        fullww = 0;
        fullwl = 0;
        
        [self kill8bitsImage];
        
        [acquisitionTime release];					acquisitionTime = nil;
        [acquisitionDate release];					acquisitionDate = nil;
        [rescaleType release];                      rescaleType = nil;
        [radiopharmaceuticalStartTime release];		radiopharmaceuticalStartTime = nil;
        
        [repetitiontime release];					repetitiontime = nil;
        [echotime release];							echotime = nil;
        [flipAngle release];						flipAngle = nil;
        
        [laterality release];						laterality = nil;
        [viewPosition release];						viewPosition = nil;
        [patientPosition release];					patientPosition = nil;
        [units release];							units = nil;
        [decayCorrection release];					decayCorrection = nil;
        
        if( reloadAnnotations)
            [self reloadAnnotations];
        
        [self clearCachedDCMFrameworkFiles];
        [self clearCachedPapyGroups];
        
        if( fExternalOwnedImage == nil)
        {
            if( fImage != nil)
            {
                free(fImage);
                fImage = nil;
            }
        }
        
        fImage = nil;
        needToCompute8bitRepresentation = YES;
    }
    @catch (NSException * e) 
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [checking unlock];
}

- (void) dealloc
{
    [checking lock];
    
    @synchronized( cachedDCMTKFileFormat)
    {
        if( self.dcmtkDcmFileFormat)
        {
            NSMutableDictionary *dic = [cachedDCMTKFileFormat objectForKey: self.srcFile];
            
            [dic setValue: [NSNumber numberWithInt: [[dic objectForKey: @"count"] intValue]-1] forKey: @"count"];
            
            if( [[dic objectForKey: @"count"] intValue] == 0)
                [cachedDCMTKFileFormat removeObjectForKey: self.srcFile];
            
            self.dcmtkDcmFileFormat = nil;
        }
    }
    
    if( shutterPolygonal)
        free( shutterPolygonal);
    
    [modalityString release];
    [transferFunction release];
    
    [positionerPrimaryAngle release];
    [positionerSecondaryAngle release];
    
    [acquisitionTime release];
    [acquisitionDate release];
    [rescaleType release];
    [radiopharmaceuticalStartTime release];
    
    [repetitiontime release];
    [echotime release];
    [flipAngle release];
    
    [laterality release];
    [units release];
    [patientPosition release];
    [viewPosition release];
    [decayCorrection release];
    [generatedName release];
    [SOPClassUID release];
    [frameofReferenceUID release];
    [imageType release];
    
    self.waveform = nil;
    self.referencedSOPInstanceUID = nil;
    
    if( fExternalOwnedImage == nil)
    {
        if( fImage != nil)
        {
            free(fImage);
            fImage = nil;
        }
    }
    
    
    if( baseAddr)
    {
        free( baseAddr);
        baseAddr = nil;
    }
    [imageObjectID release];
    imageObjectID = nil;
    
    [URIRepresentationAbsoluteString release];
    URIRepresentationAbsoluteString = nil;
    
    [yearOld release];
    yearOld = nil;
    
    [yearOldAcquisition release];
    yearOldAcquisition = nil;
    
    [annotationsDBFields release];
    annotationsDBFields = nil;
    
    for(int i=0; i<maxNumberOfOverlays; i++) {
        if( oData[i]) free( oData[i]);
    }
    if( VOILUT_table) free( VOILUT_table);
    
    if( subGammaFunction) vImageDestroyGammaFunction( subGammaFunction);
    
    [annotationsDictionary release];
    [usRegions release];
    
    if(LUT12baseAddr) free(LUT12baseAddr);
    
    [self clearCachedPapyGroups];
    [self clearCachedDCMFrameworkFiles];
    
    [_srcFile release];
    _srcFile = nil;
    
    [checking unlock];
    [checking release];
    checking = nil;
    
    if( shortRed) free( shortRed);
    if( shortGreen) free( shortGreen);
    if( shortBlue) free( shortBlue);
    
    [super dealloc];
}

// SUV stuff
#pragma mark-
#pragma mark SUV

- (float) appliedFactorPET2SUV
{
    if( SUVConverted)
        return factorPET2SUV;
    else
        return 1.0;
}

-(void) copySUVfrom: (DCMPix*)from
{
    self.radiopharmaceuticalStartTime = from.radiopharmaceuticalStartTime;
    self.acquisitionTime = from.acquisitionTime;
    self.acquisitionDate = from.acquisitionDate;
    self.rescaleType = from.rescaleType;
    self.radionuclideTotalDose = from.radionuclideTotalDose;
    self.radionuclideTotalDoseCorrected = from.radionuclideTotalDoseCorrected;
    self.patientsWeight = from.patientsWeight;
    self.units = from.units;
    self.displaySUVValue = from.displaySUVValue;
    self.SUVConverted = from.SUVConverted;
    self.factorPET2SUV = from.factorPET2SUV;
    self.slope = from.slope;
    
    self.decayCorrection = from.decayCorrection;
    self.maxValueOfSeries = from.maxValueOfSeries;
    self.minValueOfSeries = from.minValueOfSeries;
    self.decayFactor = from.decayFactor;
    self.halflife = from.halflife;
    
    [annotationsDictionary release];
    annotationsDictionary = [from.annotationsDictionary retain];
    [self checkSUV];
}

- (void) checkSUV
{
    hasSUV = NO;
    
    if( ![self.units isEqualToString: @"BQML"] && ![self.units isEqualToString: @"CNTS"]) return;  // Must be BQ/cc
    
    if( [self.units isEqualToString: @"CNTS"] && philipsFactor == 0.0) return;
    
    if( self.decayCorrection == nil) return;
    
    if( [self.decayCorrection isEqualToString: @"START"] == NO && [self.decayCorrection isEqualToString: @"NONE"] == NO && [self.decayCorrection isEqualToString: @"ADMIN"] == NO) return;
    
    if( [self.decayCorrection isEqualToString: @"NONE"] || [self.decayCorrection isEqualToString: @"ADMIN"])
    {
        decayFactor = 1.0;
        radionuclideTotalDoseCorrected = radionuclideTotalDose;
    }
    else
    {
        if( decayFactor == 0.0f) return;
        if( halflife <= 0.0f) return;
        if( acquisitionTime == nil || radiopharmaceuticalStartTime == nil) return;
    }
    
    if( self.radionuclideTotalDose <= 0.0) return;	
    
    if( isRGB) return;
    
    hasSUV = YES;
}


#pragma mark -
#pragma mark Database links

- (NSString *)description
{
    NSMutableString *description = [NSMutableString string];
    [description appendString:NSStringFromClass([self class])];
    [description appendString:[NSString stringWithFormat:@" <%lx>", (unsigned long) self]];
    [description appendString:[NSString stringWithFormat: @" source File: %@\n", self.srcFile]];
    [description appendString:[NSString stringWithFormat: @"core Data Image ID: %@\n", imageObjectID]];
    [description appendString:[NSString stringWithFormat: @"width: %d\n", (int) width]];
    [description appendString:[NSString stringWithFormat: @"height: %d\n", (int) height]];
    [description appendString:[NSString stringWithFormat: @"pixelRatio: %f\n", pixelRatio]];
    [description appendString:[NSString stringWithFormat: @"origin X: %f Y: %f  Z: %f\n", originX, originY, originZ]];
    
    return description;
}

#pragma mark -
#pragma mark Image Annotations

/*
#ifdef OSIRIX_VIEWER

- (NSString*) getDICOMFieldValueForGroup:(int)group element:(int)element DCMLink:(DCMObject*)dcmObject
{
    DCMAttribute *attr = [dcmObject attributeForTag: [DCMAttributeTag tagWithGroup: group element: element]];
    
    if( attr)
    {
        NSMutableString *result = nil;
        
        for( id field in [attr values])
        {
            if([field isKindOfClass:[NSString class]])
            {
                NSString *vr = [attr vr];
                
                if([vr isEqualToString:@"DS"]) field = [NSString stringWithFormat:@"%.6g", [field floatValue]];
                
                if( result == nil) result = [NSMutableString stringWithString: field];
                else [result appendFormat: @" / %@", field];
            }
            else if([field isKindOfClass:[NSNumber class]])
            {
                NSString *vr = [attr vr];
                
                if([vr isEqualToString:@"FD"]) field = [NSString stringWithFormat:@"%.6g", [field floatValue]];
                if([vr isEqualToString:@"FL"]) field = [NSString stringWithFormat:@"%.6g", [field floatValue]];
                
                if([field isKindOfClass:[NSString class]])
                {
                    if( result == nil) result = [NSMutableString stringWithString: field];
                    else [result appendFormat: @" / %@", field];
                }
                else
                {
                    if( result == nil) result = [NSMutableString stringWithString: [field stringValue]];
                    else [result appendFormat: @" / %@", [field stringValue]];
                }
            }
            else if([field isKindOfClass:[NSDate class]])
            {
                NSString *vr = [attr vr];
                if([vr isEqualToString:@"DA"])
                {
                    if( result == nil) result = [NSMutableString stringWithString: [[NSUserDefaults dateFormatter] stringFromDate:field]];
                    else [result appendFormat: @" / %@", [[NSUserDefaults dateFormatter] stringFromDate:field]];
                }
                else if([vr isEqualToString:@"TM"])
                {
                    if( result == nil) result = [NSMutableString stringWithString: [BrowserController TimeWithSecondsFormat: field]];
                    else [result appendFormat: @" / %@", [BrowserController TimeWithSecondsFormat: field]];
                }
                else
                {
                    if( result == nil) result = [NSMutableString stringWithString: [BrowserController DateTimeWithSecondsFormat: field]];
                    else [result appendFormat: @" / %@", [BrowserController DateTimeWithSecondsFormat: field]];
                }
            }
        }
        
        return result;
    }
    return nil;
}


- (void)loadCustomImageAnnotationsDBFields: (DicomImage*) imageObj
{
#ifdef OSIRIX_VIEWER
    if( annotationsDBFields)
        NSLog( @"***** loadCustomImageAnnotationsDBFields has been called several times !!");
    
    annotationsDBFields = [[NSMutableDictionary alloc] init];
    
    NSDictionary *annotationsForModality = nil;
    @synchronized( gCUSTOM_IMAGE_ANNOTATIONS)
    {
        annotationsForModality = [gCUSTOM_IMAGE_ANNOTATIONS objectForKey: self.modalityString];
        
        if(!annotationsForModality) annotationsForModality = [gCUSTOM_IMAGE_ANNOTATIONS objectForKey:@"Default"];
        if([[annotationsForModality objectForKey:@"sameAsDefault"] intValue]==1) annotationsForModality = [gCUSTOM_IMAGE_ANNOTATIONS objectForKey:@"Default"];
        
        annotationsForModality = [[annotationsForModality copy] autorelease];
    }
    
    // image sides (LowerLeft, LowerMiddle, LowerRight, MiddleLeft, MiddleRight, TopLeft, TopMiddle, TopRight) & sameAsDefault
    NSArray *keys = [annotationsForModality allKeys];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [imageObj.managedObjectContext lock];
#pragma clang diagnostic pop
    
    for( NSString *key in keys)
    {
        if(![key isEqualToString:@"sameAsDefault"])
        {
            NSArray *annotations = [annotationsForModality objectForKey: key];
//            NSMutableArray *annotationsOUT = [NSMutableArray array];
            
            @try
            {
                for ( NSDictionary *annot in annotations)
                {
                    NSArray *content = [annot objectForKey:@"fullContent"];
//                    NSMutableArray *contentOUT = [NSMutableArray array];
                    
//                    BOOL contentForLine = NO;
                    
                    for ( int f=0; f<[content count]; f++)
                    {
                        @try
                        {
                            NSDictionary *field = [content objectAtIndex:f];
                            NSString *type = [field objectForKey:@"type"];
                            NSString *value = nil;
                            
                            if([type isEqualToString:@"DB"])
                            {
                                @try
                                {
                                    NSString *fieldName = [field objectForKey:@"field"];
                                    NSString *level = [field objectForKey:@"level"];
                                    if([level isEqualToString:@"image"])
                                        value = [imageObj valueForKey:fieldName];
                                    
                                    else if([level isEqualToString:@"series"])
                                        value = [imageObj valueForKeyPath:[NSString stringWithFormat:@"series.%@", fieldName]];
                                    
                                    else if([level isEqualToString:@"study"])
                                    {
                                        value = [imageObj valueForKeyPath:[NSString stringWithFormat:@"series.study.%@", fieldName]];
                                        
                                        if( [fieldName isEqualToString:@"name"])
                                            value = @"PatientName";
                                    }
                                    
                                    if( value == nil)
                                        [annotationsDBFields setObject: [NSNull null] forKey: [NSString stringWithFormat: @"%@ %@", fieldName, level]];
                                    else
                                        [annotationsDBFields setObject: value forKey: [NSString stringWithFormat: @"%@ %@", fieldName, level]];
                                }
                                @catch (NSException *e)
                                {
                                    NSLog(@"CustomImageAnnotations DB Exception: %@", e);
                                    value = @"ERROR IN ANNOTATIONS - See Preferences->Annotations";
                                }
                            }
                        }
                        
                        @catch (NSException *e)
                        {
                            NSLog(@"CustomImageAnnotations Exception: %@", e);
                        }
                    }
                }
            }
            @catch( NSException *e) {
                NSLog(@"CustomImageAnnotations Exception: %@", e);
            }
        }
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [imageObj.managedObjectContext unlock];
#pragma clang diagnostic pop

#endif
}
- (NSMutableDictionary*) annotationsDBFields
{
    NSMutableDictionary *d = nil;
    
    @synchronized( annotationsDBFields)
    {
        d = [[annotationsDBFields mutableCopy] autorelease];
    }
    
    return d;
}

- (void) setAnnotationsDBFields: (NSMutableDictionary*) d
{
    if( d != annotationsDBFields)
    {
        @synchronized( annotationsDBFields)
        {
            [annotationsDBFields release];
            annotationsDBFields = nil;
        }
        
        annotationsDBFields = [d retain];
    }
}

- (NSMutableDictionary*) annotationsDictionary
{
    NSMutableDictionary *d = nil;
    
    @synchronized( annotationsDictionary)
    {
        d = [[annotationsDictionary mutableCopy] autorelease];
    }
    
    return d;
}

- (void) setAnnotationsDictionary: (NSMutableDictionary*) d
{
    if( d != annotationsDictionary)
    {
        @synchronized( annotationsDictionary)
        {
            [annotationsDictionary release];
            annotationsDictionary = nil;
        }
        
        annotationsDictionary = [d retain];
    }
}

#endif
*/
@end
