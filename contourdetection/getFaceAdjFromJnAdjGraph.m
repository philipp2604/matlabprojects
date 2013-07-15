function [faceAdj,edges2cells,setOfCellsMat,listOfEdgeIDs] = getFaceAdjFromJnAdjGraph...
    (edgeIDs,nodeEdges,junctionTypeListInds,jAnglesAll_alpha,...
    boundaryEdgeIDs,edges2nodes)
% Inputs: adjacency graph of junctions (planar graph)
%   edgeIDs -
%   nodeEdges -
%   junctionTypeListInds -
%   jAnglesAll_alpha -
%   boundaryEdgeIDs - edges at the border of the image. Each of them belong
%   just to one cell
%   edges2nodes - 

% Outputs: 
%   faceAdj - adjacency graph of the faces of the input planar graph
%   edges2cells - each row corresponds to an edge. the two columns give you
%   the two cells that are connected by that edge. The order of edges
%   present is according to listOfEdgeIDs
%   setOfCellsMat - each row corresponds to a cell and contains the set of
%   edges bounding that cell as a row vector with zero padding.
%   listOfEdgeIDs - the edges considered in the faceAdjMatrix. Each of these edges
%   connects a pair of cells

MAX_EDGE_USAGE = 2;
MAX_BOUNDARY_EDGE_USAGE = 1;

% get edge list - keep a count of their usage i.e. the two regions each
% edge separates
numEdges = numel(edgeIDs);
edgeUsage = zeros(numEdges,2);  % col1: edgeID, col2: usage
edgeUsage(:,1) = edgeIDs;

% separately identify edges on the boundary. these edges will only bound
% one cell. p.s. there can be a few false negatives.

%setOfCells = []; % each row corresponds to a cell i.e. a set of edges enclosing a cell
cellInd = 0;
for i=1:numEdges
    % debug code
    if(i==183)  % edgeID = 15
        a = 99;
    end % debug code end
    
    % check usage
    currentEdgeID = edgeIDs(i);
    currentEdgeUsage = edgeUsage(i,2); 
    % if boundaryEdge, max usage is 1
    % check if the edge is a boundary edge.
    currentEdgeIsBoundary = 0;
    if(max(boundaryEdgeIDs==currentEdgeID))
        % is a boundary edge
        currentEdgeIsBoundary = 1;
        if(currentEdgeUsage>=MAX_BOUNDARY_EDGE_USAGE)
            continue
        end 
        % we don't want to initialize a loop with a boundary edge. - ????
%         continue
    else
        % not a boundary edge
        if(currentEdgeUsage>=MAX_EDGE_USAGE)
            continue
        end
    end
    % get next edge to complete clockwise loop at both ends
    currentNodeListInds = edges2nodes(i,:);    % row vector containing nodeListInds
    % check usage of next edge (both ends)
    nextEdgeIDs_2 = zeros(1,2);
    [nextEdgeIDs_2(1),~] = getNextEdge(currentEdgeID,currentNodeListInds(1),nodeEdges...
        ,junctionTypeListInds,jAnglesAll_alpha,edges2nodes,edgeIDs);
    [nextEdgeIDs_2(2),~] = getNextEdge(currentEdgeID,currentNodeListInds(2),nodeEdges...
        ,junctionTypeListInds,jAnglesAll_alpha,edges2nodes,edgeIDs);
    % start debug code
    if(nextEdgeIDs_2(1)==307)
        a = 98;
    elseif(nextEdgeIDs_2(2)==307)
        a = 97;
    end
    % end debug code
    
    nextEdgeUsage_2 = zeros(1,2);
    nextEdgeUsage_2(1) = edgeUsage((edgeUsage(:,1)==nextEdgeIDs_2(1)),2);
    nextEdgeUsage_2(2) = edgeUsage((edgeUsage(:,1)==nextEdgeIDs_2(2)),2);
    % check if any of the candidates are ok in terms of usage
    edge1ok = 0;
    edge2ok = 0;
    % if at least one is ok
        % set usage for this edge and next edge
        % continue loop aggregation along next edge
    % else continue
    if(max(boundaryEdgeIDs==nextEdgeIDs_2(1)))
        % nextEdge(1) is a boundary edge
        % if the current edge is also a boundary edge, pick edge2
        if(currentEdgeIsBoundary)
            edge1ok = 0;
        else
            if(nextEdgeUsage_2(1)<MAX_BOUNDARY_EDGE_USAGE)
                edge1ok = 1;
                % flag set. get loop            
            else
                edge1ok = 0;
            end
        end
    else
        % nextEdge(1) is not a boundary edge (most likely)
        if(nextEdgeUsage_2(1)<MAX_EDGE_USAGE)
            edge1ok = 1;
            % flag set. get loop
        else
            edge1ok = 0;
        end
    end
    if(~edge1ok)
        % if nextEdge(1) is not ok, check if nextEdge(2) is ok
        if(max(boundaryEdgeIDs==nextEdgeIDs_2(2)))
        % nextEdge(2) is a boundary edge
            if(nextEdgeUsage_2(2)<MAX_BOUNDARY_EDGE_USAGE)
                edge2ok = 1;
                % flag set. get loop
            else
                edge2ok = 0;
            end
        else
        % nextEdge(2) is not a boundary edge (most likely)
            if(nextEdgeUsage_2(2)<MAX_EDGE_USAGE)
                edge2ok = 1;
                % flag set. get loop.
            else
                edge2ok = 0;
            end
        end
    end   
    
    % find loops (closed contours)
    setOfEdges_loop = [];
    if(edge1ok)
        % look for loop containing edge1
        [setOfEdges_loop,edgeUsage_new] = getEdgeLoop(currentNodeListInds(1),...
            currentEdgeID,nodeEdges,junctionTypeListInds,jAnglesAll_alpha,edgeUsage,...
            boundaryEdgeIDs,MAX_EDGE_USAGE,MAX_BOUNDARY_EDGE_USAGE,...
            edges2nodes,edgeIDs);

    elseif(edge2ok)
        % look for loop containing edge2
        [setOfEdges_loop,edgeUsage_new] = getEdgeLoop(currentNodeListInds(2),...
            currentEdgeID,nodeEdges,junctionTypeListInds,jAnglesAll_alpha,edgeUsage,...
            boundaryEdgeIDs,MAX_EDGE_USAGE,MAX_BOUNDARY_EDGE_USAGE,...
            edges2nodes,edgeIDs);
    end
    
    if(~isempty(setOfEdges_loop) && setOfEdges_loop(1)~=0)
        % start debug code
        if(~isempty(find(setOfEdges_loop==307)))
            a = 88;
        end
        % end debug code
        
        
        cellInd = cellInd + 1;
        % setOfCells = [setOfCells; setOfEdges_loop];
        setOfCells{cellInd} = setOfEdges_loop;
        edgeUsage = edgeUsage_new;
    end
    
    % start debug code
    if(edgeUsage(193,2))
        a = 77;
    end
    % end debug code
end
% create adjacency matrix for the cells. The coefficients correspond to the
% edgeID that connects the corresponding pair of cells
setOfCellsMat = setOfCells2Mat(setOfCells);
numCells = size(setOfCellsMat,1);
cellList = 1:numCells; % row vector
% add the cellList (index) as the first col of setOfCells. This is done so
% that we can reuse getAdjacencyMat() to creage faceAdj.
setOfCellsMat_2 = [cellList' setOfCellsMat];
[faceAdj,edges2cells,~,listOfEdgeIDs] = getAdjacencyMat(setOfCellsMat_2);