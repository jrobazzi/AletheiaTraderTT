function gcapercent(varargin)
% gcapercent.m
%
% add '%' symbol to end of axes labels of the current axes (i.e. gca).
%
%   SYNAX:
%       gcapercent with no arguments adds % symbol to both x and y axes.
%
%       gcapercent('x') addes % symbol to only x axis
%
%       gcapercent('y') adds the % symbol to only the y axis
%
%   EXAMPLES:
%       % change both axes
%       plot(0:10, 0:10, 'o--b')
%       gcapercent
%
%       % change only x axis
%       plot(0:10, 0:10, 'o--b')
%       gcapercent('x')
%
%   NOTES:
%       Place this function in your %%My Documents%%\MATLAB folder so that
%       you can call this function from all your projects
%
%       Make sure you adjust your axes ranges before you use gcapercent.
%       For example:
%           plot(0:10, 0:10, 'o--b')
%           axis([0 5 0 5])
%           gcapercent
%
% Kristofer D. Kusano
% rev0 - 9/25/12

%% check inputs
if (nargin > 0 && ~ischar(varargin{1}))
    error('gcapercent:ArgNotChar', 'argument must be a character')
end

%% figure out which axis/axes to apply % symbol to
if (nargin > 0)
    argstr = upper(varargin{1});
else
    argstr = '';
end

switch argstr
    case '' % both x and y
        decider = 0;
    case 'X'
        decider = 1;
    case 'Y'
        decider = 2;
    otherwise
        error('gcapercent:ArgNotXY', 'argument must be ''x'', ''y'', or no argument')
end

%% apply % smybol
if (decider == 0 || decider == 1) % do x
    xtl = get(gca, 'xticklabel');
    xtll = '';
    for i = 1:size(xtl, 1)
        xtll = [xtll; xtl(i, :) '%'];
    end
    set(gca, 'xticklabel', xtll)
end

if (decider == 0 || decider == 2) % do y
    ytl = get(gca, 'yticklabel');
    ytll = '';
    for i = 1:length(ytl)
        ytll = [ytll; ytl(i, :) '%'];
    end
    set(gca, 'yticklabel', ytll)
end