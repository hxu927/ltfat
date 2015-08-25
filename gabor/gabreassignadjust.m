function sr=gabreassignadjust(s,pderivs,a,varargin)
%GABREASSIGNADJUST Reassign time-frequency distribution
%   Usage:  sr = gabreassign(s,pderivs,a,mu);
%
%   `gabreassign(s,pderivs,a,mu)` reassigns the values of the positive
%   time-frequency distribution *s* using first and second order phase 
%   derivatives given by *pderivs* and parameter *mu*>0. 
%   The lattice is determined by the time shift *a* and the number of 
%   channels deduced from the size of *s*.
%
%   *pderivs* is a cell array of phase derivatives obtainable by 
%   as follows::
%
%      pderivs = gabphasederiv({'t','f','tt','ff','tf'},...,'relative');
%
%   Please see help of |gabphasederiv| for description of the other
%   parameters.
%
%   `gabreassign(s,pderivs,a,mu,despeckle)` works as above, but some 
%   coeficients are removed prior to the reassignment process. More
%   precisely a mixed phase derivative `pderivs{5}` is used to determine 
%   which coefficients `m,n` belong to sinusoidal components (such that 
%   `abs(1+pderivs{5}(m,n))` is close to zero) and to impulsive
%   components (such that `abs(pderivs{5}(m,n))` is close to zero).
%   Parameter *despeckle* determines a threshold on the previous quantities
%   such that coefficients with higher associated values are set to zeros.
%
%   Algorithm
%   ---------
%
%   The routine uses the adjustable reassignment presented in the
%   references.
%
%   Examples:
%   ---------
%
%   The following example demonstrates how to manually create a
%   reassigned spectrogram.:::
%
%     % Compute the phase derivatives
%     a=4; M=100;
%     [pderivs, c] = gabphasederiv({'t','f','tt','ff','tf'},'dgt',bat,'gauss',a,M,'relative');
%
%     % Reassignemt parameter
%     mu = 0.1;
%     % Perform the actual reassignment
%     sr = gabreassignadjust(abs(c).^2,pderivs,a,mu);
%
%     % Display it using plotdgt
%     plotdgt(sr,a,143000,50);
%  
%   See also: gabphasederiv, gabreassign
%
%   References: aufl12 auchfl12b ltfatnote042

% AUTHOR: Peter L. Søndergaard, 2008; Zdeněk Průša 2015

thisname = upper(mfilename);
complainif_notenoughargs(nargin,3,thisname);
complainif_notposint(a,'a',thisname);

definput.keyvals.mu=0;
definput.keyvals.despeckle=0;
[~,~,mu,despeckle] = ltfatarghelper({'mu','despeckle'},definput,varargin);

if ~(isscalar(mu) && mu>=0)
    error('%s: mu must be a real positive number.',thisname);
end

if ~(isscalar(despeckle) && despeckle>=0)
    error('%s: despeckle must be a real positive number.',thisname);
end

[M,N,W] = size(s);
if W>1
    error(['%s: c must be 2D matrix.'],thisname); 
end

if ~(iscell(pderivs) && numel(pderivs) == 5) 
    error(['%s: pderiv must be a cell array of phase derivatives in ',...
           'the following order t,f,tt,ff,tf.'],thisname);
end

% Basic checks
if any(cellfun(@(el) isempty(el) || ~isnumeric(el),{s,pderivs{:}}))
    error(['%s: s and elements of the cell array pderivs must be ',...
           'non-empty and numeric.'],upper(mfilename));
end

% Check if argument sizes are consistent
sizes = cellfun(@size,pderivs,'UniformOutput',0);
if ~isequal(size(s),sizes{:})
   error(['%s: s and all elements of the cell array pderivs must ',... 
         'have the same size.'], upper(mfilename));
end

% Check if any argument is not real
if any(cellfun(@(el) ~isreal(el),{s,pderivs{:}}))
   error('%s: s and all elements of the cell array pderivs must be real.',...
          upper(mfilename));
end

if any(s<0)
    error('%s: s must contain positive numbers only.',...
        upper(mfilename));
end

[tgrad,fgrad,ttgrad,ffgrad,tfgrad] = deal(pderivs{:});


if despeckle~=0
    % Removes coefficients which are neither sinusoidal component or
    % impulse component based on the mixed derivative.
    
    % How reassigned time position changes over time
    thatdt = -tfgrad;
    % How reassigned frequency position changes along frequency
    ohatdo = 1+tfgrad;
    % Only coefficients with any of the previous lower than despeckle is
    % kept.
    s(~(abs(ohatdo)<despeckle | abs(thatdt)<despeckle)) = 0;
end


% Construct the inverses explicitly
%
%  |trelpos| = |A1  A2|^-1|B1|
%  |frelpos| = |A3  A4|   |B2|
%
%  det(A)*|trelpos| = | A4  -A2|*|B1|
%         |frelpos| = |-A3   A1 |B2|

B1 = fgrad(:);
B2 = tgrad(:);

A1 =  tfgrad(:)  + 1 + mu;
A2 = -ffgrad(:);
A3 = -ttgrad(:);
A4 = -tfgrad(:) + mu;

dets = (A1.*A4-A2.*A3);

oneoverdets=1./dets;
% Remove nearly singular matrices
% The coefficients will not be reassigned
oneoverdets(abs(dets)<1e-10) = 0;

trelpos = oneoverdets.*( A4.*B1 - A2.*B2);
frelpos = oneoverdets.*(-A3.*B1 + A1.*B2);

% frelpos is derived from tgrad and
% trelpos is derived from fgrad
sr=comp_gabreassign(s,reshape(frelpos,M,N),reshape(trelpos,M,N),a);

