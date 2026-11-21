function tab = element_table(obj)
% Elements of the matrix: one row per group of rows, then per group of columns.
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag (the group), Kind ("rowgroup" or "colgroup") and Index (row in the Separator* vectors).
    end
    Tag   = obj.sct_data.sv_tag;
    Kind  = obj.sct_data.sv_kind;
    Index = (1:numel(Tag))';
    tab = table(Tag, Kind, Index);
end
