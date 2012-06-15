function BLOM_Setup(ipopt_dir)
% Function to easily compile BLOM_NLP for the first time. If called with no
% input arguments, use uigetdir (this will fail in a -nodisplay instance of
% Matlab). Otherwise take first input argument as path to Ipopt.

% mfilename('fullpath') returns the entire path to this script
% the first output of fileparts(ans) gives the path string, same as basename in unix
BLOM_dir = fileparts(mfilename('fullpath'));


switch (computer)
    case {'PCWIN','PCWIN64'}
        build_ipopt = false;        
    case  {'GLNX86','GLNXA64'}
        build_ipopt = true; 
        makefile = 'Makefile';
    case {'MACI','MACI64'}
        build_ipopt = true;
        makefile = 'Makefile.mac';
end



if (build_ipopt)
    if nargin==0
        ipopt_dir = uigetdir('','Pick an IPOPT folder that holds lib directory, press cancel for no IPOPT');
    end
    if (ipopt_dir ~= 0) && ~isempty(ipopt_dir)
        cur_dir = pwd;
        cd([BLOM_dir '/BLOM_Ipopt']);
        eval(['! make -f ' makefile ' all IPOPTPATH=' ipopt_dir]);
        
        if (~exist('BLOM_NLP','file'))
            warning('Compilation of BLOM_NLP failed. Check the screen for errors');
        else
            disp('---------------------------------');
            disp('BLOM_NLP was succesfully compiled');
            disp('---------------------------------');
        end
        cd(cur_dir)
    else
        warning(['Invalid selection of ipopt_dir=' ipopt_dir])
    end
end