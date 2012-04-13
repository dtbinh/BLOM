function code = BLOM_FunctionCode(fcn)
% This function outputs the exception values used in BLOM to represent
% special transcendental (non-polynomial) functions. It takes one input
% argument, a string representing the desired function such as 'exp',
% 'log', etc. The output is a scalar double value that is used everywhere
% else in BLOM to represent these functions and trigger special behavior
% for function and gradient generation and evaluation.

switch fcn
   case 'exp'
      code = 2^64;
   case 'log'
      code = 2^65;
   otherwise
      % output a vector listing all the exception code values
      code = [2^64, 2^65];
end


% notes to self:
% hex2num('43d74910d52d3051') is the largest double for which (1-eps/2)^x > 0
% hex2num('43c62e42fefa39ef') is the largest double for which (1+eps)^x < inf
% hex2num('c3d62e42fefa39ee') is the smallest double for which (1-eps/2)^x < inf
% hex2num('c3c74910d52d3052') is the smallest double for which (1+eps)^x > 0

