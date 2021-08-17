These original screenshots (in screenshots/original) were made with a calibration where each frustum has different VERTICAL and HORIZONTAL opening angles.
This results in a *pixel-aspect ratio* (delta x / delta y, NOT to be confused with the image *resolution* aspect ratio!) being not equal to 1:1 !

This is a problem for software like Hugin, Google Earth, Mistika, that accept only *One FOV angle* as a single parameter!
Reason: The other FOV angle is calculated by the image *resolution* aspect ratio. 
It is implicitly assumed that the *pixel-aspect ratio* is 1:1!
This simplifying assumption is plausible from a physical point of view: 
A camera lens most often has a circular symmetry and the sensor's pixels are arranged in a square-pattern, resulting in both FOV angles (vert.+horiz.) being identical.
But with computer graphics, you can generate "squeezed" images that are incompatible with the "single FOV angle approach".
Unfortunately, our VIOSO calibration is optimized for best coverage of the area lit by a projector with a fixed resolution, and hence for each projector has two rather arbitrary FOV angles, resultin in pixel aspects != 1.

In order to be accepted by Hugin etc., the *pixel-aspect ratio* needs to be adjusted to be 1:1 via scaling along either the x- OR the y axis.
There are multiple ways to achieve this. The best approach depends on the FOV angles and the image/video processing pipeline being capaple of handling non-standard resolutions and/or transparency.

There are many possible approaches, where the most elegant ultimately depends on the original pixel aspect and the video pipeline capabilities
(can it handle different video sources, each with an arbitrary resolution? Can it handle transparency? Performance and storage criteria may also apply ...):

Examples:

1. Paste the original WGXGA-image into a tranparent square-shaped 2560x2560 canvas, and scale the image content along the y axis by (see workaround/clusterCaptureWithMistikaAndHugin/scripts/calc_square-pixeled_resolution_from_original_resolution_and_FovAngles.py):

	pixelAspectRatio = (tan(horizontalFOV_halfAngle) / tan(verticalFOV_halfAngle)) * (y_resolution_original / x_resolution_original)
	y_resolution_new = (1.0/aspectRatio_perPixel) * y_resolution_original 

	Pro: All images same resolution (2560x2560)
	Cons: Wasteful transparent padding, information loss for pixelAspectRatios > 1.0
	
2.  X-scale the image,  *change* the X-resolution of the resulting image (no padding or cropping!).

	x_resolution_new = (aspectRatio_perPixel) * x_resolution_original 




WARNING:
These screenshots have a 29 pixel wide "black bar" on top, the rest of the image is displaced to the bottom by this amount (so that the bottom 29 lines of the image contents are missing!).
This is due to a bug of Blackmagick HDMI capture cards with WQXGA resolution. Make sure to correct for this before further processing!

N.B. We now use Magewell capture cards, which don't have this bug, but due to the capture machine having different hardware issues at the time of writing, I had to resolve to old captures.