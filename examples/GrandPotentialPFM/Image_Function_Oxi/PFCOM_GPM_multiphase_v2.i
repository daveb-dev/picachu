#------------------------------------------------------------------------------#
# 3-phase GPM simulation
# Initial condition
#------------------------------------------------------------------------------#
[Mesh]
  type = GeneratedMesh
  dim = 2

  xmin = 0
  xmax = 3
  nx = 30

  ymin = 0
  ymax = 12
  ny = 120

  uniform_refine = 2
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w]
  [../]
  #Phase alpha: carbon fiber
  [./etaa0]
  [../]
  #Phase beta: char
  [./etab0]
  [../]
  #Phase gamma: gas
  [./etag0]
  [../]
[]

#------------------------------------------------------------------------------#
# Bnds stuff
[AuxVariables]
  [./bnds]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[AuxKernels]
  [./BndsCalc]
    type = BndsCalcAux
    variable = bnds
    execute_on = timestep_end
    v = 'etaa0 etab0 etag0'
    var_name_base = 'eta'
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
  [./IC_etag0]
    type = FunctionIC
    variable = etag0
    function = ic_func_etag0
  [../]
  [./IC_w]
    type = ConstantIC
    variable = w
    value = 0
  [../]
[]


#------------------------------------------------------------------------------#
[Functions]
  [./ic_func_etaa0]
    type = ParsedFunction
    value = 'int_thick:=0.3; 0.5^2*(1.0-tanh(pi*(x-1.0)/int_thick))*(1.0+tanh(pi*(-y+10.0)/int_thick))'
  [../]
  [./ic_func_etab0]
    type = ParsedFunction
    value = 'int_thick:=0.3; 0.5^2*(1.0+tanh(pi*(x-1.0)/int_thick))*(1.0+tanh(pi*(-y+10.0)/int_thick))'
  [../]
  [./ic_func_etag0]
    type = ParsedFunction
    value = 'int_thick:=0.3; 0.5*(1.0+tanh(pi*(y-10.0)/int_thick))'
  [../]
[]


#------------------------------------------------------------------------------#
[Kernels]
  #----------------------------------------------------------------------------#
  # etaa0 kernels
  [./ACa0_bulk]
    type = ACGrGrMulti
    variable = etaa0
    v =           'etab0 etag0'
    gamma_names = 'gab   gag'
  [../]

  [./ACa0_sw]
    type = ACSwitching
    variable = etaa0
    Fj_names  = 'omega_a omega_b omega_g'
    hj_names  = 'h_a     h_b     h_g'
    args = 'etab0 etag0 w'
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

  #----------------------------------------------------------------------------#
  # etab0 kernels
  [./ACb0_bulk]
    type = ACGrGrMulti
    variable = etab0
    v =           'etaa0 etag0'
    gamma_names = 'gab   gbg'
  [../]

  [./ACb0_sw]
    type = ACSwitching
    variable = etab0
    Fj_names  = 'omega_a omega_b omega_g'
    hj_names  = 'h_a     h_b     h_g'
    args = 'etaa0 etag0 w'
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

  #----------------------------------------------------------------------------#
  # etag0 kernels
  [./ACd0_bulk]
    type = ACGrGrMulti
    variable = etag0
    v =           'etaa0 etab0'
    gamma_names = 'gag   gbg'
  [../]

  [./ACd0_sw]
    type = ACSwitching
    variable = etag0
    Fj_names  = 'omega_a omega_b omega_g'
    hj_names  = 'h_a     h_b     h_g'
    args = 'etaa0 etab0 w'
  [../]

  [./ACd0_int]
    type = ACInterface
    variable = etag0
    kappa_name = kappa
  [../]

  [./ed0_dot]
    type = TimeDerivative
    variable = etag0
  [../]

  #----------------------------------------------------------------------------#
  # Chemical potential kernels
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

  #----------------------------------------------------------------------------#
  # Coupled kernels
  [./coupled_etaa0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etaa0
    Fj_names = 'rho_a rho_b rho_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0'
  [../]

  [./coupled_etab0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etab0
    Fj_names = 'rho_a rho_b rho_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0'
  [../]

  [./coupled_etag0dot]
    type = CoupledSwitchingTimeDerivative
    variable = w
    v = etag0
    Fj_names = 'rho_a rho_b rho_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0'
  [../]
[]


#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  # Switching functions
  # Phase alpha: fiber
  [./switch_a]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_a
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etaa0'

    outputs = exodus
    output_properties = h_a
  [../]

  # Phase beta: char
  [./switch_b]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_b
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etab0'

    outputs = exodus
    output_properties = h_b
  [../]

  # Phase gamma: gas
  [./switch_g]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_g
    all_etas = 'etaa0 etab0 etag0'
    phase_etas = 'etag0'

    outputs = exodus
    output_properties = h_g
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential densities
  [./omega_a]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = omega_a

    material_property_names = 'Va Aa xeq_a'
    function = '-0.5*w^2/Va^2/Aa - w/Va*xeq_a'

    derivative_order = 2

    outputs = exodus
    output_properties = omega_a
  [../]

  [./omega_b]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = omega_b

    material_property_names = 'Va Ab xeq_b'
    function = '-0.5*w^2/Va^2/Ab-w/Va*xeq_b'

    derivative_order = 2

    outputs = exodus
    output_properties = omega_b
  [../]

  [./omega_g]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = omega_g

    material_property_names = 'Va Ag xeq_g'
    function = '-0.5*w^2/Va^2/Ag-w/Va*xeq_g'

    derivative_order = 2

    outputs = exodus
    output_properties = omega_g
  [../]

  #----------------------------------------------------------------------------#
  # Number densities
  [./rho_a]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = rho_a
    material_property_names = 'Va Aa xeq_a'
    function = 'w/Va^2/Aa + xeq_a/Va'
    derivative_order = 2

    outputs = exodus
    output_properties = rho_a
  [../]

  [./rho_b]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = rho_b
    material_property_names = 'Va Ab xeq_b'
    function = 'w/Va^2/Ab + xeq_b/Va'
    derivative_order = 2

    outputs = exodus
    output_properties = rho_b
  [../]

  [./rho_g]
    type = DerivativeParsedMaterial
    args = 'w'
    f_name = rho_g
    material_property_names = 'Va Ag xeq_g'
    function = 'w/Va^2/Ag + xeq_g/Va'
    derivative_order = 2

    outputs = exodus
    output_properties = rho_g
  [../]

  #----------------------------------------------------------------------------#
  # Overall concetration
  [./c]
    type = ParsedMaterial
    material_property_names = 'Va rho_a rho_b rho_g h_a h_b h_g'
    function = 'Va * (h_a * rho_a + h_b * rho_b + h_g * rho_g)'
    f_name = c
    outputs = exodus
  [../]

  #----------------------------------------------------------------------------#
  # Constant parameters
  [./constants]
    # kappa and L doing fine so far
    # Fix D according to carbon
    type = GenericConstantMaterial
    prop_names =  'kappa     L       D       Va'
    prop_values = '0.01      0.01    1.0     1.0'
    #outputs = exodus
  [../]

  [./gammas]
    # Future work: how to make these parameters realistic
    type = GenericConstantMaterial
    prop_names  = 'gab    gag     gbg     mu'
    prop_values = '1.5    1.5     1.5     1.0'
  [../]

  [./carbon_params]
    type = GenericConstantMaterial
    prop_names  = 'Aa       xeq_a    Ab      xeq_b     Ag       xeq_g'
    prop_values = '34.535   0.9      10.0    0.7       100.0    0.1'
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
    # Not sure why, but I kept this way because it works
    type = DerivativeParsedMaterial
    f_name = chi
    material_property_names = 'Va h_a Aa h_b Ab h_g Ag'
    function = '(h_a/Aa + h_b/Ab + h_g/Ag) / Va^2'
    derivative_order = 2
    outputs = exodus
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
  # Preconditioned JFNK (default)
  type = Transient

  scheme = bdf2
  #solve_type = NEWTON
  solve_type = PJFNK
  petsc_options_iname = -pc_type
  petsc_options_value = asm

  nl_max_its = 15
  nl_abs_tol = 1e-10
  nl_rel_tol = 1.0e-8

  l_max_its = 15
  l_tol = 1.0e-3

  start_time = 0.0
  num_steps = 20

  dt = 1.0

  # [./TimeStepper]
  #   type = IterationAdaptiveDT
  #   dt = 1.0
  #   optimal_iterations = 8
  #   iteration_window = 2
  # [../]
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
  #file_base = ./results/GPM_vx_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
[]


#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]
