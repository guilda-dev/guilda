function s_tag = add_checked(obj, d)
% Add a record read from a file (import_csv); "" takes event<n>.
    arguments (Input)
        obj
        d      % Disturbance record (struct with the fields of add_disturbance).
    end
    arguments (Output)
        s_tag  % Tag of the added disturbance.
    end
    s_tag = obj.add_record(d, "event");
end
