function G=franamat(F,L);
%FRANAMAT  Frame analysis operator matrix
%   Usage: G=franamat(F,L);
%
%   `G=franamat(F,L)` returns the matrix representation *G* of the frame
%   analysis operator for a frame *F* of length *L*. The frame object *F*
%   must have been created using |newframe|_.
%
%   The frame analysis operator matrix contains all the frame atoms as column vectors. It has
%   dimensions $L \times Ncoef$, where $Ncoef$ is the number of
%   coefficients. The number of coefficients can be found as
%   `Ncoef=framered(F)*L`. This means than the frame matrix is usually
%   **very** large, and this routine should only be used for small values
%   of *L*.
%
%   The action of the frame transform operator |frana|_ is equal to
%   multiplication with the Hermitean transpose of the frame
%   matrix. Consider the following simple example:::
%
%     L=200;
%     F=newframe('dgt','gauss','dual',10,20);
%     G=franamat(F,L);
%     testsig = randn(L,1);
%     res = frana(F,testsig)-G'*testsig;
%     norm(res)
%
%   See also: newframe, frana, frsyn, franaadj, frsynmat

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

switch(F.type)
 case {'dgtreal','fftreal'}
  error('%s: The analysis operator of this frame does not have a matrix representation.',upper(mfilename));
 otherwise
  
  Lcheck=framelengthsignal(F,L);
  if Lcheck~=L
    error('%s: Incompatible frame length.',upper(mfilename));
  end;
  
  % Generic code handles all frames where there are no extra coefficients
  % in the representation
  Ncoef=framered(F)*L;
  coef=eye(Ncoef);
  G = franaadj(F,coef);  
end;
