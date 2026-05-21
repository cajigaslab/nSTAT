# Bug-pattern audit — 2026-05-20T22:08:35Z

Phase D2.1 of [docs/superpowers/plans/2026-05-20-comprehensive-codebase-audit.md](docs/superpowers/plans/2026-05-20-comprehensive-codebase-audit.md).


## isa(x,'nan') always-false
Pattern: `isa\([^,]+,\s*'nan'\)`

```
./+nstat/+decoding/PPAF.m:748:                        if(condNum<eps || isnan(condNum)) % FIX: isa(condNum,'nan') always false; use isnan()
```

## eval() survivors (should be feval or refactor)
Pattern: `(^|[^a-zA-Z_])eval\(`

```
./SignalObj.m:898:                s = feval(class(sObj),sObj.time, absData,name,sObj.xlabelval, sObj.xunits,sObj.yunits,dataLabels,plotProps); % FIX: replaced eval() with feval() for safety
./SignalObj.m:900:                s = feval(class(sObj),sObj.time, absData,name,sObj.xlabelval, sObj.xunits,sObj.yunits,[],plotProps); % FIX: replaced eval() with feval() for safety
./SignalObj.m:915:                s = feval(class(sObj),sObj.time, logData,name,sObj.xlabelval, sObj.xunits,yunits,dataLabels,plotProps); % FIX: replaced eval() with feval()
./SignalObj.m:917:                s = feval(class(sObj),sObj.time, logData,name,sObj.xlabelval, sObj.xunits,yunits,[],plotProps); % FIX: replaced eval() with feval()
./SignalObj.m:934:                m = feval(class(sObj),sObj.time, mdata,name,sObj.xlabelval, sObj.xunits,sObj.yunits); % FIX: replaced eval() with feval() for safety
./SignalObj.m:942:                     m = feval(class(sObj),[sObj.time(1); sObj.time(end)], [mdata;mdata],name,sObj.xlabelval, sObj.xunits,sObj.yunits,dataLabels); % FIX: replaced eval() with feval() for safety
./SignalObj.m:945:                     m = feval(class(sObj),[sObj.time(1); sObj.time(end)], [mdata;mdata],name,sObj.xlabelval, sObj.xunits,sObj.yunits); % FIX: replaced eval() with feval() for safety
./SignalObj.m:967:                m = feval(class(sObj),sObj.time, mdata,name,sObj.xlabelval, sObj.xunits,sObj.yunits); % FIX: replaced eval() with feval() for safety
./SignalObj.m:975:                     m = feval(class(sObj),[sObj.time(1); sObj.time(end)], [mdata;mdata],name,sObj.xlabelval, sObj.xunits,sObj.yunits,dataLabels); % FIX: replaced eval() with feval() for safety
./SignalObj.m:978:                     m = feval(class(sObj),[sObj.time(1); sObj.time(end)], [mdata;mdata],name,sObj.xlabelval, sObj.xunits,sObj.yunits); % FIX: replaced eval() with feval() for safety
./SignalObj.m:997:                m = feval(class(sObj),sObj.time, mdata,name,sObj.xlabelval, sObj.xunits,sObj.yunits); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1005:                     m = feval(class(sObj),[sObj.time(1); sObj.time(end)], [mdata;mdata],name,sObj.xlabelval, sObj.xunits,sObj.yunits,dataLabels); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1008:                     m = feval(class(sObj),[sObj.time(1); sObj.time(end)], [mdata;mdata],name,sObj.xlabelval, sObj.xunits,sObj.yunits); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1025:                     m = feval(class(sObj),sObj.time, stdData,name,sObj.xlabelval, sObj.xunits,sObj.yunits); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1033:                     m = feval(class(sObj),[sObj.time(1); sObj.time(end)], [stdData;stdData],name,sObj.xlabelval, sObj.xunits,sObj.yunits,dataLabels); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1036:                    m = feval(class(sObj),[sObj.time(1); sObj.time(end)], [stdData;stdData],name,sObj.xlabelval, sObj.xunits,sObj.yunits); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1241:             sxCorr = feval(class(s1),lags,data,name,'\Delta \tau','s',dataLabels); % FIX: replaced eval() with feval() for safety    
./SignalObj.m:1276:             sxCov = feval(class(s1),lags,data,name,'\Delta \tau','s',dataLabels); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1316:                 mergedSig = feval(class(sObj),s1c.time, data, name, s1c.xlabelval,s1c.xunits, s1c.yunits, dataLabels); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1339:                sigOut = feval(class(sigIn),time, data,name, xlabelval, xunits, yunits,dataLabels,plotProps); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1646:%                         eval(strcat('v.(''',actString,''')=sObj.getSubSignal(''',UniqueSigLabels{i},''');'))
./SignalObj.m:1654:%                         eval(strcat('v.(''',sObj.dataLabels{i},''')=sObj.getSubSignal(i);'))
./SignalObj.m:1793:                        sOut = feval(class(sObj),actTime, data,name, xlabelval, xunits, yunits,dataLabels); % FIX: replaced eval() with feval() for safety
./SignalObj.m:1797:%                         eval(evalstring);
./SignalObj.m:2299:            sOut = feval(class(sObj),time, data,name, xlabelval, xunits, yunits,dataLabels,plotProps); % FIX: replaced eval() with feval() for safety
./SignalObj.m:2375:        args = eval(['{' plotStr '}']); %#ok<EVLC> % contained eval parses property list only
```

## rng('shuffle') reproducibility break
Pattern: `rng\(\s*'shuffle'`

```
./Analysis.m:1546:    % FIX: removed `rng('shuffle','twister')` — was clobbering caller seed
```

## symvar() reorder hazard
Pattern: `(^|[^a-zA-Z_])symvar\(`

```
./CIF.m:255:            % instead of symvar(cifObj.varIn). symvar() reorders variables
./CIF.m:331:                cifObj.indepVars = symvar(cifObj.lambdaDelta);
./CIF.m:1071:            nActualVars = numel(symvar(cifObj.varIn));
```

## log(0) literal
Pattern: `log\s*\(\s*0\s*\)`

```
./Analysis.m:641:                lambdaDelta = max(data*delta, eps); % FIX (Task 0.1c): eps guard for log(0)
./Analysis.m:642:                oneMinusLambdaDelta = max(1 - data*delta, eps); % FIX (Task 0.1c): missing log() wrapper; eps guard for log(0)
./FitResult.m:354:                          lambdaDelta = max(newLambda.data*delta, eps); % FIX: was bare 'data' (undefined); guard against log(0)
./FitResult.m:355:                          oneMinusLambdaDelta = max(1 - newLambda.data*delta, eps); % FIX: missing log() wrapper; eps guard for log(0)
./FitResult.m:375:                          lambdaDelta = max(newLambda.data(:,i)*delta, eps); % FIX: index by loop variable i (multi-result column); guard against log(0)
./FitResult.m:376:                          oneMinusLambdaDelta = max(1 - newLambda.data(:,i)*delta, eps); % FIX: missing log() wrapper; eps guard for log(0)
./FitResult.m:418:            lambdaDelta = max(lambda.data*delta, eps); % FIX: guard against log(0)
./FitResult.m:419:            oneMinusLambdaDelta = max(1 - lambda.data*delta, eps); % FIX: missing log() wrapper; eps guard for log(0)
```

## silent catch (no exception captured)
Pattern: `^[[:space:]]*catch[[:space:]]*$`

```
./tools/inspect_thinning_only.m:37:        catch
./tools/inspect_simulink_models.m:71:            catch
./tools/inspect_simulink_models.m:109:    catch
./tools/+nstat/applyPlotStyle.m:43:    catch
./tools/+nstat/applyPlotStyle.m:60:    catch
./tools/+nstat/applyPlotStyle.m:77:    catch
./tools/+nstat/applyPlotStyle.m:89:    catch
./tools/+nstat/applyPlotStyle.m:102:    catch
./tools/+nstat/+docs/exportFigure.m:48:    catch
./tools/+nstat/getPlotStyle.m:25:    catch
./tools/verify_all_examples.m:133:                catch
./tools/check_readme_figures.m:262:    catch
./tools/check_parity_against_baseline.m:314:    catch
```

## ExplambdaDeltaCubed should be .^3 not .^2 (review context)
Pattern: `ExplambdaDeltaCubed.*\.\^2`

```
./+nstat/+decoding/PPLFP.m:911:                                ExplambdaDeltaCubed  = 1/McExp*sum(ld.^3,2); % FIX: was ld.^2 (copy-paste); should be ld.^3 for cubic moment
./+nstat/+decoding/PPLFP.m:965:                                ExplambdaDeltaCubed  = 1/McExp*sum(ld.^3,2); % FIX: was ld.^2 (copy-paste); should be ld.^3 for cubic moment
./+nstat/+decoding/PointProcessEM.m:426:                                ExplambdaDeltaCubed  = 1/McExp*sum(ld.^3,2); % FIX: was ld.^2 (copy-paste); should be ld.^3 for cubic moment
./+nstat/+decoding/PointProcessEM.m:480:                                ExplambdaDeltaCubed  = 1/McExp*sum(ld.^3,2); % FIX: was ld.^2 (copy-paste); should be ld.^3 for cubic moment
```

## DecodingAlgorithms.* static call from app code
Pattern: `DecodingAlgorithms\.(PPDecode|PPHybrid|PPSS|mPPCO|PPLFP)_`

```
./+nstat/+decoding/PPLFP.m:13:    % nSTAT review action plan. DecodingAlgorithms.PPLFP_* are now thin
./+nstat/+decoding/PPLFP.m:15:    % DecodingAlgorithms.mPPCO_* shims (added in 428c344) chain through
./+nstat/+decoding/SSGLM.m:11:    % 2026-05-19 nSTAT review action plan). DecodingAlgorithms.PPSS_* are
./+nstat/+decoding/PointProcessEM.m:1792:%                 [x_u(:,k), W_u(:,:,k)] = DecodingAlgorithms.PPDecode_updateLinear(x_p(:,k), W_p(:,:,k), dN,mu,beta,fitType,gamma,HkAll,k,[]);
./+nstat/+decoding/PointProcessEM.m:1793:%                 [x_p(:,k+1), W_p(:,:,k+1)] = DecodingAlgorithms.PPDecode_predict(x_u(:,k), W_u(:,:,k), A(:,:,min(size(A,3),k)), Q(:,:,min(size(Q,3))));
./DecodingAlgorithms.m:87:                ['DecodingAlgorithms.PPDecode_predict is deprecated; use ' ...
./DecodingAlgorithms.m:95:                ['DecodingAlgorithms.PPDecode_update is deprecated; use ' ...
./DecodingAlgorithms.m:103:                ['DecodingAlgorithms.PPDecode_updateLinear is deprecated; use ' ...
./DecodingAlgorithms.m:212:                ['DecodingAlgorithms.PPSS_EMFB is deprecated; use ' ...
./DecodingAlgorithms.m:224:                ['DecodingAlgorithms.PPSS_EM is deprecated; use ' ...
./DecodingAlgorithms.m:236:                ['DecodingAlgorithms.PPSS_EStep is deprecated; use ' ...
./DecodingAlgorithms.m:248:                ['DecodingAlgorithms.PPSS_MStep is deprecated; use ' ...
./DecodingAlgorithms.m:909:        % class via varargin/varargout. The legacy DecodingAlgorithms.mPPCO_*
./DecodingAlgorithms.m:918:                ['DecodingAlgorithms.PPLFP_fixedIntervalSmoother is deprecated; use ' ...
./DecodingAlgorithms.m:930:                ['DecodingAlgorithms.PPLFP_DecodeLinear is deprecated; use ' ...
./DecodingAlgorithms.m:942:                ['DecodingAlgorithms.PPLFP_Decode_predict is deprecated; use ' ...
./DecodingAlgorithms.m:954:                ['DecodingAlgorithms.PPLFP_Decode_update is deprecated; use ' ...
./DecodingAlgorithms.m:966:                ['DecodingAlgorithms.PPLFP_EMCreateConstraints is deprecated; use ' ...
./DecodingAlgorithms.m:978:                ['DecodingAlgorithms.PPLFP_ComputeParamStandardErrors is deprecated; use ' ...
./DecodingAlgorithms.m:990:                ['DecodingAlgorithms.PPLFP_EM is deprecated; use ' ...
./DecodingAlgorithms.m:1002:                ['DecodingAlgorithms.PPLFP_EStep is deprecated; use ' ...
./DecodingAlgorithms.m:1014:                ['DecodingAlgorithms.PPLFP_MStep is deprecated; use ' ...
./DecodingAlgorithms.m:1102:                ['DecodingAlgorithms.mPPCO_fixedIntervalSmoother is deprecated; ' ...
./DecodingAlgorithms.m:1103:                 'use DecodingAlgorithms.PPLFP_fixedIntervalSmoother instead. ' ...
./DecodingAlgorithms.m:1105:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_fixedIntervalSmoother(varargin{:});
./DecodingAlgorithms.m:1113:                 'use DecodingAlgorithms.PPLFP_DecodeLinear instead. ' ...
./DecodingAlgorithms.m:1115:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_DecodeLinear(varargin{:});
./DecodingAlgorithms.m:1123:                 'use DecodingAlgorithms.PPLFP_Decode_predict instead. ' ...
./DecodingAlgorithms.m:1125:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_Decode_predict(varargin{:});
./DecodingAlgorithms.m:1133:                 'use DecodingAlgorithms.PPLFP_Decode_update instead. ' ...
./DecodingAlgorithms.m:1135:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_Decode_update(varargin{:});
./DecodingAlgorithms.m:1142:                ['DecodingAlgorithms.mPPCO_EMCreateConstraints is deprecated; ' ...
./DecodingAlgorithms.m:1143:                 'use DecodingAlgorithms.PPLFP_EMCreateConstraints instead. ' ...
./DecodingAlgorithms.m:1145:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_EMCreateConstraints(varargin{:});
./DecodingAlgorithms.m:1152:                ['DecodingAlgorithms.mPPCO_ComputeParamStandardErrors is deprecated; ' ...
./DecodingAlgorithms.m:1153:                 'use DecodingAlgorithms.PPLFP_ComputeParamStandardErrors instead. ' ...
./DecodingAlgorithms.m:1155:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_ComputeParamStandardErrors(varargin{:});
./DecodingAlgorithms.m:1162:                ['DecodingAlgorithms.mPPCO_EM is deprecated; ' ...
./DecodingAlgorithms.m:1163:                 'use DecodingAlgorithms.PPLFP_EM instead. ' ...
./DecodingAlgorithms.m:1165:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_EM(varargin{:});
./DecodingAlgorithms.m:1172:                ['DecodingAlgorithms.mPPCO_EStep is deprecated; ' ...
./DecodingAlgorithms.m:1173:                 'use DecodingAlgorithms.PPLFP_EStep instead. ' ...
./DecodingAlgorithms.m:1175:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_EStep(varargin{:});
./DecodingAlgorithms.m:1182:                ['DecodingAlgorithms.mPPCO_MStep is deprecated; ' ...
./DecodingAlgorithms.m:1183:                 'use DecodingAlgorithms.PPLFP_MStep instead. ' ...
./DecodingAlgorithms.m:1185:            [varargout{1:nargout}] = DecodingAlgorithms.PPLFP_MStep(varargin{:});
```

## Summary

Total candidate matches across all patterns: **102**

Note: matches are *candidates*; some patterns have legitimate uses (e.g., 
`eval(` inside backwards-compat shims, `DecodingAlgorithms.*` calls in
the facade itself or in cross-language parity tests). Human triage required.
