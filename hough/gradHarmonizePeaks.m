function gradHarmonizedPeaks3D = gradHarmonizePeaks(peaks3D,orientations,gradMap,barLength,barWidth)
% adjusts the votes in peaks3D so that the peaks in harmony with the
% gradient are enhanced.

% parameters
w1 = 5;
gradThresh = 0.5;
margin = (max(barLength,barWidth)+1)/2 ;
[numRows numCols numOrientations] = size(peaks3D);
% initialize
gradHarmonizedPeaks3D = zeros(numRows,numCols,numOrientations);
% remove gradient magnitudes from the image border
gradMag = gradMap(:,:,1);
gradMag(1:margin,:) = 0;
gradMag((numRows-margin):numRows,:) = 0;
gradMag(:,1:margin) = 0;
gradMag(:,(numCols-margin):numCols) = 0;

gradMag = gradMag./max(max(gradMag)); % normalizing gradient magnitudes 0-1
gradOri = gradMap(:,:,2);
% discretize gradMap(:,:,2) to match the [orientations]
%discreteGradOri = discretizeAngles(gradMap(:,:,2),orientations);

% get the perpendicular directions to the grad orientations
gradOriPerp = gradOri - 90;
adjInd = find(gradOriPerp<0);
gradOriPerp(adjInd) = gradOriPerp(adjInd) + 180;

%gradMap(:,:,2) = gradOriPerp;

% now gradMap contains the grad magnitude and the discretized perpendicular
% orientation of the gradient.

% calculate and assign scores depending on the deviation of orientations to
% the perpendiculars to the gradients

% we can process each orientation of peaks3D separately

% get the points with this orientation from gradMap - GP1

for i=1:numOrientations
    % for each orientation, identify the relevant points from gradMap
    orientation = orientations(i);
    gradPointInd = getSimilarGradOriPoints(gradOriPerp,orientation); % indices of the points
            % that are relevant for this orientation (doesn't consider magnitude)
    gradMag_i = gradMag;
    ind_gradMag_i = find(gradMag_i>gradThresh);
    gradPointInd = intersect(gradPointInd,ind_gradMag_i);
    
    H_i = peaks3D(:,:,i);
    H_i = H_i./(max(max(H_i))); % normalization of votes
    score1 = exp(-(gradMag_i(gradPointInd) - H_i(gradPointInd)).^2);
    H_i(gradPointInd) = H_i(gradPointInd) + score1.*w1;
    gradHarmonizedPeaks3D(:,:,i) = H_i;
    
end
