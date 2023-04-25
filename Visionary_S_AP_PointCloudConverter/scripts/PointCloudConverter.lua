--[[----------------------------------------------------------------------------

  Application Name: Visionary_S_AP_PointCloudConverter
  
  Summary:
  Show how to calculate a full pointcloud and only a subpart of the image as pointloud in Lua
  
  Description:
  Set up the camera to take live images continuously and automatically calculate
  pointclouds out of it. First the full Z image is converted to a pointcloud
  and shown via the left Viewer. As second sample only a subset of the image
  in form of a pixel region is converted to a pointcloud to show how to save
  performance and convert only what you need to a pointcloud.
  
  How to run:
  Start by running the app (F5) or debugging (F7+F10).
  Set a breakpoint on the first row inside the main function to debug step-by-step.
  See the results in the different 3D viewer on the DevicePage.
  
  More Information:
  If you want to run this app on an emulator some changes are needed to get images.
    
------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------
  
  --uncomment Log.setLevel if you want to see the number of points in Log.info in the handleOnNewImage function
  --Log.setLevel("INFO")

-- Variables, constants, serves etc. should be declared here.

-- setup the camera, set default config and get the camera model
local camera = Image.Provider.Camera.create()
Image.Provider.Camera.stop(camera)
local config = Image.Provider.Camera.getDefaultConfig(camera)
Image.Provider.Camera.setConfig(camera, config)
local cameraModel = Image.Provider.Camera.getInitialCameraModel(camera)

-- generate point cloud converter for Planar conversion from Z image to point cloud
local pc_converter = Image.PointCloudConversion.PlanarDistance.create()

-- initialize the point cloud converter with the camera model
pc_converter:setCameraModel(cameraModel)

-- setup the two viewers
local viewers =
  { View.create("v1"),
    View.create("v2") }

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  Image.Provider.Camera.start(camera)
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register("Engine.OnStarted", main)

--------------------------------------------------------------------------------

--@handleOnNewImage(image:Image,sensordata:SensorData)
local function handleOnNewImage(image)
  -- calculate the full point cloud and color it with the distance values
  local pointCloud = pc_converter:toPointCloud(image[1], image[1])
  Log.info("Number of points of Pointcloud containing the full image: " .. pointCloud:getSize())
  -- send the whole pointcloud to the viewer to get in touch with the data
  viewers[1]:clear()
  viewers[1]:addPointCloud(pointCloud, nil)
  viewers[1]:present()

  -- calculate only a subset of the image to a pointcloud for better performance
  local pixelregionCenter = Image.PixelRegion.createCircle(Point.create(320, 256), 100)
  local pointCloudCenter = pc_converter:toPointCloud(image[1], image[1], pixelregionCenter)
  Log.info("Number of points of Pointcloud containing the the inner circle of the image defined by pixel region: " .. pointCloudCenter:getSize())
  -- send the pointcloud of the center of the image to the viewer to get in touch with the data
  viewers[2]:clear()
  viewers[2]:addPointCloud(pointCloudCenter, nil)
  viewers[2]:present()
end

--------------------------------------------------------------------------------

-- register to OnNewImage with a Event Queue, so the images don't pile up during the long PointCloud calculation
eventQueueHandle = Script.Queue.create()
eventQueueHandle:setMaxQueueSize(1)
eventQueueHandle:setPriority("HIGH")
eventQueueHandle:setFunction(handleOnNewImage)
Image.Provider.Camera.register(camera, "OnNewImage", handleOnNewImage)

--End of Function and Event Scope-----------------------------------------------
