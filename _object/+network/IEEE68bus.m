function net = IEEE68bus()
    fn = fullfile(pwd,'_GUILDA','_object','+network','IEEE68bus');
    net = network.build(fn);
end