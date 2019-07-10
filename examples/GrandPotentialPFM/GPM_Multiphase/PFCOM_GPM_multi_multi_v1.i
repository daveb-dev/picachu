#------------------------------------------------------------------------------#
# 3-phase GPM simulation
# Carbon and oxygen at equilibrium: working
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

  uniform_refine = 1
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w_c]
  [../]
  [./w_o]
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
#Bnds stuff
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
  [./IC_w_c]
    type = ConstantIC
    variable = w_c
    value = 0.0
  [../]
  [./IC_w_o]
    type = ConstantIC
    variable = w_o
    value = 0.0
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
    args = 'etab0 etag0 w_c w_o'
  [../]

  [./ACa0_int]
    type = ACInterface
    variable = etaa0
    kappa_name = kappa
  [../]

  [./etaa0_dot]
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
    args = 'etaa0 etag0 w_c w_o'
  [../]

  [./ACb0_int]
    type = ACInterface
    variable = etab0
    kappa_name = kappa
  [../]

  [./etab0_dot]
    type = TimeDerivative
    variable = etab0
  [../]

  #----------------------------------------------------------------------------#
  # etag0 kernels
  [./ACg0_bulk]
    type = ACGrGrMulti
    variable = etag0
    v =           'etaa0 etab0'
    gamma_names = 'gag   gbg'
  [../]

  [./ACg0_sw]
    type = ACSwitching
    variable = etag0
    Fj_names  = 'omega_a omega_b omega_g'
    hj_names  = 'h_a     h_b     h_g'
    args = 'etaa0 etab0 w_c w_o'
  [../]

  [./ACg0_int]
    type = ACInterface
    variable = etag0
    kappa_name = kappa
  [../]

  [./etag0_dot]
    type = TimeDerivative
    variable = etag0
  [../]

  #----------------------------------------------------------------------------#
  # Chemical potential kernels
  #----------------------------------------------------------------------------#
  # Carbon
  [./w_c_dot]
    type = SusceptibilityTimeDerivative
    variable = w_c
    f_name = chi_c
    args = '' # in this case chi (the susceptibility) is simply a constant
  [../]

  [./diffusion_c]
    type = MatDiffusion
    variable = w_c
    D_name = Dchi_c
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Oxygen
  [./w_o_dot]
    type = SusceptibilityTimeDerivative
    variable = w_o
    f_name = chi_o
    args = '' # in this case chi (the susceptibility) is simply a constant
  [../]

  [./diffusion_o]
    type = MatDiffusion
    variable = w_o
    D_name = Dchi_o
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Coupled kernels
  #----------------------------------------------------------------------------#
  # Carbon
  [./coupled_etaa0dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = etaa0
    Fj_names = 'rho_c_a rho_c_b rho_c_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o'
  [../]

  [./coupled_etab0dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = etab0
    Fj_names = 'rho_c_a rho_c_b rho_c_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o'
  [../]

  [./coupled_etag0dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = etag0
    Fj_names = 'rho_c_a rho_c_b rho_c_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_o'
  [../]

  #----------------------------------------------------------------------------#
  # Oxygen
  [./coupled_etaa0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = etaa0
    Fj_names = 'rho_o_a rho_o_b rho_o_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_c'
  [../]

  [./coupled_etab0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = etab0
    Fj_names = 'rho_o_a rho_o_b rho_o_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_c'
  [../]

  [./coupled_etag0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = etag0
    Fj_names = 'rho_o_a rho_o_b rho_o_g'
    hj_names = 'h_a   h_b   h_g'
    args = 'etaa0 etab0 etag0 w_c'
  [../]

  #----------------------------------------------------------------------------#
  # END OF KERNELS
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
    f_name = omega_a
    args = 'w_c w_o'

    function = '-0.5*w_c^2/(Va^2 *A_c_a) - xeq_c_a*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_a) - xeq_o_a*w_o/Va'

    material_property_names = 'Va A_c_a A_o_a xeq_c_a xeq_o_a'

    derivative_order = 2
    outputs = exodus
    output_properties = omega_a
  [../]

  [./omega_b]
    type = DerivativeParsedMaterial
    f_name = omega_b

    args = 'w_c w_o'

    function = '-0.5*w_c^2/(Va^2 *A_c_b) - xeq_c_b*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_b) - xeq_o_b*w_o/Va'

    material_property_names = 'Va A_c_b A_o_b xeq_c_b xeq_o_b'

    derivative_order = 2
    outputs = exodus
    output_properties = omega_b
  [../]

  [./omega_g]
    type = DerivativeParsedMaterial
    f_name = omega_g

    args = 'w_c w_o'

    function = '-0.5*w_c^2/(Va^2 *A_c_g) - xeq_c_g*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_g) - xeq_o_g*w_o/Va'

    material_property_names = 'Va A_c_g A_o_g xeq_c_g xeq_o_g'

    derivative_order = 2
    outputs = exodus
    output_properties = omega_g
  [../]

  #----------------------------------------------------------------------------#
  # CARBON
  [./rho_c_a]
    type = DerivativeParsedMaterial
    f_name = rho_c_a
    args = 'w_c'

    function = 'w_c/(A_c_a*Va^2) + xeq_c_a/Va'

    material_property_names = 'Va A_c_a xeq_c_a'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_c_a
  [../]

  [./rho_c_b]
    type = DerivativeParsedMaterial
    f_name = rho_c_b
    args = 'w_c'

    function = 'w_c/(A_c_b*Va^2) + xeq_c_b/Va'

    material_property_names = 'Va A_c_b xeq_c_b'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_c_b
  [../]

  [./rho_c_g]
    type = DerivativeParsedMaterial
    f_name = rho_c_g
    args = 'w_c'

    function = 'w_c/(A_c_g*Va^2) + xeq_c_g/Va'

    material_property_names = 'Va A_c_g xeq_c_g'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_c_g
  [../]

  [./rho_c]
    type = DerivativeParsedMaterial
    f_name = rho_c
    args = 'w_c etaa0 etab0 etag0'

    function = 'h_a*rho_c_a + h_b*rho_c_b + h_g*rho_c_g'

    material_property_names = 'h_a h_b h_g rho_c_a rho_c_b rho_c_g'

    outputs = exodus
    output_properties = rho_c
  [../]

  [./x_c]
    type = DerivativeParsedMaterial
    f_name = x_c
    args = 'w_c etaa0 etab0 etag0'

    function = 'Va*rho_c'

    material_property_names = 'Va rho_c'

    outputs = exodus
    output_properties = x_c
  [../]

  #----------------------------------------------------------------------------#
  # OXYGEN
  [./rho_o_a]
    type = DerivativeParsedMaterial
    f_name = rho_o_a
    args = 'w_o'

    function = 'w_o/(A_o_a*Va^2) + xeq_o_a/Va'

    material_property_names = 'Va A_o_a xeq_o_a'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_o_a
  [../]

  [./rho_o_b]
    type = DerivativeParsedMaterial
    f_name = rho_o_b
    args = 'w_o'

    function = 'w_o/(A_o_b*Va^2) + xeq_o_b/Va'

    material_property_names = 'Va A_o_b xeq_o_b'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_o_b
  [../]

  [./rho_o_g]
    type = DerivativeParsedMaterial
    f_name = rho_o_g
    args = 'w_o'

    function = 'w_o/(A_o_g*Va^2) + xeq_o_g/Va'

    material_property_names = 'Va A_o_g xeq_o_g'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_o_g
  [../]

  [./rho_o]
    type = DerivativeParsedMaterial
    f_name = rho_o
    args = 'w_o etaa0 etab0 etag0'

    function = 'h_a*rho_o_a + h_b*rho_o_b + h_g*rho_o_g'

    material_property_names = 'h_a h_b h_g rho_o_a rho_o_b rho_o_g'

    outputs = exodus
    output_properties = rho_o
  [../]

  [./x_o]
    type = DerivativeParsedMaterial
    f_name = x_o
    args = 'w_o etaa0 etab0 etag0'

    function = 'Va*rho_o'

    material_property_names = 'Va rho_o'

    outputs = exodus
    output_properties = x_o
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

  [./params_carbon]
    type = GenericConstantMaterial
    prop_names  = 'A_c_a    xeq_c_a
                   A_c_b    xeq_c_b
                   A_c_g    xeq_c_g'
    prop_values = '34.535   0.9
                   10.0     0.7
                   100.0    0.1'
  [../]

  [./params_oxygen]
    type = GenericConstantMaterial
    prop_names  = 'A_o_a    xeq_o_a
                   A_o_b    xeq_o_b
                   A_o_g    xeq_o_g'
    prop_values = '1e4      0.1
                   10.0     0.3
                   10.0     0.9'
  [../]

  [./chi_c]
    type = DerivativeParsedMaterial
    f_name = chi_c

    function = '(h_a/A_c_a + h_b/A_c_b + h_g/A_c_g) / Va^2'

    material_property_names = 'Va h_a A_c_a h_b A_c_b h_g A_c_g'

    derivative_order = 2
    outputs = exodus
    output_properties = chi_c
  [../]

  [./chi_o]
    type = DerivativeParsedMaterial
    f_name = chi_o

    function = '(h_a/A_o_a + h_b/A_o_b + h_g/A_o_g) / Va^2'

    material_property_names = 'Va h_a A_o_a h_b A_o_b h_g A_o_g'

    derivative_order = 2
    outputs = exodus
    output_properties = chi_o
  [../]

  # Diffusivities
    [./diff_c]
      type = DerivativeParsedMaterial
      f_name = D_c
      args = 'etaa0 etab0 etag0'
      material_property_names = 'h_a h_b h_g'
      function = '(h_a*0.1 + h_b*0.1 +h_g*10)'

      outputs = exodus
      output_properties = D_c
    [../]

    [./diff_o]
      type = DerivativeParsedMaterial
      f_name = D_o
      args = 'etaa0 etab0 etag0'
      material_property_names = 'h_a h_b h_g'
      function = '(h_a*0.1 + h_b*0.1 +h_g*10)'

      outputs = exodus
      output_properties = D_o
    [../]

    [./mob_c]
      type = DerivativeParsedMaterial
      f_name = Dchi_c
      material_property_names = 'D_c chi_c'
      function = 'D_c*chi_c'
      derivative_order = 2
      #outputs = exodus
    [../]

    [./mob_o]
      type = DerivativeParsedMaterial
      f_name = Dchi_o
      material_property_names = 'D_o chi_o'
      function = 'D_o*chi_o'
      derivative_order = 2
      #outputs = exodus
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

  [./Predictor]
    type = SimplePredictor
    scale = 1
  [../]

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.1
    growth_factor = 1.2
    cutback_factor = 0.8
    optimal_iterations = 12
    iteration_window = 0
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
  #file_base = ./results/GPM_vx_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
[]


#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]
