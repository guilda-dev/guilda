function net = Tutorial3bus()
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    net = network.build(fn);
end