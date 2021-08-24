# Script to parse view frustum data from an xml file
# (an SGCT config file used in OpenSpace, to pe precise),
# converts them vom FOV+EulerAngles(YawPitchRoll/YXZ) representation
# to "3 corners of the projection plane" representation.
# The result is written into another xml file
# (a ParaView .pvx file).
#
# IMPORTANT:
#   Input is REQUIRED to be IN ORDER: 
#     arenamaster, arenart1 .. arenart5.
# Output will have the following order:
#    arenart3, arenart1, arenart2, arenart4, arenart5.
# This is because for the ParaView .pvx files, 
# The association between a real server computer (a.k.a. arenartX) 
#	and a "Machine" xml-element seems to have nothing to do with their host names!
# It is instead done in the same order as the machines are specified in 
#   machines.txt 
# for mpiexec!
# If we want the "main" server to be arenart3 (because it is the QuadroSync master!),
# we have to put it on top of both machines.txt and this file!

#-------------------------------------------------------------------------------
pkg load matgeom
pkg load linear-algebra


javaaddpath ("D:/devel/xerces_java/xerces-2_12_1/xercesImpl.jar")
javaaddpath ("D:/devel/xerces_java/xerces-2_12_1/xml-apis.jar")



# directory of this script
file_path = fileparts(mfilename('fullpath'))


filename_in = strcat( file_path, "/SPContentSpaces.ini")
## These three lines are equivalent to xDoc_in = xmlread(filename_in) in Matlab
parser_in = javaObject("org.apache.xerces.parsers.DOMParser");
parser_in.parse(filename_in);
xDoc_in = parser_in.getDocument();

# 6, ignore "main"
numFrusta_in = xDoc_in.getElementsByTagName("ModelPoseParameter3D").getLength();

allViewPlaneSizes = [] ;

# skip index 0, as we are not interested in the master node
for frustumIndex = 1 : (numFrusta_in-1)
  
  viewPlaneElem = xDoc_in.getElementsByTagName("ViewSize").item(frustumIndex);
 
  viewPlaneSize_prev = [
    str2double(viewPlaneElem.getAttributes().getNamedItem("X").getNodeValue()),
    str2double(viewPlaneElem.getAttributes().getNamedItem("Y").getNodeValue())
  ]
  
  viewPlaneSize_prev(1) / viewPlaneSize_prev(2)
 
 
  viewPlaneSize_new = [
    viewPlaneSize_prev(1),
    # vpr_x / vpr_y = width / height
    # --> vpr_y = vpr_x *  height / width
    viewPlaneSize_prev(1) * 1600.0 / 2560.0
  ]
  
  viewPlaneSize_new(1) / viewPlaneSize_new(2)
  
  allViewPlaneSizes = [allViewPlaneSizes, viewPlaneSize_new];
  
  
  # write back to XML structure:

 
endfor


allViewPlaneSizes


#find max:
#HACK: know by hand

[maxX_value maxX_index] = max(allViewPlaneSizes(1,:))

maxViewPlaneSize = allViewPlaneSizes(:,maxX_index)



#-------------------------------------------------------------------------------
# write back to XML structure:

# skip index 0, as we are not interested in the master node
for frustumIndex = 1 : (numFrusta_in-1)
  
  viewPlaneElem = xDoc_in.getElementsByTagName("ViewSize").item(frustumIndex);
  
  viewPlaneElem.getAttributes().getNamedItem("X").setNodeValue(
    num2str( maxViewPlaneSize(1) )
  );
  viewPlaneElem.getAttributes().getNamedItem("Y").setNodeValue(
    num2str( maxViewPlaneSize(2) )
  );
  
endfor
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# write the XML string to file:

serializer = javaObject("org.apache.xml.serialize.XMLSerializer");
strWriter  = javaObject("java.io.StringWriter");
serializer.setOutputCharStream(strWriter);
serializer.serialize(xDoc_in);
xmlString_out = strWriter.toString();



filename_out = strcat( file_path, "/SPContentSpaces_new.ini");

fid = fopen (filename_out, "w");
if (fid == -1)
  error ("Unable to open file ", filename_out,"  Aborting...\n");
endif
fprintf(fid, "%s\n", xmlString_out);
fflush(fid);
fclose(fid);

#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
