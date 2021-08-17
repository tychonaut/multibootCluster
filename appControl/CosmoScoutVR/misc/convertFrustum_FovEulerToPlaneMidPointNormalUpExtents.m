function ret = convertFrustum_FovEulerToPlaneMidPointNormalUpExtents()

  # Script to load+parse view frustum data from an xml file
  # (an SGCT config file used in OpenSpace, to pe precise):
  # It converts the frustum data vom a "FOV+EulerAngles"-representation
  # (roll->pitch->yaw / ZXY) to a "projection plane"- representation of type
  # " midpoint: point on dome along view direction:
  #             yaw(yaw_angle) * pitch(pitch_angle) * roll(roll_angle) 
  #                * (0, 0, -radius_dome)^T;
  #              = Rotate(y, yaw_angle)* Rotate(x, pitch_angle)* Rotate(z, roll_angle) 
  #                * (0, 0, -radius_dome)^T
  #              = RollPitchYawMatrix * (0, 0, -radius_dome)^T
  #   normal:   normalized inverse view direction
  #   extents:  x_min = (-1.0) * radius_dome * tan(fov_left);
  #             x_max =          radius_dome * tan(fov_right);
  #             y_min = (-1.0) * radius_dome * tan(fov_down);
  #             y_max =          radius_dome * tan(fov_up);
  #   up:       RollPitchYawMatrix * (0,1,0)
  #   near clip: 0.2
  #   far clip:  5000
  # ".
  #
  # The result is written into an ini file
  # to be read by CosmoScout VR.
  #
  # IMPORTANT:
  #   Input is REQUIRED to be IN ORDER: 
  #     arenamaster, arenart1 .. arenart5.
  # (TODO: check if this restriction still applies for the ini stuff)
  #
  #-------------------------------------------------------------------------------
  pkg load matgeom
  pkg load linear-algebra
  
  
  ret = -1; # default: error

  # load xml-parser stuff:
  javaaddpath ("D:/devel/xerces_java/xerces-2_12_1/xercesImpl.jar")
  javaaddpath ("D:/devel/xerces_java/xerces-2_12_1/xml-apis.jar")

  # directory of this script
  file_path = fileparts(mfilename('fullpath'))



  radius_dome_metres = 3.0;


  # load an parse input xml file:
  filename_in = strcat( file_path, "/openspace_sgct_config_INPUT.xml")
  ## These three lines are equivalent to xDoc_in = xmlread(filename_in) in Matlab
  xml_parser_in = javaObject("org.apache.xerces.parsers.DOMParser");
  xml_parser_in.parse(filename_in);
  xDoc_in = xml_parser_in.getDocument();


  numFrusta_in = xDoc_in.getElementsByTagName("PlanarProjection").getLength();

  frusta_FOV_Euler = [] ;

  # Read relevant frustum data into structure:
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

    frustum_FOV_Euler = struct("fov", fov, "eulerAngles", eulerAngles);
    
    frusta_FOV_Euler = [frusta_FOV_Euler, frustum_FOV_Euler];
    
  endfor



  #debug print
  #frusta_FOV_Euler
  #frusta_FOV_Euler(1).fov
  #frusta_FOV_Euler(1).eulerAngles



  # for debug  plotting: -------------
  #clf # clear figure
  #hold on
  #xlabel("x")
  #ylabel("y")
  #zlabel("z")
  #axis("equal")

  #plotData = [];
  # ----------------------------------


  #-------------------------------------------------------------------------------
  #-------------------------------------------------------------------------------
  # do the conversions from one frustum representation to the other:


  projectionPlanes = [];
  for frustumIndex_in = 1 : numel(frusta_FOV_Euler)
   
    #printf("frustum #: %d\n", frustumIndex_in)
    
    projectionName = strcat("arenart", num2str(frustumIndex_in), "_PROJECTION");
   
    # degrees to radians:
    fovU = deg2rad(frusta_FOV_Euler(frustumIndex_in).fov.up);
    fovD = deg2rad(frusta_FOV_Euler(frustumIndex_in).fov.down);
    fovL = deg2rad(frusta_FOV_Euler(frustumIndex_in).fov.left);
    fovR = deg2rad(frusta_FOV_Euler(frustumIndex_in).fov.right);
    

    plane_extents = struct(
      "x_min", (-1.0) * radius_dome_metres * tan(fovL),
      "x_max",          radius_dome_metres * tan(fovR),
      "y_min", (-1.0) * radius_dome_metres * tan(fovD),
      "y_max",          radius_dome_metres * tan(fovU) 
    );

    
    # start view direction: negative z-axis:
    mainDir_normalized = [0, 0, -1.0]' ;

    #initial position and vector params of projection plane:
    plane_midPoint =  mainDir_normalized * radius_dome_metres;
    # inverse view direciton
    plane_normal = -1.0 * mainDir_normalized * radius_dome_metres;
    plane_up     = [0, 1.0, 0]'; # positive y
    
    
    ##----------------------------------------------------------------------------
	
    # Set up rotation matrix:
    # On reasons for this particular rotation order and angle signs, check 
    # <multiOSCluster dir>/appControl/ParaView/misc/convertFrustum_FovEulerToPlaneCorners.m
	# or https://en.wikipedia.org/wiki/Aircraft_principal_axes
	# or https://en.wikipedia.org/wiki/Euler_angles#Tait.E2.80.93Bryan_angles
    
    # degrees to radians:
    yaw =   deg2rad((frusta_FOV_Euler(frustumIndex_in).eulerAngles.yaw));
    pitch = deg2rad((frusta_FOV_Euler(frustumIndex_in).eulerAngles.pitch));
    roll =  deg2rad((frusta_FOV_Euler(frustumIndex_in).eulerAngles.roll));
    
    yaw   *= -1.0;
    pitch *=  1.0; #NOT negate
    roll  *= -1.0;
    
    yawMat   = createRotationOy( yaw );
    pitchMat = createRotationOx( pitch );
    rollMat  = createRotationOz( roll );
    
    rotationMat = yawMat * pitchMat *  rollMat;

    # 4x4 -> 3x3
    rotationMat = rotationMat(1:3, 1:3);
    ##----------------------------------------------------------------------------

    mainDir_normalized = rotationMat * mainDir_normalized;
    plane_midPoint =  rotationMat * plane_midPoint;
    plane_normal   =  rotationMat * plane_normal;
    plane_up       =  rotationMat * plane_up;
    
    currentProjectionPlane = struct(
      "NAME", projectionName,
      "PROJ_PLANE_MIDPOINT",  plane_midPoint,
      "PROJ_PLANE_NORMAL", plane_normal,
      "PROJ_PLANE_UP", plane_up,
      "PROJ_PLANE_EXTENTS", plane_extents,
      "CLIPPING_RANGE", [0.2, 5000.0]
    );
    
    projectionPlanes = [projectionPlanes, currentProjectionPlane];
    
    #plot stuff --------------------
    #i = frustumIndex_in;
    #plot3(     
    #  [0, planeCorners.mainDir(1)],    [0,planeCorners.mainDir(2)],    [0,planeCorners.mainDir(3)] , "",
    #  [0, planeCorners.LowerLeft(1)],  [0,planeCorners.LowerLeft(2)],  [0,planeCorners.LowerLeft(3)] , "",
    #  [0, planeCorners.LowerRight(1)], [0,planeCorners.LowerRight(2)], [0,planeCorners.LowerRight(3)] , "",
    #  [0, planeCorners.UpperLeft(1)],  [0,planeCorners.UpperLeft(2)],  [0,planeCorners.UpperLeft(3)] , "",
    #  [0, planeCorners.UpperRight(1)], [0,planeCorners.UpperRight(2)], [0,planeCorners.UpperRight(3)] , "",   
    #  planeCorners.screenFrame_xs, 
    #  planeCorners.screenFrame_ys, 
    #  planeCorners.screenFrame_zs, 
    #  "-"
    #)
    #text ( planeCorners.mainDir(1), planeCorners.mainDir(2), planeCorners.mainDir(3),
    #       strcat( "frustum", num2str(frustumIndex_in)));
    
  endfor

  
  # Load template ini file
  iniFileName_in = "display_distributed_cluster_TEMPLATE.ini";
  iniStruct_in_out = ini2struct(iniFileName_in);

  #-------------------------------------------------------------------------------
  #-------------------------------------------------------------------------------
  # modify relevant values in the loaded ini struct:
  
  
  
  for planeIndex_out = 1 : numel(frusta_FOV_Euler)
    
    currProjPlaneName = strcat("arenart", num2str(planeIndex_out), "_PROJECTION");
    currProjPlaneIniStruct = iniStruct_in_out.(currProjPlaneName);
    
    currProjPlaneSGCTStruct = projectionPlanes(planeIndex_out);
    
    midpoint = currProjPlaneSGCTStruct.PROJ_PLANE_MIDPOINT;
    normal =   currProjPlaneSGCTStruct.PROJ_PLANE_NORMAL;
    up =       currProjPlaneSGCTStruct.PROJ_PLANE_UP;
    extents =  currProjPlaneSGCTStruct.PROJ_PLANE_EXTENTS;
    
    currProjPlaneIniStruct.PROJ_PLANE_MIDPOINT = ...
      strcat(
        num2str(midpoint(1)), ", ",
        num2str(midpoint(2)), ", ",
        num2str(midpoint(3))
      );
    currProjPlaneIniStruct.PROJ_PLANE_NORMAL = ...
      strcat(
        num2str(normal(1)), ", ",
        num2str(normal(2)), ", ",
        num2str(normal(3))
      );
    currProjPlaneIniStruct.PROJ_PLANE_UP = ...
      strcat(
        num2str(up(1)), ", ",
        num2str(up(2)), ", ",
        num2str(up(3))
      );
    currProjPlaneIniStruct.PROJ_PLANE_EXTENTS = ...
      strcat(
        num2str(extents.x_min), ", ",
        num2str(extents.x_max), ", ",
        num2str(extents.y_min), ", ",
        num2str(extents.y_max)
      );      
     
     
    # assign updated structure to main struct:
    iniStruct_in_out.(currProjPlaneName) = currProjPlaneIniStruct;
    
  endfor
  



  #-----------------------------------------------------------------------------
  # write the modified INI struct to output INI file:
  writeIniFile("display_distributed_cluster_OUTPUT.ini", iniStruct_in_out);
  
  
  ret = 0; # success
  return
  
endfunction
#------------------------------------------------------------------------------- 
#-------------------------------------------------------------------------------
  

#https://stackoverflow.com/questions/11453165/matlab-get-string-containing-variable-name
function out = varname(var)
  out = inputname(1);
end
