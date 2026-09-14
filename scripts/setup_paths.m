function root = setup_paths()
%SETUP_PATHS  Add config/ and src/ to the MATLAB path and return the repo root.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root,'config'));
    addpath(fullfile(root,'scripts'));
    addpath(genpath(fullfile(root,'src')));
    cd(root);
end
