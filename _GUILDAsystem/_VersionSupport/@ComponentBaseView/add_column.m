function tp = add_column(comp, tp)
% Return the tab_parameter of a component with the deprecated "base" column first.
    arguments (Input)
        comp  % Component whose tab_parameter is returned.
        tp    % tab_parameter table without the "base" column.
    end
    arguments (Output)
        tp    % tab_parameter table with the "base" column first.
    end
    tp = [table(ComponentBaseView(comp), 'VariableNames', "base"), tp];
end
