function [cvec,Lc] = wavcell2pack(ccell,varargin)
%WAVCELL2PACK Changes wavelet coefficients storing format
%   Usage:  [cvec,Lc] = wavcell2pack(ccell);
%
%   Input parameters:
%         ccell    : Coefficients stored in a collumn cell-array.
%
%   Output parameters:
%         cvec     : Coefficients in packed format.
%         Lc       : Vector containing coefficients lengths.
%
%   *cvec* is column vector or matrix with *W* columns for multi-channel inputs containing
%   coefficients in the packed format. Coefficients are stored as follows:
%   `cvec(1:Lc(1),w)` - approximation coefficients at level *J* of the channel *w*,
%   `cvec(1+sum(Lc(1:j-1)):sum(Lc(1:j),w)` for *j>1*.
%

if(nargin<1)
    error('%s: Too few input parameters.',upper(mfilename));
end

definput.flags.format = {'channels','onecol'};
[flags,kv]=ltfatarghelper({},definput,varargin);

JJtotal = length(ccell);


if(flags.do_channels)
   [cLen, W] = size(ccell{end});

   Lc = zeros(JJtotal,1);
   for jj=1:JJtotal
      Lc(jj) =  size(ccell{jj},1);
   end

   cvec = zeros(sum(Lc),W);

   lenSumIdx = 1;
   lenSum = 0;
   for jj=1:JJtotal
      cvec(1+lenSum:Lc(lenSumIdx)+lenSum,:) = ccell{jj};
      lenSum = lenSum+Lc(lenSumIdx);
      lenSumIdx=lenSumIdx+1;
   end
elseif(flags.do_onecol)
   cLens = zeros(JJtotal,1); 
   Lc = cell(JJtotal,1);
   for jj=1:JJtotal
      Lc{jj} =  size(ccell{jj});
      cLens(jj) = prod(Lc{jj});
   end
   
   cvec = zeros(sum(cLens),1);
   
   lenSumIdx = 1;
   lenSum = 0;
   for jj=1:JJtotal
      cvec(1+lenSum:cLens(lenSumIdx)+lenSum,:) = ccell{jj}(:);
      lenSum = lenSum+cLens(lenSumIdx);
      lenSumIdx=lenSumIdx+1;
   end 
    
else
    error('Should not get here.');
end

