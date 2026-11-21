function click_element(obj, i_row)
% Report a click on an element: raise ElementClicked and call ElementClickedFcn.
%
% The subclasses call it from the ButtonDownFcn (or another hit test) of the graphics
% objects of each element, with the row of the element in tab_element.
    arguments (Input)
        obj
        i_row (1,1) double  % Row of the element in tab_element.
    end
    tab  = obj.element_table();
    data = GraphEventData(tab.Tag(i_row), tab.Kind(i_row), tab.Index(i_row));
    notify(obj, "ElementClicked", data);
    if ~isempty(obj.ElementClickedFcn)
        obj.ElementClickedFcn(obj, data);
    end
end
