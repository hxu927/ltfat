function [b,a,z,p,k] = halfbandiir(N,fp,varargin)
%
% HALFBANDIIR  Halfband IIR filter design.
%   [B,A,Z,P,K] = HALFBANDIIR(N,Fp) designs a lowpass N-th order
%   halfband IIR filter with an equiripple characteristic.
%
%   The filter order, N, must be selected such that N is an odd integer.
%   Fp determines the passband edge frequency that must satisfy
%   0 < Fp < 1/2 where 1/2 corresponds to pi/2 [rad/sample].
%
%   [B,A,Z,P,K] = HALFBANDIIR('minorder',Fp,Dev) designs the minimum
%   order IIR filter, with passband edge Fp and ripple Dev.
%   Dev is a passband ripple that must satisfy 0 < Dev (linear) < 0.29289
%   or stopband attenuation that must satisfy Dev (dB) > 3.1
%
%   The last three left-hand arguments are the zeros and poles returned in
%   length N column vectors Z and P, and the gain in scalar K. 
% 
%   [B,A,Z,P,K] = HALFBANDIIR(...'high') returns a highpass halfband filter.
%
%   EXAMPLE: Design a minimum order halfband filter with given max ripple
%      [b,a,z,p,k]=halfbandiir('minorder',.45,0.0001);
%
%   Authors: Miroslav Lutovac  and  Ljiljana Milic
%   lutovac@kondor.etf.bg.ac.yu     milic@kondor.imp.bg.ac.yu
%   http://kondor.etf.bg.ac.yu/~lutovac
%   http://galeb.etf.bg.ac.yu/~milic
%   Copyright (c) 2003 Miroslav Lutovac and Ljiljana Milic
%   $Revision: 2.1 $  $Date: 2003/04/02 12:22:33 $

% This file is part of EMF toolbox for MATLAB.
% Refer to the file LICENSE.TXT for full details.
%                        
% EMF version 2.1, Copyright (c) 2003 M. Lutovac and Lj. Milic
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; see LICENSE.TXT for details.
%                       
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%                       
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc.,  59 Temple Place,  Suite 330,  Boston,
% MA  02111-1307  USA,  http://www.fsf.org/

error(nargchk(2,4,nargin));

[minOrderFlag,lowpassFlag,msg] = validateParseInput(N,fp,varargin{:});
error(msg);

omegap = fp*pi;
omegas = (1-fp)*pi;
if minOrderFlag,
  if varargin{1} <1
    deltap = varargin{1};
    deltas = sqrt(deltap*(2-deltap));
    Rp = -20*log10(1-deltap);
    Rs = -20*log10(deltas);
  else
    Rs = varargin{1};
    deltas = 10^(-Rs/20);
    deltap = 1-sqrt(1-deltas^2);
    Rp = -20*log10(1-deltap);
  end
  N = estimateOrder(omegap,omegas,Rp,Rs);
end

if N < 3, N = 3; end

fa = (1-fp)/2;
x = 1/(tan(pi*fp/2))^2;
if x >= sqrt(2)
   t = .5*(1-(1-1/x^2)^(1/4))/(1+(1-1/x^2)^(1/4));
   q = t+2*t^5+15*t^9+150*t^13;
else
   t = .5*(1-1/sqrt(x))/(1+1/sqrt(x));
   qp = t+2*t^5+15*t^9+150*t^13;
   q = exp(pi^2/log(qp));
end
L = (1/4)*sqrt(1/q^N-1);
Rp = 10*log10(1+1/L);
Rs = 10*log10(1+L);

if N == 3
  beta = nfp2beta(N,fp/2);
  p = [0;i*sqrt(beta);-i*sqrt(beta)];
  z = [-1
       (beta-1 + i*sqrt(3*beta^2 + 2*beta-1))/(2*beta)
       (beta-1 - i*sqrt(3*beta^2 + 2*beta-1))/(2*beta)];
  k =  beta/2;
  b = [beta 1 1 beta]/2;
  a = [1 0 beta 0];
elseif N == 5
  [beta,zeroi,select] = nfp2beta(N,fp/2);
  k = 1/2;
  p = 0;
  z = -1;
  for ind = 2:2:N
    ind2 = ind/2;
    p = [p;i*sqrt(beta(ind2));-i*sqrt(beta(ind2))];
    z = [z;(zeroi(ind2)^2-select+i*2*sqrt(select)*zeroi(ind2))/(select+zeroi(ind2)^2)];
    z = [z;(zeroi(ind2)^2-select-i*2*sqrt(select)*zeroi(ind2))/(select+zeroi(ind2)^2)];
    k = k*(1+beta(ind2))*(1+zeroi(ind2)^2/select)/4;
  end
  aOdd = 1;  bOdd = 1;
  for ind = 1:2:length(beta)
    aOdd = conv(aOdd,[1 0 beta(ind)]);
    bOdd = conv(bOdd,[beta(ind) 0 1]);
  end
  aEven = 1; bEven = 1;
  for ind = 2:2:length(beta)
    aEven = conv(aEven,[1 0 beta(ind)]);
    bEven = conv(bEven,[beta(ind) 0 1]);
  end
  a = conv(conv(aOdd,aEven),[1 0]);
  b = (conv(conv(aOdd,bEven),[0 1]) + conv(conv(bOdd,aEven),[1 0]))/2;
else
  %  [z,p,k] = ellip(N,Rp,Rs,omegap/pi)
  %  [b,a] = ellip(N,Rp,Rs,omegap/pi)
  [beta,zeroi,select] = nfp2beta(N,fp/2);
  k = 1/2;
  p = 0;
  z = -1;
  for ind = 2:2:N
    ind2 = ind/2;
    p = [p;i*sqrt(beta(ind2));-i*sqrt(beta(ind2))];
    z = [z;(zeroi(ind2)^2-select+i*2*sqrt(select)*zeroi(ind2))/(select+zeroi(ind2)^2)];
    z = [z;(zeroi(ind2)^2-select-i*2*sqrt(select)*zeroi(ind2))/(select+zeroi(ind2)^2)];
    k = k*(1+beta(ind2))*(1+zeroi(ind2)^2/select)/4;
  end
  aOdd = 1;  bOdd = 1;
  for ind = 1:2:length(beta)
    aOdd = conv(aOdd,[1 0 beta(ind)]);
    bOdd = conv(bOdd,[beta(ind) 0 1]);
  end
  aEven = 1; bEven = 1;
  for ind = 2:2:length(beta)
    aEven = conv(aEven,[1 0 beta(ind)]);
    bEven = conv(bEven,[beta(ind) 0 1]);
  end
  a = conv(conv(aOdd,aEven),[1 0]);
  b = (conv(conv(aOdd,bEven),[0 1]) + conv(conv(bOdd,aEven),[1 0]))/2;
end

if ~lowpassFlag,
  z = -z;
  b = b.*((-(ones(size(b)))).^(1:length(b)));
end

%-------------------------------------------------------------
function N = estimateOrder(omegap,omegas,Rp,Rs)
  N = ellipord(omegap/pi,omegas/pi,Rp,Rs);
  N = adjustOrder(N);
	
%-------------------------------------------------------------
function N = adjustOrder(N)
  if (N+1) ~= 2*fix((N+1)/2),
    N = N + 1;
  end

%-------------------------------------------------------------
function [minOrderFlag,lowpassFlag,msg] = validateParseInput(N,fp,varargin)
  msg = '';
  minOrderFlag = 0;
  lowpassFlag = 1;
  if nargin > 2 & ischar(varargin{end}),
    stringOpts = {'low','high'};
    lpindx = strmatch(lower(varargin{end}),stringOpts);
    if ~isempty(lpindx) & lpindx == 2,
      lowpassFlag = 0;
    end
  end
  if ischar(N),
    ordindx = strmatch(lower(N),'minorder');
    if ~isempty(ordindx),
      minOrderFlag = 1;
      if nargin < 3,
        msg = 'Passband ripple, Dev, must be specified for minimum order design.';
        return
      end
      if ~isValidScalar(varargin{1}),
        msg = 'Passband ripple must be a scalar.';
        return
      elseif varargin{1} <= 0 | ((varargin{1} >= 0.29289)&(varargin{1} <= 3.1)) ,
        msg = ['Dev=' num2str(varargin{1}) ', it must be 0<Dev(linear)<0.29289, or Dev (dB) >3.1'];
        return
      end
    else
      msg = 'Specified unrecognized order.';
      return
    end
  elseif ~isValidScalar(N),
    msg = 'Specified unrecognized order.';
    return
  else
    if (N+1) ~= 2*fix((N+1)/2),
      msg = ['N=' num2str(N) ', order must be an odd integer.'];
      return
    end
    if nargin > 2 & ~ischar(varargin{1}),
      msg = 'Passband ripple, Dev, can be specified for minimum order design, only.';
      return
    end
  end
  if length(fp) ~= 1,
    msg = ['Length of Fp = ' num2str(length(fp)) ', length must be 1.'];
    return
  else,
    if ~isValidScalar(fp),
      msg = 'Passband edge frequency must be a scalar, 0<Fp<1/2.';
      return
    end
    if fp <= 0 | fp >= 0.5,
      msg = ['Fp=' num2str(fp) ', passband edge frequency must satisfy 0<Fp<1/2.'];
      return
    end
  end

%------------------------------------------------------------------------
function bol = isValidScalar(a)
  bol = 1;
  if ~isnumeric(a) | isnan(a) | isinf(a) | isempty(a) | length(a) > 1,
    bol = 0;
  end


%------------------------------------------------------------------------
function [beta,xx,a] = nfp2beta(n,fp)
  a = 1/tan(pi*fp)^2;
  for ind = 1:(n-1)/2
    x = ellipj( ((2*ind-1)/n + 1)*ellipke(1/a^2), 1/a^2);
    b(ind) = ((a+x^2) - sqrt((1-x^2)*(a^2-x^2)) )/((a+x^2) + sqrt((1-x^2)*(a^2-x^2)));
    xx(ind) = x;
  end
  beta = sort(b);

%------- [EOF] ----------------------------------------------------------
