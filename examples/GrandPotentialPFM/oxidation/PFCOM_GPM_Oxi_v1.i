#------------------------------------------------------------------------------#
# PFCOM using the grand potential model
# Using function IC for a hyperbolic tangent profile
# Added oxygen
#------------------------------------------------------------------------------#
[Mesh]
  # length scale -> microns
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
[Problem]
  type = FEProblem
  coord_type = RZ
  rz_coord_axis = Y
[]

#------------------------------------------------------------------------------#
# Coordinates for bounding box IC
[GlobalParams]
[]

#------------------------------------------------------------------------------#
[Variables]
  [./w_c]
  [../]
  [./w_o]
  [../]
  [./eta0]
  [../]
  [./eta1]
  [../]
[]

#------------------------------------------------------------------------------#
[ICs]
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

  [./IC_eta0] #fiber
    type = FunctionIC
    variable = eta0
    function = fiber
  [../]

  [./IC_eta1] #gas
    type = FunctionIC
    variable = eta1
    function = gas
  [../]
[]

#------------------------------------------------------------------------------#
[Functions]
  [./fiber]
    type = ParsedFunction
    value = '(1/2)^2*(1.0-tanh((x-1.0)/0.1))*(1.0+tanh((-y+10.0)/0.1))'
  [../]

  [./gas]
    type = ParsedFunction
    value = '1-(1/2)^2*(1.0-tanh((x-1.0)/0.1))*(1.0+tanh((-y+10.0)/0.1))'
  [../]
[]

#------------------------------------------------------------------------------#
[Modules]
  [./PhaseField]
    [./GrandPotential]
      chemical_potentials = 'w_c w_o' # Different chemical potentials
      mobilities = 'D D'
      susceptibilities = 'chi chi'


      free_energies_w = 'x_c_fiber x_c_gas x_o_fiber x_o_gas' #Fj_names for ACInterface
      free_energies_gr = 'GP_fiber GP_gas' #Fj_names for ACSwitching
      switching_function_names = 'h_fiber h_gas' #Fj_names for ACInterface

      gamma_gr = gamma
      kappa_gr = kappa
      mobility_name_gr = L

      op_num = 2
      var_name_base = eta
      # This is a hack because the action is not made to not have any grains
      # But it doesn't matter, this will assign the correct kernels to etas
    [../]
  [../]
[]

#------------------------------------------------------------------------------#
[AuxVariables]
  [./rho_c]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./rho_o]
    family = MONOMIAL
    order = CONSTANT
  [../]
[]

[AuxKernels]
  [./aux_rho_c]
    type = MaterialRealAux
    property = 'x_c'
    variable = rho_c
  [../]
  [./aux_rho_o]
    type = MaterialRealAux
    property = 'x_o'
    variable = rho_o
  [../]
[]

#------------------------------------------------------------------------------#
[Kernels]
  [./Recomb_C]
    type = Reaction_GPM
    mob_name = R
    atomic_vol = Va
    variable = w_c
    v = rho_c
    w = rho_o
  [../]
[]

#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  # Reaction rate constants
  [./reaction_rates]
    type = ParsedMaterial
    f_name = R
    args = 'rho_o rho_c'

    constant_names = 'RR'
    constant_expressions = '-10'
    function = 'if(rho_o<0.0,0,if(rho_c<0.0,0,RR))'

    outputs = exodus
  [../]

  #----------------------------------------------------------------------------#
  #Parameters
  [./constants]
    type = GenericConstantMaterial
    prop_names  = 'D      chi    gamma   mu'
    prop_values = '0.1   0.03    1.5     1.0'
  [../]

  [./interfacial_param]
    type = GenericConstantMaterial
    prop_names  = 'kappa     L'
    prop_values = '1e-2      10.0'
  [../]

  [./Va]
    # Units: cm3/atom
    type = GenericConstantMaterial
    prop_names = 'Va'
    prop_values = '1.0'
  [../]

  [./params_oxygen]
    type = GenericConstantMaterial
    prop_names =  'xeq_o_gas    xeq_o_fiber   A_o_gas   A_o_fiber'
    prop_values = '0.99         0.01          10.0      1e5'
  [../]

  [./params_carbon]
    type = GenericConstantMaterial
    prop_names =  'xeq_c_gas    xeq_c_fiber   A_c_gas   A_c_fiber'
    prop_values = '0.01         0.9702        1e5      34.5350'
  [../]

  #----------------------------------------------------------------------------#
  # Switching Functions
  [./switch_fiber]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_fiber
    all_etas = 'eta0 eta1'
    phase_etas = 'eta0'

    outputs = exodus
    output_properties = h_fiber
  [../]

  [./switch_gas]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = h_gas
    all_etas = 'eta0 eta1'
    phase_etas = 'eta1'

    outputs = exodus
    output_properties = h_gas
  [../]

  #----------------------------------------------------------------------------#
  # Concentrations
  #----------------------------------------------------------------------------#
  # Carbon
  [./x_c_fiber]
    type = DerivativeParsedMaterial
    f_name = x_c_fiber

    function = 'w_c/(Va*A_c_fiber) + xeq_c_fiber'

    args = 'w_c'
    material_property_names = 'Va A_c_fiber xeq_c_fiber'

    outputs = exodus
    output_properties = x_c_fiber
    enable_jit = false
  [../]
  [./x_c_gas]
    type = DerivativeParsedMaterial
    f_name = x_c_gas

    function = 'w_c/(Va*A_c_gas) + xeq_c_gas'

    args = 'w_c'
    material_property_names = 'Va A_c_gas xeq_c_gas'

    outputs = exodus
    output_properties = x_c_gas
    enable_jit = false
  [../]
  [./x_c]
    type = DerivativeParsedMaterial
    f_name = x_c

    function = 'h_fiber*x_c_fiber + h_gas*x_c_gas'

    args = ''
    material_property_names = 'h_fiber h_gas x_c_fiber x_c_gas'

    outputs = exodus
    output_properties = x_c
    enable_jit = false
  [../]


  #----------------------------------------------------------------------------#
  # Oxygen
  [./x_o_fiber]
    type = DerivativeParsedMaterial
    f_name = x_o_fiber

    function = 'w_c/(Va*A_o_fiber) + xeq_o_fiber'

    args = 'w_c'
    material_property_names = 'Va A_o_fiber xeq_o_fiber'

    outputs = exodus
    output_properties = x_o_fiber
    enable_jit = false
  [../]
  [./x_o_gas]
    type = DerivativeParsedMaterial
    f_name = x_o_gas

    function = 'w_o/(Va*A_o_gas) + xeq_o_gas'

    args = 'w_o'
    material_property_names = 'Va A_o_gas xeq_o_gas'

    outputs = exodus
    output_properties = x_o_gas
    enable_jit = false
  [../]
  [./x_o]
    type = DerivativeParsedMaterial
    f_name = x_o

    function = 'h_fiber*x_o_fiber + h_gas*x_o_gas'

    args = ''
    material_property_names = 'h_fiber h_gas x_o_fiber x_o_gas'

    outputs = exodus
    output_properties = x_o
    enable_jit = false
  [../]


  #----------------------------------------------------------------------------#
  # Grand potential density of the fiber phase according to parabolic free energy
  [./GP_fiber]
    type = DerivativeParsedMaterial
    f_name = GP_fiber

    function = '-0.5*w_c^2/(Va^2 *A_c_fiber) - xeq_c_fiber*w_c/Va +Ref
                -0.5*w_o^2/(Va^2 *A_o_fiber) - xeq_o_fiber*w_o/Va'

    args = 'w_c w_o'
    material_property_names = 'Va A_c_fiber A_o_fiber xeq_c_fiber xeq_o_fiber'

    constant_names =       'Ref'
    constant_expressions = '-0.0052'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_fiber
    enable_jit = false
  [../]

  # Grand potential density of the gas phase according to parabolic free energy
  [./GP_gas]
    type = DerivativeParsedMaterial
    f_name = GP_gas

    function = '-0.5*w_c^2/(Va^2 *A_c_gas) - xeq_c_gas*w_c/Va
                -0.5*w_o^2/(Va^2 *A_o_gas) - xeq_o_gas*w_o/Va'

    args = 'w_c w_o'
    material_property_names = 'Va A_c_gas A_o_gas xeq_c_gas xeq_o_gas'

    derivative_order = 2

    outputs = exodus
    output_properties = GP_gas
    enable_jit = false
  [../]

[]

#------------------------------------------------------------------------------#
[Postprocessors]
  [./total_carbon]
    type = ElementIntegralMaterialProperty
    mat_prop = 'x_c'
    execute_on = 'INITIAL TIMESTEP_END'
  [../]
  [./total_oxygen]
    type = ElementIntegralMaterialProperty
    mat_prop = 'x_o'
    execute_on = 'INITIAL TIMESTEP_END'
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
  # solve_type = NEWTON

  # NEWTON Takes 172s to run 20 timesteps, reaches 48s with a max dt of 8
  # All the shabang below takes 510s, reaches 1212s!!, max dt of 219!

  petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm      31                  lu           1'

  l_max_its = 15
  l_tol = 1e-3
  nl_max_its = 15
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-8

  end_time = 10000
  #dtmax = 2

  #num_steps = 20

  [./Predictor]
    type = SimplePredictor
    scale = 1
  [../]

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e-2
    growth_factor = 1.2
    cutback_factor = 0.8
    optimal_iterations = 12
    iteration_window = 0
  [../]
[]

#------------------------------------------------------------------------------#
[Outputs]
  exodus = true
  csv = true
  file_base = ./results_v1/PFCOM_GPM_Oxi_v1_out
  execute_on = 'INITIAL TIMESTEP_END FINAL'
  perf_graph = true
[]

#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]
