function net = IEEE68bus()
% Build the GUILDA v2 IEEE 68-bus network from the CSV files in this folder.
% Archived source data of network.IEEE68bus (B. Pal and B. Chaudhuri, "Robust
% Control in Power Systems", Springer, 2005, pp. 171-178). It calls the v2
% function network.build, which GUILDA no longer has.
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end