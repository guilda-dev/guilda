function tab = test_levels()
% 実行に時間のかかるテストの一覧 (テスト名 → 段階 "medium" / "large")
%
%   tab = DebugScript.test_levels()
%
% DebugScript.run_all("Level", ...) はこの一覧でテストを選ぶ。
%   small  : 一覧にないテスト (新しく追加したテストは必ず small として実行される)
%   medium : 1 件 1 秒程度を超えるテスト
%   large  : 1 件 3 秒程度を超えるテスト (組み込みネットワークをすべて扱うもの、v3 との比較、CPF など)
% 時間は run_all の Time 列 (R2026a) を目安にする。重いテストを追加したら登録し、
% 名前を変えたり削除したりしたら該当行も直すこと (存在しない名前は run_all が警告する)。
%
% テスト名は "<ファイル名>/<セクション名から作られる名前>"。
% 名前は DebugScript.run_all の一覧、または {testsuite("DebugScript").Name} で確認できる。

    list = [strings(0,2)
    % ---- F10_api_foundation ----------------------------------------------------------------------
    "test_F10_api_foundation/ResolveOptionsRejectsAnUnknownName", "medium"
    "test_F10_api_foundation/AnalysisResultPlotAndExportContract", "medium"
    % ---- F15_build_checks ------------------------------------------------------------------------
    "test_F15_build_checks/AllBuilt_inNetworksStillBuild", "large"
    % ---- F16_csv_io ------------------------------------------------------------------------------
    "test_F16_csv_io/BuildingTheBuilt_inNetworksDoesNotWarn", "large"
    "test_F16_csv_io/export_csvNamesTheLocalControllersItDoesNotWrite", "medium"
    "test_F16_csv_io/BusTagsSurviveARoundTrip", "medium"
    % ---- F19_model_constructor -------------------------------------------------------------------
    "test_F19_model_constructor/Built_inNetworksAndTheBundledCSVDataDoNotWarnAboutQ", "large"
    % ---- F1_model_building -----------------------------------------------------------------------
    "test_F1_model_building/AddLocalControllerAVRAndPSS", "medium"
    "test_F1_model_building/ReplaceAVRKeepsItsPSS", "medium"
    "test_F1_model_building/AddLocalControllerAVR_DC1", "medium"
    % ---- F21_controller_editing ------------------------------------------------------------------
    "test_F21_controller_editing/ValidControllersStillAttach", "medium"
    "test_F21_controller_editing/remove_local_controller_ThePSSAlone_ThenTheAVR_EachLoggedAndLeavingAWorkingModel", "medium"
    % ---- F22_model_contract ----------------------------------------------------------------------
    "test_F22_model_contract/EveryLocalControllerPassesOnEveryGenerator", "large"
    "test_F22_model_contract/EveryComponentPassesAtTheEquilibrium", "medium"
    "test_F22_model_contract/EveryComponentStaysAtTheEquilibriumInASimulation", "medium"
    "test_F22_model_contract/EveryGeneratorPassesWithEachRowOfParameter_csv", "medium"
    "test_F22_model_contract/EveryLocalControllerStaysAtTheEquilibriumInASimulation", "medium"
    "test_F22_model_contract/EveryGlobalControllerWorksOnTheGeneratorsThatHaveItsInputs", "medium"
    % ---- F24_tags --------------------------------------------------------------------------------
    "test_F24_tags/ARenameMakesNothingStaleAndAnalysesRunWithoutInitialize", "medium"
    % ---- F26_call_graph --------------------------------------------------------------------------
    "test_F26_call_graph/TheCallGraphDoesNotDependOnAPrivateFolderAboveGUILDA", "large"
    "test_F26_call_graph/APackageFolderAboveAUserClassDoesNotHideAReceiverOfThatName", "large"
    % ---- F27_park_equal_reactance ----------------------------------------------------------------
    "test_F27_park_equal_reactance/Xq_pEqualToXqGivesAFiniteEquilibriumWithEd_0", "medium"
    % ---- F28_avr_dc1_field_limit -----------------------------------------------------------------
    "test_F28_avr_dc1_field_limit/DefaultLimitsGiveTheSameTrajectoryAsNoLimits", "medium"
    "test_F28_avr_dc1_field_limit/UpperLimitClipsTheFieldVoltageInAFault", "medium"
    "test_F28_avr_dc1_field_limit/LowerLimit0ClipsTheFieldVoltage", "medium"
    % ---- F29_open_branch -------------------------------------------------------------------------
    "test_F29_open_branch/OpenAndRecloseReturnsNearTheEquilibrium", "large"
    "test_F29_open_branch/OpenBranchAfterTheFallbackToDenseMatrices", "large"
    "test_F29_open_branch/YOfTheOpenPhaseIsTheYWithoutTheBranch", "medium"
    "test_F29_open_branch/BusCurrentsFollowTheYOfEachPhase", "medium"
    "test_F29_open_branch/PermanentOpeningAfterAFault", "medium"
    "test_F29_open_branch/OverlappingOpeningsUseTheUnionOfTheOpenBranches", "medium"
    % ---- F2_powerflow ----------------------------------------------------------------------------
    "test_F2_powerflow/DynamicMethodReachesTheAlgebraicSolution", "large"
    "test_F2_powerflow/PlotAndExportOfTheResult", "large"
    "test_F2_powerflow/AlgebraicPowerFlowConvergesOn9_busSystem", "medium"
    "test_F2_powerflow/SwitchingTheSlackBusLeavesExactlyOne", "medium"
    "test_F2_powerflow/PowerFlowOnIEEE14HonorsGeneratorSettings", "medium"
    "test_F2_powerflow/PowerFlowOnIEEE14MatchesMATPOWERCase14", "medium"
    "test_F2_powerflow/DynamicMethodConverges", "medium"
    "test_F2_powerflow/Name_ValueOptionsOverrideSolverDefaultsForOneCallOnly", "medium"
    "test_F2_powerflow/DynamicMethodExportsConvergenceHistoryAsJSON", "medium"
    "test_F2_powerflow/COMPATV3PositionalModeAndExportOptions", "medium"
    % ---- F30_governor ----------------------------------------------------------------------------
    "test_F30_governor/TheSlotsKeepAFixedOrderWhateverTheOrderOfAttachment", "large"
    "test_F30_governor/EachLPTSettlesWithItsDroopAfterALoadStep", "large"
    "test_F30_governor/get_sysIncludesTheGovernorStates_AndTheModelStaysFinite", "large"
    "test_F30_governor/ASmallStepMatchesTheLinearModelWithTheGovernor", "large"
    "test_F30_governor/ATripOfTheGeneratorRestartsItsGovernorFromTheEquilibrium", "large"
    "test_F30_governor/AnAGCOnPmechAddsToTheGovernorOutput", "large"
    "test_F30_governor/WithoutEventsTheNetworkWithAVR_PSSAndGovernorsStaysAtTheEquilibrium", "medium"
    "test_F30_governor/TheLoadLimiter77MCapsTheOutput", "medium"
    "test_F30_governor/Load_limitOperation_PLM_0_KeepsPmechForAFrequencyDrop", "medium"
    "test_F30_governor/validatePassesAndTheAnalyticJacobiansAgreeAtTheEquilibrium", "medium"
    "test_F30_governor/remove_local_controllerRemovesOneSlotAndLeavesTheOther", "medium"
    "test_F30_governor/AGovernorAndALocalControllerCannotDriveTheSameInput", "medium"
    "test_F30_governor/replace_componentWithControllers__keep_MovesBothSlots", "medium"
    "test_F30_governor/export_csvNamesTheGovernorItDoesNotWrite", "medium"
    % ---- F31_scenario ----------------------------------------------------------------------------
    "test_F31_scenario/AFaultThenAPermanentOpeningEqualsTwoOld_styleEvents", "large"
    "test_F31_scenario/DefaultJudge_StableAndOut_of_stepOnIEEE9bus", "large"
    "test_F31_scenario/StoredTimeAndOptions_TheCallWins", "medium"
    "test_F31_scenario/Ownership_Add_Remove_Move_Copy", "medium"
    "test_F31_scenario/UnknownTagsAtAddAndAtRunTime", "medium"
    "test_F31_scenario/CSVRoundTripWithSeveralScenariosInOneFile", "medium"
    "test_F31_scenario/IncompleteVerdictAndACustomJudge", "medium"
    "test_F31_scenario/Compatibility_ODEeventWarnsOnceAndGivesTheSameResults", "medium"
    % ---- F3_edit_handling ------------------------------------------------------------------------
    "test_F3_edit_handling/LocalControllerAddAndReplaceMakeTheEquilibriumStale", "large"
    "test_F3_edit_handling/NetworkHzEditRedesignsTheLQRGain", "large"
    "test_F3_edit_handling/NetworkHzEditRedesignsTheLQRGainThroughTheLayers", "large"
    "test_F3_edit_handling/SolversCalledDirectlyCheckTheEquilibrium", "medium"
    "test_F3_edit_handling/DynamicsEditMakesHandlesAndEquilibriumStale", "medium"
    "test_F3_edit_handling/BaseHzEditMarksTheHandlesAndInitializeRebuildsThem", "medium"
    "test_F3_edit_handling/TopologyChangesMakeThePowerFlowStale", "medium"
    "test_F3_edit_handling/LQRAddAndWeightEditMakeTheEquilibriumStale", "medium"
    "test_F3_edit_handling/OperationOPFAndGraphEditsKeepTheEquilibrium", "medium"
    "test_F3_edit_handling/InitializeRebuildsOnlyTheStaleHandles", "medium"
    "test_F3_edit_handling/LocalControllerDynamicsEditIsRebuiltAtInitialize", "medium"
    "test_F3_edit_handling/GlobalControllerDynamicsEditIsRebuiltAndMarked", "medium"
    "test_F3_edit_handling/NetworkHzEditMarksEveryHandle", "medium"
    "test_F3_edit_handling/HandlesAreBuiltAtInitialize", "medium"
    % ---- F3_initialize ---------------------------------------------------------------------------
    "test_F3_initialize/InitializeWithOPF", "large"
    "test_F3_initialize/FailedOPFErrorsAndLeavesTheNetworkUnchanged", "large"
    "test_F3_initialize/No_eventSimulationStaysAtEquilibrium", "medium"
    "test_F3_initialize/No_eventSimulationWithLocalControllersStaysAtEquilibrium", "medium"
    "test_F3_initialize/No_eventSimulationWithGlobalControllerStaysAtEquilibrium", "medium"
    "test_F3_initialize/InitializeFromXequilibrium", "medium"
    "test_F3_initialize/DeprecatedMethodsOptionAndValuesWarn", "medium"
    "test_F3_initialize/EquilibriumVoltageAndCurrentHaveASingleOwner", "medium"
    % ---- F4_opf ----------------------------------------------------------------------------------
    "test_F4_opf/IEEE14ACOPF", "large"
    "test_F4_opf/ACOPFWithActiveBranchCurrentAndPowerLimits", "large"
    "test_F4_opf/DualsMatchFinite_differenceSensitivitiesOfTheOptimalCost", "large"
    "test_F4_opf/ACAndDCOPFReproduceTheMATPOWERCase14Optimum", "large"
    "test_F4_opf/ResultClassOfAllThreeMethods", "large"
    "test_F4_opf/Name_ValueOptionsOverrideSolverDefaultsForOneCallOnly", "large"
    "test_F4_opf/PlotAndExportOfTheResult", "large"
    "test_F4_opf/DeprecatedMethodsOption", "large"
    "test_F4_opf/DCOPFUsesTheMATPOWERSusceptance1_X", "large"
    "test_F4_opf/CostOptionAddsAUserCostToTheObjective", "large"
    "test_F4_opf/ConstraintOptionBindsAndItsDualHasTheUser_sName", "large"
    "test_F4_opf/ProblemAndInitialPointSolveAUser_modifiedProblem", "large"
    "test_F4_opf/Network_levelReserveConstraintAndCost", "large"
    "test_F4_opf/DCOptimalPowerFlow", "medium"
    "test_F4_opf/ACOptimalPowerFlow", "medium"
    "test_F4_opf/ACOPFRespectsGeneratorLimits", "medium"
    "test_F4_opf/IEEE14ELDAndDCOPF", "medium"
    "test_F4_opf/ACOPFOnA2_busSystemMatchesTheClosedForm", "medium"
    "test_F4_opf/ConversionToAMATPOWERCase", "medium"
    "test_F4_opf/LegacySix_outputForm", "medium"
    "test_F4_opf/Price_responsiveLoad_ALoadWithPBoundsAndItsOwnCost", "medium"
    "test_F4_opf/InfiniteOperationLimitsRemoveTheDefaultLimits", "medium"
    "test_F4_opf/DefaultCost_falseLeavesOutTheCostsOfTab_parameter_OPF", "medium"
    "test_F4_opf/ReferenceBusSelectsTheBusWithAFixedAngle", "medium"
    "test_F4_opf/StoredCostAndConstraintInNet_solver_OPF", "medium"
    "test_F4_opf/OPFOptionsDoNotMakeTheEquilibriumStale", "medium"
    "test_F4_opf/InvalidCostAndConstraintStopWithAnError", "medium"
    % ---- F5_cpf ----------------------------------------------------------------------------------
    "test_F5_cpf/CPFTracesTheNoseCurve", "large"
    "test_F5_cpf/CPFStartsFromTheEquilibriumAndVoltageDropsTowardTheNose", "large"
    "test_F5_cpf/PlotAndExportOfTheResult", "large"
    "test_F5_cpf/COMPATV3Continuation_Power_FlowAndSolverCPFConstructor", "large"
    "test_F5_cpf/Name_ValueOptionsOverrideSolverDefaultsForOneCallOnly", "medium"
    "test_F5_cpf/FailedPreconditionsAndUnknownOptionsStopWithAnError", "medium"
    % ---- F6_simulation ---------------------------------------------------------------------------
    "test_F6_simulation/PlotAndExportOfTheSimulationResult", "large"
    "test_F6_simulation/LoadStepWithGlobalController", "large"
    "test_F6_simulation/PhaseThatStartsAtRestInALargeNetwork", "large"
    "test_F6_simulation/FaultInIEEJWEST10KeepsTheRotorAngles", "large"
    "test_F6_simulation/IEEJWEST10StartsFromItsEquilibriumForAnyTimeSpan", "large"
    "test_F6_simulation/SimulationResultStructure", "medium"
    "test_F6_simulation/TrajectoryFollowsTheVariableMap", "medium"
    "test_F6_simulation/PointAtAPhaseBoundary", "medium"
    "test_F6_simulation/Name_ValueOverridesLeaveSolver_ODEUnchanged", "medium"
    "test_F6_simulation/FaultWithLocalControllers", "medium"
    "test_F6_simulation/AVRAndPSSResponseIsUnchangedByNameWiring", "medium"
    "test_F6_simulation/FaultWithLQR", "medium"
    "test_F6_simulation/TrippedGlobalControllerGivesNoOutput", "medium"
    "test_F6_simulation/TwoGlobalControllersActTogether", "medium"
    "test_F6_simulation/NetworkHzSetsTheRotorAngleDynamics", "medium"
    "test_F6_simulation/SolverStopReportsThePhaseAndTheSolverMessage", "medium"
    % ---- F7_linearization ------------------------------------------------------------------------
    "test_F7_linearization/ModelShapeAndNamesPerAlgorithm", "large"
    "test_F7_linearization/NonUnitBusWithACurrentIsAbsorbedIntoY", "large"
    "test_F7_linearization/DeprecatedNonUnitOptionWarnsAndIgnoresBusesWithoutStates", "large"
    "test_F7_linearization/DeprecatedSolver_LIN_NonUnitWarnsAndActsAsTheOption", "large"
    "test_F7_linearization/AnalyticJacobiansMatchNumericalDifferentiation", "large"
    "test_F7_linearization/EachComponentTypeGivesSameEigenvaluesInThreeAlgorithms", "large"
    "test_F7_linearization/LocalAndGlobalControllersInThreeAlgorithms", "large"
    "test_F7_linearization/TwoGlobalControllersInThreeAlgorithms", "large"
    "test_F7_linearization/LayerGet_sys_IgnoredArguments_NoInternalArguments_NamesAndSingleComputation__83_", "large"
    "test_F7_linearization/LinearizeMatchesV3Get_sysMatricesForEveryAlgorithm", "large"
    "test_F7_linearization/PointFromASimulationResultAndATime", "large"
    "test_F7_linearization/NoMessageAboutNonUnitWithoutTheOption", "large"
    "test_F7_linearization/OutputAndInputSelectTheChannels", "large"
    "test_F7_linearization/GetSysKron", "medium"
    "test_F7_linearization/GetSysFeedback", "medium"
    "test_F7_linearization/BusWithoutAnI_to_VFormIsEliminatedAutomatically", "medium"
    "test_F7_linearization/DeprecatedNonUnitNamingABusWithStatesIsRejected", "medium"
    "test_F7_linearization/FeedbackKeepsTheInputsOfZero_powerLoads", "medium"
    "test_F7_linearization/BusWithoutComponents", "medium"
    "test_F7_linearization/I2VPortStopsWhenDIsSingular", "medium"
    "test_F7_linearization/WithLocalControllers", "medium"
    "test_F7_linearization/WithGlobalController", "medium"
    "test_F7_linearization/Inputs_StatesAndOutputsOfGet_sysOnEachLayer", "medium"
    "test_F7_linearization/IndexAModelOfEachLayerByFullChannelName", "medium"
    "test_F7_linearization/VariableMapIsConsistentWithTheLinearModel", "medium"
    "test_F7_linearization/PointAtTheEquilibriumEqualsTheDefault", "medium"
    "test_F7_linearization/LQRImprovesTheDampingOfIEEE14", "medium"
    "test_F7_linearization/PointFromASimulationWithControllersAtAnEquilibriumTime", "medium"
    "test_F7_linearization/PointFromASimulationWithControllersAtAPerturbedTime", "medium"
    "test_F7_linearization/PointThatIsNotFiniteNamesTheVariables", "medium"
    "test_F7_linearization/PointAroundATrip", "medium"
    "test_F7_linearization/PointInsideAFaultIsReportedAndKeepsTheModelNetwork", "medium"
    "test_F7_linearization/ResidualAtThePoint", "medium"
    "test_F7_linearization/PlotDrawsTheAlgorithmOfTheOptions", "medium"
    "test_F7_linearization/ConfigurationsThatCannotBeLinearizedStopWithAGUILDAError", "medium"
    "test_F7_linearization/CoordinateIsAnOptionOfLinearizeAndGet_sys", "medium"
    "test_F7_linearization/DefaultChannelsOfGet_sysDoNotChange", "medium"
    "test_F7_linearization/FeedbackCannotOutputAStateItRemoves", "medium"
    "test_F7_linearization/CanonicalLinearizationDemoRuns", "medium"
    % ---- F8_utilities ----------------------------------------------------------------------------
    "test_F8_utilities/InfoPrintsSummary", "large"
    "test_F8_utilities/structKeepsEachLayerAndGivesARepeatedOneItsFirstPath", "large"
    "test_F8_utilities/DrawDiagram", "large"
    "test_F8_utilities/CSVExportImportRoundTrip", "large"
    "test_F8_utilities/CSVRoundTripKeepsTransformerTapAndPhase", "large"
    "test_F8_utilities/MATFileRoundTripKeepsAUsableNetwork", "large"
    "test_F8_utilities/MATFileRoundTripKeepsControllersAndLowerLayers", "large"
    "test_F8_utilities/MATFileRoundTripKeepsTheLinearModels", "large"
    "test_F8_utilities/MATPOWERImportReproducesCase14", "large"
    "test_F8_utilities/TemplateIEEE14bus_NoTapDiffersFromIEEE14busOnlyInTheTaps", "large"
    "test_F8_utilities/TemplateIEEE14bus_lossless", "large"
    "test_F8_utilities/TemplateIEEE9busKeepsTheV2Data", "large"
    "test_F8_utilities/TemplateIEEE68busKeepsTheV2Data", "large"
    "test_F8_utilities/AdmittanceMatrixIsSymmetricAndMatchesBranchData", "medium"
    "test_F8_utilities/CSVRoundTripKeepsHzBaseMVAAndTheSlackBus", "medium"
    "test_F8_utilities/DeprecatedCsvNetHandlerWrappers", "medium"
    "test_F8_utilities/TemplateIEEE14bus", "medium"
    "test_F8_utilities/TemplateIshizaki6Bus", "medium"
    "test_F8_utilities/TemplateTEST31bus", "medium"
    "test_F8_utilities/TemplateTxt3Bus", "medium"
    % ---- F9_environment --------------------------------------------------------------------------
    "test_F9_environment/GUILDAStartsInBatchMode", "medium"
    "test_F9_environment/ComponentKeyMapIsGeneratedAtStartup", "medium"
    % ---- I105_model_contracts --------------------------------------------------------------------
    "test_I105_model_contracts/TripOfAGeneratorThatRequiresPAndQCompletes", "medium"
    % ---- I111_unfeasible_dae_message -------------------------------------------------------------
    "test_I111_unfeasible_dae_message/FaultOnAGeneratorBusExplainsTheFailure", "medium"
    % ---- I50_trip_with_local_controller ----------------------------------------------------------
    "test_I50_trip_with_local_controller/DefaultIEEE9TripCompletes", "medium"
    "test_I50_trip_with_local_controller/DefaultIEEE9TripWithALongerHorizonCompletes", "medium"
    "test_I50_trip_with_local_controller/TripWithAVRRestartsFromTheStoredEquilibrium", "medium"
    % ---- I51_tripped_unit_jacobian ---------------------------------------------------------------
    "test_I51_tripped_unit_jacobian/JacobianMatchesTheRight_handSideWhileAGeneratorIsTripped", "medium"
    "test_I51_tripped_unit_jacobian/JacobianMatchesTheRight_handSideWithATrippedUnitUnderAGlobalController", "medium"
    "test_I51_tripped_unit_jacobian/MaxStepAppliesInTheTripPhase", "medium"
    % ---- I53_scalar_timespan ---------------------------------------------------------------------
    "test_I53_scalar_timespan/OffsetAndAnEventWithoutEffectKeepASingleTime", "medium"
    % ---- I54_simulate_time -----------------------------------------------------------------------
    "test_I54_simulate_time/AScenarioAsTheFirstArgumentRunsWithoutTime", "medium"
    "test_I54_simulate_time/EmptyTimeTakesTheTimeSpanOfTheEvents", "medium"
    % ---- I55_time_limit --------------------------------------------------------------------------
    "test_I55_time_limit/PartialResultWarnsWithAnyNumberOfOutputs", "medium"
    "test_I55_time_limit/PhasesThatEachFitInTheLimitStopWhenTheirSumDoesNot", "medium"
    "test_I55_time_limit/LimitIncludesTheTimeOfTheInitialCondition", "medium"
    % ---- I56_initialize_equilibrium --------------------------------------------------------------
    "test_I56_initialize_equilibrium/OPFInitializeGivesARealEquilibrium", "large"
    "test_I56_initialize_equilibrium/OPFInitializeWithSeveralComponentsOnOneBus", "medium"
    "test_I56_initialize_equilibrium/EditsThatTheEquilibriumMethodWouldLoseStopWithAnError", "medium"
    "test_I56_initialize_equilibrium/FailedAnalysisStillKeepsThePreviousEquilibrium", "medium"
    % ---- I58_input_under_local_controller --------------------------------------------------------
    "test_I58_input_under_local_controller/AStepOnAnInputDrivenByAnAVRMatchesGet_sys", "medium"
    "test_I58_input_under_local_controller/AStepOnAnInputNoControllerDrivesStillMatchesGet_sys", "medium"
    "test_I58_input_under_local_controller/AGlobalControllerOnADrivenInputAddsToTheLocalController", "medium"
    % ---- I61_restore_working_data ----------------------------------------------------------------
    "test_I61_restore_working_data/UnitStaysConnectedAfterATripLastingToTheEndTime", "medium"
    "test_I61_restore_working_data/WorkingDataIsRestoredAfterAnErrorDuringAFaultAndTrips", "medium"
    "test_I61_restore_working_data/RerunAfterATripMatchesARunOnAFreshNetwork", "medium"
    % ---- I62_keep_completed_phases ---------------------------------------------------------------
    "test_I62_keep_completed_phases/WorkingDataIsRestoredAfterAFailedPhase", "medium"
    % ---- I63_export ------------------------------------------------------------------------------
    "test_I63_export/EveryFormatOfExportIsAcceptedAndWritten", "large"
    "test_I63_export/NetworkWithoutControllersKeepsItsColumns", "medium"
    % ---- I64_simulate_sparse ---------------------------------------------------------------------
    "test_I64_simulate_sparse/FalseIndexErrorFallsBackToDenseMatrices", "large"
    "test_I64_simulate_sparse/PhasesAfterTheFallbackStayDenseAndTheFaultIsSolved", "large"
    "test_I64_simulate_sparse/TimeLimitIncludesTheTimeOfTheFallback", "large"
    "test_I64_simulate_sparse/MassMatrixAndJacobianAreSparseByDefault", "medium"
    "test_I64_simulate_sparse/SparseRunAgreesWithTheTightSolutionWithinTheTolerance", "medium"
    "test_I64_simulate_sparse/InputEventOnAPhaseAfterPhasesWithoutOne", "medium"
    % ---- I67_replace_controllers -----------------------------------------------------------------
    "test_I67_replace_controllers/AKeptAVRAndPSSAreSimulatedAfterNet_initialize", "medium"
    "test_I67_replace_controllers/AKeptLQRFollowsTheStatesOfTheNewComponent", "medium"
    "test_I67_replace_controllers/test_keep_IsRejectedWhenTheNewComponentLacksAnObservedSignal", "medium"
    % ---- I68_network_xequilibrium ----------------------------------------------------------------
    "test_I68_network_xequilibrium/NetworkEquilibriumFollowsTheVariableMap", "medium"
    % ---- I70_controller_tab_parameter ------------------------------------------------------------
    "test_I70_controller_tab_parameter/LocalControllerTab_parameterEditIsLoggedAndRebuilt", "medium"
    "test_I70_controller_tab_parameter/NestedLocalControllerTab_parameterEditIsLogged", "medium"
    "test_I70_controller_tab_parameter/LocalControllerAssignmentOfTheSameValuesIsNotAnEdit", "medium"
    "test_I70_controller_tab_parameter/GlobalControllerTab_parameterEditIsLoggedAndRebuilt", "medium"
    % ---- I71_layer_get_sys -----------------------------------------------------------------------
    "test_I71_layer_get_sys/CPFAfterANetworkHzEditAndInitializeKeepsThePath", "large"
    "test_I71_layer_get_sys/LayerGet_sysAfterADynamicsEditAsksForInitialize", "medium"
    "test_I71_layer_get_sys/LayerGet_sysAfterInitializeUsesTheEditedModel", "medium"
    "test_I71_layer_get_sys/CPFAfterADynamicsEditAsksForInitialize", "medium"
    % ---- I90_auto_slack_selection ----------------------------------------------------------------
    "test_I90_auto_slack_selection/ThePowerFlow_OPFAndNetwork_to_mpcUseTheSameBusWhenTheFirstBusHasNoQ_NaN", "large"
    "test_I90_auto_slack_selection/TheBusThatIsSetStaysTheReferenceOfOPFAndNetwork_to_mpc", "medium"
    % ---- I91_slack_power_assignment --------------------------------------------------------------
    "test_I91_slack_power_assignment/ACSVRoundTripKeepsTheOperatingPoint", "medium"
    "test_I91_slack_power_assignment/Method__OPF_And_equilibrium_KeepThePowersTheyFix_WhateverTheOrder", "medium"
    % ---- I92_network_islands ---------------------------------------------------------------------
    "test_I92_network_islands/AFailedOPFOnASplitNetworkNamesTheIslands_AlsoWhenTheOPFStopsWithAnInternalError", "large"
    "test_I92_network_islands/TheBuilt_inNetworksDoNotWarn", "large"
    "test_I92_network_islands/Method__OPF_AndMethod__equilibrium_WarnOnABalancedIslandToo", "medium"
    % ---- I93_model_equilibrium -------------------------------------------------------------------
    "test_I93_model_equilibrium/ModelsOfComponentsAreCheckedWithEveryMethod", "large"
    "test_I93_model_equilibrium/TheBuilt_inNetworksAreFarBelowTheThreshold_WithTheirControllers", "large"
    ];
    tab = table(list(:,1), list(:,2), 'VariableNames', ["Test","Level"]);
end
