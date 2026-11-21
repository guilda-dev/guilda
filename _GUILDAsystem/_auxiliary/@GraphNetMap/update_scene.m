function update_scene(obj, k) %#ok<INUSD>
% Show sample k: a power flow has one sample, which create_scene draws, so nothing changes.
%
% The title stays the one of create_scene (the quantities of the colors and arrows).
    arguments (Input)
        obj
        k (1,1) double  % Index of the sample (always 1).
    end
end
