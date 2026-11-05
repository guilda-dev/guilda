function n = next_edit_seq()
% Next number of the edit sequence shared by all layers (LayerPackage.store_edit).
%
% Orders edits made within one tick of the clock in tab_editLog.
    persistent n_last
    if isempty(n_last)
        n_last = 0;
    end
    n_last = n_last + 1;
    n = n_last;
end
