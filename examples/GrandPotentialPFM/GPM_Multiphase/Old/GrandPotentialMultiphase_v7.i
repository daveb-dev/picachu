#------------------------------------------------------------------------------#
#
#------------------------------------------------------------------------------#
[Mesh]
  type = GeneratedMesh
  dim = 2

  xmin = 0.0
  xmax = 3.0
  nx = 60

  ymin = 0.0
  ymax = 12.0
  ny = 240
[]


#------------------------------------------------------------------------------#
[GlobalParams]
  op_num = 2
  var_name_base = etab
[]


#------------------------------------------------------------------------------#
[Variables]
  [./w]
  [../]
  [./etaa0]
  [../]
  [./etab0]
  [../]
  [./etab1]
  [../]
[]


#------------------------------------------------------------------------------#
[AuxVariables]
  [./bnds]
    order = FIRST
    family = LAGRANGE
  [../]
[]


#------------------------------------------------------------------------------#
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
  [./IC_etab1]
    type = FunctionIC
    variable = etab1
    function = ic_func_etab1
  [../]
  [./IC_w]
    type = ConstantIC
    value = -0.05
    variable = w
  [../]
[]


#------------------------------------------------------------------------------#
[Functions]
  [./ic_func_etab0]
    type = ParsedFunction
    value = '(1/2)^2*(1.0-tanh((x-1.0)/0.1))*(1.0+tanh((-y+10.0)/0.1))'
  [../]
  [./ic_func_etab1]
    type = ParsedFunction
    value = '(1/2)^2*(1.0-tanh((-x+1.0)/0.1))*(1.0+tanh((-y+10.0)/0.1))'
  [../]
  [./ic_func_etaa0]
    type = ParsedFunction
    value = '1/2*(1.0+tanh((y-10.0)/0.1))'
  [../]
[]


#------------------------------------------------------------------------------#
[BCs]
[]


#------------------------------------------------------------------------------#
[Kernels]
# Order parameter eta_alpha0
  [./ACa0_bulk]
    type = ACGrGrMulti
    variable = etaa0
    v =           'etab0 etab1'
    gamma_names = 'gab   gab'
  [../]
  [./ACa0_sw]
    type = ACSwitching
    variable = etaa0
    Fj_names  = 'omegaa omegab'
    hj_names  = 'ha     hb'
    args = 'etab0 etab1 w'
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
    v =           'etaa0 etab1'
    gamma_names = 'gab   gbb'
  [../]
  [./ACb0_sw]
    type = ACSwitching
    variable = etab0
    Fj_names  = 'omegaa omegab'
    hj_names  = 'ha     hb'
    args = 'etaa0 etab1 w'
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
# Order parameter eta_beta1
  [./ACb1_bulk]
    type = ACGrGrMulti
    variable = etab1
    v =           'etaa0 etab0'
    gamma_names = 'gab   gbb'
  [../]
  [./ACb1_sw]
    type = ACSwitching
    variable = etab1
    Fj_names  = 'omegaa omegab'
    hj_names  = 'ha     hb'
    args = 'etaa0 etab0 w'
  [../]
  [./ACb1_int]
    type = ACInterface
    variable = etab1
    kappa_name = kappa
  [../]
  [./eb1_dot]
    type = TimeDerivative
    variable = etab1
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
    Fj_names = 'rhoa rhob'
    hj_names = 'ha   hb'
    args = 'etaa0 etab0 etab1'
  [../]
  [./coupled_etab0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etab0
    Fj_names = 'rhoa rhob'
    hj_names = 'ha   hb'
    args = 'etaa0 etab0 etab1'
  [../]
  [./coupled_etab1dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etab1
    Fj_names = 'rhoa rhob'
    hj_names = 'ha   hb'
    args = 'etaa0 etab0 etab1'
  [../]
[]


#------------------------------------------------------------------------------#
[AuxKernels]
  [./BndsCalc]
    type = BndsCalcAux
    variable = bnds
    execute_on = timestep_end
  [../]
[]


#------------------------------------------------------------------------------#
[Materials]
  [./ha]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = ha
    all_etas = 'etaa0 etab0 etab1'
    phase_etas = 'etaa0'
  [../]
  [./hb]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = hb
    all_etas = 'etaa0 etab0 etab1'
    phase_etas = 'etab0 etab1'
  [../]
  [./omegaa]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = omegaa
    material_property_names = 'Vm ka caeq'
    function = '-0.5*w^2/Vm^2/ka-w/Vm*caeq'
    derivative_order = 2
    enable_jit = false
  [../]
  [./omegab]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = omegab
    material_property_names = 'Vm kb cbeq'
    function = '-0.5*w^2/Vm^2/kb-w/Vm*cbeq'
    derivative_order = 2
    enable_jit = false
  [../]
  [./rhoa]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = rhoa
    material_property_names = 'Vm ka caeq'
    function = 'w/Vm^2/ka + caeq/Vm'
    derivative_order = 2
    enable_jit = false
  [../]
  [./rhob]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = rhob
    material_property_names = 'Vm kb cbeq'
    function = 'w/Vm^2/kb + cbeq/Vm'
    derivative_order = 2
    enable_jit = false
  [../]
  [./const]
    type = GenericConstantMaterial
    prop_names =  'kappa_c  kappa   L   D    chi  Vm   ka    caeq kb    cbeq  gab gbb mu'
    prop_values = '0        0.005    1.0 1.0  1.0  1.0  10.0  0.1  10.0  0.9   4.5 1.5 1.0'
  [../]
  [./Mobility]
    type = DerivativeParsedMaterial
    f_name = Dchi
    material_property_names = 'D chi'
    function = 'D*chi'
    derivative_order = 2
    enable_jit = false
  [../]
[]


#------------------------------------------------------------------------------#
[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]


#------------------------------------------------------------------------------#
[Executioner]
  type = Transient
  scheme = bdf2
  petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm      31                  lu           1'

  l_tol = 1.0e-3
  nl_rel_tol = 1.0e-8
  nl_abs_tol = 1e-8

  num_steps = 20

  [./TimeStepper]
    type = SolutionTimeAdaptiveDT
    dt = 0.1
  [../]
[]

#------------------------------------------------------------------------------#
[Postprocessors]
  # Stats
  [./dt]
    type = TimestepSize
  [../]
  [./alive_time]
    type = PerfGraphData
     data_type = TOTAL
     section_name = 'Root'
  [../]
  [./mem_usage]
    type = MemoryUsage
    mem_type = physical_memory
  [../]
[]

#------------------------------------------------------------------------------#
[Outputs]
  exodus = true
  csv = true
  file_base = ./results_GPM_v7/GPM_v7_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
[]

#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]
