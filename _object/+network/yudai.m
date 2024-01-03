function net = yudai()
    fn = fullfile(pwd,'_GUILDA','_object','+network','yudai');
    net = network.build(fn);
end