function reset_edit(obj)
    % Initialize edit state for this layer and descendants.
    %
    % Resets edit status and clears edit logs recursively.
    obj.s_edit.str_flag = "initialized";
    obj.s_edit.l_staleEquilibrium = false;
    obj.tab_editLog  = array2table(zeros(0,6),'VariableNames',{'timestamp','ID','log','tag','before','after'});
    cellfun(@(c) c.reset_edit, obj.children);
end