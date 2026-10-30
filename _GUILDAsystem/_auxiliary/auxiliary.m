classdef auxiliary < handle
% Base class of the classes that assist analyses (solvers, results, parameters, drawers).
%
% It separates the classes that make up the power system model from those intended for
% analysis assistance:
%
% - Classes that constitute the power system model inherit from PowerSystemModel.
% - Classes intended for analysis assistance inherit from auxiliary.
%
% See also PowerSystemModel, AnalysisResult
end