import os
import ctypes
from ctypes import c_void_p, c_char_p, c_size_t, c_double, Structure, POINTER, byref

# Load Frameworks
cf = ctypes.cdll.LoadLibrary('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
cg = ctypes.cdll.LoadLibrary('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
iio = ctypes.cdll.LoadLibrary('/System/Library/Frameworks/ImageIO.framework/ImageIO')

# Structures
class CGPoint(Structure):
    _fields_ = [('x', c_double), ('y', c_double)]

class CGSize(Structure):
    _fields_ = [('width', c_double), ('height', c_double)]

class CGRect(Structure):
    _fields_ = [('origin', CGPoint), ('size', CGSize)]

# CoreFoundation functions
CFURLCreateFromFileSystemRepresentation = cf.CFURLCreateFromFileSystemRepresentation
CFURLCreateFromFileSystemRepresentation.restype = c_void_p
CFURLCreateFromFileSystemRepresentation.argtypes = [c_void_p, c_char_p, c_size_t, ctypes.c_bool]

CFStringCreateWithCString = cf.CFStringCreateWithCString
CFStringCreateWithCString.restype = c_void_p
CFStringCreateWithCString.argtypes = [c_void_p, c_char_p, ctypes.c_uint32]

CFRelease = cf.CFRelease
CFRelease.argtypes = [c_void_p]

# ImageIO functions
CGImageSourceCreateWithURL = iio.CGImageSourceCreateWithURL
CGImageSourceCreateWithURL.restype = c_void_p
CGImageSourceCreateWithURL.argtypes = [c_void_p, c_void_p]

CGImageSourceCreateImageAtIndex = iio.CGImageSourceCreateImageAtIndex
CGImageSourceCreateImageAtIndex.restype = c_void_p
CGImageSourceCreateImageAtIndex.argtypes = [c_void_p, c_size_t, c_void_p]

CGImageDestinationCreateWithURL = iio.CGImageDestinationCreateWithURL
CGImageDestinationCreateWithURL.restype = c_void_p
CGImageDestinationCreateWithURL.argtypes = [c_void_p, c_void_p, c_size_t, c_void_p]

CGImageDestinationAddImage = iio.CGImageDestinationAddImage
CGImageDestinationAddImage.argtypes = [c_void_p, c_void_p, c_void_p]

CGImageDestinationFinalize = iio.CGImageDestinationFinalize
CGImageDestinationFinalize.restype = ctypes.c_bool
CGImageDestinationFinalize.argtypes = [c_void_p]

# CoreGraphics functions
CGImageCreateWithImageInRect = cg.CGImageCreateWithImageInRect
CGImageCreateWithImageInRect.restype = c_void_p
CGImageCreateWithImageInRect.argtypes = [c_void_p, CGRect]

CGImageGetWidth = cg.CGImageGetWidth
CGImageGetWidth.restype = c_size_t
CGImageGetWidth.argtypes = [c_void_p]

CGImageGetHeight = cg.CGImageGetHeight
CGImageGetHeight.restype = c_size_t
CGImageGetHeight.argtypes = [c_void_p]

CGImageRelease = cg.CGImageRelease
CGImageRelease.argtypes = [c_void_p]

kCFStringEncodingUTF8 = 0x08000100

def get_image_size(path):
    abs_path = os.path.abspath(path).encode('utf-8')
    url = CFURLCreateFromFileSystemRepresentation(None, abs_path, len(abs_path), False)
    if not url:
        return None
    src = CGImageSourceCreateWithURL(url, None)
    CFRelease(url)
    if not src:
        return None
    img = CGImageSourceCreateImageAtIndex(src, 0, None)
    CFRelease(src)
    if not img:
        return None
    w = CGImageGetWidth(img)
    h = CGImageGetHeight(img)
    CGImageRelease(img)
    return (w, h)

def crop_exact(src_path, dst_path, x, y, width, height):
    """
    Crops src_path at pixel box (x, y, width, height) with (0,0) at top-left.
    Saves to dst_path (.png or .jpg).
    """
    os.makedirs(os.path.dirname(os.path.abspath(dst_path)), exist_ok=True)
    abs_src = os.path.abspath(src_path).encode('utf-8')
    src_url = CFURLCreateFromFileSystemRepresentation(None, abs_src, len(abs_src), False)
    if not src_url:
        raise RuntimeError(f"Cannot create URL for {src_path}")
    
    src = CGImageSourceCreateWithURL(src_url, None)
    CFRelease(src_url)
    if not src:
        raise RuntimeError(f"Cannot create CGImageSource from {src_path}")
        
    img = CGImageSourceCreateImageAtIndex(src, 0, None)
    CFRelease(src)
    if not img:
        raise RuntimeError(f"Cannot create CGImage from {src_path}")
        
    img_w = CGImageGetWidth(img)
    img_h = CGImageGetHeight(img)
    
    # Clamp to image boundaries
    x = max(0, min(x, img_w - 1))
    y = max(0, min(y, img_h - 1))
    width = min(width, img_w - x)
    height = min(height, img_h - y)
    
    rect = CGRect(CGPoint(x, y), CGSize(width, height))
    cropped = CGImageCreateWithImageInRect(img, rect)
    CGImageRelease(img)
    if not cropped:
        raise RuntimeError(f"CGImageCreateWithImageInRect failed for {src_path} at {rect}")
        
    abs_dst = os.path.abspath(dst_path).encode('utf-8')
    dst_url = CFURLCreateFromFileSystemRepresentation(None, abs_dst, len(abs_dst), False)
    
    uti_name = b"public.png"
    uti_cf = CFStringCreateWithCString(None, uti_name, kCFStringEncodingUTF8)
    
    dest = CGImageDestinationCreateWithURL(dst_url, uti_cf, 1, None)
    CFRelease(dst_url)
    CFRelease(uti_cf)
    
    if not dest:
        CGImageRelease(cropped)
        raise RuntimeError(f"Cannot create CGImageDestination for {dst_path}")
        
    CGImageDestinationAddImage(dest, cropped, None)
    success = CGImageDestinationFinalize(dest)
    CFRelease(dest)
    CGImageRelease(cropped)
    
    if not success:
        raise RuntimeError(f"Failed to finalize image destination {dst_path}")
        
    print(f"Cropped {src_path} -> {dst_path} [{width}x{height} from ({x}, {y})]")
    return True

if __name__ == "__main__":
    # Test on running and cycling
    crop_exact("assets/Neon Running and Cycling Duo.png", "build/py_runner.png", 0, 0, 840, 941)
    crop_exact("assets/Neon Running and Cycling Duo.png", "build/py_cyclist.png", 830, 0, 840, 941)
