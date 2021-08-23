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


#javaaddpath ("C:/Users/Domecaster/devel/xerces-2_12_1/xercesImpl.jar")
#javaaddpath ("C:/Users/Domecaster/devel/xerces-2_12_1/xml-apis.jar")
javaaddpath ("D:/devel/xerces_java/xerces-2_12_1/xercesImpl.jar")
javaaddpath ("D:/devel/xerces_java/xerces-2_12_1/xml-apis.jar")



# directory of this script
file_path = fileparts(mfilename('fullpath'))


filename_in = strcat( file_path, "/openspace_sgct_config_IN.xml")
## These three lines are equivalent to xDoc_in = xmlread(filename_in) in Matlab
parser_in = javaObject("org.apache.xerces.parsers.DOMParser");
parser_in.parse(filename_in);
xDoc_in = parser_in.getDocument();

numFrusta_in = xDoc_in.getElementsByTagName("PlanarProjection").getLength();

frusta_FOV_Euler = [] ;

# skip index 0, as we are not interested in the master node
for frustumIndex = 1 : (numFrusta_in-1)
  
  planarProjElem = xDoc_in.getElementsByTagName("PlanarProjection").item(frustumIndex);
 
  childNodes = planarProjElem.getChildNodes();

  
   fov = struct ( "up", 10, "down", 20, "left", 30, "right", 40 ) ;
   eulerAngles = struct ( "yaw", 0, "pitch", 0 , "roll", 0) ;
  
  for childIndex = 0 : (childNodes.getLength() - 1)
      
    childNode = childNodes.item(childIndex);
      
    if(strcmp(childNode.getNodeName(), "FOV"))
      
      fovAttribs = childNode.getAttributes();
      
      fov = struct ( 
        "up",     str2double(fovAttribs.getNamedItem("up").getNodeValue()),
        "down",   str2double(fovAttribs.getNamedItem("down").getNodeValue()),
        "left",   str2double(fovAttribs.getNamedItem("left").getNodeValue()),
        "right",  str2double(fovAttribs.getNamedItem("right").getNodeValue())
      );
      
    endif
    
    if(strcmp(childNode.getNodeName(), "Orientation"))
    
      dirAttribs = childNode.getAttributes();
      
      eulerAngles = struct (
        "yaw",    str2double(dirAttribs.getNamedItem("heading").getNodeValue()),
        "pitch",  str2double(dirAttribs.getNamedItem("pitch").getNodeValue()),
        "roll",   str2double(dirAttribs.getNamedItem("roll").getNodeValue())
      );
      
    endif
    
  endfor

  frustum_FOV_Euler = struct("fov", fov, "eulerAngles", eulerAngles)
  
  frusta_FOV_Euler = [frusta_FOV_Euler, frustum_FOV_Euler];
  
endfor

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

# do the conversions :

#for plotting:
clf # clear figure
hold on
xlabel("x")
ylabel("y")
zlabel("z")
axis("equal")

plotData = [];

frusta_planeCorners = [];
for frustumIndex_in = 1 : numel(frusta_FOV_Euler)
 
  printf("frustum #: %d\n", frustumIndex_in)
 
  fovU = deg2rad(frusta_FOV_Euler(frustumIndex_in).fov.up);
  fovD = deg2rad(frusta_FOV_Euler(frustumIndex_in).fov.down);
  fovL = deg2rad(frusta_FOV_Euler(frustumIndex_in).fov.left);
  fovR = deg2rad(frusta_FOV_Euler(frustumIndex_in).fov.right);

  ll = [ -tan(fovL), -tan(fovD), -1.0]' ;
  lr = [  tan(fovR), -tan(fovD), -1.0]' ;
  ul = [ -tan(fovL),  tan(fovU), -1.0]' ;
  ur = [  tan(fovR),  tan(fovU), -1.0]' ;
  
  
  mainDir = [0, 0, -1.0]' ;
  
  #DEBUG TEST: 3m radius, like in dome
  ll *= 3.0;
  lr *= 3.0;
  ul *= 3.0;
  ur *= 3.0;
  
  mainDir *= 6.0;
  
  #yaw pitch roll -> rotate about y,x,z
  yaw =   deg2rad((frusta_FOV_Euler(frustumIndex_in).eulerAngles.yaw));
  pitch = deg2rad((frusta_FOV_Euler(frustumIndex_in).eulerAngles.pitch));
  roll =  deg2rad((frusta_FOV_Euler(frustumIndex_in).eulerAngles.roll));
  
  
  
  ##-----------------------------------------------------------------------------
  ## Mirroring OpenSpace's approach here, as the calibration works there:
  ## see glm::quat sgct_core::ReadConfig::parseOrientationNode(tinyxml2::XMLElement* element)
  yaw   *= -1.0;
  pitch *=  1.0; #NOT negate
  roll  *= -1.0;
  
  yawMat   = createRotationOy( yaw );
  pitchMat = createRotationOx( pitch );
  rollMat  = createRotationOz( roll );
  
  ## original try: yxz -> yaw pitch roll; that's how OpenSpace does it
  #   rotationMat = rollMat * pitchMat * yawMat;
  ## next try: xyz: pitch yaw roll; looks good in plot, NEARLY correct in Paraview...
  #   rotationMat = rollMat * yawMat * pitchMat ;
  #
  ## Trial out of desparation: invert order: yxz -> zxy
  ## This works! This would imply that VIOSO has the euler angle convention 
  ## "roll pitch yaw" ("zxy"), despite verbal claims and GUI and calibration artifacts
  ## claiming "yxz". 
  rotationMat = yawMat * pitchMat *  rollMat;
  # 
  ## HINDSIGHT INSIGHT:
  ## Reason this works: After freshing up on quaternions
  ## ( https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#Using_quaternion_as_rotations ),
  ## I saw in the OpenSpace parsing code that it has actually the order
  ##   roll -> ptich -> yaw , 
  ## obfuscated by "read from bottom to top"-style-code
  ## just like matrix transforms are to be read from left to right:
  ##      quat = glm::rotate(quat, glm::radians(y), glm::vec3(0.0f, 1.0f, 0.0f));
  ##      quat = glm::rotate(quat, glm::radians(x), glm::vec3(1.0f, 0.0f, 0.0f));
  ##      quat = glm::rotate(quat, glm::radians(z), glm::vec3(0.0f, 0.0f, 1.0f));
  ## So this is totally legit. In hindsight, there are the following general problems:
  ## This convention is nowhere documented to be used, neither by Vioso 
  ## nor by Paraview, OpenSpace or Google Earth.
  ## Also, I have nowwhere found that this is a *common* convention.
  ## Finally, when asked our calibration provider to confirm the "yaw pitch roll"-convention,
  ## he did so, although the order is the opposite even after reporting these results.
  ## One may argue that it is confusing that
  ## semantic and notational order are different, but this underlines the point
  ## how much trouble can be saved by decent documentation.
  ##-----------------------------------------------------------------------------

  
  
  # 4x4 -> 3x3
  rotationMat = rotationMat(1:3, 1:3) 
  
  ll = rotationMat * ll;
  lr = rotationMat * lr;
  ul = rotationMat * ul;
  ur = rotationMat * ur;
  
  mainDir = rotationMat * mainDir;


  
  planeCorners = struct(
    "LowerLeft",  ll,
    "LowerRight", lr,
    "UpperLeft", ul,
    "UpperRight", ur,
    "mainDir", mainDir,
    "screenFrame_xs", [ ll(1), lr(1), ur(1), ul(1), ll(1) ],
    "screenFrame_ys", [ ll(2), lr(2), ur(2), ul(2), ll(2) ],
    "screenFrame_zs", [ ll(3), lr(3), ur(3), ul(3), ll(3) ]
  )
  
  frusta_planeCorners = [frusta_planeCorners, planeCorners];
  
  #plot stuff
  i = frustumIndex_in;
  plot3( 
     
    [0, planeCorners.mainDir(1)],    [0,planeCorners.mainDir(2)],    [0,planeCorners.mainDir(3)] , "",
    [0, planeCorners.LowerLeft(1)],  [0,planeCorners.LowerLeft(2)],  [0,planeCorners.LowerLeft(3)] , "",
    [0, planeCorners.LowerRight(1)], [0,planeCorners.LowerRight(2)], [0,planeCorners.LowerRight(3)] , "",
    [0, planeCorners.UpperLeft(1)],  [0,planeCorners.UpperLeft(2)],  [0,planeCorners.UpperLeft(3)] , "",
    [0, planeCorners.UpperRight(1)], [0,planeCorners.UpperRight(2)], [0,planeCorners.UpperRight(3)] , "",
    
    planeCorners.screenFrame_xs, planeCorners.screenFrame_ys, planeCorners.screenFrame_zs, "-"
  )
  text ( planeCorners.mainDir(1), planeCorners.mainDir(2), planeCorners.mainDir(3),
         strcat( "frustum", num2str(frustumIndex_in)));
  

  
endfor



#  plot3( 
#  
#    [0, planeCorners(1).mainDir(1)], [0,planeCorners(1).mainDir(2)], [0,planeCorners(1).mainDir(3)] , "",
#    [0, planeCorners(1).LowerLeft(1)], [0,planeCorners(1).LowerLeft(2)], [0,planeCorners(1).LowerLeft(3)] , "",
#    [0, planeCorners(1).LowerRight(1)], [0,planeCorners(1).LowerRight(2)], [0,planeCorners(1).LowerRight(3)] , "",
#    [0, planeCorners(1).UpperLeft(1)], [0,planeCorners(1).UpperLeft(2)], [0,planeCorners(1).UpperLeft(3)] , "",
#    [0, planeCorners(1).UpperRight(1)], [0,planeCorners(1).UpperRight(2)], [0,planeCorners(1).UpperRight(3)] , "",
#    
#    planeCorners(1).screenFrame_xs, planeCorners(1).screenFrame_ys, planeCorners(1).screenFrame_zs, ""
#  )
  



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

#create XML string by loading a Paraview .pvx file, and modify the relevant values:

filename_toMod = strcat( file_path, "/FOURPOINT_TEMPLATE_for_moreViz.xml");
## These three lines are equivalent to xDoc_in = xmlread(filename_in) in Matlab
parser_out = javaObject("org.apache.xerces.parsers.DOMParser");
parser_out.parse(filename_toMod);
xDoc_out = parser_out.getDocument();


numFrusta_out = xDoc_out.getElementsByTagName("Machine").getLength();

if(numel(frusta_FOV_Euler) != numFrusta_out)
 error("in/out frustum count do not match!")
endif

for frustumIndex_out = 0 : (numFrusta_out -1 )
  
  machineElem = xDoc_out.getElementsByTagName("Machine").item(frustumIndex_out);
  
  #hostname = machineElem.getAttributes().getNamedItem("Name").getNodeValue()
  ## As be cannot rely on the order of the data in the .pvx file,
  ## and as machine names are only available as attributes,
  ## we have to extract the index: "arenart" are 7 digits.
  #hostIndex= str2num( hostname(8))
  
  hostIP = machineElem.getAttributes().getNamedItem("Name").getNodeValue()
  ## As be cannot rely on the order of the data in the .pvx file,
  ## and there are only machine "names" (actually, IPs, see notes above) 
  ## available, we have to extract the machine index: from the IP:
  ## "10.0.10.2x" has nine literals before the relevant digit implying the 
  ## number of the RealTime node.
  hostIndex= str2num( hostIP(10))
  
  
  planeCorners =  frusta_planeCorners(hostIndex);
  LowerLeft_string  = num2str( planeCorners.LowerLeft' )
  LowerRight_string = num2str( planeCorners.LowerRight' )
  UpperRight_string = num2str( planeCorners.UpperRight' )
  UpperLeft_string = num2str( planeCorners.UpperLeft' )
  
  
  machineElem.getAttributes().getNamedItem("LowerLeft").setNodeValue(LowerLeft_string);
  machineElem.getAttributes().getNamedItem("LowerRight").setNodeValue(LowerRight_string);
  machineElem.getAttributes().getNamedItem("UpperRight").setNodeValue(UpperRight_string);
  machineElem.getAttributes().getNamedItem("UpperLeft").setNodeValue(UpperLeft_string);
    
endfor 


#-------------------------------------------------------------------------------
# write the XML string to file:

serializer = javaObject("org.apache.xml.serialize.XMLSerializer");
strWriter  = javaObject("java.io.StringWriter");
serializer.setOutputCharStream(strWriter);
serializer.serialize(xDoc_out);
xmlString_out = strWriter.toString();



filename_out = strcat( file_path, "/FOURPOINT_output_for_moreViz.xml");

fid = fopen (filename_out, "w");
if (fid == -1)
  error ("Unable to open file ", filename_out,"  Aborting...\n");
endif
fprintf(fid, "%s\n", xmlString_out);
fflush(fid);
fclose (fid);

#-------------------------------------------------------------------------------
