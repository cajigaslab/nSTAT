%% MATLAB 2025b Help Integration for nSTAT
% This page documents the help-file structure used by nSTAT so it appears as
% supplemental software documentation in MATLAB.
%
% The configuration in this release is aligned with MATLAB R2025b.
%
%% Required Files
% nSTAT uses the standard external toolbox documentation layout:
%
% * `info.xml` in the toolbox root.
% * `helpfiles/helptoc.xml` with `toc version="2.0"`.
% * HTML help content referenced by each `target` in `helptoc.xml`.
%
%% Build and Refresh the Search Database
% Run the installer script from the nSTAT root folder:
%
%   nSTAT_Install
%
% or run these commands manually:
%
%   rootDir = fileparts(which('nSTAT_Install'));
%   helpDir = fullfile(rootDir,'helpfiles');
%   builddocsearchdb(helpDir);
%   rehash toolboxcache;
%
%% MATLAB 2025b Behavior
% Starting in R2024b, toolbox documentation is shown in the system browser.
% External toolbox documentation appears in MATLAB documentation under
% Supplemental Software.
%
% Use these pages as entry points:
%
% * <NeuralSpikeAnalysis_top.html nSTAT Home>
% * <ClassDefinitions.html Class Definitions>
% * <Examples.html Example Index>
%
%% Troubleshooting
% * If the nSTAT docs are not visible, run `rehash toolboxcache`.
% * If nSTAT pages do not appear in search, run `builddocsearchdb` again.
% * Ensure all `target` entries in `helptoc.xml` map to real HTML files.
