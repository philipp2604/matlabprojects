function relZresolution = predictThicknessFromCurve(...
        imageStackFileName,xcorrMat,maxShift,calibrationMethod)
% Returns the section thickness relative to the xy resolution. Multiply by
% xyResolution to get the actual thickness.

% calibrationMethod
% 1 - correlation coefficient across ZY sections, along x axis
% 2 - correlation coefficient across XY sections, along x axis
% 3 - SD of XY per pixel intensity difference
% TODO: methods robust against registration problems
    
inputImageStack = readTiffStackToArray(imageStackFileName);
numImg = size(inputImageStack,3);

relZresolution = zeros(1,numImg-1); % relative to xy pix resolution

if(calibrationMethod==3)
    
else

for i = 1:numImg-1
   
   image1 = inputImageStack(:,:,i);
   image2 = inputImageStack(:,:,(i+1));
   relZresolution(i) = getRelativeDistance_cc2(image1,image2,mean(xcorrMat,1),maxShift);
   
end

end