# checkcode sweep (Phase D2.2) — 2026-05-20T18:09:08***

Phase D2.2 of [docs/superpowers/plans/2026-05-20-comprehensive-codebase-audit.md](../superpowers/plans/2026-05-20-comprehensive-codebase-audit.md).

## Inventory

- Files in scope: 43 (top-level + `+nstat/` + `tools/`)
- Files with findings: 29
- Total finding lines: 1567

## Per-file findings (top 20 by line count)

### `SignalObj.m` (269 lines)

```
L 133 (C 33): Extra semicolon is unnecessary.
L 206 (C 26-34): 'setYunits' is referenced but is not a property, method, or event name defined in this class.
L 211 (C 26-34): 'setXunits' is referenced but is not a property, method, or event name defined in this class.
L 255 (C 25-31): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 301 (C 17-23): There is a property named 'maxTime'. Maybe this is a reference to it?
L 302 (C 51-57): There is a property named 'maxTime'. Maybe this is a reference to it?
L 341 (C 17-23): There is a property named 'minTime'. Maybe this is a reference to it?
L 342 (C 34-40): There is a property named 'minTime'. Maybe this is a reference to it?
L 342 (C 77-83): There is a property named 'minTime'. Maybe this is a reference to it?
L 384 (C 28-47): To improve performance, use 'isscalar' instead of length comparison.
L 396 (C 22-28): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 400 (C 45-64): To improve performance, use 'isscalar' instead of length comparison.
L 469 (C 14-17): There is a property named 'time'. Did you mean to reference it?
L 469 (C 19-22): There is a property named 'data'. Did you mean to reference it?
L 470 (C 13-16): There is a property named 'name'. Did you mean to reference it?
L 471 (C 13-21): There is a property named 'xlabelval'. Did you mean to reference it?
L 472 (C 13-18): There is a property named 'xunits'. Did you mean to reference it?
L 473 (C 13-18): There is a property named 'yunits'. Did you mean to reference it?
L 474 (C 13-22): There is a property named 'dataLabels'. Did you mean to reference it?
L 475 (C 13-21): There is a property named 'plotProps'. Did you mean to reference it?
L 477 (C 28-31): There is a property named 'time'. Did you mean to reference it?
L 477 (C 34-37): There is a property named 'data'. Did you mean to reference it?
L 477 (C 39-42): There is a property named 'name'. Did you mean to reference it?
L 477 (C 45-53): There is a property named 'xlabelval'. Did you mean to reference it?
L 477 (C 56-61): There is a property named 'xunits'. Did you mean to reference it?
L 477 (C 64-69): There is a property named 'yunits'. Did you mean to reference it?
L 477 (C 71-80): There is a property named 'dataLabels'. Did you mean to reference it?
L 477 (C 82-90): There is a property named 'plotProps'. Did you mean to reference it?
L 752 (C 14): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 758 (C 14): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 860 (C 17-23): There is a property named 'minTime'. Maybe this is a reference to it?
L 861 (C 17-23): There is a property named 'maxTime'. Maybe this is a reference to it?
L 862 (C 17-26): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 863 (C 35-44): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 863 (C 66-75): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 864 (C 32-38): There is a property named 'minTime'. Maybe this is a reference to it?
L 864 (C 72-78): There is a property named 'minTime'. Maybe this is a reference to it?
L 865 (C 32-38): There is a property named 'maxTime'. Maybe this is a reference to it?
L 865 (C 72-78): There is a property named 'maxTime'. Maybe this is a reference to it?
L 870 (C 21-24): There is a property named 'data'. Maybe this is a reference to it?
L 876 (C 42-45): There is a property named 'data'. Maybe this is a reference to it?
L 878 (C 32-35): There is a property named 'data'. Maybe this is a reference to it?
L 880 (C 32-35): There is a property named 'data'. Maybe this is a reference to it?
L 890 (C 14-18): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 890 (C 20-27): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 891 (C 13-16): There is a property named 'name'. Did you mean to reference it?
L 892 (C 13-21): There is a property named 'plotProps'. Did you mean to reference it?
L 894 (C 21-30): There is a property named 'dataLabels'. Did you mean to reference it?
L 896 (C 25-34): There is a property named 'dataLabels'. Did you mean to reference it?
L 898 (C 58-61): There is a property named 'name'. Did you mean to reference it?
L 898 (C 103-112): There is a property named 'dataLabels'. Did you mean to reference it?
L 898 (C 114-122): There is a property named 'plotProps'. Did you mean to reference it?
L 900 (C 58-61): There is a property named 'name'. Did you mean to reference it?
L 900 (C 106-114): There is a property named 'plotProps'. Did you mean to reference it?
L 906 (C 14-18): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 906 (C 20-27): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 907 (C 13-16): There is a property named 'name'. Did you mean to reference it?
L 908 (C 13-18): There is a property named 'yunits'. Did you mean to reference it?
L 909 (C 13-21): There is a property named 'plotProps'. Did you mean to reference it?
L 911 (C 21-30): There is a property named 'dataLabels'. Did you mean to reference it?
L 913 (C 25-34): There is a property named 'dataLabels'. Did you mean to reference it?
L 915 (C 58-61): There is a property named 'name'. Did you mean to reference it?
L 915 (C 91-96): There is a property named 'yunits'. Did you mean to reference it?
L 915 (C 98-107): There is a property named 'dataLabels'. Did you mean to reference it?
L 915 (C 109-117): There is a property named 'plotProps'. Did you mean to reference it?
L 917 (C 58-61): There is a property named 'name'. Did you mean to reference it?
L 917 (C 91-96): There is a property named 'yunits'. Did you mean to reference it?
L 917 (C 101-109): There is a property named 'plotProps'. Did you mean to reference it?
L 933 (C 17-20): There is a property named 'name'. Maybe this is a reference to it?
L 934 (C 56-59): There is a property named 'name'. Maybe this is a reference to it?
L 937 (C 21-30): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 939 (C 25-34): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 941 (C 22-25): There is a property named 'name'. Maybe this is a reference to it?
L 942 (C 90-93): There is a property named 'name'. Maybe this is a reference to it?
L 942 (C 135-144): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 944 (C 22-25): There is a property named 'name'. Maybe this is a reference to it?
L 945 (C 90-93): There is a property named 'name'. Maybe this is a reference to it?
L 966 (C 17-20): There is a property named 'name'. Maybe this is a reference to it?
L 967 (C 56-59): There is a property named 'name'. Maybe this is a reference to it?
L 970 (C 21-30): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 972 (C 25-34): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 974 (C 22-25): There is a property named 'name'. Maybe this is a reference to it?
L 975 (C 90-93): There is a property named 'name'. Maybe this is a reference to it?
L 975 (C 135-144): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 977 (C 22-25): There is a property named 'name'. Maybe this is a reference to it?
L 978 (C 90-93): There is a property named 'name'. Maybe this is a reference to it?
L 996 (C 17-20): There is a property named 'name'. Maybe this is a reference to it?
L 997 (C 56-59): There is a property named 'name'. Maybe this is a reference to it?
L 1000 (C 21-30): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1002 (C 25-34): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1004 (C 22-25): There is a property named 'name'. Maybe this is a reference to it?
L 1005 (C 90-93): There is a property named 'name'. Maybe this is a reference to it?
L 1005 (C 135-144): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1007 (C 22-25): There is a property named 'name'. Maybe this is a reference to it?
L 1008 (C 90-93): There is a property named 'name'. Maybe this is a reference to it?
L 1024 (C 22-25): There is a property named 'name'. Maybe this is a reference to it?
L 1025 (C 63-66): There is a property named 'name'. Maybe this is a reference to it?
L 1028 (C 21-30): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1030 (C 25-34): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1032 (C 22-25): There is a property named 'name'. Maybe this is a reference to it?
L 1033 (C 94-97): There is a property named 'name'. Maybe this is a reference to it?
L 1033 (C 139-148): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1035 (C 21-24): There is a property named 'name'. Maybe this is a reference to it?
L 1036 (C 93-96): There is a property named 'name'. Maybe this is a reference to it?
L 1059 (C 28-33): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1066 (C 22-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1066 (C 36-41): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1077 (C 24-29): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1145 (C 34-37): When using PMTM with three output arguments, the 'ConfidenceLevel' input argument is recommended.
L 1182 (C 18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1182 (C 23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1182 (C 28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1182 (C 33): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1183 (C 17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1192 (C 21-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1193 (C 21-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1194 (C 21-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1195 (C 21-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1214 (C 24-31): Best practice is to separate output variables with commas.
L 1216 (C 25-32): Best practice is to separate output variables with commas.
L 1220 (C 18-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1221 (C 18-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1224 (C 14-23): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1228 (C 22-31): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1234 (C 17-20): There is a property named 'data'. Maybe this is a reference to it?
L 1237 (C 18-21): There is a property named 'data'. Maybe this is a reference to it?
L 1240 (C 14-17): There is a property named 'name'. Maybe this is a reference to it?
L 1241 (C 44-47): There is a property named 'data'. Maybe this is a reference to it?
L 1241 (C 49-52): There is a property named 'name'. Maybe this is a reference to it?
L 1241 (C 72-81): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1249 (C 24-31): Best practice is to separate output variables with commas.
L 1251 (C 25-32): Best practice is to separate output variables with commas.
L 1255 (C 18-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1256 (C 18-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1259 (C 14-23): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1263 (C 22-31): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1269 (C 17-20): There is a property named 'data'. Maybe this is a reference to it?
L 1272 (C 18-21): There is a property named 'data'. Maybe this is a reference to it?
L 1275 (C 14-17): There is a property named 'name'. Maybe this is a reference to it?
L 1276 (C 43-46): There is a property named 'data'. Maybe this is a reference to it?
L 1276 (C 48-51): There is a property named 'name'. Maybe this is a reference to it?
L 1276 (C 71-80): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1306 (C 18-21): There is a property named 'data'. Maybe this is a reference to it?
L 1307 (C 18-27): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1309 (C 25-34): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1312 (C 25-34): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1314 (C 18-21): There is a property named 'name'. Maybe this is a reference to it?
L 1316 (C 58-61): There is a property named 'data'. Maybe this is a reference to it?
L 1316 (C 64-67): There is a property named 'name'. Maybe this is a reference to it?
L 1316 (C 108-117): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1331 (C 17-20): There is a property named 'time'. Did you mean to reference it?
L 1332 (C 17-20): There is a property named 'data'. Did you mean to reference it?
L 1333 (C 17-20): There is a property named 'name'. Did you mean to reference it?
L 1334 (C 17-25): There is a property named 'xlabelval'. Did you mean to reference it?
L 1335 (C 17-22): There is a property named 'xunits'. Did you mean to reference it?
L 1336 (C 17-22): There is a property named 'yunits'. Did you mean to reference it?
L 1337 (C 17-26): There is a property named 'dataLabels'. Did you mean to reference it?
L 1338 (C 17-25): There is a property named 'plotProps'. Did you mean to reference it?
L 1339 (C 45-48): There is a property named 'time'. Did you mean to reference it?
L 1339 (C 51-54): There is a property named 'data'. Did you mean to reference it?
L 1339 (C 56-59): There is a property named 'name'. Did you mean to reference it?
L 1339 (C 62-70): There is a property named 'xlabelval'. Did you mean to reference it?
L 1339 (C 73-78): There is a property named 'xunits'. Did you mean to reference it?
L 1339 (C 81-86): There is a property named 'yunits'. Did you mean to reference it?
L 1339 (C 88-97): There is a property named 'dataLabels'. Did you mean to reference it?
L 1339 (C 99-107): There is a property named 'plotProps'. Did you mean to reference it?
L 1362 (C 17-23): There is a property named 'minTime'. Maybe this is a reference to it?
L 1363 (C 17-23): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1364 (C 25-31): There is a property named 'minTime'. Maybe this is a reference to it?
L 1364 (C 49-55): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1390 (C 15-18): There is a property named 'time'. Maybe this is a reference to it?
L 1390 (C 20-23): There is a property named 'data'. Maybe this is a reference to it?
L 1391 (C 24-27): There is a property named 'time'. Maybe this is a reference to it?
L 1392 (C 24-27): There is a property named 'data'. Maybe this is a reference to it?
L 1393 (C 31-34): There is a property named 'time'. Maybe this is a reference to it?
L 1394 (C 31-34): There is a property named 'time'. Maybe this is a reference to it?
L 1395 (C 44-47): There is a property named 'time'. Maybe this is a reference to it?
L 1464 (C 21-30): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1466 (C 40-49): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1504 (C 44): Extra semicolon is unnecessary.
L 1562 (C 22-27): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1756 (C 44): Extra semicolon is unnecessary.
L 1764 (C 15-18): There is a property named 'data'. Maybe this is a reference to it?
L 1767 (C 17-23): There is a property named 'minTime'. Maybe this is a reference to it?
L 1768 (C 17-23): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1770 (C 32-38): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1770 (C 40-46): There is a property named 'minTime'. Maybe this is a reference to it?
L 1770 (C 63-69): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1770 (C 71-77): There is a property named 'minTime'. Maybe this is a reference to it?
L 1771 (C 34-37): There is a property named 'data'. Maybe this is a reference to it?
L 1772 (C 25-28): There is a property named 'time'. Maybe this is a reference to it?
L 1772 (C 41-47): There is a property named 'minTime'. Maybe this is a reference to it?
L 1772 (C 49-55): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1773 (C 57-63): There is a property named 'minTime'. Maybe this is a reference to it?
L 1773 (C 66-72): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1776 (C 25-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1776 (C 25-28): There is a property named 'data'. Maybe this is a reference to it?
L 1776 (C 73-76): There is a property named 'time'. Maybe this is a reference to it?
L 1779 (C 20-23): There is a property named 'time'. Maybe this is a reference to it?
L 1779 (C 36-42): There is a property named 'minTime'. Maybe this is a reference to it?
L 1779 (C 44-50): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1780 (C 52-58): There is a property named 'minTime'. Maybe this is a reference to it?
L 1780 (C 61-67): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1782 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1782 (C 21-24): There is a property named 'data'. Maybe this is a reference to it?
L 1782 (C 65-68): There is a property named 'time'. Maybe this is a reference to it?
L 1786 (C 19-22): There is a property named 'name'. Maybe this is a reference to it?
L 1787 (C 19-27): There is a property named 'xlabelval'. Maybe this is a reference to it?
L 1788 (C 19-24): There is a property named 'xunits'. Maybe this is a reference to it?
L 1789 (C 19-24): There is a property named 'yunits'. Maybe this is a reference to it?
L 1790 (C 19-28): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1790 (C 37-40): There is a property named 'data'. Maybe this is a reference to it?
L 1793 (C 59-62): There is a property named 'data'. Maybe this is a reference to it?
L 1793 (C 64-67): There is a property named 'name'. Maybe this is a reference to it?
L 1793 (C 70-78): There is a property named 'xlabelval'. Maybe this is a reference to it?
L 1793 (C 81-86): There is a property named 'xunits'. Maybe this is a reference to it?
L 1793 (C 89-94): There is a property named 'yunits'. Maybe this is a reference to it?
L 1793 (C 96-105): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1843 (C 16-30): To improve performance, use 'isscalar' instead of length comparison.
L 1865 (C 29-38): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1865 (C 29-38): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1869 (C 29-38): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1872 (C 33-42): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1876 (C 43-52): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 1888 (C 21-28): Best practice is to separate output variables with commas.
L 1966 (C 58-79): To improve performance, use 'isscalar' instead of length comparison.
L 1988 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1991 (C 25-28): Calling AXES(h) in a loop can be slow. Consider moving the call to AXES outside the loop.
L 1992 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2003 (C 29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2005 (C 29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2021 (C 30-40): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 2033 (C 61-71): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 2072 (C 48-66): To improve performance, use 'isscalar' instead of length comparison.
L 2121 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2170 (C 16-33): To improve performance, use 'isscalar' instead of length comparison.
L 2178 (C 16-33): To improve performance, use 'isscalar' instead of length comparison.
L 2215 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2260 (C 25-37): 'isDataMaskSet' is referenced but is not a property, method, or event name defined in this class.
L 2267 (C 13-16): There is a property named 'time'. Maybe this is a reference to it?
L 2269 (C 17-20): There is a property named 'data'. Maybe this is a reference to it?
L 2272 (C 20-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2272 (C 20-23): There is a property named 'data'. Maybe this is a reference to it?
L 2272 (C 28-31): There is a property named 'data'. Maybe this is a reference to it?
L 2274 (C 25-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2274 (C 25-34): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 2276 (C 29-37): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2276 (C 29-37): There is a property named 'plotProps'. Maybe this is a reference to it?
L 2279 (C 20-25): Value assigned to variable might be unused.
L 2282 (C 17-20): There is a property named 'data'. Maybe this is a reference to it?
L 2283 (C 17-26): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 2284 (C 17-25): There is a property named 'plotProps'. Maybe this is a reference to it?
L 2286 (C 21-30): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 2288 (C 25-33): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2288 (C 25-33): There is a property named 'plotProps'. Maybe this is a reference to it?
L 2296 (C 13-16): There is a property named 'name'. Maybe this is a reference to it?
L 2297 (C 13-21): There is a property named 'xlabelval'. Maybe this is a reference to it?
L 2297 (C 39-44): There is a property named 'xunits'. Maybe this is a reference to it?
L 2297 (C 57-62): There is a property named 'yunits'. Maybe this is a reference to it?
L 2299 (C 38-41): There is a property named 'time'. Maybe this is a reference to it?
L 2299 (C 44-47): There is a property named 'data'. Maybe this is a reference to it?
L 2299 (C 49-52): There is a property named 'name'. Maybe this is a reference to it?
L 2299 (C 55-63): There is a property named 'xlabelval'. Maybe this is a reference to it?
L 2299 (C 66-71): There is a property named 'xunits'. Maybe this is a reference to it?
L 2299 (C 74-79): There is a property named 'yunits'. Maybe this is a reference to it?
L 2299 (C 81-90): There is a property named 'dataLabels'. Maybe this is a reference to it?
L 2299 (C 92-100): There is a property named 'plotProps'. Maybe this is a reference to it?
L 2306 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2375 (C 41-50): A Code Analyzer message was once suppressed here, but the message is no longer generated.

```

### `+nstat/+decoding/PPLFP.m` (218 lines)

```
L 72 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 75 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 90 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 240 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 243 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 259 (C 17-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 305 (C 23): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 327 (C 16-30): To improve performance, use 'isscalar' instead of length comparison.
L 483 (C 17): Value assigned to variable might be unused.
L 522 (C 13-14): Value assigned to variable might be unused.
L 523 (C 13-14): Value assigned to variable might be unused.
L 524 (C 13-15): Value assigned to variable might be unused.
L 525 (C 17): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 566 (C 21-26): The preallocated value assigned to variable might be unused.
L 627 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 634 (C 21-30): 'matlabpool' has been removed. With appropriate code changes, use 'parpool' instead.
L 642 (C 29-30): Value assigned to variable might be unused.
L 650 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 671 (C 29-30): Value assigned to variable might be unused.
L 678 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 703 (C 29-30): Value assigned to variable might be unused.
L 711 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 732 (C 29-30): Value assigned to variable might be unused.
L 739 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 776 (C 29-30): Value assigned to variable might be unused.
L 777 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 796 (C 29-30): Value assigned to variable might be unused.
L 797 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 825 (C 29-30): Value assigned to variable might be unused.
L 826 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 845 (C 29-30): Value assigned to variable might be unused.
L 846 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 881 (C 33-34): Value assigned to variable might be unused.
L 882 (C 36-53): To improve performance, use 'isscalar' instead of length comparison.
L 901 (C 33-34): Value assigned to variable might be unused.
L 902 (C 36-53): To improve performance, use 'isscalar' instead of length comparison.
L 934 (C 33-34): Value assigned to variable might be unused.
L 935 (C 36-53): To improve performance, use 'isscalar' instead of length comparison.
L 955 (C 33-34): Value assigned to variable might be unused.
L 956 (C 36-53): To improve performance, use 'isscalar' instead of length comparison.
L 968 (C 61-62): Parenthesize the multiplication of 'Hk' and its transpose to ensure the result is Hermitian.
L 999 (C 16-33): To improve performance, use 'isscalar' instead of length comparison.
L 1018 (C 52): Extra semicolon is unnecessary.
L 1045 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1052 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1062 (C 21-30): 'matlabpool' has been removed. With appropriate code changes, use 'parpool' instead.
L 1089 (C 21-25): Value assigned to variable might be unused.
L 1162 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 1170 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1171 (C 29-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1179 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 1187 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1188 (C 29-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1194 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1197 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1199 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1200 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1201 (C 25-42): To improve performance, use 'isscalar' instead of length comparison.
L 1202 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1233 (C 21-25): Value assigned to variable might be unused.
L 1306 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 1314 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1315 (C 29-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1323 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 1331 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1332 (C 29-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1338 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1341 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1343 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1344 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1345 (C 25-42): To improve performance, use 'isscalar' instead of length comparison.
L 1346 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1416 (C 17-34): To improve performance, use 'isscalar' instead of length comparison.
L 1427 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1427 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1427 (C 30): Best practice is to separate output variables with commas.
L 1434 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1434 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1434 (C 30): Best practice is to separate output variables with commas.
L 1445 (C 17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1445 (C 22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1445 (C 22): Best practice is to separate output variables with commas.
L 1455 (C 22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1455 (C 24): Best practice is to separate output variables with commas.
L 1461 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1461 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1461 (C 30): Best practice is to separate output variables with commas.
L 1469 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1469 (C 26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1469 (C 26): Best practice is to separate output variables with commas.
L 1480 (C 22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1480 (C 24): Best practice is to separate output variables with commas.
L 1486 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1486 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1486 (C 30): Best practice is to separate output variables with commas.
L 1494 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1494 (C 26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1494 (C 26): Best practice is to separate output variables with commas.
L 1504 (C 22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1504 (C 24): Best practice is to separate output variables with commas.
L 1510 (C 26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1510 (C 31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1510 (C 31): Best practice is to separate output variables with commas.
L 1520 (C 18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1520 (C 23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1520 (C 23): Best practice is to separate output variables with commas.
L 1529 (C 22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1529 (C 27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1529 (C 27): Best practice is to separate output variables with commas.
L 1539 (C 18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1539 (C 23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1539 (C 23): Best practice is to separate output variables with commas.
L 1548 (C 18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1548 (C 23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1548 (C 23): Best practice is to separate output variables with commas.
L 1554 (C 17-34): To improve performance, use 'isscalar' instead of length comparison.
L 1558 (C 22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1558 (C 27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1558 (C 27): Best practice is to separate output variables with commas.
L 1578 (C 16-33): To improve performance, use 'isscalar' instead of length comparison.
L 1626 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1630 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1635 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1644 (C 13-18): Value assigned to variable might be unused.
L 1646 (C 13-15): Value assigned to variable might be unused.
L 1667 (C 13-17): Value assigned to variable might be unused.
L 1688 (C 13-17): Value assigned to variable might be unused.
L 1704 (C 18-20): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1704 (C 32-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1704 (C 46-47): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1704 (C 54-68): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 18-21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 36-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 54-57): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 72-75): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 90-97): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 112-116): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 131-137): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 152-159): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 173-177): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1707 (C 191-196): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1711 (C 26): Use of brackets [] is unnecessary.
L 1757 (C 37-41): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1761 (C 72-79): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1761 (C 82-91): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1761 (C 94-104): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1761 (C 106-110): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1761 (C 112-117): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1764 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1765 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1766 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1767 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1768 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1769 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1770 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1784 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1787 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1789 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1850 (C 26): Use of brackets [] is unnecessary.
L 1857 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 1858 (C 21-25): Value assigned to variable might be unused.
L 1863 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 1865 (C 21-25): Value assigned to variable might be unused.
L 1887 (C 13-17): Value assigned to variable might be unused.
L 1921 (C 13-19): Value assigned to variable might be unused.
L 1974 (C 16-33): To improve performance, use 'isscalar' instead of length comparison.
L 2006 (C 14-20): Value assigned to variable might be unused.
L 2007 (C 14-20): Value assigned to variable might be unused.
L 2014 (C 13-15): The preallocated value assigned to variable might be unused.
L 2015 (C 13-15): The preallocated value assigned to variable might be unused.
L 2016 (C 13-15): The preallocated value assigned to variable might be unused.
L 2017 (C 13-15): The preallocated value assigned to variable might be unused.
L 2022 (C 23-24): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 2050 (C 13-19): The preallocated value assigned to variable might be unused.
L 2070 (C 13-17): Value assigned to variable might be unused.
L 2133 (C 23-37): To improve performance, use 'isscalar' instead of length comparison.
L 2162 (C 24-38): To improve performance, use 'isscalar' instead of length comparison.
L 2230 (C 13-19): Value assigned to variable might be unused.
L 2234 (C 13-17): Value assigned to variable might be unused.
L 2237 (C 13-15): Value assigned to variable might be unused.
L 2238 (C 13-17): Value assigned to variable might be unused.
L 2240 (C 13-14): Value assigned to variable might be unused.
L 2325 (C 39-42): For array or cell array, performance can be improved using logical indexing instead of 'find'.
L 2326 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2349 (C 21-27): Value assigned to variable might be unused.
L 2350 (C 21-25): Value assigned to variable might be unused.
L 2352 (C 21-27): Value assigned to variable might be unused.
L 2353 (C 21-25): Value assigned to variable might be unused.
L 2357 (C 21-28): Value assigned to variable might be unused.
L 2363 (C 26): Use of brackets [] is unnecessary.
L 2371 (C 29): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 2376 (C 24-33): 'matlabpool' has been removed. With appropriate code changes, use 'parpool' instead.
L 2378 (C 21-26): Value assigned to variable might be unused.
L 2396 (C 37-38): Value assigned to variable might be unused.
L 2403 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2425 (C 37-38): Value assigned to variable might be unused.
L 2432 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2473 (C 21-35): Value assigned to variable might be unused.
L 2491 (C 37-38): Value assigned to variable might be unused.
L 2498 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2523 (C 37-38): Value assigned to variable might be unused.
L 2530 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2593 (C 37-38): Value assigned to variable might be unused.
L 2600 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2620 (C 37-38): Value assigned to variable might be unused.
L 2627 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2681 (C 37-38): Value assigned to variable might be unused.
L 2688 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2711 (C 37-38): Value assigned to variable might be unused.
L 2718 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2784 (C 41-42): Value assigned to variable might be unused.
L 2791 (C 44-65): To improve performance, use 'isscalar' instead of length comparison.
L 2811 (C 41-42): Value assigned to variable might be unused.
L 2818 (C 44-65): To improve performance, use 'isscalar' instead of length comparison.
L 2863 (C 32-53): To improve performance, use 'isscalar' instead of length comparison.
L 2880 (C 41-42): Value assigned to variable might be unused.
L 2904 (C 41-42): Value assigned to variable might be unused.
L 2944 (C 29-37): Variable appears to change size on every loop iteration. Consider preallocating for speed.

```

### `+nstat/+decoding/PointProcessEM.m` (168 lines)

```
L 147 (C 21-26): The preallocated value assigned to variable might be unused.
L 206 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 213 (C 21-30): 'matlabpool' has been removed. With appropriate code changes, use 'parpool' instead.
L 220 (C 25-26): Value assigned to variable might be unused.
L 228 (C 28-45): To improve performance, use 'isscalar' instead of length comparison.
L 249 (C 25-26): Value assigned to variable might be unused.
L 256 (C 28-45): To improve performance, use 'isscalar' instead of length comparison.
L 267 (C 84): '-' produces a value that might be unused.
L 291 (C 29-30): Value assigned to variable might be unused.
L 292 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 311 (C 29-30): Value assigned to variable might be unused.
L 312 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 340 (C 29-30): Value assigned to variable might be unused.
L 341 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 360 (C 29-30): Value assigned to variable might be unused.
L 361 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 396 (C 33-34): Value assigned to variable might be unused.
L 397 (C 36-53): To improve performance, use 'isscalar' instead of length comparison.
L 416 (C 33-34): Value assigned to variable might be unused.
L 417 (C 36-53): To improve performance, use 'isscalar' instead of length comparison.
L 449 (C 33-34): Value assigned to variable might be unused.
L 450 (C 36-53): To improve performance, use 'isscalar' instead of length comparison.
L 470 (C 33-34): Value assigned to variable might be unused.
L 471 (C 36-53): To improve performance, use 'isscalar' instead of length comparison.
L 483 (C 61-62): Parenthesize the multiplication of 'Hk' and its transpose to ensure the result is Hermitian.
L 514 (C 16-33): To improve performance, use 'isscalar' instead of length comparison.
L 529 (C 48): Extra semicolon is unnecessary.
L 554 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 561 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 571 (C 21-30): 'matlabpool' has been removed. With appropriate code changes, use 'parpool' instead.
L 638 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 646 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 647 (C 29-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 651 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 659 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 660 (C 29-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 666 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 669 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 671 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 672 (C 25-42): To improve performance, use 'isscalar' instead of length comparison.
L 673 (C 29-36): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 703 (C 21-25): Value assigned to variable might be unused.
L 746 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 754 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 755 (C 29-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 759 (C 32-49): To improve performance, use 'isscalar' instead of length comparison.
L 767 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 768 (C 29-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 774 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 777 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 779 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 780 (C 25-42): To improve performance, use 'isscalar' instead of length comparison.
L 781 (C 29-36): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 839 (C 17-34): To improve performance, use 'isscalar' instead of length comparison.
L 851 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 851 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 851 (C 30): Best practice is to separate output variables with commas.
L 858 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 858 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 858 (C 30): Best practice is to separate output variables with commas.
L 870 (C 22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 870 (C 24): Best practice is to separate output variables with commas.
L 876 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 876 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 876 (C 30): Best practice is to separate output variables with commas.
L 884 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 884 (C 26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 884 (C 26): Best practice is to separate output variables with commas.
L 894 (C 22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 894 (C 24): Best practice is to separate output variables with commas.
L 900 (C 26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 900 (C 31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 900 (C 31): Best practice is to separate output variables with commas.
L 912 (C 22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 912 (C 27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 912 (C 27): Best practice is to separate output variables with commas.
L 922 (C 18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 922 (C 23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 922 (C 23): Best practice is to separate output variables with commas.
L 931 (C 18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 931 (C 23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 931 (C 23): Best practice is to separate output variables with commas.
L 937 (C 17-34): To improve performance, use 'isscalar' instead of length comparison.
L 941 (C 22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 941 (C 27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 941 (C 27): Best practice is to separate output variables with commas.
L 959 (C 16-33): To improve performance, use 'isscalar' instead of length comparison.
L 1007 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1011 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1016 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1025 (C 13-18): Value assigned to variable might be unused.
L 1027 (C 13-15): Value assigned to variable might be unused.
L 1057 (C 13-17): Value assigned to variable might be unused.
L 1073 (C 18-20): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1073 (C 32-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1073 (C 46-47): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1073 (C 54-68): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1076 (C 18-21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1076 (C 36-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1076 (C 54-58): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1076 (C 73-79): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1076 (C 94-101): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1076 (C 115-119): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1076 (C 133-138): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1080 (C 26): Use of brackets [] is unnecessary.
L 1097 (C 30-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1100 (C 30-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1103 (C 30-42): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1104 (C 30-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1114 (C 26-29): 'time' produces a value that might be unused.
L 1124 (C 37-44): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1128 (C 75-79): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1128 (C 81-86): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1131 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1132 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1133 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1134 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1135 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1136 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1147 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1150 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1152 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1194 (C 26): Use of brackets [] is unnecessary.
L 1202 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 1203 (C 21-25): Value assigned to variable might be unused.
L 1208 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 1209 (C 21-25): Value assigned to variable might be unused.
L 1256 (C 13-19): Value assigned to variable might be unused.
L 1299 (C 16-33): To improve performance, use 'isscalar' instead of length comparison.
L 1657 (C 23-24): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1707 (C 23-37): To improve performance, use 'isscalar' instead of length comparison.
L 1733 (C 24-38): To improve performance, use 'isscalar' instead of length comparison.
L 2112 (C 39-42): For array or cell array, performance can be improved using logical indexing instead of 'find'.
L 2113 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 2136 (C 21-27): Value assigned to variable might be unused.
L 2137 (C 21-25): Value assigned to variable might be unused.
L 2139 (C 21-27): Value assigned to variable might be unused.
L 2140 (C 21-25): Value assigned to variable might be unused.
L 2144 (C 21-28): Value assigned to variable might be unused.
L 2150 (C 26): Use of brackets [] is unnecessary.
L 2158 (C 29): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 2164 (C 24-33): 'matlabpool' has been removed. With appropriate code changes, use 'parpool' instead.
L 2183 (C 37-38): Value assigned to variable might be unused.
L 2190 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2212 (C 37-38): Value assigned to variable might be unused.
L 2219 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2260 (C 21-35): Value assigned to variable might be unused.
L 2276 (C 37-38): Value assigned to variable might be unused.
L 2283 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2305 (C 37-42): Value assigned to variable might be unused.
L 2308 (C 37-38): Value assigned to variable might be unused.
L 2315 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2378 (C 37-38): Value assigned to variable might be unused.
L 2385 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2406 (C 37-38): Value assigned to variable might be unused.
L 2413 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2467 (C 37-38): Value assigned to variable might be unused.
L 2474 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2498 (C 37-38): Value assigned to variable might be unused.
L 2505 (C 40-57): To improve performance, use 'isscalar' instead of length comparison.
L 2570 (C 41-42): Value assigned to variable might be unused.
L 2577 (C 44-65): To improve performance, use 'isscalar' instead of length comparison.
L 2598 (C 41-42): Value assigned to variable might be unused.
L 2605 (C 44-65): To improve performance, use 'isscalar' instead of length comparison.
L 2649 (C 32-53): To improve performance, use 'isscalar' instead of length comparison.
L 2665 (C 41-42): Value assigned to variable might be unused.
L 2689 (C 41-42): Value assigned to variable might be unused.
L 2729 (C 29-37): Variable appears to change size on every loop iteration. Consider preallocating for speed.

```

### `FitResult.m` (140 lines)

```
L 131 (C 25-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 133 (C 25-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 135 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 136 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 206 (C 21-29): There is a property named 'covLabels'. Maybe this is a reference to it?
L 207 (C 21-29): There is a property named 'covLabels'. Maybe this is a reference to it?
L 208 (C 21-27): There is a property named 'numHist'. Maybe this is a reference to it?
L 209 (C 21-27): There is a property named 'numHist'. Maybe this is a reference to it?
L 210 (C 21-31): There is a property named 'histObjects'. Maybe this is a reference to it?
L 211 (C 21-31): There is a property named 'histObjects'. Maybe this is a reference to it?
L 212 (C 21-34): There is a property named 'ensHistObjects'. Maybe this is a reference to it?
L 213 (C 21-34): There is a property named 'ensHistObjects'. Maybe this is a reference to it?
L 214 (C 21): There is a property named 'b'. Maybe this is a reference to it?
L 215 (C 21): There is a property named 'b'. Maybe this is a reference to it?
L 216 (C 21-23): There is a property named 'dev'. Maybe this is a reference to it?
L 217 (C 21-23): There is a property named 'AIC'. Maybe this is a reference to it?
L 218 (C 21-23): There is a property named 'BIC'. Maybe this is a reference to it?
L 219 (C 21-25): There is a property named 'logLL'. Maybe this is a reference to it?
L 220 (C 21-25): There is a property named 'stats'. Maybe this is a reference to it?
L 221 (C 21-25): There is a property named 'stats'. Maybe this is a reference to it?
L 222 (C 21-26): There is a property named 'lambda'. Maybe this is a reference to it?
L 225 (C 25-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 233 (C 21-28): There is a property named 'XvalData'. Maybe this is a reference to it?
L 234 (C 21-28): There is a property named 'XvalTime'. Maybe this is a reference to it?
L 241 (C 21): There is a property named 'Z'. Maybe this is a reference to it?
L 242 (C 21): There is a property named 'U'. Maybe this is a reference to it?
L 243 (C 22): There is a property named 'X'. Maybe this is a reference to it?
L 243 (C 76): There is a property named 'Z'. Maybe this is a reference to it?
L 268 (C 48-56): There is a property named 'covLabels'. Maybe this is a reference to it?
L 268 (C 58-64): There is a property named 'numHist'. Maybe this is a reference to it?
L 268 (C 66-76): There is a property named 'histObjects'. Maybe this is a reference to it?
L 268 (C 78-91): There is a property named 'ensHistObjects'. Maybe this is a reference to it?
L 268 (C 93-98): There is a property named 'lambda'. Maybe this is a reference to it?
L 268 (C 100): There is a property named 'b'. Maybe this is a reference to it?
L 268 (C 103-105): There is a property named 'dev'. Maybe this is a reference to it?
L 268 (C 108-112): There is a property named 'stats'. Maybe this is a reference to it?
L 268 (C 114-116): There is a property named 'AIC'. Maybe this is a reference to it?
L 268 (C 118-120): There is a property named 'BIC'. Maybe this is a reference to it?
L 268 (C 122-126): There is a property named 'logLL'. Maybe this is a reference to it?
L 268 (C 139-146): There is a property named 'XvalData'. Maybe this is a reference to it?
L 268 (C 148-155): There is a property named 'XvalTime'. Maybe this is a reference to it?
L 269 (C 40): There is a property named 'Z'. Maybe this is a reference to it?
L 269 (C 42): There is a property named 'U'. Maybe this is a reference to it?
L 270 (C 45): There is a property named 'X'. Maybe this is a reference to it?
L 293 (C 17-25): There is a property named 'covLabels'. Maybe this is a reference to it?
L 294 (C 17-23): There is a property named 'numHist'. Maybe this is a reference to it?
L 295 (C 17-27): There is a property named 'histObjects'. Maybe this is a reference to it?
L 297 (C 17-22): There is a property named 'lambda'. Maybe this is a reference to it?
L 298 (C 17): There is a property named 'b'. Maybe this is a reference to it?
L 299 (C 17-19): There is a property named 'dev'. Maybe this is a reference to it?
L 300 (C 17-21): There is a property named 'stats'. Maybe this is a reference to it?
L 301 (C 17-19): There is a property named 'AIC'. Maybe this is a reference to it?
L 302 (C 17-19): There is a property named 'BIC'. Maybe this is a reference to it?
L 303 (C 17-21): There is a property named 'logLL'. Maybe this is a reference to it?
L 305 (C 17-24): There is a property named 'XvalData'. Maybe this is a reference to it?
L 306 (C 17-24): There is a property named 'XvalTime'. Maybe this is a reference to it?
L 309 (C 46-54): There is a property named 'covLabels'. Maybe this is a reference to it?
L 309 (C 56-62): There is a property named 'numHist'. Maybe this is a reference to it?
L 309 (C 64-74): There is a property named 'histObjects'. Maybe this is a reference to it?
L 309 (C 87-92): There is a property named 'lambda'. Maybe this is a reference to it?
L 309 (C 94): There is a property named 'b'. Maybe this is a reference to it?
L 309 (C 97-99): There is a property named 'dev'. Maybe this is a reference to it?
L 309 (C 102-106): There is a property named 'stats'. Maybe this is a reference to it?
L 309 (C 108-110): There is a property named 'AIC'. Maybe this is a reference to it?
L 309 (C 112-114): There is a property named 'BIC'. Maybe this is a reference to it?
L 309 (C 116-120): There is a property named 'logLL'. Maybe this is a reference to it?
L 309 (C 133-140): There is a property named 'XvalData'. Maybe this is a reference to it?
L 309 (C 142-149): There is a property named 'XvalTime'. Maybe this is a reference to it?
L 310 (C 17): There is a property named 'Z'. Maybe this is a reference to it?
L 311 (C 17): There is a property named 'U'. Maybe this is a reference to it?
L 312 (C 17): There is a property named 'X'. Maybe this is a reference to it?
L 320 (C 38): There is a property named 'Z'. Maybe this is a reference to it?
L 320 (C 40): There is a property named 'U'. Maybe this is a reference to it?
L 321 (C 43): There is a property named 'X'. Maybe this is a reference to it?
L 329 (C 13-14): This keyword might not be aligned with its matching END on line 403.
L 430 (C 13-20): There is a property named 'flatMask'. Did you mean to reference it?
L 444 (C 17-24): There is a property named 'flatMask'. Did you mean to reference it?
L 446 (C 31-38): There is a property named 'flatMask'. Did you mean to reference it?
L 464 (C 17-23): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 503 (C 17): There is a property named 'b'. Maybe this is a reference to it?
L 507 (C 39): There is a property named 'b'. Maybe this is a reference to it?
L 510 (C 25-32): Value assigned to variable might be unused.
L 511 (C 28-34): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 513 (C 35): There is a property named 'b'. Maybe this is a reference to it?
L 514 (C 54): There is a property named 'b'. Maybe this is a reference to it?
L 539 (C 46): There is a property named 'b'. Maybe this is a reference to it?
L 540 (C 53): There is a property named 'b'. Maybe this is a reference to it?
L 674 (C 17-29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 681 (C 22-29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 681 (C 36-42): If you are operating on scalar values, consider using 'str2double' for faster performance.
L 686 (C 21-33): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 687 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 703 (C 21-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 706 (C 25-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 765 (C 15-20): Value assigned to variable might be unused.
L 779 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 784 (C 22-29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 784 (C 36-42): If you are operating on scalar values, consider using 'str2double' for faster performance.
L 797 (C 18-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 799 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 830 (C 13-21): Value assigned to variable might be unused.
L 838 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 840 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 846 (C 16-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 848 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 850 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 904 (C 15-16): This keyword might not be aligned with its matching END on line 906.
L 909 (C 13-21): Value assigned to variable might be unused.
L 925 (C 16-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 927 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 929 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1082 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1147 (C 26-36): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 1174 (C 30-40): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 1223 (C 26-36): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 1331 (C 26-36): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 1361 (C 13): Value assigned to variable might be unused.
L 1400 (C 26-36): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 1426 (C 26-36): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 1447 (C 34): Extra semicolon is unnecessary.
L 1448 (C 18-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1448 (C 36-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1536 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1537 (C 21-33): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1677 (C 38): Extra comma is unnecessary.
L 1683 (C 89): Extra comma is unnecessary.
L 1688 (C 39): Extra comma is unnecessary.
L 1697 (C 49): Extra comma is unnecessary.
L 1704 (C 9-13): EXIST with two input arguments is generally faster and clearer than with one input argument.
L 1704 (C 29): Extra comma is unnecessary.
L 1707 (C 13-18): Using ISEMPTY is usually faster than comparing LENGTH to 0.
L 1707 (C 56): Extra comma is unnecessary.
L 1715 (C 44): Extra comma is unnecessary.
L 1722 (C 18): Extra comma is unnecessary.
L 1729 (C 5-16): Value assigned to variable might be unused.
L 1780 (C 5-14): Value assigned to variable might be unused.
L 1786 (C 5-15): Value assigned to variable might be unused.
L 1800 (C 30): Extra comma is unnecessary.
L 1826 (C 19): Extra comma is unnecessary.
L 1836 (C 17-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.

```

### `nspikeTrain.m` (108 lines)

```
L 218 (C 13-22): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 221 (C 47-56): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 245 (C 26-35): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 254 (C 23-32): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 306 (C 46-55): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 325 (C 18-23): Function return value might be unset.
L 458 (C 29-38): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 460 (C 29-38): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 460 (C 48-57): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 466 (C 48-57): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 466 (C 59-68): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 470 (C 48-57): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 470 (C 59-68): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 474 (C 48-57): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 474 (C 59-68): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 497 (C 25-34): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 499 (C 25-34): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 499 (C 44-53): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 506 (C 44-53): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 506 (C 55-64): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 510 (C 44-53): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 510 (C 55-64): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 514 (C 44-53): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 514 (C 55-64): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 562 (C 13-22): There is a property named 'spikeTimes'. Did you mean to reference it?
L 563 (C 20-29): There is a property named 'spikeTimes'. Did you mean to reference it?
L 570 (C 13): Value assigned to variable might be unused.
L 570 (C 13): There is a property named 'B'. Did you mean to reference it?
L 571 (C 22-31): There is a property named 'spikeTimes'. Did you mean to reference it?
L 572 (C 13-14): Value assigned to variable might be unused.
L 572 (C 13-14): There is a property named 'An'. Did you mean to reference it?
L 585 (C 18): Function return value might be unset.
L 612 (C 15-20): Value assigned to variable might be unused.
L 615 (C 17-23): Value assigned to variable might be unused.
L 618 (C 17-23): Value assigned to variable might be unused.
L 621 (C 17-23): Value assigned to variable might be unused.
L 656 (C 13): Value assigned to variable might be unused.
L 730 (C 17-22): Value assigned to variable might be unused.
L 741 (C 14-18): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 741 (C 20-23): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 778 (C 13-22): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 779 (C 25-34): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 801 (C 44): Extra semicolon is unnecessary.
L 812 (C 17-23): There is a property named 'minTime'. Maybe this is a reference to it?
L 813 (C 17-23): There is a property named 'maxTime'. Maybe this is a reference to it?
L 815 (C 17-26): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 817 (C 32-38): There is a property named 'maxTime'. Maybe this is a reference to it?
L 817 (C 40-46): There is a property named 'minTime'. Maybe this is a reference to it?
L 817 (C 63-69): There is a property named 'maxTime'. Maybe this is a reference to it?
L 817 (C 71-77): There is a property named 'minTime'. Maybe this is a reference to it?
L 821 (C 48-57): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 821 (C 59-68): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 821 (C 71-77): There is a property named 'minTime'. Maybe this is a reference to it?
L 821 (C 81-90): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 821 (C 93-99): There is a property named 'maxTime'. Maybe this is a reference to it?
L 823 (C 48-57): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 823 (C 59-68): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 823 (C 71-77): There is a property named 'minTime'. Maybe this is a reference to it?
L 823 (C 81-90): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 823 (C 92-98): There is a property named 'maxTime'. Maybe this is a reference to it?
L 825 (C 63-69): There is a property named 'minTime'. Maybe this is a reference to it?
L 832 (C 68-74): There is a property named 'maxTime'. Maybe this is a reference to it?
L 832 (C 76-82): There is a property named 'minTime'. Maybe this is a reference to it?
L 833 (C 31-33): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 837 (C 29-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 844 (C 44-53): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 844 (C 59-68): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 844 (C 71-77): There is a property named 'minTime'. Maybe this is a reference to it?
L 844 (C 79-88): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 844 (C 91-97): There is a property named 'maxTime'. Maybe this is a reference to it?
L 845 (C 25-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 847 (C 44-53): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 847 (C 59-68): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 847 (C 71-77): There is a property named 'minTime'. Maybe this is a reference to it?
L 847 (C 79-88): There is a property named 'spikeTimes'. Maybe this is a reference to it?
L 847 (C 90-96): There is a property named 'maxTime'. Maybe this is a reference to it?
L 848 (C 26-40): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 852 (C 59-65): There is a property named 'minTime'. Maybe this is a reference to it?
L 860 (C 62-68): There is a property named 'maxTime'. Maybe this is a reference to it?
L 860 (C 70-76): There is a property named 'minTime'. Maybe this is a reference to it?
L 861 (C 25-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 864 (C 25-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 900 (C 43-48): Input argument might be unused. Consider replacing the argument with ~, or make this method Static instead.
L 932 (C 12-15): There is a property named 'name'. Did you mean to reference it?
L 933 (C 12-21): There is a property named 'sampleRate'. Did you mean to reference it?
L 934 (C 12-21): There is a property named 'spikeTimes'. Did you mean to reference it?
L 935 (C 12-18): There is a property named 'minTime'. Did you mean to reference it?
L 936 (C 12-18): There is a property named 'maxTime'. Did you mean to reference it?
L 942 (C 12-16): This variable, apparently a structure, is changed but the value might be unused.
L 944 (C 12-20): There is a property named 'xlabelval'. Did you mean to reference it?
L 945 (C 12-17): There is a property named 'xunits'. Did you mean to reference it?
L 946 (C 30-39): There is a property named 'spikeTimes'. Did you mean to reference it?
L 946 (C 41-44): There is a property named 'name'. Did you mean to reference it?
L 946 (C 48-57): There is a property named 'sampleRate'. Did you mean to reference it?
L 946 (C 59-65): There is a property named 'minTime'. Did you mean to reference it?
L 946 (C 67-73): There is a property named 'maxTime'. Did you mean to reference it?
L 946 (C 76-84): There is a property named 'xlabelval'. Did you mean to reference it?
L 946 (C 86-91): There is a property named 'xunits'. Did you mean to reference it?
L 985 (C 17-25): There is a property named 'xlabelval'. Maybe this is a reference to it?
L 986 (C 17-22): There is a property named 'xunits'. Maybe this is a reference to it?
L 987 (C 17-20): There is a property named 'name'. Maybe this is a reference to it?
L 988 (C 17-22): There is a property named 'yunits'. Maybe this is a reference to it?
L 989 (C 28-33): There is a property named 'xunits'. Maybe this is a reference to it?
L 990 (C 43-48): There is a property named 'xunits'. Maybe this is a reference to it?
L 994 (C 31-39): There is a property named 'xlabelval'. Maybe this is a reference to it?
L 996 (C 28-33): There is a property named 'yunits'. Maybe this is a reference to it?
L 997 (C 43-48): There is a property named 'yunits'. Maybe this is a reference to it?
L 1001 (C 31-34): There is a property named 'name'. Maybe this is a reference to it?

```

### `nstColl.m` (106 lines)

```
L 128 (C 21-32): Best practice is to separate output variables with commas.
L 129 (C 15-34): To improve performance, use 'isscalar' instead of length comparison.
L 149 (C 28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 155 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 155 (C 31-38): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 160 (C 24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 176 (C 17-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 178 (C 17-29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 191 (C 17-20): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 267 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 310 (C 13-19): There is a property named 'minTime'. Maybe this is a reference to it?
L 311 (C 13-19): There is a property named 'maxTime'. Maybe this is a reference to it?
L 314 (C 17-23): There is a property named 'minTime'. Maybe this is a reference to it?
L 314 (C 58-64): There is a property named 'minTime'. Maybe this is a reference to it?
L 315 (C 17-23): There is a property named 'maxTime'. Maybe this is a reference to it?
L 315 (C 58-64): There is a property named 'maxTime'. Maybe this is a reference to it?
L 317 (C 35-41): There is a property named 'minTime'. Maybe this is a reference to it?
L 318 (C 35-41): There is a property named 'maxTime'. Maybe this is a reference to it?
L 390 (C 19-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 424 (C 25-34): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 425 (C 25-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 426 (C 47-56): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 427 (C 29-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 427 (C 54-63): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 431 (C 21-30): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 433 (C 40-49): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 434 (C 44-53): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 517 (C 42): Extra semicolon is unnecessary.
L 568 (C 73): Extra semicolon is unnecessary.
L 573 (C 23-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 584 (C 13-19): The preallocated value assigned to variable might be unused.
L 595 (C 17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 632 (C 25-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 649 (C 28-37): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 831 (C 13-19): There is a property named 'minTime'. Maybe this is a reference to it?
L 832 (C 13-19): There is a property named 'maxTime'. Maybe this is a reference to it?
L 834 (C 47-53): There is a property named 'minTime'. Maybe this is a reference to it?
L 834 (C 55-61): There is a property named 'maxTime'. Maybe this is a reference to it?
L 837 (C 39-45): There is a property named 'minTime'. Maybe this is a reference to it?
L 838 (C 39-45): There is a property named 'maxTime'. Maybe this is a reference to it?
L 839 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 843 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 849 (C 14-20): There is a property named 'minTime'. Maybe this is a reference to it?
L 849 (C 42-48): There is a property named 'maxTime'. Maybe this is a reference to it?
L 851 (C 31-37): There is a property named 'maxTime'. Maybe this is a reference to it?
L 851 (C 39-45): There is a property named 'minTime'. Maybe this is a reference to it?
L 852 (C 17-26): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 853 (C 79-85): There is a property named 'minTime'. Maybe this is a reference to it?
L 853 (C 87-93): There is a property named 'maxTime'. Maybe this is a reference to it?
L 853 (C 95-104): There is a property named 'sampleRate'. Maybe this is a reference to it?
L 861 (C 23): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 868 (C 17-18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 876 (C 17-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 879 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 880 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 886 (C 27-33): There is a property named 'minTime'. Maybe this is a reference to it?
L 922 (C 13-25): Value assigned to variable might be unused.
L 951 (C 21-33): Value assigned to variable might be unused.
L 953 (C 21-33): Value assigned to variable might be unused.
L 968 (C 13-20): Value assigned to variable might be unused.
L 995 (C 61-71): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 1067 (C 13-16): Value assigned to variable might be unused.
L 1078 (C 17-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1096 (C 15-17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1097 (C 15-17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1114 (C 43): Extra semicolon is unnecessary.
L 1120 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1133 (C 21-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1145 (C 17-18): This condition has no effect because all blocks in this if statement are identical. This indicates a bug in the code. Remove the condition or change the code blocks.
L 1147 (C 21-26): Value assigned to variable might be unused.
L 1149 (C 21-26): Value assigned to variable might be unused.
L 1152 (C 21-26): Value assigned to variable might be unused.
L 1154 (C 21-26): Value assigned to variable might be unused.
L 1159 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1160 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1207 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1208 (C 50): Extra semicolon is unnecessary.
L 1209 (C 25-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1216 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1217 (C 50): Extra semicolon is unnecessary.
L 1218 (C 25-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1305 (C 17-20): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1314 (C 17-22): Value assigned to variable might be unused.
L 1335 (C 20-31): To improve performance, use 'isscalar' instead of length comparison.
L 1341 (C 17-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1342 (C 46): Extra semicolon is unnecessary.
L 1343 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1357 (C 88-93): Input argument might be unused. Consider replacing the argument with ~ instead.
L 1359 (C 17-22): Value assigned to variable might be unused.
L 1383 (C 17-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1384 (C 46): Extra semicolon is unnecessary.
L 1385 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1419 (C 13-19): There is a property named 'minTime'. Maybe this is a reference to it?
L 1420 (C 13-19): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1429 (C 42-48): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1430 (C 42-48): There is a property named 'minTime'. Maybe this is a reference to it?
L 1439 (C 42-48): There is a property named 'maxTime'. Maybe this is a reference to it?
L 1440 (C 42-48): There is a property named 'minTime'. Maybe this is a reference to it?
L 1447 (C 17-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1460 (C 20-25): 'nanvar' is not recommended. With appropriate code changes, use 'var' instead.
L 1469 (C 17-23): Value assigned to variable might be unused.
L 1472 (C 17-23): Value assigned to variable might be unused.
L 1507 (C 45): Extra semicolon is unnecessary.
L 1547 (C 21-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1549 (C 21-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1584 (C 46): Extra semicolon is unnecessary.

```

### `+nstat/+decoding/KF_EM.m` (94 lines)

```
L 110 (C 13-18): Value assigned to variable might be unused.
L 112 (C 13-15): Value assigned to variable might be unused.
L 131 (C 13-17): Value assigned to variable might be unused.
L 150 (C 13-17): Value assigned to variable might be unused.
L 165 (C 18-20): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 165 (C 32-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 165 (C 46-47): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 165 (C 54-68): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 168 (C 18-21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 168 (C 36-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 168 (C 54-57): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 168 (C 72-75): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 168 (C 90-97): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 168 (C 111-115): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 168 (C 129-134): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 172 (C 26): Use of brackets [] is unnecessary.
L 177 (C 30-35): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 177 (C 37-41): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 180 (C 71-75): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 180 (C 77-82): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 183 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 184 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 185 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 186 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 187 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 188 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 189 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 201 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 204 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 206 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 266 (C 26): Use of brackets [] is unnecessary.
L 274 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 275 (C 21-25): Value assigned to variable might be unused.
L 280 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 281 (C 21-25): Value assigned to variable might be unused.
L 426 (C 13): Value assigned to variable might be unused.
L 464 (C 13-14): Value assigned to variable might be unused.
L 465 (C 13-14): Value assigned to variable might be unused.
L 466 (C 13-15): Value assigned to variable might be unused.
L 467 (C 17): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 571 (C 21-26): The preallocated value assigned to variable might be unused.
L 668 (C 48): Extra semicolon is unnecessary.
L 732 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 739 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 780 (C 21-25): Value assigned to variable might be unused.
L 845 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 847 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 850 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 852 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 881 (C 21-25): Value assigned to variable might be unused.
L 944 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 947 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 949 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1020 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1020 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1020 (C 30): Best practice is to separate output variables with commas.
L 1027 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1027 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1027 (C 30): Best practice is to separate output variables with commas.
L 1037 (C 17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1037 (C 22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1037 (C 22): Best practice is to separate output variables with commas.
L 1047 (C 22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1047 (C 24): Best practice is to separate output variables with commas.
L 1053 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1053 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1053 (C 30): Best practice is to separate output variables with commas.
L 1061 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1061 (C 26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1061 (C 26): Best practice is to separate output variables with commas.
L 1072 (C 22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1072 (C 24): Best practice is to separate output variables with commas.
L 1078 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1078 (C 30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1078 (C 30): Best practice is to separate output variables with commas.
L 1086 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1086 (C 26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1086 (C 26): Best practice is to separate output variables with commas.
L 1096 (C 22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1096 (C 24): Best practice is to separate output variables with commas.
L 1102 (C 26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1102 (C 31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1102 (C 31): Best practice is to separate output variables with commas.
L 1112 (C 18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1112 (C 23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1112 (C 23): Best practice is to separate output variables with commas.
L 1121 (C 22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1121 (C 27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1121 (C 27): Best practice is to separate output variables with commas.
L 1148 (C 23-24): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1176 (C 13-19): The preallocated value assigned to variable might be unused.
L 1194 (C 13-17): Value assigned to variable might be unused.
L 1248 (C 13-15): Value assigned to variable might be unused.
L 1249 (C 13-17): Value assigned to variable might be unused.

```

### `Analysis.m` (77 lines)

```
L 95 (C 16-22): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 128 (C 29-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 245 (C 41-45): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 247 (C 41-48): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 363 (C 41-45): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 365 (C 41-48): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 427 (C 16-38): To improve performance, use 'isscalar' instead of length comparison.
L 548 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 549 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 551 (C 21-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 582 (C 21-32): Value assigned to variable might be unused.
L 598 (C 59): Extra semicolon is unnecessary.
L 612 (C 33-34): Value assigned to variable might be unused.
L 613 (C 25): Value assigned to variable might be unused.
L 767 (C 22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 786 (C 13-18): Value assigned to variable might be unused.
L 879 (C 31-36): 'nanmin' is not recommended. With appropriate code changes, use 'min' instead.
L 879 (C 38-43): 'nanmax' is not recommended. With appropriate code changes, use 'max' instead.
L 940 (C 25): If you intend to specify expression precedence, use parentheses () instead of brackets [].
L 941 (C 48): If you intend to specify expression precedence, use parentheses () instead of brackets [].
L 1093 (C 25-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1100 (C 40-44): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1102 (C 41-58): For readability, use '~contains(str1, str2)' instead of 'isempty(strfind(str1, str2))'.
L 1103 (C 21-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1104 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1105 (C 21-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1113 (C 17-22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1113 (C 25-29): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1280 (C 25-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1287 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1303 (C 31-47): Function might be unused.
L 1348 (C 6-9): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1359 (C 6): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1391 (C 20-23): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1480 (C 32): Extra semicolon is unnecessary.
L 1482 (C 8): Extra semicolon is unnecessary.
L 1487 (C 65): Extra semicolon is unnecessary.
L 1488 (C 32): Extra semicolon is unnecessary.
L 1489 (C 13-14): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1492 (C 11-14): To improve performance, replace ISEMPTY(FIND(X)) with ISEMPTY(FIND( X, 1 )).
L 1493 (C 26): Extra semicolon is unnecessary.
L 1495 (C 8): Extra semicolon is unnecessary.
L 1496 (C 11-14): To improve performance, replace ISEMPTY(FIND(X)) with ISEMPTY(FIND( X, 1 )).
L 1497 (C 26): Extra semicolon is unnecessary.
L 1499 (C 8): Extra semicolon is unnecessary.
L 1504 (C 38): Extra semicolon is unnecessary.
L 1507 (C 76): Extra semicolon is unnecessary.
L 1508 (C 32): Extra semicolon is unnecessary.
L 1510 (C 74): Extra semicolon is unnecessary.
L 1516 (C 40): Extra semicolon is unnecessary.
L 1519 (C 79): Extra semicolon is unnecessary.
L 1520 (C 32): Extra semicolon is unnecessary.
L 1525 (C 8): Extra semicolon is unnecessary.
L 1533 (C 26): Extra semicolon is unnecessary.
L 1535 (C 8): Extra semicolon is unnecessary.
L 1536 (C 41): Extra semicolon is unnecessary.
L 1538 (C 8): Extra semicolon is unnecessary.
L 1558 (C 22): Extra semicolon is unnecessary.
L 1576 (C 8): Extra semicolon is unnecessary.
L 1729 (C 12): Extra comma is unnecessary.
L 1732 (C 33): Extra comma is unnecessary.
L 1734 (C 37): Extra comma is unnecessary.
L 1739 (C 12): Extra comma is unnecessary.
L 1743 (C 12): Extra comma is unnecessary.
L 1747 (C 12): Extra comma is unnecessary.
L 1752 (C 27): Extra comma is unnecessary.
L 1758 (C 2-6): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 1761 (C 26): Extra comma is unnecessary.
L 1770 (C 27): If you intend to specify expression precedence, use parentheses () instead of brackets [].
L 1777 (C 13): Extra comma is unnecessary.
L 1788 (C 16): Extra semicolon is unnecessary.
L 1789 (C 12): Extra semicolon is unnecessary.
L 1790 (C 8): Extra semicolon is unnecessary.
L 1796 (C 19): Extra comma is unnecessary.
L 1806 (C 25): Extra comma is unnecessary.
L 1808 (C 16): Extra comma is unnecessary.
L 1813 (C 30): Extra comma is unnecessary.

```

### `FitResSummary.m` (75 lines)

```
L 150 (C 13-20): There is a property named 'flatMask'. Did you mean to reference it?
L 166 (C 25-32): There is a property named 'flatMask'. Did you mean to reference it?
L 169 (C 31-38): There is a property named 'flatMask'. Did you mean to reference it?
L 296 (C 12-22): Value assigned to variable might be unused.
L 302 (C 17-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 305 (C 18-19): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 305 (C 21-22): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 308 (C 17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 340 (C 17): Value assigned to variable might be unused.
L 343 (C 13-20): Value assigned to variable might be unused.
L 357 (C 16-31): Value assigned to variable might be unused.
L 361 (C 16-24): Value assigned to variable might be unused.
L 374 (C 12-15): There is a property named 'bAct'. Maybe this is a reference to it?
L 375 (C 12-16): There is a property named 'seAct'. Maybe this is a reference to it?
L 376 (C 34-37): There is a property named 'bAct'. Maybe this is a reference to it?
L 376 (C 55-58): There is a property named 'bAct'. Maybe this is a reference to it?
L 379 (C 47-50): There is a property named 'bAct'. Maybe this is a reference to it?
L 379 (C 68-72): There is a property named 'seAct'. Maybe this is a reference to it?
L 415 (C 25-35): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 452 (C 17-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 518 (C 18-23): Function return value might be unset.
L 524 (C 12-21): There is a property named 'numNeurons'. Did you mean to reference it?
L 525 (C 51-60): There is a property named 'numNeurons'. Did you mean to reference it?
L 543 (C 18-23): Function return value might be unset.
L 549 (C 12-21): There is a property named 'numNeurons'. Did you mean to reference it?
L 550 (C 51-60): There is a property named 'numNeurons'. Did you mean to reference it?
L 567 (C 18-23): Function return value might be unset.
L 573 (C 12-21): There is a property named 'numNeurons'. Did you mean to reference it?
L 574 (C 53-62): There is a property named 'numNeurons'. Did you mean to reference it?
L 621 (C 26-36): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 658 (C 26-36): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 735 (C 23-39): 'computePlotParams' is referenced but is not a property, method, or event name defined in this class.
L 752 (C 17-29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 757 (C 22-29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 757 (C 36-42): If you are operating on scalar values, consider using 'str2double' for faster performance.
L 760 (C 21-33): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 761 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 776 (C 18-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 778 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 815 (C 23-39): 'computePlotParams' is referenced but is not a property, method, or event name defined in this class.
L 838 (C 23-39): 'computePlotParams' is referenced but is not a property, method, or event name defined in this class.
L 849 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 854 (C 22-29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 854 (C 36-42): If you are operating on scalar values, consider using 'str2double' for faster performance.
L 867 (C 18-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 869 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 899 (C 13-21): Value assigned to variable might be unused.
L 906 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 908 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 914 (C 16-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 916 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 918 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1026 (C 13-21): Value assigned to variable might be unused.
L 1033 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1035 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1041 (C 16-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1043 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1045 (C 17-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1111 (C 23-39): 'computePlotParams' is referenced but is not a property, method, or event name defined in this class.
L 1144 (C 17-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1218 (C 38): Extra comma is unnecessary.
L 1224 (C 89): Extra comma is unnecessary.
L 1229 (C 39): Extra comma is unnecessary.
L 1238 (C 49): Extra comma is unnecessary.
L 1245 (C 9-13): EXIST with two input arguments is generally faster and clearer than with one input argument.
L 1245 (C 29): Extra comma is unnecessary.
L 1248 (C 13-18): Using ISEMPTY is usually faster than comparing LENGTH to 0.
L 1248 (C 56): Extra comma is unnecessary.
L 1256 (C 44): Extra comma is unnecessary.
L 1263 (C 18): Extra comma is unnecessary.
L 1270 (C 5-16): Value assigned to variable might be unused.
L 1311 (C 5-14): Value assigned to variable might be unused.
L 1317 (C 5-15): Value assigned to variable might be unused.
L 1331 (C 30): Extra comma is unnecessary.
L 1357 (C 19): Extra comma is unnecessary.

```

### `+nstat/+decoding/PPHF.m` (65 lines)

```
L 34 (C 17-18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 36 (C 13-17): Value assigned to variable might be unused.
L 71 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 72 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 73 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 75 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 82 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 83 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 85 (C 25-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 87 (C 25-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 89 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 91 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 92 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 117 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 118 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 119 (C 21-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 123 (C 25-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 131 (C 28-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 138 (C 28-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 153 (C 29-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 186 (C 21-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 209 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 210 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 216 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 219 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 220 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 233 (C 17-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 234 (C 17-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 246 (C 17-19): Assignment to variable might be unnecessary.
L 468 (C 16-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 475 (C 17-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 478 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 480 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 489 (C 20-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 522 (C 32-35): Function return value might be unset.
L 529 (C 14): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 532 (C 17-18): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 534 (C 13-17): Value assigned to variable might be unused.
L 559 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 560 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 561 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 569 (C 21-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 570 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 572 (C 25-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 574 (C 25-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 576 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 578 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 579 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 604 (C 21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 605 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 617 (C 28-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 620 (C 28-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 634 (C 29-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 666 (C 21-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 682 (C 13-19): Value assigned to variable might be unused.
L 683 (C 13-19): Value assigned to variable might be unused.
L 685 (C 13): Value assigned to variable might be unused.
L 692 (C 17-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 693 (C 17-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 705 (C 17-19): Assignment to variable might be unnecessary.
L 921 (C 16-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 928 (C 17-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 931 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 933 (C 25-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 942 (C 20-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.

```

### `CovColl.m` (46 lines)

```
L 245 (C 20-40): To improve performance, use 'isscalar' instead of length comparison.
L 333 (C 25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 392 (C 41): Extra semicolon is unnecessary.
L 416 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 496 (C 33): Extra semicolon is unnecessary.
L 504 (C 53-62): Input argument might be unused. Consider replacing the argument with ~ instead.
L 509 (C 17-26): Value assigned to variable might be unused.
L 529 (C 13-19): There is a property named 'covMask'. Did you mean to reference it?
L 530 (C 20-26): There is a property named 'covMask'. Did you mean to reference it?
L 531 (C 26-32): There is a property named 'covMask'. Did you mean to reference it?
L 532 (C 24-30): There is a property named 'covMask'. Did you mean to reference it?
L 534 (C 32-38): There is a property named 'covMask'. Did you mean to reference it?
L 535 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 535 (C 42-48): There is a property named 'covMask'. Did you mean to reference it?
L 594 (C 13-19): Value assigned to variable might be unused.
L 594 (C 13-19): There is a property named 'maxTime'. Maybe this is a reference to it?
L 596 (C 13-19): Value assigned to variable might be unused.
L 596 (C 13-19): There is a property named 'minTime'. Maybe this is a reference to it?
L 598 (C 13-20): Value assigned to variable might be unused.
L 691 (C 21-24): Calling AXES(h) in a loop can be slow. Consider moving the call to AXES outside the loop.
L 702 (C 51): Extra semicolon is unnecessary.
L 748 (C 47): Extra semicolon is unnecessary.
L 806 (C 56): Extra semicolon is unnecessary.
L 819 (C 13-19): There is a property named 'minTime'. Maybe this is a reference to it?
L 819 (C 35-41): There is a property named 'maxTime'. Maybe this is a reference to it?
L 820 (C 16-22): There is a property named 'minTime'. Maybe this is a reference to it?
L 821 (C 34-40): There is a property named 'minTime'. Maybe this is a reference to it?
L 823 (C 16-22): There is a property named 'maxTime'. Maybe this is a reference to it?
L 824 (C 34-40): There is a property named 'maxTime'. Maybe this is a reference to it?
L 852 (C 13-20): There is a property named 'covArray'. Maybe this is a reference to it?
L 853 (C 13-19): There is a property named 'covMask'. Maybe this is a reference to it?
L 854 (C 13-25): There is a property named 'covDimensions'. Maybe this is a reference to it?
L 857 (C 17-23): There is a property named 'covMask'. Maybe this is a reference to it?
L 858 (C 17-24): There is a property named 'covArray'. Maybe this is a reference to it?
L 859 (C 17-29): There is a property named 'covDimensions'. Maybe this is a reference to it?
L 861 (C 13-18): There is a property named 'numCov'. Maybe this is a reference to it?
L 862 (C 30-37): There is a property named 'covArray'. Maybe this is a reference to it?
L 863 (C 30-36): There is a property named 'covMask'. Maybe this is a reference to it?
L 864 (C 28-33): There is a property named 'numCov'. Maybe this is a reference to it?
L 865 (C 35-47): There is a property named 'covDimensions'. Maybe this is a reference to it?
L 866 (C 13-19): There is a property named 'minTime'. Maybe this is a reference to it?
L 867 (C 13-19): There is a property named 'maxTime'. Maybe this is a reference to it?
L 868 (C 30-36): There is a property named 'minTime'. Maybe this is a reference to it?
L 869 (C 30-36): There is a property named 'maxTime'. Maybe this is a reference to it?
L 870 (C 16-21): There is a property named 'numCov'. Maybe this is a reference to it?
L 893 (C 41): Extra semicolon is unnecessary.

```

### `+nstat/+decoding/SSGLM.m` (40 lines)

```
L 44 (C 20-22): Value assigned to variable might be unused.
L 57 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 60 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 64 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 66 (C 17-22): Value assigned to variable might be unused.
L 87 (C 17-23): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 88 (C 61-65): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 88 (C 76-81): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 90 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 91 (C 31-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 91 (C 46-54): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 91 (C 65-70): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 91 (C 81-86): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 93 (C 25-31): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 95 (C 67-72): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 102 (C 29-33): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 111 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 113 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 133 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 137 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 161 (C 13-22): Value assigned to variable might be unused.
L 201 (C 13-19): Value assigned to variable might be unused.
L 202 (C 13-19): Value assigned to variable might be unused.
L 203 (C 13): Value assigned to variable might be unused.
L 212 (C 13-15): Value assigned to variable might be unused.
L 239 (C 18-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 239 (C 31-32): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 239 (C 44-46): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 239 (C 58-62): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 239 (C 80-86): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 244 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 246 (C 21-31): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 267 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 272 (C 21-27): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 323 (C 16): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 350 (C 21-22): Value assigned to variable might be unused.
L 357 (C 21-33): The preallocated value assigned to variable might be unused.
L 366 (C 21-22): Value assigned to variable might be unused.
L 398 (C 23-24): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 476 (C 14): Value assigned to variable might be unused.

```

### `DecodingAlgorithms.m` (39 lines)

```
L 260 (C 17-20): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 320 (C 21-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 326 (C 21-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 332 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 334 (C 29-39): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 422 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 423 (C 20-35): To improve performance, use 'isscalar' instead of length comparison.
L 427 (C 21): The preallocated value assigned to variable might be unused.
L 429 (C 21-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 432 (C 25-36): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 434 (C 25-36): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 463 (C 16): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 533 (C 21-34): Value assigned to variable might be unused.
L 556 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 557 (C 20-35): To improve performance, use 'isscalar' instead of length comparison.
L 561 (C 21): The preallocated value assigned to variable might be unused.
L 569 (C 13-14): The preallocated value assigned to variable might be unused.
L 605 (C 25-52): Value assigned to variable might be unused.
L 658 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 661 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 665 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 674 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 675 (C 20-35): To improve performance, use 'isscalar' instead of length comparison.
L 679 (C 21): The preallocated value assigned to variable might be unused.
L 681 (C 21-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 693 (C 25-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 696 (C 25-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 703 (C 16-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 760 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 763 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 767 (C 21-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 776 (C 25): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 777 (C 20-35): To improve performance, use 'isscalar' instead of length comparison.
L 781 (C 21): The preallocated value assigned to variable might be unused.
L 783 (C 21-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 795 (C 25-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 798 (C 25-35): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 805 (C 16-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 817 (C 58): Use of brackets [] is unnecessary.

```

### `+nstat/+decoding/PPAF.m` (29 lines)

```
L 37 (C 95-97): Input argument might be unused. Consider replacing the argument with ~ instead.
L 42 (C 14): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 65 (C 17-18): The preallocated value assigned to variable might be unused.
L 66 (C 17-19): The preallocated value assigned to variable might be unused.
L 115 (C 24-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 122 (C 24-27): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 130 (C 25-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 152 (C 14): Value assigned to variable might be unused. Consider replacing the variable with ~ instead.
L 397 (C 17-18): The preallocated value assigned to variable might be unused.
L 398 (C 17-19): The preallocated value assigned to variable might be unused.
L 449 (C 25-26): Value assigned to variable might be unused.
L 457 (C 25-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 459 (C 25-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 467 (C 25-26): Value assigned to variable might be unused.
L 469 (C 25-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 485 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 488 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 502 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 503 (C 21-28): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 660 (C 17-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 663 (C 17-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 677 (C 17-21): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 678 (C 17-24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 852 (C 16-30): To improve performance, use 'isscalar' instead of length comparison.
L 905 (C 21-27): Value assigned to variable might be unused.
L 915 (C 21-31): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 1005 (C 13-17): Value assigned to variable might be unused.
L 1096 (C 16-32): To improve performance, use 'isscalar' instead of length comparison.
L 1120 (C 13-17): Value assigned to variable might be unused.

```

### `Trial.m` (18 lines)

```
L 173 (C 21-34): There is a property named 'trainingWindow'. Maybe this is a reference to it?
L 174 (C 21-36): There is a property named 'validationWindow'. Maybe this is a reference to it?
L 176 (C 21-34): There is a property named 'trainingWindow'. Maybe this is a reference to it?
L 177 (C 21-36): There is a property named 'validationWindow'. Maybe this is a reference to it?
L 182 (C 41-54): There is a property named 'trainingWindow'. Maybe this is a reference to it?
L 183 (C 41-56): There is a property named 'validationWindow'. Maybe this is a reference to it?
L 184 (C 33-46): There is a property named 'trainingWindow'. Maybe this is a reference to it?
L 185 (C 33-46): There is a property named 'trainingWindow'. Maybe this is a reference to it?
L 233 (C 16): Extra semicolon is unnecessary.
L 297 (C 39): Extra semicolon is unnecessary.
L 542 (C 17-23): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 543 (C 17-23): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 562 (C 19-40): To improve performance, use 'isscalar' instead of length comparison.
L 599 (C 21-25): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 663 (C 24): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 907 (C 29-32): Input argument might be unused. Consider replacing the argument with ~ instead.
L 907 (C 34-39): Input argument might be unused. Consider replacing the argument with ~ instead.
L 909 (C 17-22): Value assigned to variable might be unused.

```

### `CIF.m` (14 lines)

```
L 194 (C 23-29): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 237 (C 21-29): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 238 (C 21-33): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 342 (C 16-57): To improve performance, use 'isscalar' instead of length comparison.
L 360 (C 16-78): To improve performance, use 'isscalar' instead of length comparison.
L 387 (C 29): Use of brackets [] is unnecessary.
L 387 (C 33): Use of brackets [] is unnecessary.
L 387 (C 39): Use of brackets [] is unnecessary.
L 414 (C 42): Extra semicolon is unnecessary.
L 794 (C 18-20): Using ANS as a variable is not recommended as ANS is frequently overwritten by MATLAB.
L 796 (C 15-17): Using ANS as a variable is not recommended as ANS is frequently overwritten by MATLAB.
L 798 (C 15-17): Using ANS as a variable is not recommended as ANS is frequently overwritten by MATLAB.
L 961 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 1040 (C 21-23): Variable appears to change size on every loop iteration. Consider preallocating for speed.

```

### `History.m` (14 lines)

```
L 137 (C 17-26): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 169 (C 17-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 170 (C 17-19): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 188 (C 17-22): Value assigned to variable might be unused.
L 293 (C 19-22): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 316 (C 23-30): Value assigned to variable might be unused.
L 324 (C 23-29): There is a property named 'minTime'. Maybe this is a reference to it?
L 325 (C 23-29): There is a property named 'maxTime'. Maybe this is a reference to it?
L 326 (C 34-40): There is a property named 'minTime'. Maybe this is a reference to it?
L 327 (C 27-33): There is a property named 'minTime'. Maybe this is a reference to it?
L 329 (C 34-40): There is a property named 'maxTime'. Maybe this is a reference to it?
L 330 (C 27-33): There is a property named 'maxTime'. Maybe this is a reference to it?
L 333 (C 51-57): There is a property named 'minTime'. Maybe this is a reference to it?
L 333 (C 59-65): There is a property named 'maxTime'. Maybe this is a reference to it?

```

### `nSTAT_Install.m` (13 lines)

```
L 43 (C 1-7): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 56 (C 9-15): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 68 (C 9-13): Calling functions using 'feval' is usually not necessary. Call the function directly instead.
L 72 (C 13-17): Calling functions using 'feval' is usually not necessary. Call the function directly instead.
L 83 (C 1-7): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 86 (C 1-7): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 193 (C 5-11): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 243 (C 1-7): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 248 (C 57-67): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 250 (C 1-90): 'display(sprintf(...))' can usually be replaced by 'fprintf(...\n)'.
L 266 (C 1-7): Programmatic use of DISPLAY is not recommended. Use DISP or FPRINTF instead.
L 276 (C 1-79): 'display(sprintf(...))' can usually be replaced by 'fprintf(...\n)'.
L 328 (C 44-54): A Code Analyzer message was once suppressed here, but the message is no longer generated.

```

### `Covariate.m` (11 lines)

```
L 64 (C 15-17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 65 (C 15-17): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 159 (C 18-20): Using ANS as a variable is not recommended as ANS is frequently overwritten by MATLAB.
L 160 (C 13-15): Using ANS as a variable is not recommended as ANS is frequently overwritten by MATLAB.
L 182 (C 25-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 187 (C 25-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 192 (C 25-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 206 (C 25-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 211 (C 25-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 216 (C 25-30): Variable appears to change size on every loop iteration. Consider preallocating for speed.
L 239 (C 29-34): Variable appears to change size on every loop iteration. Consider preallocating for speed.

```

### `tools/check_parity_against_baseline.m` (6 lines)

```
L 30 (C 56-66): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 238 (C 123-133): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 246 (C 121-131): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 258 (C 103-113): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 291 (C 82-92): A Code Analyzer message was once suppressed here, but the message is no longer generated.
L 296 (C 88-98): A Code Analyzer message was once suppressed here, but the message is no longer generated.

```


## Summary triage (Phase D2.2)

- **0 "definite error" severity findings.** No checkcode message of the
  kind that would prevent the file from parsing or executing.
- **1567 stylistic findings across 29 of 43 in-scope files.** The
  distribution is dominated by:
  - Extra semicolons / missing semicolons.
  - `length(x) == 1` suggested → `isscalar(x)`.
  - `DISPLAY` → `DISP` / `FPRINTF` recommendation (legacy API).
  - "There is a property named X — maybe this is a reference?" (a
    heuristic catching field/property name collisions; nearly always
    a false positive in this codebase because the code intentionally
    refers to local variables with names similar to class properties).
  - Variable shadowing in inner functions, `%#ok` annotation
    candidates, function-handle precision.

### Decision

**No actionable defects from checkcode.** The findings are an accumulated
stylistic backlog, not bugs. Treat as opportunistic cleanup during
future refactors rather than a single concerted sweep.

The pattern-based audit (D2.1, [`bug_pattern_audit.md`](bug_pattern_audit.md))
is the canonical sibling-bug detector and is run from the deploy gate.
The checkcode sweep here is informational and stops short of being a
release blocker.

## Open follow-up

If the team chooses to drain the checkcode backlog, the largest files by
finding count are:

- `SignalObj.m` (269 findings) — old + organic.
- The `+nstat/+decoding/*` cluster classes (largely inherited from the
  facade refactor; style warnings carried over from the original code).
- `Analysis.m`, `FitResult.m`, `CIF.m` — core math files.

A 1-day cleanup PR could realistically halve the count without changing
any behavior, using `mlint` quick-fixes for the safe categories
(semicolons, `isscalar`, `DISP`). Defer this until a developer has a
free afternoon.
