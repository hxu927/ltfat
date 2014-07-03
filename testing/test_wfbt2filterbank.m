function test_failed=test_wfbt2filterbank
%TEST_FILTERBANK test the equivalence of wfbt anf filterbank
%  Usage: test_wfbt2filterbank()
%


disp(' ===============  TEST_WFBT2FILTERBANK ===========');

test_failed=0;

L = [ 135, 211];
W = [1,2,3];
W = 1;
gt = {};
gt{1} = {'db4',1,'dwt'};
gt{2} = {'db4',4,'full'};
gt{3} = {{'ana:spline4:4',3,'dwt'},{'syn:spline4:4',3,'dwt'}};
gt{4} = wfbtinit(gt{2});
gt{4} = wfbtremove(3,0,gt{4});
gt{4} = wfbtremove(3,1,gt{4});
gt{5} = {{'ana:symorth3',3,'dwt'},{'ana:symorth3',3,'dwt'}};



% This case tests different filters in nodes
wt2 = wfbtinit({'db3',1});
wt2 = wfbtput(1,1,'db10',wt2);

gt{5} = wt2;


scaling = {'scale','sqrt','noscale'};
scalingInv = scaling(end:-1:1);

crossoverval = 10000;
    

for hh=1:2

    if hh==1
        testWhat = 'wfbt';
    elseif hh==2
        testWhat = 'wpfbt';
    end
    fprintf(' ===============  Testing %s ===========\n',testWhat);
        

for jj=1:numel(gt)

   for ww=1:numel(W)
   for ii=1:numel(L)
      f = tester_rand(L(ii),1);
      gttmp = gt(jj);
      if isempty(gttmp{1})
          continue;
      end
       
      if iscell(gt{jj}) && iscell(gt{jj}{1})
           gttmp = gt{jj}{1};
         else
           gttmp = gttmp{1};
         end


      if strcmp(testWhat,'wfbt')   
        refc = wfbt(f,gttmp);
        [g,a] = wfbt2filterbank(gttmp);
      elseif strcmp(testWhat,'wpfbt') 
        refc = wpfbt(f,gttmp);
        [g,a] = wpfbt2filterbank(gttmp);
      end
      
      
      c = filterbank(f,g,a,'crossover',1);
      
      err = norm(cell2mat(c)-cell2mat(refc));
      [test_failed,fail]=ltfatdiditfail(err,test_failed);
      
      if ~isstruct(gt{jj})
         fprintf('FILT %d, COEF, FFT         L= %d, W= %d, err=%.4e %s \n',jj,L(ii),W(ww),err,fail); 
      else
         fprintf('FILT %d, COEF, FFT         L= %d, W= %d, err=%.4e %s\n',jj,L(ii),W(ww),err,fail); 
      end;
      
       c = filterbank(f,g,a,'crossover',crossoverval);
       
       err = norm(cell2mat(c)-cell2mat(refc));
       [test_failed,fail]=ltfatdiditfail(err,test_failed);
       
       if ~isstruct(gt{jj})
          fprintf('FILT %d, COEF,  TD         L= %d, W= %d, err=%.4e %s \n',jj,L(ii),W(ww),err,fail); 
       else
          fprintf('FILT %d, COEF,  TD         L= %d, W= %d, err=%.4e %s\n',jj,L(ii),W(ww),err,fail); 
       end;
      
      if iscell(gt{jj}) && iscell(gt{jj}{2})
         gttmp = gt{jj}{2};
      end
         if strcmp(testWhat,'wfbt')   
            [g,a] = wfbt2filterbank(gttmp);
         elseif strcmp(testWhat,'wpfbt') 
            [g,a] = wpfbt2filterbank(gttmp);
         end
      
      
      fhat = ifilterbank(refc,g,a,L(ii),'crossover',1);
      err = norm(fhat-f);
      [test_failed,fail]=ltfatdiditfail(err,test_failed);
      
      if ~isstruct(gt{jj})
         fprintf('FILT %d, INV,  FFT         L= %d, W= %d, err=%.4e %s \n',jj,L(ii),W(ww),err,fail); 
      else
         fprintf('FILT %d, INV,  FFT         L= %d, W= %d, err=%.4e %s\n',jj,L(ii),W(ww),err,fail); 
      end;

      fhat = ifilterbank(refc,g,a,L(ii),'crossover',crossoverval);
      err = norm(fhat-f);
      [test_failed,fail]=ltfatdiditfail(err,test_failed);
      
      if ~isstruct(gt{jj})
         fprintf('FILT %d, INV,   TD         L= %d, W= %d, err=%.4e %s \n',jj,L(ii),W(ww),err,fail); 
      else
         fprintf('FILT %d, INV,   TD         L= %d, W= %d, err=%.4e %s\n',jj,L(ii),W(ww),err,fail); 
      end;
      

      
      for scIdx = 1:numel(scaling)
      gttmp = gt(jj);
      if iscell(gt{jj}) && iscell(gt{jj}{1})
         gttmp = gt{jj}{1};
      else
         gttmp = gttmp{1};
      end
      

      
      if strcmp(testWhat,'wfbt') 
          urefc = uwfbt(f,gttmp,scaling{scIdx});
          [g,a] = wfbt2filterbank(gttmp);
      elseif strcmp(testWhat,'wpfbt') 
          urefc = uwpfbt(f,gttmp,scaling{scIdx});
          [g,a] = wpfbt2filterbank(gttmp);
      end
      g = comp_filterbankscale(g,a,scaling{scIdx});

      
      uc = ufilterbank(f,g,1,'crossover',crossoverval);
      
      err = norm(uc-urefc);
      [test_failed,fail]=ltfatdiditfail(err,test_failed);
      
      if ~isstruct(gt{jj})
         fprintf('FILT %d, %s, COEF, FFT, UNDEC, L= %d, W= %d, err=%.4e %s \n',jj,scaling{scIdx},L(ii),W(ww),err,fail); 
      else
         fprintf('FILT %d, %s, COEF, FFT, UNDEC, L= %d, W= %d, err=%.4e %s\n',jj,scaling{scIdx},L(ii),W(ww),err,fail); 
      end;
      
      if iscell(gt{jj}) && iscell(gt{jj}{2})
          gttmp = gt{jj}{2};
      end
      
         if strcmp(testWhat,'wfbt')   
            [g,a] = wfbt2filterbank(gttmp);
         elseif strcmp(testWhat,'wpfbt') 
            [g,a] = wpfbt2filterbank(gttmp);
         end
         g = comp_filterbankscale(g,a,scalingInv{scIdx});

      fhat = ifilterbank(urefc,g,ones(numel(g),1),L(ii),'crossover',crossoverval);
      
      err = norm(fhat-f);
      [test_failed,fail]=ltfatdiditfail(err,test_failed);
      
      if ~isstruct(gt{jj})
         fprintf('FILT %d, %s, INV,  FFT, UNDEC, L= %d, W= %d, err=%.4e %s \n',jj,scaling{scIdx},L(ii),W(ww),err,fail); 
      else
         fprintf('FILT %d, %s INV,  FFT, UNDEC, L= %d, W= %d, err=%.4e %s\n',jj,scaling{scIdx},L(ii),W(ww),err,fail); 
      end;
      
      end
      
   end
   end
end
end
end