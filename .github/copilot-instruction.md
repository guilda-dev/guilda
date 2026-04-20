# japanese feedback
Please provide your feedback in Japanese.

# Project Overview
This software is designed with object-oriented programming (OOP).
Its functions include power system modeling, power flow analysis, OPF,
approximate linearization, eigenvalue analysis, and time-domain simulation.

# Coding Convention (Naming Convention)

## 1. Classes and Methods
- **Class names**: UpperCamelCase
  - Example: `Component`, `SimulationResult`
- **Method names**: snake_case
  - Example: `calculate_power_flow`, `on_edit`

## 2. Property and Variable Naming Rules
Variables should generally follow **`[type][size]_[name]`** in snake_case.

### Variable Type (First Prefix)
- `c`: complex
- `r`: real
- `l`: logical
- `s`: symbolic variable (sym)
- `f`: symbolic function
- `i`: index
- `n`: count/number
- `str`: string

### Size (Second Prefix)
- *(none)*: scalar (do not add a size prefix for scalars)
- `v`: column vector
- `r`: row vector
- `m`: matrix

### Naming Examples
- **`cv_Vequilibrium`**: [c: complex] + [v: column vector] + [_Vequilibrium]
- **`im_solution`**: [i: index] + [m: matrix] + [_solution]
- **`r_gain`**: [r: real] + [none: scalar] + [_gain]
- **`str_message`**: [str: string] + [none: scalar] + [_message]

---

## 3. Exception Rules (Fixed Prefixes)
For the following data types, use the fixed prefixes regardless of size.

- **Dictionary type**: `dict_` + [name]
  - Example: `dict_params`
- **Function handle**: `fcn_` + [name]
  - Example: `fcn_objective`
- **Table type**: `tab_` + [name]
  - Example: `tab_bus_data`
- **Struct type**: `sct_` + [name]
  - Example: `sct_results`
- **GUILDA-specific class (cell array)**: `a_` + **[ClassName]**
  - Used for cell arrays that store GUILDA class objects.
  - Example: `a_Controller` (stores `Controller` class objects)
- **Parameter class**: `params_` + [data name]
  - Used when storing GUILDA's `Parameter` class.
  - Example: `params_generator`

## 4. How to Document Class Definitions

### Help Comments for Class Definition
For the class definition, include the following information in the help comments using the specified tags:
```
% <@Desc> Detailed description of the class and its purpose
% <@Role> Role of the class, e.g. 'CoreComponent', 'Utility', 'DataStructure'
% <@Constructor> Description of the constructor and its arguments
%  i.e.
%  >> obj = MyClass(arg1, arg2) 
%      - arg1; description of arg1
%      - arg2: description of arg2
```

### Help Comments for Methods
For each method, include the following information in the help comments using the specified tags:
```
% <@Desc> detailed method description
% <@Role> role of the method e.g. 'CoreFunction', 'HelperFunction', 'EventHandler'
% <@Abst> method summary
% <@Argin> [argument descriptions]
%  e.g. 
%      arg1 - [Description of arg1]
%      arg2 - [Description of arg2]
% <@Argout> [output descriptions]
%  e.g. 
%      out1 - [Description of out1]
%      out2 - [Description of out2]
% <@Option> [option descriptions]
%  e.g.
%     'OptionName' - [Description of the option]
```

### Help Comments for Properties
For each property, include the following information in the help comments using the specified tags:
```
% <@Desc> description of the property
% <@Role> role of the property e.g. OPF, simulate, linearize, etc.
% <@Type> data type     e.g. 'double', 'logical', 'table', 'struct'
% <@Size> data size     e.g. 1x1, 1xN, MxN
```


---

# Git Branching Rules (Branch Strategy)
The following branch strategy must be followed for development and release workflows.

## Branch Definitions
- **`main`**
  - Production/public branch with validated functionality.
  - Must always remain stable.

- **`beta`**
  - Development branch for new features and upcoming releases.
  - Merge into `main` after verification is complete.

- **`develop/xx-yyyy`**
  - Working branch for feature changes and bug fixes.
  - Must branch from `beta` and merge back into `beta` after completion.

## Workflow and Naming Rules
1. **Create (Checkout)**: Always branch from `beta`.
2. **Naming**: `develop/{IssueNumber}-{implementation}`
   - Example: `develop/12-add_opf_solver`
3. **Merge**:
   - Create a Pull Request after implementation is complete.
   - Merge into `beta` after review and verification.

---

# Design and Implementation Guidelines

## Class Constructors
- Even when called without arguments (`nargin == 0`), constructors must initialize instances with default values.

```matlab
methods
    function obj = MyClass(arg1)
        arguments
            arg1 = 0
        end
        obj.r_value = arg1;
    end
end