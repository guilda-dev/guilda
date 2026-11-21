function l = has_playback(obj)
% Whether the graph changes from sample to sample: it then gets the playback bar.
%
% The base takes two or more samples. A subclass whose data may have several samples that
% it does not draw one by one (e.g. GraphChart) narrows it.
    arguments (Input)
        obj
    end
    arguments (Output)
        l (1,1) logical  % The graph has samples to play.
    end
    l = numel(obj.rv_t) >= 2;
end
