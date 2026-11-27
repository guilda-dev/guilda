function tab = element_table(obj)
% Elements of the diagram: one row per block, then one per arrow.
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag, Kind (the kind of block or of signal) and Index (row in the Block* or Arrow* vectors).
    end
    d = obj.sct_data;
    Tag   = [d.sv_blockTag; d.sv_arrowTag];
    Kind  = [d.sv_blockKind; d.sv_arrowKind];
    Index = [(1:numel(d.sv_blockTag))'; (1:numel(d.sv_arrowTag))'];
    tab = table(Tag, Kind, Index);
end
