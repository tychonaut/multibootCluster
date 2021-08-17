#!/usr/bin/python3

# If a given program takes only input that only has ONE *vertical* FOV half angle,
# than it calculates the *horizontal* FOV angle based on the aspect rastio of the image resolution.
# This can only work by assuming that all pixels are *squared* in the wolrd and thereby 
#
#   resolution aspect ratio == image physical length aspect ratio!
#
# Our VIOSO calibration has the flexibility to combine arbitrary image resolition
# and both vertical and horizonatal opening angles, resulting in images with "rectangular, 
# i.e. non-sqare pixels". 
# This is flexible , but incompatible to programs like Google Earth, Hugin, PTGui and Mistika. 
# For those programs, we need to stretch the images to make the pixels sqaure and hence above relationship
# We will scale tehm along the x axis, but this is just a convention.


# Example call:  
#    python calc_square-pixeled_Xresolution_From_OriginalResolution_and_FovAngles.py 2560 1600 61 45
# The output will be
#     >> res_x_new =  2886 <<
# So scale the images and videos from that source alon the x axis to match that new value.
# The images will look unnaturally stretched, but at least hugin will stitch them together correctly.

#More info on Hugin's conventions:
# http://hugin.sourceforge.net/docs/manual/Field_of_View.html
# http://hugin.sourceforge.net/docs/manual/Image_positioning_model.html
#   https://en.wikipedia.org/wiki/Aircraft_principal_axes
#   https://en.wikipedia.org/wiki/Euler_angles#Tait.E2.80.93Bryan_angles


import sys
import math


pixelCount_x_old               = float(sys.argv[1])
pixelCount_y_old               = float(sys.argv[2])




hFOV_halfAngleDegrees = float(sys.argv[3])
vFOV_halfAngleDegrees = float(sys.argv[4])


print("Image width in pixels:", pixelCount_x_old)
print("Image height in pixels:", pixelCount_y_old)
print("Horizontal FOV half-angle in degrees provided:", hFOV_halfAngleDegrees)
print("Vertical   FOV half-angle in degrees provided:", vFOV_halfAngleDegrees)


tan_vFOV_halfAngle =  math.tan( math.pi/180.0 * vFOV_halfAngleDegrees)
tan_hFOV_halfAngle =  math.tan( math.pi/180.0 * hFOV_halfAngleDegrees)


aspectRatio_XbyY_pixelcount = pixelCount_x_old / pixelCount_y_old
#delta x / delta y : "what rectangular shape has a pixel?
aspectRatio_perPixel = (tan_hFOV_halfAngle / tan_vFOV_halfAngle) * \
                        (pixelCount_y_old / pixelCount_x_old)
                        
print("Pixel-Aspect ratio (what rectangular shape has a pixel in this image?):\n    ", 
       aspectRatio_perPixel)
       
       
#res_y_new = aspectRatio_perPixel * pixelCount_y_old       
#above seems wrong...
res_y_new = (1.0/aspectRatio_perPixel) * pixelCount_y_old       

print("EITHER DO (if the video pipeline does not like strange arbitrary resolutions):\n"    
      "Y-Resolution value to scale the image  along the Y (!!!) axis"
      "(so that the square-pixel-assumtion becomes valid for Hugin:\n\n"
      "    >> res_Y_new = ", round(res_y_new) , "<<\n")
      
      
print("Paste the original image into a tranparent "
      "square-shaped 2560x2560 canvas, and Y-scale the "
      "image's layer to ", round(res_y_new),"."
      "Enter the HORIZONTAL FOV FULL ANGLE into Hugin's"
      "'v' param: v", 2*hFOV_halfAngleDegrees,
      "\n the 'v' is misleading!!!\n"
      )


res_x_new = (aspectRatio_perPixel) * pixelCount_x_old       

print("OR do (better for pixel aspects >1) :\n"    
      "X-Resolution value to scale the image  along the X (!!!) axis"
      "(so that the square-pixel-assumtion becomes valid for Hugin:\n\n"
      "    >> res_X_new = ", round(res_x_new) , "<<\n")
      
      
print("X-scale the "
      "image to ", round(res_x_new),", and CHANGE the X-resolution of the resulting image."
      "Enter the HORIZONTAL FOV FULL ANGLE into Hugin's"
      "'v' param: v", 2*hFOV_halfAngleDegrees,
      "\n the 'v' is misleading!!11"
      )


  
  
"""   
JUNK to come, ignore!      
      
print("Do not change the resolution of the image: make side columns transparent or crop!")


inverse_aspectRatio_perPixel = 1.0 / aspectRatio_perPixel
vFOV_halfAngle_new = math.atan(inverse_aspectRatio_perPixel * tan_vFOV_halfAngle) * 180.0 / math.pi
print("new vertical FULL FOV angle to input to hugin :\n\n"
      "    >> vFOV_halfAngle_new = ", 2.0 * vFOV_halfAngle_new , "<<\n")
  





inverse_aspectRatio_perPixel = 1.0 / aspectRatio_perPixel
print("inverse pixel-aspect ratio, to shrink pixels along the x axis with,"
      "leaving the edges transparent):\n    ", 
       inverse_aspectRatio_perPixel)
   


   
res_x_new = inverse_aspectRatio_perPixel * pixelCount_x_old

print("X-Resolution value to scale the along the x axis"
      "(so that the square-pixel-assumtion becomes valid for Hugin:\n\n"
      "    >> res_x_new = ", round(res_x_new) , "<<\n")
print("do not change the resolution of the image: make side columns transparent or crop!")

#---- old

# w/h = tan(wFov)/tan(hfov) <-- in order for this to hold, we have to calculate a new x-resolution from the rest:

res_x_new = pixelCount_y_old * tan_hFOV_halfAngle / tan_vFOV_halfAngle

print("X-Resolution Value to scale th image so that the square-pixel-assumtion becomes valid for Hugin "
  "to calc its own horizontal fov angle:\n\n"
  "    >> res_x_new = ", round(res_x_new) , "<<\n")

print("- - -")
print("Sanity checks if a  triple of the new resolution and an old vFovAngle "
  "yields the correct hfov Angle of the vioso Calibration. Later we want to use the output to make all "
  "VIOSO frustums and images square-pixeled.")



aspectRatio_new = res_x_new / pixelCount_y_old
print ("new squared-pixel-based aspectRatio of scaled image of dimensions(",
       res_x_new, "x", pixelCount_y_old,"):\n\n", aspectRatio_new, "\n\n")


print("Vertical FOV half-angle in degrees provided:", vFOV_halfAngleDegrees)

hFOV_halfAngleDegrees_new = \
    180.0/math.pi * \
    math.atan(  aspectRatio_new * \
                math.tan( math.pi/180.0 * vFOV_halfAngleDegrees) 
    )


print("Horizontal FOV half-angle in degrees corresponding to an aspect ratio of ", aspectRatio_new, ": ")
print(hFOV_halfAngleDegrees_new)

#print("Horizontal FOV FULL-angle in degrees corresponding to an aspect ratio of ", aspectRatio_new, ": ")
#print(2.0*hFOV_halfAngleDegrees_new)

"""