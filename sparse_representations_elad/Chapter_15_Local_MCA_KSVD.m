% Figures - 15.7, 15.8, and 15.9
% =========================================
% This function applies K-SVD denoising on the given image (barbara)
% followed by a processing of the obtained dicitonary, in order to 
% distinguish between texture and cartoon atoms. Based on this 
% labeling, the image is decomposed. 



function []=Chapter_15_Local_MCA_KSVD()


K=256; 
n=8; 
sigma=10; % noise power
const=sqrt(1.15); 
numIteration=25; 
lambda=0.5; 

% Gather the data from the noisy Barbara
y0=imread('barbara.png'); 
y0=double(y0); 
N=size(y0,1);
noise=randn(N,N);
y=y0+sigma*noise; % add noise
PSNRinput=10*log10(255^2/mean((y(:)-y0(:)).^2)); 

Data=zeros(n^2,(N-n+1)^2);
cnt=1; 
for j=1:1:N-n+1
    for i=1:1:N-n+1
        patch=y(i:i+n-1,j:j+n-1);
        Data(:,cnt)=patch(:); 
        cnt=cnt+1;
    end;
end;

% initialize the dictionary
Dictionary=zeros(n,sqrt(K));
for k=0:1:sqrt(K)-1,
    V=cos([0:1:n-1]*k*pi/sqrt(K));
    if k>0, V=V-mean(V); end;
    Dictionary(:,k+1)=V/norm(V);
end;
Dictionary=kron(Dictionary,Dictionary);
Dictionary=Dictionary*diag(1./sqrt(sum(Dictionary.*Dictionary)));

% zeroing various result vectors
TotalErr=zeros(1,21+1);
NumCoef=zeros(1,21+1);

% Sparse coding with the initial dictionary
% CoefMatrix=OMPerr(Dictionary,Data, sigma*const);
% ==> The next line uses Ron Rubinstein's very fast OMP package
CoefMatrix=omp2(Dictionary'*Data,sum(Data.*Data),Dictionary'*Dictionary,n*sigma*const); 
yout=RecoverImage(y,lambda,Dictionary,CoefMatrix); 
PSNRoutput=10*log10(255^2/mean((yout(:)-y0(:)).^2)); 
disp([PSNRinput,PSNRoutput]);

% compute the errors
counter=1;
TotalErr(counter)=sqrt(sum(sum((Data-Dictionary*CoefMatrix).^2))/numel(Data));
NumCoef(counter)=length(find(CoefMatrix))/size(Data,2);
disp(['Iteration ',num2str(0),':  Error=',num2str(TotalErr(counter)), ...
    ', Average cardinality: ',num2str(NumCoef(counter))]);
counter=counter+1;

% Main Iterations
for iterNum=1:numIteration

    % Update the dictionary
    Dictionary(:,1)=Dictionary(:,1); % the DC term remain unchanged
    for j=2:1:size(Dictionary,2)
        relevantDataIndices=find(CoefMatrix(j,:));
        if ~isempty(relevantDataIndices)
            tmpCoefMatrix=CoefMatrix(:,relevantDataIndices);
            tmpCoefMatrix(j,:)=0;
            errors=Data(:,relevantDataIndices)-Dictionary*tmpCoefMatrix;
            [betterDictionaryElement,singularValue,betaVector]=svds(errors,1);
            CoefMatrix(j,relevantDataIndices)=singularValue*betaVector';
            Dictionary(:,j)=betterDictionaryElement;
        end;
    end;
    IMdict=Chapter_12_DispDict(Dictionary,sqrt(K),sqrt(K),n,n,0);
    figure(1); clf; 
    imagesc(IMdict); colormap(gray(256)); axis image; axis off; drawnow; 
    % print -depsc2 Chapter_15_KSVD_dicALL.eps

    % Compute the errors and display
    TotalErr(counter)=sqrt(sum(sum((Data-Dictionary*CoefMatrix).^2))/numel(Data));
    NumCoef(counter)=length(find(CoefMatrix))/size(Data,2);
    disp(['Iteration ',num2str(iterNum),': Error=',num2str(TotalErr(counter)),...
        ', Average cardinality: ',num2str(NumCoef(counter))]);
    counter=counter+1;
    
    % lean-up rarely used or too-close atoms
    T2=0.99; T1=3;
    Er=sum((Data-Dictionary*CoefMatrix).^2,1);
    G=Dictionary'*Dictionary;
    G=G-diag(diag(G));
    for j=2:1:size(Dictionary,2)
        if max(G(j,:))>T2
            alternativeAtom=find(G(j,:)==max(G(j,:)));
            [val,pos]=max(Er);
            Er(pos(1))=0;
            Dictionary(:,j)=Data(:,pos(1))/norm(Data(:,pos(1)));
            G=Dictionary'*Dictionary;
            G=G-diag(diag(G));            
        elseif length(find(abs(CoefMatrix(j,:))>1e-7))<=T1
            [val,pos]=max(Er);
            Er(pos(1))=0;
            Dictionary(:,j)=Data(:,pos(1))/norm(Data(:,pos(1)));
            G=Dictionary'*Dictionary;
            G=G-diag(diag(G));
        end;
    end;
    
    % Sparse coding: find the coefficients
    % CoefMatrix=OMPerr(Dictionary,Data,sigma*const);
    % ==> The next line uses Ron Rubinstein's very fast OMP package
    CoefMatrix=omp2(Dictionary'*Data,sum(Data.*Data),Dictionary'*Dictionary,n*sigma*const);
    yout=RecoverImage(y,lambda,Dictionary,CoefMatrix); 
    PSNRoutput=10*log10(255^2/mean((yout(:)-y0(:)).^2)); 
    disp([PSNRinput,PSNRoutput]);

    % Compute the errors and display
    TotalErr(counter)=sqrt(sum(sum((Data-Dictionary*CoefMatrix).^2))/numel(Data));
    NumCoef(counter)=length(find(CoefMatrix))/size(Data,2);
    disp(['Iteration ',num2str(iterNum),': Error=',num2str(TotalErr(counter)),...
        ', Average cardinality: ',num2str(NumCoef(counter))]);
    counter=counter+1;   
end;

% ========================================================

% The denoising is done, and now we turn to the sepration task, by
% detecting the most active atoms and tagging them as belonging to the
% texture

% Measuring the activity of each atom by ~TV
Activity=zeros(1,K);
for k=1:1:K
    atom=reshape(Dictionary(:,k),[n,n]);
    Activity(k)=sum(sum(abs(atom(:,1:n-1)-atom(:,2:n))))+...
                     sum(sum(abs(atom(1:n-1,:)-atom(2:n,:))));
end
Activity=Activity/max(Activity);

% Display the activity map
DispMAP(ones(n^2,1)*Activity,sqrt(K),sqrt(K),n,n,2,1); 
% print -depsc2 Chapter_15_LocalActivityMAP.eps

% The separation by separating the dictionary
T=0.27; % the threshold for choosing texture/cartoon atom
DispMAP(ones(n^2,1)*(Activity>T),sqrt(K),sqrt(K),n,n,3,0); 
% print -depsc2 Chapter_15_DictionaryTag.eps
CartoonAtoms=find(Activity<=T);
TextureAtoms=find(Activity>T);

% Separating the coefficients
CoefMatrixCartoon=CoefMatrix(CartoonAtoms,:);
CoefMatrixTexture=CoefMatrix(TextureAtoms,:);

% Building the cartoon and texture parts
Texture=RecoverImage(y,0,Dictionary(:,TextureAtoms),CoefMatrixTexture); 
Cartoon=RecoverImage(y,0,Dictionary(:,CartoonAtoms),CoefMatrixCartoon); 

figure(4); imagesc(Cartoon); colormap(gray(256)); axis image; axis off; 
% print -depsc2 Chapter_15_Local_KSVD_Cartoon.eps

figure(5); imagesc(Texture); colormap(gray(256)); axis image; axis off; 
% print -depsc2 Chapter_15_Local_KSVD_Texture.eps

return;

% ========================================================
% ========================================================

function [A]=OMPerr(D,X,errorGoal)
% ========================================================
% Sparse coding of a group of signals based on a given dictionary and specified representation
% error to get.
% input arguments: D - the dictionary
%                           X - the signals to represent
%                           errorGoal - the maximal allowed representation error
% output arguments: A - sparse coefficient matrix.
% ========================================================
[n,P]=size(X);
[n,K]=size(D);
E2 = errorGoal^2*n;
maxNumCoef = n/2;
A = sparse(size(D,2),size(X,2));
h=waitbar(0,'OMP on each example ...');
for k=1:1:P,
    waitbar(k/P);
    a=[];
    x=X(:,k);
    residual=x;
    indx = [];
    a = [];
    currResNorm2 = sum(residual.^2);
    j = 0;
    while currResNorm2>E2 && j < maxNumCoef,
        j = j+1;
        proj=D'*residual;
        pos=find(abs(proj)==max(abs(proj)));
        pos=pos(1);
        indx(j)=pos;
        a=pinv(D(:,indx(1:j)))*x;
        residual=x-D(:,indx(1:j))*a;
        currResNorm2 = sum(residual.^2);
    end;
    if (~isempty(indx))
        A(indx,k)=a;
    end
end;
close(h); 
return;

% ========================================================
% ========================================================

function [yout]=RecoverImage(y,lambda,D,CoefMatrix)
% ========================================================
% ========================================================
N=size(y,1); 
n=sqrt(size(D,1)); 
yout=zeros(N,N); 
Weight=zeros(N,N); 
i=1; j=1;
for k=1:1:(N-n+1)^2,
    patch=reshape(D*CoefMatrix(:,k),[n,n]); 
    yout(i:i+n-1,j:j+n-1)=yout(i:i+n-1,j:j+n-1)+patch; 
    Weight(i:i+n-1,j:j+n-1)=Weight(i:i+n-1,j:j+n-1)+1; 
    if i<N-n+1 
        i=i+1; 
    else
        i=1; j=j+1; 
    end;
end;
yout=(yout+lambda*y)./(Weight+lambda); 
return;

% ========================================================
% ========================================================

function []=DispMAP(D,numRows,numCols,X,Y,fig,bar)

% This function displays the activity map in the same way the diciotnary is
% shown

borderSize=1;

% Preparing the image 
sizeForEachImage =sqrt(size(D,1))+borderSize;
I=zeros(sizeForEachImage*numRows+borderSize,...
            sizeForEachImage*numCols+borderSize,3);
I(:,:,1)=0;
I(:,:,2)=0; 
I(:,:,3)=1; 

% Fill the image with the atoms
counter=1;
for j = 1:numRows
    for i = 1:numCols
        I(borderSize+(j-1)*sizeForEachImage+1:j*sizeForEachImage,...
           borderSize+(i-1)*sizeForEachImage+1:i*sizeForEachImage,1)...
           =reshape(D(:,counter),X,Y);
        I(borderSize+(j-1)*sizeForEachImage+1:j*sizeForEachImage,...
           borderSize+(i-1)*sizeForEachImage+1:i*sizeForEachImage,2)...
           =reshape(D(:,counter),X,Y);
        I(borderSize+(j-1)*sizeForEachImage+1:j*sizeForEachImage,...
           borderSize+(i-1)*sizeForEachImage+1:i*sizeForEachImage,3)...
           =reshape(D(:,counter),X,Y);
        counter = counter+1;
    end
end

figure(fig); clf;
imagesc(I); colormap(gray(256)); axis image; axis off; drawnow;
if bar==1
    colorbar; 
end;

return;
