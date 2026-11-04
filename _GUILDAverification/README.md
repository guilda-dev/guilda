# GUILDA verification

This folder checks the bundled models of GUILDA against published results. It is not
part of the toolbox: nothing in `_GUILDAsystem`, `_GUILDAobject` or `_GUILDAtutorial`
uses it, and `GUILDA` does not put it on the MATLAB path.

## Layout

One subfolder per bundled network, named after its class (for example `IEEJ_WEST30/` for
`network.IEEJ_WEST30`). Each subfolder holds:

- `README.md`: the literature reference, what is compared, the disturbance sequence, the
  criterion, the modelling differences from the reference, how to run the comparison,
  and the latest measured agreement as a dated record (base commit and date).
- The cases as Scenario CSV files (`Scenario.export_csv` format, read with
  `Scenario.import_csv`), and the published verdicts or values in a separate CSV keyed by
  the scenario tag.
- A comparison function (`compare_<table>.m`) that builds the network, imports the
  scenarios, simulates and judges each, and prints and returns the published result next
  to the GUILDA result with the agreement count.

## How to run

Start GUILDA from the repository root (`>> GUILDA`), then either run the comparison file
with its defaults or change to its folder and call it with options. All the comparison
functions work both ways; for example:

```matlab
run(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST30", "compare_table4_13.m"))

cd(fullfile(GUILDA.pwd, "_GUILDAverification", "IEEJ_WEST30"))
tab = compare_table4_13(Governor=false);
```

The repository root, which holds `@GUILDA`, is not on the path itself, so a comparison
function adds it for the duration of the run when the current folder is elsewhere, and
removes it afterwards. Running every case of a network can take several minutes.

## Literature

Each subfolder cites its sources by link and bibliographic data only. Do not add copies
of papers, reports, figures or tables from them; transcribe only the case data and the
verdicts needed for the comparison.
