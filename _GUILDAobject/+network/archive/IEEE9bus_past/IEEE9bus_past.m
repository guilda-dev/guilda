function net = IEEE9bus()
% Build the GUILDA v2 IEEE 9-bus network from the CSV files in this folder.
% Archived source data of network.IEEE9bus: the model used in the simulator that
% preceded GUILDA. It calls the v2 function network.build, which GUILDA no
% longer has.
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end