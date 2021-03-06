% function [cumulative, usage] = getWordUsage(sparsecoefmatrix)

% generate statistics for each word based on their usage for image
% reconstruction

% outputs:
% cumulative = cumulative value of all the (positive) coefficients for
% each word. column vector.
% usage = number of times each word has been used. column vector.

function [cumulative, usage] = getWordUsage(sparsecoefmatrix)
cumulative = sum(sparsecoefmatrix,2); % sums up the coefficient values for each word

usage = zeros(size(sparsecoefmatrix,1),1);
for i = 1:size(sparsecoefmatrix,1)
    usage(i) = length(find(sparsecoefmatrix(i,:))); % 
end

figure(1);
hist(cumulative',length(cumulative));
title('Cumulative coefficient values for each word');

figure(2);
hist(usage',length(usage));
title('Usage for each word');