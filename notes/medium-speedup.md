# medium を 20 分以内にする見直しと F91 の停止 (2026-11-21)

基準: guilda `c08d691b`、検証リポジトリ `9cbec6e`。作業ブランチは両方とも `test/medium-speedup`。計測は R2026a の `matlab -batch`。

## 結果

| 段階 | 前 | 後 |
|---|---|---|
| medium | 1125 件・1671 s (27.9 分)、FAIL 0 | 854 件・977 s (16.3 分、壁時計)、FAIL 0 |
| large | (未計測) | 1380 件・4668 s (約 78 分、壁時計)、FAIL 1 (下記) |

- どちらの計測でも、ほかのセッションの MATLAB が 1〜2 個同時に動いていました (負荷平均 5〜7)。負荷のない状態は計測していません。
- large の FAIL は F77 `askOfTheOPFFormOpensFastTheSecondTimeAndTheResultGUIOpensFastOnIEEE68bus` の時間の判定 (比 11.9、上限 6) だけです。F77 だけを流すと 2 回とも PASS でした。負荷による揺れと判断しました。このテストは見えない窓の経路 (10 s の待ち) を測っており、下の ask.m の変更 (見える窓の経路) は通りません。
- SKIP 1 件は F4 の MATPOWER 比較 (MATPOWER がパスにない) です。

## F91 が -batch で止まった原因 (確認済み)

`DrawerOptionDialog/ask.m` の見える窓の待ち `uiwait(h_fig)` が、待つ前に押されたボタンを失っていました。

- `h_fig.Name = s_signature;` のあと `h_fig.Visible = l_visible;` でコールバックとタイマーが動きます。テストの押下タイマー (ダイアログを Name で探す) がそこで Run を押すと、`close_dialog` が UserData を入れて `uiresume` します。ところが、まだ `uiwait` に入っていないので、この `uiresume` は効きません。その後の `uiwait` が上限なしで待ち続けました。
- F91 では、`batchStartupOptionUsed` を隠して見える窓にした節 (5・6 番目) で起こります。押すタイマーがいつ動くかで決まるので、起きたり起きなかったりします (止まった回は共有チェックアウトで、ほかの MATLAB と同時に動いていました。今回の medium と F91 単独の実行では止まりませんでした)。
- 再現: 見える窓で、0.001 s ごとのタイマーで Run を押すと、10 回中 7 回 `uiwait` が戻りませんでした (UserData にはコードが入ったまま)。修正後は 10 回中 0 回です。
- GUI の担当の見立て (a) の場所で合っていました。(b) の `G.animate` と (d) の `batchStartupOptionUsed` の偽物が残る件は、今回の停止の原因ではありませんでした。

### 修正 (GUI のコード、GUI の担当のレビュー済み)

- guilda `22f57117`: 見える窓は `while isvalid(h_fig) && isempty(h_fig.UserData) && h_fig.Visible` の間 `uiwait(h_fig, 1)` で待ちます。1 s ごとに UserData を読み直すので、取りこぼした `uiresume` があっても戻ります。待っている間にダイアログが隠されたら、取り消しとして終わります。人が答える見える窓には時間の上限を付けません (GUI の担当の判断)。
- 検証 `4aa29e6`・`409243b`: F66 `ARunPressedBeforeTheDialogWaitsIsNotLost_AskReturnsTheCode` (medium)。ダイアログの Name の PostSet リスナーで Run を押すので、必ず `uiwait` の前に押されます。修正前の ask.m では FAIL (20 s 後に救出タイマーが uiresume)、修正後は約 2 s で PASS です。
- F91 の最後の節で、`plot_iteration` の再生中に窓を閉じても `GUILDA:GraphBase:PlaybackTimer`・`GUILDA:GraphNetDiagram:FlowTimer` の警告が出ないことを確かめるようにしました (`lastwarn`)。

## medium の見直し (検証 `56305c3`)

- 確かめる内容は変えていません。`test_levels.m` の段階を書き換えただけです。large は全件を流すので、移したテストは large で必ず流れます。
- 1 回目: 前の medium の計測で 3 s を超えた 120 件 (medium 115 件、small 5 件) を large へ移しました。ほかの MATLAB の負荷で後の計測が約 1.56 倍になり、まだ 20 分を超えていました。
- 2 回目: その後の medium の計測 (負荷あり) で 3 s (負荷なしで約 2 s) を超えた medium の 151 件を large へ移しました。この回で small を超えたもの 9 件は small のまま残しています (小さい段階の煙テストを減らさないため)。
- 共通設定 (ファイルで 1 回) の時間は、そのファイルで最初に流れるテストに乗ります。先頭のテストを large に移すと、次のテストにその時間が移ります。見積もると共通設定の合計は約 60 s で、主な原因ではありませんでした。
- large の目安を「1 件 3 秒程度」から「2 秒程度」に改め、`run_all.m`・`test_levels.m` のヘッダーと For Developer の Model Implementation のページの時間を直しました。
- 小さい系統への置き換えと、共通の前処理の使い回しはしていません (テストの内容が変わるため)。

## 未確認・残っていること

- 負荷のない状態の medium の時間 (後) は計測していません。
- `matlab -batch "cd <GUILDA>; DebugScript.run_all"` は、ワークツリーでは `DebugScript.run_all` を解決できません (`_GUILDAverification` がパスにないため)。先に `GUILDA;` を実行する必要があります。今回は直していません。
- `fix/ode-default-tolerance` が `test_levels.m` に行を足すと、この変更と衝突する可能性があります。

## large へ移したテスト (271 件)

「（small から）」は small から移したものです。それ以外は medium から移しました。

- `test_F2_powerflow`（5 件）: `WarmStartThatFailsIsSolvedOnceMoreFromTheFlatStart`、`plot_voltageDrawsTheLimitsThatAreFinite`、`plot_networkColorsTheBusesAndDrawsTheFlowsAsArrows`、`WarmStartStartsFromTheLastConvergedSolution`、`EveryMethodReachesTheSameSolution`
- `test_F4_opf`（14 件）: `DCOPFReadsNaNTapAndPhaseOfPiLinesAs1And0`（small から）、`DCOptimalPowerFlow`、`ACOPFRespectsGeneratorLimits`、`IEEE14ELDAndDCOPF`、`ACOPFOnA2_busSystemMatchesTheClosedForm`、`ConversionToAMATPOWERCase`、`InfiniteOperationLimitsRemoveTheDefaultLimits`、`DefaultCost_falseLeavesOutTheCostsOfTab_parameter_OPF`、`disp_formulationShowsTheFormulationAndTheCountsOfABuiltProblem`、`EconomicLoadDispatch`、`ELDWithABindingGeneratorLimit`、`EveryCallBuildsTheOPFProblemFromTheCurrentNetwork`、`DCOPFCongestionPricesOnA3_busLoop`、`OPFVariablesAreTheBusVoltagesAndTheComponentPowers`
- `test_F5_cpf`（3 件）: `LimitsOptionValuesAreChecked`（small から）、`CPFOnA3_busNetworkPassesTheNose`（small から）、`FailedPreconditionsAndUnknownOptionsStopWithAnError`
- `test_F6_simulation`（7 件）: `SimulationResultStructure`、`PointAtAPhaseBoundary`、`FaultWithLocalControllers`、`AVRAndPSSResponseIsUnchangedByNameWiring`、`FaultWithLQR`、`TwoGlobalControllersActTogether`、`NetworkHzSetsTheRotorAngleDynamics`
- `test_F7_linearization`（25 件）: `ContributionsByTag_ByClassAndBySeveralTargets`、`ContributionsOfAllElementsSumToTheDAE`、`VariableMapsOfTheControllersAndTheEquilibriumColumn`、`Zero_powerLoadsKeepTheirInputs`、`BusWithoutComponents`、`Inputs_StatesAndOutputsOfGet_sysOnEachLayer`、`VariableMapIsConsistentWithTheLinearModel`、`PointAtTheEquilibriumEqualsTheDefault`、`LQRImprovesTheDampingOfIEEE14`、`PointFromASimulationWithControllersAtAnEquilibriumTime`、`PointFromASimulationWithControllersAtAPerturbedTime`、`PointThatIsNotFiniteNamesTheVariables`、`PointAroundATrip`、`PointInsideAFaultIsReportedAndKeepsTheModelNetwork`、`PlotDrawsTheAlgorithmOfTheOptions`、`ConfigurationsThatCannotBeLinearizedStopWithAGUILDAError`、`PortIsAnOptionOfGet_sys`、`DefaultChannelsOfGet_sysDoNotChange`、`CanonicalLinearizationDemoRuns`、`LQRClosedLoopMatchesItsDesignModel`、`PointGivesTheControllerInputsAsGiven`、`PointWithoutTheControllerInputsStopsWithPointSize`、`OverridesApplyToOneCallAndLeaveTheSolverUnchanged`、`FlagReportsASingularAvv`、`FormatSsAndTheLQRControllersStopWithoutControlSystemToolbox`
- `test_F8_utilities`（7 件）: `CSVRoundTripKeepsHzBaseMVAAndTheSlackBus`、`DeprecatedCsvNetHandlerWrappers`、`TemplateIEEE14bus`、`TemplateTEST31bus`、`TemplateTxt3Bus`、`TemplateTutorial6busHasTheOperatingPointOfTheIEEJ2026Spring_massExample`、`Tutorial6busWithoutGovernorsKeepsTheFrequencyDeviationOfTheDamping`
- `test_F9_environment`（3 件）: `GUILDASettingChangesSettingsByCommand`、`GUILDASettingWindowHasAnEditorForEverySetting`、`UserSettingsWithoutAVersionAreResetToTheDefaults`
- `test_F16_csv_io`（2 件）: `exportWritesTheLocalControllers_TheStaticOnesIncluded_AndImportRestoresThem`、`exportWritesTheGlobalControllersAndImportRestoresThem`
- `test_F21_controller_editing`（1 件）: `remove_local_controller_ThePSSAlone_ThenTheAVR_EachLoggedAndLeavingAWorkingModel`
- `test_F22_model_contract`（4 件）: `EveryComponentPassesAtTheEquilibrium`、`EveryComponentStaysAtTheEquilibriumInASimulation`、`EveryLocalControllerStaysAtTheEquilibriumInASimulation`、`check_model_contractReportsEachKindOfViolation`
- `test_F24_tags`（1 件）: `LabelsAreTheNameAndTheTagOfTheOwner`
- `test_F26_call_graph`（1 件）: `TheCachedFileReadsGiveTheSameCallGraph`（small から）
- `test_F28_avr_dc1_field_limit`（1 件）: `TheDefaultKapInitializesIEEE9busAndIEEE14bus`
- `test_F30_governor`（2 件）: `TheLoadLimiter77MCapsTheOutput`、`Load_limitOperation_PLM_0_KeepsPmechForAFrequencyDrop`
- `test_F31_scenario`（2 件）: `OverlappingAndTouchingEventsOfOneTarget`、`ScenarioFiles_TheContent_TheTimeSeriesAndItsMethodRoundTrip`
- `test_F34_signatures`（1 件）: `MethodsOfThe_auxiliaryClassesSuggestTheirChoices`
- `test_F35_controller_signal_routing`（4 件）: `TwoLocalControllersWithTheSameInputNameBothReceiveTheOutput`、`TheJacobianMatchesFiniteDifferencesWithAGlobalControllerOnOutputsAndVoltages`、`TheLinearModelAgreesWithTheJacobianOfTheSimulation`、`AGlobalControllerReadsTheVoltageOfABusWithoutComponents`
- `test_F36_tutorial_all_models`（3 件）: `TheNetworkHasEveryRegisteredControllerAndBranchKeyAndAnEmptyBus`、`AThree_phaseFaultOnBus8Settles`、`ODEAndDAEGiveTheSameStableEigenvalues`
- `test_F37_disp_connection`（1 件）: `EveryTargetOfTheConnectionMapIsInTheText`
- `test_F38_result_judge`（3 件）: `IncompleteVerdictAndAJudgeFunctionOfTheUser`、`JudgeOfARunStoppedByStopOnOutOfStep_flag2_`、`TheResultWorksAfterTheNetworkIsDeleted`
- `test_F39_simulation_data`（1 件）: `solveReadsOnlyTheData`
- `test_F40_stop_and_sample_time`（2 件）: `StopOnOutOfStep`、`SampleTimeKeepsTheStopTimeOfStopOnOutOfStep`
- `test_F42_branch_events`（4 件）: `test3openOfTwoCircuitsHalvesTheBranch`、`A3LGNearTheToEndIsCloseToAFaultOfThatBus`、`CombinedBranchStatesShareOneMatrixPerSet`、`ATrippedLocalControllerIsNaNToTheEnd`
- `test_F42_graph_spring`（5 件）: `set_timeDrawsTheNearestSampleAtTheExpectedCoordinates`、`SamplesNamedByTheDataAreShownInTheTitleInsteadOfTheTime`、`ANodeAtZeroVoltageIn3DSitsAtTheBottomAndNothingLeavesTheAxes`、`TickLabelsOfSmall2DPicturesDoNotOverlap`、`Two3DPicturesInOneFigureKeepTheirObjectsInTheirOwnAxes`
- `test_F43_spring_model`（5 件）: `OwnNodeOfAClassicalGeneratorEqualsVfieldE_jdelta`、`TrippedUnitIsNaNAndThePictureStillDraws`、`UninitializedOrStaleNetStopsWithRunNet_initializeFirst`、`RemainingCurrentAtABusEqualsTheLoadCurrent`、`PowerFlowResultShowsTheBusesOnly`
- `test_F44_net_diagram`（2 件）: `UninitializedOrStaleNetStopsWithRunNet_initializeFirst`、`StyleTransformerDrawsTheSymbolAtTheFromEnd`
- `test_F45_ode_component_current`（3 件）: `AGenerator_sCurrentIsItsOwnF_IAtASample`、`TheViewField_TheExportAndTheOutputTimesOfSampleTime`、`AResultWithoutComponentCurrentsHasNaNColumns`
- `test_F46_graph_base`（3 件）: `set_positionIsAnErrorOnGraphSpring`、`TimeChangedFiresAfterSet_timeOnLinkedGraphsAndDuringAnimate`、`SamplesNamedByTheDataReplaceTheTimeInThePlaybackBar`
- `test_F47_graph_interaction`（2 件）: `reset_styleReturnsTheStylesToTheDefaultsOfTheData`、`ACaptureOfTheDiagramHasNoAxis_wideLines`
- `test_F48_graph_chart`（3 件）: `set_styleByTagAndByVectorGiveTheSameGraphics`、`ParentIsAContainerOr_ForASinglePanel_AnAxesOrUiaxes`、`TheFigureKeepsTheGraph_SavefigDoesNotRecurse_DeletingTheFigureFreesIt`
- `test_F49_graph_netmap`（2 件）: `ParentIsAContainer_AnAxesOrAUiaxes`、`plot_networkReturnsAGraphNetMapWithTheDrawingOfThePowerFlow`
- `test_F50_gui_history_option`（2 件）: `get_codeLeavesOutTheDefaultsAndOffersTheModelKeys`、`ValueShowsInitialValues_TheCallComparesThemWithTheDefault`
- `test_F51_model_gui_actions`（3 件）: `AFailedAddIsLoggedAsFailed_ShowsAWarningAndDoesNotNotifyModelChanged`、`RemoveInTheContextMenuOfARowOfTheChildTableRunsTheRemove__MethodOfTheParent`、`AParameterEditIsLoggedAsCode_AnInvalidValueIsRefusedAndRestored`
- `test_F53_layout_placement`（2 件）: `ABusConnectedToB014IsPlacedNearItAndTheOtherBusesStay`、`TheModelKeepsNaN_Get_layoutSavesThePlacementAndTheMapAgrees`
- `test_F54_graph_layout`（1 件）: `CSVRoundTripKeepsTheLayout`
- `test_F55_guilda_app`（1 件）: `TheStartScreenMakesAnEmptyNetworkAsTheFirstLineOfTheScript`
- `test_F58_scenario_events`（2 件）: `TheConstructorsMakeEventsOutsideAScenario_TheAddMethodsReturnThem`、`TheTablesKeepTheirColumnsAndAreBuiltFromTheEvents`
- `test_F59_diagram_2d`（11 件）: `AGraph_GRedrawKeepsTheObjectsWhileTheDrawingStays`（small から）、`test2DSymbolsSitAtTheBusHeights`、`WidthsAndSizesFollowTheRanges`、`OneScaleOverAllSamples`、`YsvdWidthsLeaveOutTheTopOutliersOnIEEE68`、`BeforeAPowerFlowTheDiagramHasNoColorbar`、`ACaptureOfThe2DDiagramHasNoAxis_wideLines`、`AutomaticColorLimitsComeFromAllSamples`、`LossColorsAreTheExactBranchLossesOnIEEE68`、`ComponentsTakeTheColormapColorOfTheirLinksAndAreBlackWithoutAValue`、`AComponentLabelSetByTheUserGetsItsTextObjectBeforeLabelModeShowsIt`
- `test_F60_flow_animation`（7 件）: `TheDotsMoveInTheFlowDirectionAtASpeedProportionalToTheFlow`、`FlowModeChoosesTheQuantity_And_none_DrawsNoDots`、`ATopologyDiagramAnd3DHaveNoDots`、`ANetworkWithoutBranchesOrLinks_OrWithOneBranch_DrawsWithoutAnError`、`export_videoAdvancesTheDotsAndLeavesNoTimer`、`ARedrawByGraph_GKeepsOneTimerAndDeletingTheContainerContentsRemovesIt`、`ClosingAWindowWhileTheDotsMoveGivesNoWarningAndLeavesNoTimer`
- `test_F61_graph_controls`（6 件）: `AValueThePropertyRefusesPutsTheWidgetBackWithAWarning`、`GraphNetDiagram_WidgetsSetThePropertiesAndThePropertiesUpdateTheWidgets`、`GraphNetDiagram_TheAutoCheckboxOfColorLimits`、`GraphNetDiagram_SwitchingDimensionFromThePanelKeepsThePanelAndItsPlace`、`GraphNetDiagram_ParentIsAUipanelOfAUifigureOrAUigridlayout`、`GraphNetMap_TheRangeOfTheBranchWidthsOnly`
- `test_F62_tag_picker`（1 件）: `CancelAndClosingReturnNoValue`
- `test_F63_avr_limiter`（2 件）: `AVR_ST1WithLimiterFalseFollowsTheTrajectoryWithoutLimits`、`AVR_DC1WithLimiterFalseFollowsTheTrajectoryWithoutLimits`
- `test_F65_static_controllers`（4 件）: `APSSGoesUnderTheStaticAVR_ItsVpssAddsToTheFieldVoltage`、`NetworksBuiltWithLocalController_falseKeepOnlyTheStaticAVRAndGovernor`、`rv_UoffsetIs0OnTheInputsALocalControllerDrivesAndRv_UequilibriumElsewhere`、`simulateWithOnlyStaticControllersGivesTheTrajectoriesOfTheNetworkWithoutThem`
- `test_F66_gui_forms`（1 件）: `DefaultsOnTheObject_EventEdit_AndFromThePropertyDefaultsOfAClass`
- `test_F68_pss_retrofit`（1 件）: `TheEigenvaluesAreThoseWithoutRetrofitAndThoseOfE__A_d_BK_`
- `test_F69_gui_layout`（1 件）: `TheChildTableOfAModelIsReusedByTheNextRenderOfThatModelAndBuiltAgainAfterARun`
- `test_F70_export_controllers`（2 件）: `AnAVR_ST1WithAPSS1AndAPSSUnderTheStaticAVRKeepTheirParents`、`option_jsonKeepsMatrices_AComplexV0_ADefaultInputAndEmptyWeights`
- `test_F72_network_element_methods`（3 件）: `get_parameterSelectsByClassAndOwnerAndSetsCostsOfTheGenerators`、`get_parameterJoinsMixedModelsWithTheUnionOfTheColumnsAndAKeyColumn`、`disp_summaryBeforeInitializeLeavesOutTheEquilibriumColumns`
- `test_F73_result_summary`（2 件）: `APowerFlowThatDidNotConvergeHasNaNSumsInGet_summaryAndOneBulletInDisp_summary`、`get_summaryOfADCOPFHoldsTheCost_ThePSums_TheBindingCountAndTheLMPRange`
- `test_F74_trajectory_mode`（4 件）: `get_trajectoryOfTheComponents_States_Inputs_OutputsAndTheOwnerFilter`、`get_trajectoryWithReferenceCOI`、`get_trajectoryWithReferenceCOILeavesATrippedUnitOutOfTheCenter`、`get_modeOfTheDAEGivesTheModesOfTheODE`
- `test_F75_model_gui_speed`（2 件）: `ARenderToAnotherModelOfTheSameKindKeepsEveryComponentAndSendsTheNewDataInOneMessage`、`PartsNotNeededAreHiddenOrDetachedAndComeBack_TheChildTable_TheAddButtonsAndTheTabs`
- `test_F77_gui_speed`（3 件）: `AReusedFormTakesValue_AndAGroupOpenedBeforeIsClosedAgain`、`AFormWhoseFieldsNeedOtherWidgetsIsDrawnAgain`、`ANewResultWindowOpensWithTheDefaultVisibilityOfFigures`
- `test_F78_pss1_zero_time_constant`（1 件）: `Example1OfTable5_7Initializes_SimulatesAndLinearizesWithoutNaN`
- `test_F79_st1_field_limit`（1 件）: `Example1OfTable5_5KeepsVfieldWithinTheOutputLimitsThroughAFault`
- `test_F80_parameter_table_cache`（1 件）: `AnExportedAndImportedNetworkHasTheEditedValues`
- `test_F81_opened_branch_flow`（3 件）: `A6openBranchCarriesNoFlowAfterTheOpeningAndAFlowBefore`、`DuringAFaultInsideABranchItsEndsCarryTheCurrentsOfTheFaultedBranch`、`ADiagramStateWithoutBranchMatricesUsesTheMatricesOfTheSnapshot`
- `test_F82_graph_matrix`（1 件）: `set_timeShowsTheNearestSampleAndItsTimeInTheTitle`
- `test_F83_energy_hessian`（2 件）: `EveryClassThatImplementsTheFormIsInTheTestNetworks`、`TheClassesWithoutTheFormStopWithTheClassName`
- `test_F84_linearization_analysis`（7 件）: `get_eigenvalueIsTheFiniteEigenvaluesInTheOrderOfGet_mode`、`get_participationSumsTheParticipationOfGet_modeByBus`、`TheLeftKernelIsDualToTheRightOne_AndItsEntryAtADeltaIsD_omega0OfTheOmegaEntry`、`TwoIslandsGiveTwoKernels_OneIndicatorPerIsland`、`EveryMethodTakesIndex_TimeAndIndex_all_OverTimeSections`、`plot_eigenvalueOfSeveralSectionsFollowsSet_timeAndLinksWithTheSimulation`、`plot_eigenvalue_pathDrawsTheLargestRealPartAndTheSmallestDampingRatioOverTheSections`
- `test_F85_linearization_hessian_form`（5 件）: `absorbedHasTheEigenvaluesAndTheTransferFunctionOfDescriptor`、`hessianIsTheDescriptorDAEJacobianWithTheRowsScaledAtTheEquilibrium`、`EverySectionHasTheHessianForm`、`UnsupportedDevicesAndPortIStopWithAnError`、`TheLosslessCaseIsSymmetricAndTheLossyOneIsNot`
- `test_F86_scenario_scalar_time`（2 件）: `ATripAndAnOpeningTakeOneTimeAndLastToTheEndOfTheRun`、`add_scenarioWithoutATagUsesCASE`
- `test_F87_gui_dependent_forms`（1 件）: `WithoutAUnitTheNamesHaveNoItemsAndTheHintAsksForTheUnit_WithoutHistoryATextField`
- `test_F90_analyze_highlight`（3 件）: `AfterARunOfAnAnalysisTabAnalyzeResultIsTheFilledPrimaryButtonUntilTheResultIsOpened`、`AResultThatTheLogMakesIsNewToo_AndEachAnalysisTabFollowsItsOwnResult`、`AfterASimulationAnalyzeResultOfTheTimeSimulationTabIsHighlightedUntilItIsOpened`
- `test_F91_result_gui_autoplay`（6 件）: `APlotThatAnimatesDoesNotPlayUnderMatlab_batchOrInAHiddenWindowAndLeavesNoTimer`、`PlayOfThePlaybackBarShowsPauseWhileAnimatePlays_PlayDoesNotStartASecondOne_PauseStopsIt`、`DeletingTheAxesStopsTheAnimation_AnotherPlotInThePanelOrAClosedWindow`、`DisplayOptionsWithoutATimeRow_TheDiagramShowsItsControlsAndATimeChartNone`、`AVisibleWindowStartsPlayingByATimerAndTheButtonReturns_Closing_ReplottingOrDeletingTheAxesLeavesNoTimer`、`TheIterationsOfAnOPFPlay_TheChartPlaysByOneTimerAndTheLinkedNetworkDiagramFollows_ClosingTheWindowLeavesNoTimer`
- `test_F92_pf_diverged_message`（1 件）: `TheIEEE9_busSystemWith2_5TimesTheLoadsDivergesInCalculate_powerflow`
- `test_F94_cpf_operating_points`（4 件）: `Step1IsTheEquilibriumAndEveryStepHasAFullPoint`、`get_sysOfAStepMatchesTheNetworkWithLoadsScaledBy_1_Lambda_`、`Limits_Q_KeepsTheFixedQOfASwitchedBus`、`ALocalControllerWithGet_equilibrium_obj_V_U_StillWorksAtTheSteps`
- `test_F95_load_current`（3 件）: `AFaultKeepsIp_Iq_PAndQAreProportionalTo_V_`、`get_sysAndTheContinuationPowerFlow`、`CSVExportAndImportRoundTrip`
- `test_F96_load_zip`（4 件）: `AnEditOfTheDynamicsMakesTheLoadStaleAndInitializeTakesTheNewValues`、`ThePowerFlowAndInitializeReproducePAndQAtTheEquilibrium`、`get_sysOfAPureZZIPLoadHasTheEigenvaluesOfLoad_impedance`、`TheLoadsOfTheIEEJNetworksAreLoad_ZIPWithTheDefaults`
- `test_F97_cpf_analysis_plots`（5 件）: `plot_pvcurveTakesTheStepsAsSamplesWithAMarkerCursor`、`plot_diagramAndPlot_spring_modelShowTheOperatingPointOfEachStep`、`LinkedPlotsOfTheStepsFollowEachOtherAndTheEigenvaluesOfNet_get_sys__res_Steps__`、`plot_generatorDrawsP_QAndTheQMarginOfTheGeneratorsAndMarksTheSwitches`、`plot_branchDrawsP_S_TheLoadingAndTheLossOfTheBranches`
- `test_F98_inverter_components`（2 件）: `ARotatedVSGAndAGFLInverterAreAtTheEquilibriumAfterInitialize`、`AVSGWithAlpha0BehavesAsGen_classical`
- `test_F99_ieee39_dynamics`（4 件）: `TheInertiaIsM_2HAndTheElectromechanicalModesAreBelow2Hz`、`AFaultWithTheConstant_powerLoadsHasNoConsistentInitialCondition`、`TheSameFaultRunsWithLoad_impedanceLoads_exampleOfTheClassHelp_`、`WithStifferGeneratorsTheFaultHasAConsistentInitialConditionWithLoad_power`
- `test_F100_graph_playback`（4 件）: `AGraphOfTwoOrMoreSamplesHasTheBarBelowItsAxes_AndOneSampleHasNone`、`TheTimerIsDeletedWhenTheFigureCloses_TheAxesOrTheGraphAreDeleted_OrTheGraphIsReplaced`、`ClosingAWindowDuringPlaybackGivesNoWarningAndLeavesNoTimer`、`export_videoAndExportgraphicsOfTheAxesLeaveOutTheBar`
- `test_I50_trip_with_local_controller`（3 件）: `DefaultIEEE9TripCompletes`、`DefaultIEEE9TripWithALongerHorizonCompletes`、`TripWithAVRCompletes`
- `test_I51_tripped_unit_jacobian`（1 件）: `PhaseWithARecomputedInitialConditionHonorsSolver`
- `test_I52_validate_events`（1 件）: `UnknownFaultTarget`
- `test_I54_simulate_time`（1 件）: `TheTimeOfTheScenarioIsUsedWithoutTime`
- `test_I55_time_limit`（2 件）: `PartialResultWarnsWithAnyNumberOfOutputs`、`PhasesThatEachFitInTheLimitStopWhenTheirSumDoesNot`
- `test_I56_initialize_equilibrium`（3 件）: `OPFInitializeWithSeveralComponentsOnOneBus`、`FailedAnalysisStillKeepsThePreviousEquilibrium`、`PowerflowAndEquilibriumWithSeveralComponentsOnOneBus`
- `test_I57_stale_gc_references`（1 件）: `ACorrectControllerStillSimulates`
- `test_I58_input_under_local_controller`（4 件）: `AStepOnAnInputDrivenByAnAVRMatchesGet_sys`、`AStepOnAnInputNoControllerDrivesStillMatchesGet_sys`、`AGlobalControllerOnADrivenInputAddsToTheLocalController`、`TheRecordedInputIsTheOutputOfTheControllerPlusTheEvent`
- `test_I61_restore_working_data`（1 件）: `RerunAfterATripMatchesARunOnAFreshNetwork`
- `test_I62_keep_completed_phases`（2 件）: `WorkingDataIsRestoredAfterAFailedPhase`、`SolverErrorInALaterPhaseKeepsTheCompletedPhases`
- `test_I67_replace_controllers`（1 件）: `test_keep_MovesRetrofitUnderTheStaticAVRAndItFollowsTheStatesOfTheNewGenerator`
- `test_I68_network_xequilibrium`（1 件）: `NetworkEquilibriumFollowsTheVariableMap`
- `test_I91_slack_power_assignment`（1 件）: `Method__OPF_And_equilibrium_KeepThePowersTheyFix_WhateverTheOrder`
- `test_I92_network_islands`（1 件）: `Method__OPF_AndMethod__equilibrium_WarnOnABalancedIslandToo`
- `test_I93_model_equilibrium`（2 件）: `ResidualsOfALocalControllerNameTheController`、`AGlobalControllerIsChecked`
- `test_I105_model_contracts`（2 件）: `fcn_MassOfALocalControllerThatUsesXStopsWithTheTag`、`UseInternalStateNamesTheComponentWithoutGetCompPQ`
- `test_I111_unfeasible_dae_message`（1 件）: `FaultOnAGeneratorBusExplainsTheFailure`
