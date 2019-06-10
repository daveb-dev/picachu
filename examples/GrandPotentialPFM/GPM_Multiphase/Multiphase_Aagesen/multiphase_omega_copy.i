[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 60
  xmin = -15
  xmax = 15
[]

[GlobalParams]
  #int_width = 3.0
  #block = 0
  #op_num = 2
  #var_name_base = etab
[]

[Variables]
  [./w]
  [../]
  [./etaa0]
  [../]
  [./etab0]
  [../]
  [./etad0]
  [../]
[]

[AuxVariables]
  #[./total_F]
  #  order = CONSTANT
  #  family = MONOMIAL
  #[../]
  #[./bnds]
  #  order = FIRST
  #  family = LAGRANGE
  #[../]
[]

[ICs]
  [./IC_etaa0]
    type = FunctionIC
    variable = etaa0
    function = ic_func_etaa0
  [../]
  [./IC_etab0]
    type = FunctionIC
    variable = etab0
    function = ic_func_etab0
  [../]
  [./IC_etad0]
    type = ConstantIC
    variable = etad0
    value = 0.1
  [../]
  [./IC_w]
    type = FunctionIC
    variable = w
    function = ic_func_w
  [../]
[]

[Functions]
  [./ic_func_etaa0]
    type = ParsedFunction
    value = '0.9*0.5*(1.0-tanh((x)/sqrt(2.0)))'
  [../]
  [./ic_func_etab0]
    type = ParsedFunction
    value = '0.9*0.5*(1.0+tanh((x)/sqrt(2.0)))'
  [../]
  [./ic_func_w] #Supersaturate alpha phase
    type = ParsedFunction
    value = 0
  [../]
[]


[BCs]

[]

[Kernels]
# Order parameter eta_alpha0
  [./ACa0_bulk]
    type = ACGrGrMulti
    variable = etaa0
    v =           'etab0 etad0'
    gamma_names = 'gab   gad'
    #args = 'etab0 etab1 w'
  [../]
  [./ACa0_sw]
    type = ACSwitching
    variable = etaa0
    Fj_names  = 'omegaa omegab omegad'
    hj_names  = 'ha     hb     hd'
    args = 'etab0 etad0 w'
  [../]
  [./ACa0_int]
    type = ACInterface
    variable = etaa0
    kappa_name = kappa
  [../]
  [./ea0_dot]
    type = TimeDerivative
    variable = etaa0
  [../]
# Order parameter eta_beta0
  [./ACb0_bulk]
    type = ACGrGrMulti
    variable = etab0
    v =           'etaa0 etad0'
    gamma_names = 'gab   gbd'
    #args = 'etaa0 etab1 w'
  [../]
  [./ACb0_sw]
    type = ACSwitching
    variable = etab0
    Fj_names  = 'omegaa omegab omegad'
    hj_names  = 'ha     hb     hd'
    args = 'etaa0 etad0 w'
  [../]
  [./ACb0_int]
    type = ACInterface
    variable = etab0
    kappa_name = kappa
  [../]
  [./eb0_dot]
    type = TimeDerivative
    variable = etab0
  [../]
# Order parameter eta_delta0
  [./ACd0_bulk]
    type = ACGrGrMulti
    variable = etad0
    v =           'etaa0 etab0'
    gamma_names = 'gad   gbd'
    #args = 'etaa0 etab0 w'
  [../]
  [./ACd0_sw]
    type = ACSwitching
    variable = etad0
    Fj_names  = 'omegaa omegab omegad'
    hj_names  = 'ha     hb     hd'
    args = 'etaa0 etab0 w'
  [../]
  [./ACd0_int]
    type = ACInterface
    variable = etad0
    kappa_name = kappa
  [../]
  [./ed0_dot]
    type = TimeDerivative
    variable = etad0
  [../]
#Chemical potential
  [./w_dot]
    type = SusceptibilityTimeDerivative
    variable = w
    f_name = chi
    args = '' # in this case chi (the susceptibility) is simply a constant
  [../]
  [./Diffusion]
    type = MatDiffusion
    variable = w
    D_name = Dchi
    args = ''
  [../]
  [./coupled_etaa0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etaa0
    Fj_names = 'rhoa rhob rhod'
    hj_names = 'ha   hb   hd'
    args = 'etaa0 etab0 etad0'
  [../]
  [./coupled_etab0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etab0
    Fj_names = 'rhoa rhob rhod'
    hj_names = 'ha   hb   hd'
    args = 'etaa0 etab0 etad0'
  [../]
  [./coupled_etad0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etad0
    Fj_names = 'rhoa rhob rhod'
    hj_names = 'ha   hb   hd'
    args = 'etaa0 etab0 etad0'
  [../]
[]

[AuxKernels]
  #[./total_F]
  #  type = TotalFreeEnergy
  #  variable = total_F
  #  interfacial_vars = 'eta1 eta2 eta3 eta0'
  #  kappa_names = 'kappa_s kappa_op kappa_op kappa_op'
  #[../]
  #[./BndsCalc]
  #  type = BndsCalcAux
  #  variable = bnds
  #  execute_on = timestep_end
  #[../]
[]

[Materials]
  [./ha_test]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = ha
    all_etas = 'etaa0 etab0 etad0'
    phase_etas = 'etaa0'
    #outputs = exodus
  [../]
  [./hb_test]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = hb
    all_etas = 'etaa0 etab0 etad0'
    phase_etas = 'etab0'
    #outputs = exodus
  [../]
  [./hd_test]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = hd
    all_etas = 'etaa0 etab0 etad0'
    phase_etas = 'etad0'
    #outputs = exodus
  [../]
  [./omegaa]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = omegaa
    material_property_names = 'Vm ka caeq'
    function = '-0.5*w^2/Vm^2/ka-w/Vm*caeq'
    derivative_order = 2
    #outputs = exodus
  [../]
  [./omegab]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = omegab
    material_property_names = 'Vm kb cbeq'
    function = '-0.5*w^2/Vm^2/kb-w/Vm*cbeq'
    derivative_order = 2
    #outputs = exodus
  [../]
  [./omegad]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = omegad
    material_property_names = 'Vm kd cdeq'
    function = '-0.5*w^2/Vm^2/kd-w/Vm*cdeq'
    derivative_order = 2
    #outputs = exodus
  [../]
  [./rhoa]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = rhoa
    material_property_names = 'Vm ka caeq'
    function = 'w/Vm^2/ka + caeq/Vm'
    derivative_order = 2
    #outputs = exodus
  [../]
  [./rhob]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = rhob
    material_property_names = 'Vm kb cbeq'
    function = 'w/Vm^2/kb + cbeq/Vm'
    derivative_order = 2
    #outputs = exodus
  [../]
  [./rhod]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = rhod
    material_property_names = 'Vm kd cdeq'
    function = 'w/Vm^2/kd + cdeq/Vm'
    derivative_order = 2
    #outputs = exodus
  [../]
  [./c]
    type = ParsedMaterial
    material_property_names = 'Vm rhoa rhob rhod ha hb hd'
    function = 'Vm * (ha * rhoa + hb * rhob + hd * rhod)'
    f_name = c
    outputs = exodus
  [../]
  [./const]
    type = GenericConstantMaterial
    prop_names =  'kappa_c  kappa   L   D    Vm   ka    caeq kb    cbeq  kd    cdeq  gab gad gbd  mu  tgrad_corr_mult'
    prop_values = '0        1       1.0 1.0  1.0  10.0  0.1  10.0  0.9   10.0  0.5   1.5 1.5 1.5  1.0 0.0'
    #outputs = exodus
  [../]
  [./Mobility]
    type = DerivativeParsedMaterial
    f_name = Dchi
    material_property_names = 'D chi'
    function = 'D*chi'
    derivative_order = 2
    #outputs = exodus
  [../]
  [./chi]
    type = DerivativeParsedMaterial
    f_name = chi
    material_property_names = 'Vm ha ka hb kb hd kd'
    function = '(ha/ka + hb/kb + hd/kd) / Vm^2'
    derivative_order = 2
    outputs = exodus
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]

# [Postprocessors]
#   [./int_pos]
#     type = FindValueOnLine
#     v = etab0
#     target = 0.5
#     start_point = '100 0 0'
#     end_point = '1000  0 0'
#     tol = 1e-8
#   [../]
# []

[VectorPostprocessors]
  [./etaa0]
    type = LineValueSampler
    variable = etaa0
    start_point = '-15 0 0'
    end_point = '15 0 0'
    num_points = 61
    sort_by = x
    execute_on = 'initial timestep_end final'
  [../]
  [./etab0]
    type = LineValueSampler
    variable = etab0
    start_point = '-15 0 0'
    end_point = '15 0 0'
    num_points = 61
    sort_by = x
    execute_on = 'initial timestep_end final'
  [../]
  [./etad0]
    type = LineValueSampler
    variable = etad0
    start_point = '-15 0 0'
    end_point = '15 0 0'
    num_points = 61
    sort_by = x
    execute_on = 'initial timestep_end final'
  [../]
[]

[Executioner]
  # Preconditioned JFNK (default)
  type = Transient
  nl_max_its = 15
  scheme = bdf2
  #solve_type = NEWTON
  solve_type = PJFNK
  petsc_options_iname = -pc_type
  petsc_options_value = asm
  l_max_its = 15
  l_tol = 1.0e-3
  nl_rel_tol = 1.0e-8
  start_time = 0.0
  num_steps = 20
  nl_abs_tol = 1e-10
  dt = 1.0
  # [./TimeStepper]
  #   type = IterationAdaptiveDT
  #   dt = 1.0
  #   optimal_iterations = 8
  #   iteration_window = 2
  # [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    execute_on = 'initial timestep_end final'
    #interval = 1
  [../]
  # [./csv]
  #   type = CSV
  #   execute_on = 'initial timestep_end final'
  #   interval = 1
  # [../]
[]
