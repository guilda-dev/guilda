function tutorial(mode)
% open Tutorial

    arguments
        mode (1,1) string {mustBeMember(mode,["none","LiveScript","GUI"])} = "LiveScript"
    end
    switch mode
        case "none"
        case "LiveScript"
            disp(' === Tutorial ===')
            disp(" >> open _Tutorial/Main.mlx")
            open _Tutorial/Main.mlx
            disp(" ")
        case "GUI"
            disp(' === GUI ===')
            disp(" >> Launching GUI...")
            warning("under development")
            disp(" ")
    end
end