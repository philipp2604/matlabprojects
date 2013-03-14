function adjacencyMat = getAdjacencyMat(nodeEdges)
% Input:
%   nodeEdges: gives the list of edgeIDs connected to each junction node
%       each row is -> junctionInd,edge1, edge2, edge3, edge4, ..
[numNodes, numEdgesPerNode] = size(nodeEdges);
adjacencyMat = zeros(numNodes);

numEdges = max(max(nodeEdges(:,2:numEdgesPerNode)));

for i=1:numEdges
    % for each edge, find the two corresponding nodes at its ends
    [R,C] = find(nodeEdges(:,2:numEdgesPerNode)==i);
    % R has the list indices of the junctions corresponding to edge i
    if(numel(R)==2)
        % assign to adjacencyMat
        nodeInd = nodeEdges(R,1);
        j1 = find(nodeEdges(:,1)==nodeInd(1));
        j2 = find(nodeEdges(:,1)==nodeInd(2));
        adjacencyMat(j1,j2) = i; % assign edgeId to the adjMat
        adjacencyMat(j2,j1) = i;
    else
        i
        numel(R)
    end
end