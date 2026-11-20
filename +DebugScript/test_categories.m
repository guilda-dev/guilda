function tab = test_categories()
% テストファイルの分類の一覧 (テストファイル名 → 分類)
%
%   tab = DebugScript.test_categories()
%
% DebugScript.run_all("Category", ...) はこの一覧でテストファイルを選ぶ。
% 1 つのファイルが複数の分類に属するときは、分類ごとに 1 行ずつ書く。
% すべての test_F*.m, test_I*.m はどこかの分類に属すること (一覧にないファイルは run_all が警告する)。
% ファイルを追加・改名・削除したら該当行も直すこと。
%
% 分類
%   model     : モデルの構築・編集・タグ・パラメータ・制御器・モデルの契約
%   powerflow : 潮流計算、平衡点の計算 (initialize)、スラック母線、島
%   simulate  : 時間応答シミュレーション、イベント、Scenario、ResultODE
%   linearize : 近似線形化 (get_sys, SolverLIN, ResultLIN)
%   opf       : 最適潮流計算
%   cpf       : 連続潮流計算
%   io        : CSV・MAT・MATPOWER の入出力、export、組み込み系統のデータ
%   graph     : 図 (Graph*、plot_*)、配置データ (get_layout, set_layout, layout_*)
%   gui       : GUI (DrawerModelGUI、DrawerResultGUI、DrawerGUILDA、DrawerTagPicker、gui_content、HistoryGUILDA)
%   env       : 起動・GUILDA.setting・コード補完・キーマップ・解析 API の基盤
%
% 変更したソース → 実行する分類の目安 (迷ったら Level="small" で全分類)
%   _GUILDAobject/+component, +branch, +controller             → model, powerflow, simulate, linearize
%   _GUILDAobject/+network (組み込み系統)                       → io, model
%   _GUILDAsystem/@PowerNetwork, @Bus, @Branch, @Component,
%     @LocalController, @GlobalController (構築・編集)          → model, io
%   _GUILDAsystem/@PowerNetwork/calculate_powerflow, initialize,
%     _auxiliary/@SolverPF, @ResultPF, @Method*                 → powerflow, simulate, opf, cpf
%   _GUILDAsystem/@PowerNetwork/simulate, build_simulation_data,
%     _auxiliary/@SolverODE, @ResultODE, @Scenario               → simulate
%   _GUILDAsystem/_auxiliary/@ProgressGUILDA (進捗表示)           → simulate, powerflow, opf, cpf
%   _GUILDAsystem/_auxiliary/@SolverLIN, @ResultLIN, get_sys    → linearize, cpf
%   _GUILDAsystem/@PowerNetwork/calculate_optimal_powerflow,
%     build_opf_problem, _auxiliary/@SolverOPF, @ResultOPF       → opf
%   _GUILDAsystem/@PowerNetwork/calculate_continuation_powerflow,
%     _auxiliary/@SolverCPF, @ResultCPF                          → cpf
%   _GUILDAsystem/@PowerNetwork/export, import, import_matpower → io
%   _GUILDAsystem/_auxiliary/@Graph*, plot_*,
%     get_layout, set_layout, layout_*                           → graph
%   _GUILDAsystem/_auxiliary/@DrawerModelGUI, @DrawerResultGUI,
%     @DrawerGUILDA, @DrawerOptionDialog, @DrawerTagPicker, @HistoryGUILDA,
%     @LayerPackage, gui_content, launch_gui                     → gui
%   @GUILDA, _GUILDAsystem/resources, _auxiliary/@ResultBase,
%     @MethodBase, @PowerSystemModel, @Parameter                 → env (@PowerSystemModel, @Parameter は model も)

    list = [strings(0,2)
    "test_F1_model_building",               "model"
    "test_F2_powerflow",                    "powerflow"
    "test_F3_edit_handling",                "model"
    "test_F3_initialize",                   "powerflow"
    "test_F4_opf",                          "opf"
    "test_F5_cpf",                          "cpf"
    "test_F6_simulation",                   "simulate"
    "test_F7_linearization",                "linearize"
    "test_F8_utilities",                    "io"
    "test_F9_environment",                  "env"
    "test_F10_api_foundation",              "env"
    "test_F15_build_checks",                "model"
    "test_F16_csv_io",                      "io"
    "test_F17_parameter_type",              "model"
    "test_F18_global_controller",           "model"
    "test_F19_model_constructor",           "model"
    "test_F21_controller_editing",          "model"
    "test_F22_model_contract",              "model"
    "test_F24_tags",                        "model"
    "test_F26_call_graph",                  "env"
    "test_F27_park_equal_reactance",        "model"
    "test_F28_avr_dc1_field_limit",         "simulate"
    "test_F29_open_branch",                 "simulate"
    "test_F30_governor",                    "model"
    "test_F30_governor",                    "simulate"
    "test_F31_scenario",                    "simulate"
    "test_F32_model_gui",                   "gui"
    "test_F33_model_gui_network",           "gui"
    "test_F34_signatures",                  "env"
    "test_F35_controller_signal_routing",   "model"
    "test_F36_tutorial_all_models",         "model"
    "test_F37_disp_connection",             "model"
    "test_F38_result_judge",                "simulate"
    "test_F39_simulation_data",             "simulate"
    "test_F40_stop_and_sample_time",        "simulate"
    "test_F41_branch_status",               "powerflow"
    "test_F41_spring_node",                 "graph"
    "test_F42_branch_events",               "simulate"
    "test_F42_graph_spring",                "graph"
    "test_F43_spring_model",                "graph"
    "test_F44_net_diagram",                 "graph"
    "test_F45_ode_component_current",       "simulate"
    "test_F46_graph_base",                  "graph"
    "test_F47_graph_interaction",           "graph"
    "test_F48_graph_chart",                 "graph"
    "test_F49_graph_netmap",                "graph"
    "test_F50_gui_history_option",          "gui"
    "test_F51_model_gui_actions",           "gui"
    "test_F52_result_gui",                  "gui"
    "test_F53_layout_placement",            "graph"
    "test_F54_graph_layout",                "graph"
    "test_F55_guilda_app",                  "gui"
    "test_F56_guilda_app_analysis",         "gui"
    "test_F57_guilda_app_sim",              "gui"
    "test_F58_scenario_events",             "simulate"
    "test_F59_diagram_2d",                  "graph"
    "test_F60_flow_animation",              "graph"
    "test_F61_graph_controls",              "graph"
    "test_F63_avr_limiter",                 "model"
    "test_F63_avr_limiter",                 "simulate"
    "test_F62_tag_picker",                  "gui"
    "test_F69_gui_layout",                  "gui"
    "test_F76_guilda_app_speed",            "gui"
    "test_F66_gui_forms",                   "gui"
    "test_F87_gui_dependent_forms",         "gui"
    "test_F75_model_gui_speed",             "gui"
    "test_F77_gui_speed",                   "gui"
    "test_F64_controller_slots",            "model"
    "test_F65_static_controllers",          "model"
    "test_F65_static_controllers",          "simulate"
    "test_F65_static_controllers",          "linearize"
    "test_F67_developer_path",              "env"
    "test_F68_pss_retrofit",                "model"
    "test_F68_pss_retrofit",                "linearize"
    "test_F68_pss_retrofit",                "simulate"
    "test_F70_export_controllers",          "io"
    "test_F71_dictionary_doc_key",          "env"
    "test_F72_network_element_methods",     "model"
    "test_F73_result_summary",              "powerflow"
    "test_F73_result_summary",              "opf"
    "test_F74_trajectory_mode",             "simulate"
    "test_F74_trajectory_mode",             "linearize"
    "test_F74_trajectory_mode",             "opf"
    "test_F78_pss1_zero_time_constant",     "model"
    "test_F78_pss1_zero_time_constant",     "simulate"
    "test_F78_pss1_zero_time_constant",     "linearize"
    "test_F79_st1_field_limit",             "model"
    "test_F79_st1_field_limit",             "simulate"
    "test_F79_st1_field_limit",             "linearize"
    "test_F80_parameter_table_cache",       "model"
    "test_F80_parameter_table_cache",       "env"
    "test_F81_opened_branch_flow",          "simulate"
    "test_F81_opened_branch_flow",          "graph"
    "test_F82_graph_matrix",                "graph"
    "test_F82_graph_matrix",                "linearize"
    "test_F83_energy_hessian",              "linearize"
    "test_F83_energy_hessian",              "model"
    "test_F84_linearization_analysis",      "linearize"
    "test_F85_linearization_hessian_form",  "linearize"
    "test_F86_scenario_scalar_time",        "simulate"
    "test_F86_scenario_scalar_time",        "env"
    "test_F94_cpf_operating_points",        "cpf"
    "test_F94_cpf_operating_points",        "linearize"
    "test_F97_cpf_analysis_plots",          "cpf"
    "test_F97_cpf_analysis_plots",          "graph"
    "test_F98_inverter_components",         "model"
    "test_F98_inverter_components",         "powerflow"
    "test_F98_inverter_components",         "simulate"
    "test_F98_inverter_components",         "linearize"
    "test_F90_analyze_highlight",           "gui"
    "test_F91_result_gui_autoplay",         "gui"
    "test_F91_result_gui_autoplay",         "graph"
    "test_F92_pf_diverged_message",         "powerflow"
    "test_F93_disp_tree_doc_link",          "model"
    "test_F95_load_current",                "model"
    "test_F95_load_current",                "powerflow"
    "test_F95_load_current",                "simulate"
    "test_F95_load_current",                "linearize"
    "test_F95_load_current",                "cpf"
    "test_F95_load_current",                "io"
    "test_F96_load_zip",                    "model"
    "test_F96_load_zip",                    "powerflow"
    "test_F96_load_zip",                    "simulate"
    "test_F96_load_zip",                    "linearize"
    "test_F96_load_zip",                    "cpf"
    "test_F96_load_zip",                    "io"
    "test_F99_ieee39_dynamics",             "simulate"
    "test_F99_ieee39_dynamics",             "linearize"
    "test_F100_graph_playback",             "graph"
    "test_I50_trip_with_local_controller",  "simulate"
    "test_I51_tripped_unit_jacobian",       "simulate"
    "test_I52_validate_events",             "simulate"
    "test_I53_scalar_timespan",             "simulate"
    "test_I54_simulate_time",               "simulate"
    "test_I55_time_limit",                  "simulate"
    "test_I56_initialize_equilibrium",      "powerflow"
    "test_I57_stale_gc_references",         "model"
    "test_I58_input_under_local_controller", "simulate"
    "test_I60_event_network",               "simulate"
    "test_I61_restore_working_data",        "simulate"
    "test_I62_keep_completed_phases",       "simulate"
    "test_I63_export",                      "io"
    "test_I64_simulate_sparse",             "simulate"
    "test_I66_shared_local_controller",     "model"
    "test_I67_replace_controllers",         "model"
    "test_I67_replace_controllers",         "simulate"
    "test_I68_network_xequilibrium",        "powerflow"
    "test_I69_avr_range_error",             "model"
    "test_I70_controller_tab_parameter",    "model"
    "test_I71_layer_get_sys",               "linearize"
    "test_I71_layer_get_sys",               "cpf"
    "test_I89_slack_cannot_balance",        "powerflow"
    "test_I90_slack_bus_required",          "powerflow"
    "test_I90_slack_bus_required",          "opf"
    "test_I91_slack_power_assignment",      "powerflow"
    "test_I92_network_islands",             "powerflow"
    "test_I93_model_equilibrium",           "powerflow"
    "test_I93_model_equilibrium",           "model"
    "test_I102_remove_unknown_tags",        "model"
    "test_I105_model_contracts",            "model"
    "test_I111_unfeasible_dae_message",     "simulate"
    ];
    tab = table(list(:,1), list(:,2), 'VariableNames', ["File","Category"]);
end
