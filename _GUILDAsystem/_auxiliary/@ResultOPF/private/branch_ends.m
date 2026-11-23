function im_end = branch_ends(sct_network)
% End buses of every branch of a network snapshot, as indices into its a_Bus.
%
% A branch end of the snapshot is "net.a_Bus{i}" (text) or the struct of the bus. Called by
% get_lmp.
    arguments (Input)
        sct_network (1,1) struct  % Snapshot of the network (struct(net, false)).
    end
    arguments (Output)
        im_end (:,2) double  % Index of the From and To buses of each branch in sct_network.a_Bus.
    end
    sv_tag = string(cellfun(@(b) b.s_tag, sct_network.a_Bus, "UniformOutput", false));
    n_br   = numel(sct_network.a_Branch);
    im_end = zeros(n_br, 2);
    for k = 1:n_br
        for m = 1:2
            x = sct_network.a_Branch{k}.a_Bus{m};
            if isstruct(x)
                im_end(k, m) = find(sv_tag == string(x.s_tag), 1);
            else
                im_end(k, m) = str2double(regexp(string(x), "a_Bus\{(\d+)\}$", "tokens", "once"));
            end
        end
    end
end
