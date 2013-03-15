function edgePriors = getEdgePriors(orientedScoreSpace3D,edges2pixels)
% computes N-by-nOrientation matrix for each edge given in edges2pixels
% returns the max response for each edge

% Inputs:
%   orientedScoreSpace3D - m-by-n-by-nOrientation matrix for the
%   orientation response for each pixel in the image of size m-by-n
%   edges2pixels - contains the pixel inds for each edge

% Output:
%   edgePriors - N-by-1 array of max responses

[numR,numC,nOrientations] = size(orientedScoreSpace3D); 
numEdges = size(edges2pixels,1);
edgePriors_all = zeros(numEdges,nOrientations);
edgePriors = zeros(numEdges,1);
for i=1:numEdges
    % for each edge, get the pixel indices
    edgePixelInds = edges2pixels(i,:);              % list indices
    edgePixelInds = edgePixelInds(edgePixelInds>0); % indices of edge pixels wrt image
    % for each orientation take the average over all pixels
    for j=1:nOrientations
        % get the total response for all edge pixels for this dimension
        orientationResp_j = orientedScoreSpace3D(:,:,j);
        meanEdgePixResp_j = mean(orientationResp_j(edgePixelInds));
        edgePriors_all(i,j) = meanEdgePixResp_j;
    end
    edgePriors(i) = max(edgePriors_all(i,:));
        
end