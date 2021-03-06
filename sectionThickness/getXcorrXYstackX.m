function cocMat = getXcorrXYstackX(inputImageStackFileName,maxShift,minShift,maxNumImages)
% calculate the correlation of XY face along the X axis . i.e. parallel to the
% cutting plane where we have maximum resolution (5nmx5nm for FIBSEM)

% Inputs:
% imageStack - image stack (tif) for which the thickness has to be
% estimated. This has to be registered along the z axis already.

% Outputs:
%   cocMat - Matrix containg coefficient of correlation for image pairs.
%   Each row corresponds to a different starting image. The distance
%   increases with the column index

inputImageStack = readTiffStackToArray(inputImageStackFileName);
% inputImageStack is a 3D array where the 3rd dimension is along the z axis

% estimate the correlation curve (mean and sd) from different sets of
% images within the max window given by maxShift

% initially use just one image

% I = double(imread(imageStack));
numImages = size(inputImageStack,3); % z axis

% TODO: current we take the first n images for the estimation. Perhaps we
% can think of geting a random n images.
disp('Estimating similarity curve using correlation coefficient of shifted XY sections ...')
if(maxNumImages>numImages)
    maxNumImages = numImages;
    str1 = sprintf('maxNumImages > numImages. using numImages = %d instead',numImages);
    disp(str1)
end
numShifts = maxShift - minShift + 1;
cocMat = zeros(maxNumImages,numShifts);
for z=1:maxNumImages
    I = inputImageStack(:,:,z);
    [numR,numC] = size(I);
    k=0;
    for g=minShift:maxShift
        A = zeros(numR,numC-g);
        B = zeros(numR,numC-g);

        A(:,:) = I(:,1+g:size(I,2));
        B(:,:) = I(:,1:size(I,2)-g);
        k=k+1;
        cocMat(z,k) = corr2(A,B);
    end
end

%% plot
% titleStr = 'Coefficient of Correlation using XY sections along X axis';
% xlabelStr = 'Shifted pixels';
% ylabelStr = 'Coefficient of Correlation';
% transparent = 0;
% shadedErrorBar((1:maxShift),mean(cocMat,1),std(cocMat),'g',transparent,...
%     titleStr,xlabelStr,ylabelStr);
