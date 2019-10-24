[Mesh]
  type = GeneratedMesh
  dim = 3

  xmin = 0
  xmax = 10
  nx = 10

  ymin = 0
  ymax = 10
  ny = 10

  zmin = 0
  zmax = 2
  nz = 2

 uniform_refine = 2
  parallel_type = REPLICATED
  #skip_partitioning = false
[]
#------------------------------------------------------------------------------#
# [Problem]
#   type = FEProblem
#   coord_type = RZ
#   rz_coord_axis = Y
# []
#------------------------------------------------------------------------------#
[Variables]
  [./w_c]
  [../]
  [./w_o]
  [../]
  [./w_co]
  [../]

  #Phase alpha: carbon fiber
  [./etaa0]
  [../]
  #Phase beta: char
  [./etab0]
  [../]
[]

#------------------------------------------------------------------------------#
# Bnds stuff
[AuxVariables]
  [./bnds]
    order = FIRST
    family = LAGRANGE
  [../]

  # Auxiliary variables for Reaction_GPM kernel
  [./rho_c_var]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./rho_o_var]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./rho_co_var]
    family = MONOMIAL
    order = CONSTANT
  [../]
[]

[AuxKernels]
  [./BndsCalc]
    type = BndsCalcAux
    variable = bnds
    execute_on = timestep_end
    v = 'etaa0 etab0'
    var_name_base = 'eta'
  [../]

  [./rho_c_aux]
    type = MaterialRealAux
    property = 'rho_c'
    variable = rho_c_var
  [../]
  [./rho_o_aux]
    type = MaterialRealAux
    property = 'rho_o'
    variable = rho_o_var
  [../]
  [./rho_co_aux]
    type = MaterialRealAux
    property = 'rho_co'
    variable = rho_co_var
  [../]
[]



#------------------------------------------------------------------------------#
[ICs]
  # [./IC_etaa0]
  #   type = FunctionIC
  #   variable = etaa0
  #   function = ic_func_etaa0
  # [../]
  # [./IC_etab0]
  #   type = FunctionIC
  #   variable = etab0
  #   function = ic_func_etab0
  # [../]
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
  [./IC_w_co]
    type = ConstantIC
    variable = w_co
    value = 0.0
  [../]

  [./IC_circ_a]
    type = SpecifiedSmoothCircleIC
    radii = 3
    3D_spheres = false
    invalue = 1
    outvalue = 0
    profile = TANH
    variable = etaa0
    x_positions = 5
    y_positions = 5
    z_positions = 0
    int_width = 0.2
  [../]

  [./IC_circ_b]
    type = SpecifiedSmoothCircleIC
    radii = 3
    3D_spheres = false
    invalue = 0
    outvalue = 1
    profile = TANH
    variable = etab0
    x_positions = 5
    y_positions = 5
    z_positions = 0
    int_width = 0.2
  [../]
[]


#------------------------------------------------------------------------------#
[Functions]
  [./ic_func_etaa0]
    type = ParsedFunction
    value = 'int_thick:=0.2; 0.5*(1.0+tanh(pi*(-y+5.0)/int_thick))'
  [../]
  [./ic_func_etab0]
    type = ParsedFunction
    value = 'int_thick:=0.2; 0.5*(1.0+tanh(pi*(y-5.0)/int_thick))'
  [../]
[]

#------------------------------------------------------------------------------#
[Kernels]
  # Chemical reaction
  [./Recomb_C]
    type = Reaction_GPM
    mob_name = K_neg
    atomic_vol = Va
    variable = w_c
    v = 'rho_c_var'
    w = 'rho_o_var'
    args = 'etaa0 etab0'
  [../]

  [./Recomb_O]
    type = Reaction_GPM
    mob_name = K_neg
    atomic_vol = Va
    variable = w_o
    v = 'rho_o_var'
    w = 'rho_c_var'
    args = 'etaa0 etab0'
  [../]

  [./Production_CO]
    type = Reaction_GPM
    mob_name = K_pos
    atomic_vol = Va
    variable = w_co
    v = 'rho_c_var'
    w = 'rho_o_var'
    args = 'etaa0 etab0'
  [../]

  #----------------------------------------------------------------------------#
  # etaa0 kernels
  [./ACa0_bulk]
    type = ACGrGrMulti
    variable = etaa0
    v =           'etab0'
    gamma_names = 'gab'
    mob_name = L
  [../]

  [./ACa0_sw]
    type = ACSwitching
    variable = etaa0
    Fj_names  = 'omega_a omega_b'
    hj_names  = 'h_a     h_b'
    args = 'etab0 w_c w_o w_co'
    mob_name = L
  [../]

  [./ACa0_int]
    type = ACInterface
    variable = etaa0
    kappa_name = kappa
    mob_name = L
    args = 'etab0'
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
    v =           'etaa0'
    gamma_names = 'gab'
    mob_name = L
  [../]

  [./ACb0_sw]
    type = ACSwitching
    variable = etab0
    Fj_names  = 'omega_a omega_b'
    hj_names  = 'h_a     h_b'
    args = 'etaa0 w_c w_o w_co'
    mob_name = L
  [../]

  [./ACb0_int]
    type = ACInterface
    variable = etab0
    kappa_name = kappa
    mob_name = L
    args = 'etaa0'
  [../]

  [./etab0_dot]
    type = TimeDerivative
    variable = etab0
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
    diffusivity = Dchi_c
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
    diffusivity = Dchi_o
    args = ''
  [../]

  #----------------------------------------------------------------------------#
  # Carbon Monoxide
  [./w_co_dot]
    type = SusceptibilityTimeDerivative
    variable = w_co
    f_name = chi_co
    args = '' # in this case chi (the susceptibility) is simply a constant
  [../]

  [./diffusion_co]
    type = MatDiffusion
    variable = w_co
    diffusivity = Dchi_co
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
    Fj_names = 'rho_c_a rho_c_b'
    hj_names = 'h_a   h_b'
    args = 'etaa0 etab0 w_o w_co'
  [../]

  [./coupled_etab0dot_c]
    type = CoupledSwitchingTimeDerivative
    variable = w_c
    v = etab0
    Fj_names = 'rho_c_a rho_c_b'
    hj_names = 'h_a   h_b'
    args = 'etaa0 etab0 w_o w_co'
  [../]

  #----------------------------------------------------------------------------#
  # Oxygen
  [./coupled_etaa0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = etaa0
    Fj_names = 'rho_o_a rho_o_b'
    hj_names = 'h_a   h_b'
    args = 'etaa0 etab0 w_c w_co'
  [../]

  [./coupled_etab0dot_o]
    type = CoupledSwitchingTimeDerivative
    variable = w_o
    v = etab0
    Fj_names = 'rho_o_a rho_o_b'
    hj_names = 'h_a   h_b'
    args = 'etaa0 etab0 w_c w_co'
  [../]

  #----------------------------------------------------------------------------#
  # Oxygen
  [./coupled_etaa0dot_co]
    type = CoupledSwitchingTimeDerivative
    variable = w_co
    v = etaa0
    Fj_names = 'rho_co_a rho_co_b'
    hj_names = 'h_a   h_b'
    args = 'etaa0 etab0 w_c w_o'
  [../]

  [./coupled_etab0dot_co]
    type = CoupledSwitchingTimeDerivative
    variable = w_co
    v = etab0
    Fj_names = 'rho_co_a rho_co_b'
    hj_names = 'h_a   h_b'
    args = 'etaa0 etab0 w_c w_o'
  [../]

[]
#----------------------------------------------------------------------------#
# END OF KERNELS


#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  # Switching functions
  [./switch_a]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_a
    all_etas = 'etaa0 etab0'
    phase_etas = 'etaa0'

    outputs = exodus
    output_properties = h_a
  [../]

  [./switch_b]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_b
    all_etas = 'etaa0 etab0'
    phase_etas = 'etab0'

    outputs = exodus
    output_properties = h_b
  [../]

  #----------------------------------------------------------------------------#
  # Grand potential densities
  [./omega_a]
    type = DerivativeParsedMaterial
    f_name = omega_a
    args = 'w_c w_o w_co'

    function = '-0.5*w_c^2/(Va^2 *A_c_a) - xeq_c_a*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_a) - xeq_o_a*w_o/Va
                -0.5*w_co^2/(Va^2 *A_co_a) - xeq_co_a*w_co/Va'

    material_property_names = 'Va A_c_a A_o_a A_co_a xeq_c_a xeq_o_a xeq_co_a'

    derivative_order = 2
    outputs = exodus
    output_properties = omega_a
  [../]

  [./omega_b]
    type = DerivativeParsedMaterial
    f_name = omega_b

    args = 'w_c w_o w_co'

    function = '-0.5*w_c^2/(Va^2 *A_c_b) - xeq_c_b*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_b) - xeq_o_b*w_o/Va
                -0.5*w_co^2/(Va^2 *A_co_b) - xeq_co_b*w_co/Va'

    material_property_names = 'Va A_c_b A_o_b A_co_b xeq_c_b xeq_o_b xeq_co_b'

    derivative_order = 2
    outputs = exodus
    output_properties = omega_b
  [../]

  [./omega]
    type = DerivativeParsedMaterial
    f_name = omega
    args = 'etaa0 etab0'

    function = 'h_a*omega_a + h_b*omega_b'

    material_property_names = 'h_a h_b omega_a omega_b'

    outputs = exodus
    output_properties = omega
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

  [./rho_c]
    type = DerivativeParsedMaterial
    f_name = rho_c
    args = 'w_c etaa0 etab0'

    function = 'h_a*rho_c_a + h_b*rho_c_b'

    material_property_names = 'h_a h_b rho_c_a rho_c_b'

    outputs = exodus
    output_properties = rho_c
  [../]

  [./x_c]
    type = DerivativeParsedMaterial
    f_name = x_c
    args = 'w_c etaa0 etab0'

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

  [./rho_o]
    type = DerivativeParsedMaterial
    f_name = rho_o
    args = 'w_o etaa0 etab0'

    function = 'h_a*rho_o_a + h_b*rho_o_b'

    material_property_names = 'h_a h_b rho_o_a rho_o_b'

    outputs = exodus
    output_properties = rho_o
  [../]

  [./x_o]
    type = DerivativeParsedMaterial
    f_name = x_o
    args = 'w_o etaa0 etab0'

    function = 'Va*rho_o'

    material_property_names = 'Va rho_o'

    outputs = exodus
    output_properties = x_o
  [../]

  #----------------------------------------------------------------------------#
  # CARBON MONOXIDE
  [./rho_co_a]
    type = DerivativeParsedMaterial
    f_name = rho_co_a
    args = 'w_co'

    function = 'w_co/(A_co_a*Va^2) + xeq_co_a/Va'

    material_property_names = 'Va A_co_a xeq_co_a'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_co_a
  [../]

  [./rho_co_b]
    type = DerivativeParsedMaterial
    f_name = rho_co_b
    args = 'w_co'

    function = 'w_co/(A_co_b*Va^2) + xeq_co_b/Va'

    material_property_names = 'Va A_co_b xeq_co_b'

    derivative_order = 2
    outputs = exodus
    output_properties = rho_co_b
  [../]

  [./rho_co]
    type = DerivativeParsedMaterial
    f_name = rho_co
    args = 'w_co etaa0 etab0'

    function = 'h_a*rho_co_a + h_b*rho_co_b'

    material_property_names = 'h_a h_b rho_co_a rho_co_b'

    outputs = exodus
    output_properties = rho_co
  [../]

  [./x_co]
    type = DerivativeParsedMaterial
    f_name = x_co
    args = 'w_co etaa0 etab0'

    function = 'Va*rho_co'

    material_property_names = 'Va rho_co'

    outputs = exodus
    output_properties = x_co
  [../]

  #----------------------------------------------------------------------------#
  # Reaction rate constants
  [./phase_mobility]
    type = GenericConstantMaterial

    prop_names = 'L'
    prop_values = '1'

    outputs = exodus
    output_properties = L
  [../]

  #----------------------------------------------------------------------------#
  # Reaction rate constants
  [./reaction_rates]
    type = GenericConstantMaterial

    prop_names = 'K_neg   K_pos'
    prop_values = '-1     1'

    outputs = exodus
    output_properties = 'K_neg K_pos'
  [../]


  #----------------------------------------------------------------------------#
  # Constant parameters
  [./constants]
    type = GenericConstantMaterial
    prop_names =  'kappa  Va'
    prop_values = '0.01   1.0'
    outputs = exodus
  [../]

  [./gammas]
    # Future work: how to make these parameters realistic
    type = GenericConstantMaterial
    prop_names  = 'gab     mu'
    prop_values = '1.0     1.0'
    outputs = exodus
  [../]

  [./params_carbon]
    type = GenericConstantMaterial
    prop_names  = 'A_c_a    xeq_c_a
                   A_c_b    xeq_c_b'
    prop_values = '34       0.97
                   100      0'

    outputs = exodus
  [../]

  [./params_oxygen]
    type = GenericConstantMaterial
    prop_names  = 'A_o_a    xeq_o_a
                   A_o_b    xeq_o_b'
    prop_values = '10       0
                   10       0.99'

    outputs = exodus
  [../]

  [./params_co]
    type = GenericConstantMaterial
    prop_names  = 'A_co_a    xeq_co_a
                   A_co_b    xeq_co_b'
    prop_values = '10       0
                   10       0.01'

    outputs = exodus
  [../]

  # Diffusivities
  #----------------------------------------------------------------------------#
  # CARBON
  [./diff_c]
    type = DerivativeParsedMaterial
    f_name = D_c
    args = 'etaa0 etab0'
    material_property_names = 'h_a h_b'
    function = '(h_a*1e-10 + h_b*1)'

    outputs = exodus
    output_properties = D_c
  [../]

  [./chi_c]
    type = DerivativeParsedMaterial
    f_name = chi_c

    function = '(h_a/A_c_a + h_b/A_c_b) / Va^2'

    material_property_names = 'Va h_a A_c_a h_b A_c_b'

    derivative_order = 2
    outputs = exodus
    output_properties = chi_c
  [../]

  [./mob_c]
    type = DerivativeParsedMaterial
    f_name = Dchi_c
    material_property_names = 'D_c chi_c'
    function = 'D_c*chi_c'
    derivative_order = 2

    outputs = exodus
    output_properties = Dchi_c
  [../]


  #----------------------------------------------------------------------------#
  # OXYGEN
  [./diff_o]
    type = DerivativeParsedMaterial
    f_name = D_o
    args = 'etaa0 etab0'
    material_property_names = 'h_a h_b'

    function = '(h_a*1e-10 + h_b*1)'

    outputs = exodus
    output_properties = D_o
  [../]

  [./chi_o]
    type = DerivativeParsedMaterial
    f_name = chi_o

    function = '(h_a/A_o_a + h_b/A_o_b) / Va^2'

    material_property_names = 'Va h_a A_o_a h_b A_o_b'

    derivative_order = 2
    outputs = exodus
    output_properties = chi_o
  [../]

  [./mob_o]
    type = DerivativeParsedMaterial
    f_name = Dchi_o
    material_property_names = 'D_o chi_o'
    function = 'D_o*chi_o'
    derivative_order = 2

    outputs = exodus
    output_properties = Dchi_o
  [../]


  #----------------------------------------------------------------------------#
  # CARBON MONOXIDE
  [./diff_co]
    type = DerivativeParsedMaterial
    f_name = D_co
    args = 'etaa0 etab0'
    material_property_names = 'h_a h_b'

    function = '(h_a*1e-10 + h_b*1)'

    outputs = exodus
    output_properties = D_co
  [../]

  [./chi_co]
    type = DerivativeParsedMaterial
    f_name = chi_co

    function = '(h_a/A_co_a + h_b/A_co_b) / Va^2'

    material_property_names = 'Va h_a A_co_a h_b A_co_b'

    derivative_order = 2
    outputs = exodus
    output_properties = chi_co
  [../]

  [./mob_co]
    type = DerivativeParsedMaterial
    f_name = Dchi_co
    material_property_names = 'D_co chi_co'
    function = 'D_co*chi_co'
    derivative_order = 2

    outputs = exodus
    output_properties = Dchi_co
  [../]


  #----------------------------------------------------------------------------#
  [./sum_eta]
    type = DerivativeParsedMaterial
    f_name = sum_eta
    args = 'etaa0 etab0'
    function = 'etaa0 + etab0'
    outputs = exodus
    output_properties = sum_eta
  [../]
[]
# End of Materials

#------------------------------------------------------------------------------#
[BCs]
  [./oxygen]
    type = PresetBC
    boundary = 'top bottom right left'
    variable = 'w_o'
    value = '0'
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
  end_time = 100

  [./Predictor]
    type = SimplePredictor
    scale = 1
  [../]

  # [./Adaptivity]
  #   initial_adaptivity = 2
  #   max_h_level = 2
  #   refine_fraction = 0.9
  #   coarsen_fraction = 0.1
  # [../]

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
[VectorPostprocessors]
  [./grain_volumes]
    type = FeatureVolumeVectorPostprocessor
    flood_counter = grain_tracker
    single_feature_per_element = true
    execute_on = 'INITIAL TIMESTEP_END FINAL'
    outputs = none
  [../]
  [./feature_volumes]
    type = FeatureVolumeVectorPostprocessor
    flood_counter = feature_counter
    execute_on = 'INITIAL TIMESTEP_END FINAL'
    outputs = none
  [../]
  [./line]
    type = LineValueSampler
    num_points  = 400
    start_point = '5.0 0.0 1.0'
    end_point   = '5.0 10.0 1.0'
    variable    = etaa0
    sort_by     = y
    execute_on  = 'INITIAL TIMESTEP_END FINAL'
    outputs     = vector
  [../]
[]

#------------------------------------------------------------------------------#
[Postprocessors]
  [./feature_counter]
    type = FeatureFloodCount
    variable = etaa0
    compute_var_to_feature_map = true
    execute_on = 'INITIAL TIMESTEP_END FINAL'
    outputs = none
  [../]
  [./volume]
    type = VolumePostprocessor
    execute_on = 'initial'
    outputs = none
  [../]
  [./volume_solid]
    type = FeatureVolumeFraction
    mesh_volume = volume
    feature_volumes = feature_volumes
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]
  [./grain_tracker]
    type = GrainTracker
    variable = 'etaa0 etab0'
    threshold = 0.1
    compute_var_to_feature_map = true
    execute_on = 'initial'
    outputs = none
  [../]

  [./total_carbon_solid]
    type = ElementIntegralMaterialProperty
    mat_prop = rho_c_a
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]
  [./total_carbon_gas]
    type = ElementIntegralMaterialProperty
    mat_prop = rho_c_b
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]

  [./total_oxygen_solid]
    type = ElementIntegralMaterialProperty
    mat_prop = rho_o_a
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]
  [./total_oxygen_gas]
    type = ElementIntegralMaterialProperty
    mat_prop = rho_o_b
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]

  [./total_co_solid]
    type = ElementIntegralMaterialProperty
    mat_prop = rho_co_a
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]
  [./total_co_gas]
    type = ElementIntegralMaterialProperty
    mat_prop = rho_co_b
    execute_on = 'INITIAL TIMESTEP_END FINAL'
  [../]


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
  [./exodus]
    type = Exodus
    execute_on = 'INITIAL TIMESTEP_END'
    file_base = ./results/moose3D_out
  [../]

  [./csv]
    type = CSV
    execute_on = 'INITIAL TIMESTEP_END'
    file_base = ./results/moose3D_out
  [../]

   [./vector]
     type = CSV
     execute_on = 'INITIAL FINAL'
     file_base = ./results/moose3D_vector_out
   [../]
[]


#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]
