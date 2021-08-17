#!/usr/bin/python3

# If a given program needs input that only has on vertical fov half angle
# and calculates the horizontal angle based on the aspect rastio of the resolutions,
# this can only work. by assuming that all pixels are squared in the wolrdand thereby 
# .resolution ration == image aspect ratio,

# Our VIOSO calibration has the flexibility to combine arbitrary image resolition
# and both vertcal and horizonatal opening angles, resulting in images with "rectangular pixels". 
# This is flexible , but incompatible 
# to programs like Google Earth, Hugin, PTGui and Mistika. 
# For those programs, we need to scretch the images to make hte pixels sqare and hence the relationship
# "wip_wid/pic_len = resolution_x / resolution_y" to hold


import sys
import math



res_x_0               = float(sys.argv[1])
res_y_0               = float(sys.argv[2])

#to be calced value
#hFOV_halfAngleDegrees = float(sys.argv[3])
vFOV_halfAngleDegrees = float(sys.argv[3])


print("Sanity checks if a  triple of the new resolution and an old vFovAngle "
  "yields the correct hfov Angle of the vioso Calibration. Later we want to use the output to make all "
  "VIOSO frustums and images square-pixeled.")



aspectRatio = res_x_0 / res_y_0
print ("new aspectRatio of scaled image of dimensions(",res_x_0, "x", res_y_0,"):\n\n", aspectRatio, "\n\n")


print("Vertical FOV half-angle in degrees provided:", vFOV_halfAngleDegrees)

hFOV_halfAngleDegrees_new = 180.0/math.pi * \
    math.atan( 
        aspectRatio * \
        math.tan( math.pi/180.0 * vFOV_halfAngleDegrees)
    )


print("Horizontal FOV half-angle in degrees corresponding to an aspect ratio of ", aspectRatio, ": ")
print(hFOV_halfAngleDegrees_new)

#print("Horizontal FOV FULL-angle in degrees corresponding to an aspect ratio of ", aspectRatio, ": ")
#print(2.0*hFOV_halfAngleDegrees_new)