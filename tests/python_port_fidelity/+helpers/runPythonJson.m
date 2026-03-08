function payload = runPythonJson(code)
%RUNPYTHONJSON Execute Python code that assigns `json_text` and decode it.

jsonText = pyrun(char(code), "json_text");
payload = jsondecode(char(jsonText));
end
