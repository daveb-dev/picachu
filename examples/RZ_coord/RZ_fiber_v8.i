
#------------------------------------------------------------------------------#
[Mesh]
  # length scale -> microns
  type = GeneratedMesh
  dim = 2

  xmin = 0.0
  xmax = 3.0
  nx = 15

  ymin = 0.0
  ymax = 12.0
  ny = 60

  uniform_refine = 4
  elem_type = QUAD4
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
  # IC Coordinates
  y1 = 0
  y2 = 10.0
  x1 = 0
  x2 = 1.0

  # VectorPP
  num_points  = 1000
  sort_by     = x
[]

#------------------------------------------------------------------------------#
[AuxVariables]
  [./f_dens]
    family = MONOMIAL
    order = CONSTANT
  [../]
  [./x_V]
    family = MONOMIAL
    order = CONSTANT
  [../]
[]

#------------------------------------------------------------------------------#
[AuxKernels]
  [./f_dens_aux]
    type = TotalFreeEnergy
    interfacial_vars = 'x_C x_O2'
    kappa_names = 'kappa_C kappa_O2'
    f_name = f_loc
    variable = f_dens
  [../]
  [./vac_conc_aux]
    type = MaterialRealAux
    property = vac_conc
    variable = x_V
  [../]
[]

#------------------------------------------------------------------------------#
[Modules]
  [./PhaseField]
    [./Conserved]
      [./x_C]
        solve_type = FORWARD_SPLIT
        kappa = kappa_C
        free_energy = f_loc
        mobility = M_C
        args = 'x_O2 eta'
      [../]
      [./x_O2]
        solve_type = FORWARD_SPLIT
        kappa = kappa_O2
        free_energy = f_loc
        mobility = M_O2
        args = 'x_C eta'
      [../]
    [../]
    [./Nonconserved]
      [./eta]
        kappa = kappa_eta
        mobility = L
        free_energy = f_loc
        args = 'x_C x_O2'
      [../]
    [../]
  [../]
[]

#------------------------------------------------------------------------------#
[ICs]
  [./IC_x_O2]
    type = ConstantIC
    variable = x_O2
     value = 0.0
  [../]
  [./IC_x_C]
    type = BoundingBoxIC
    variable = x_C
    inside = 0.999
    outside = 0
  [../]
  [./IC_eta]
    type = BoundingBoxIC
    variable = eta
    inside = 0.0
    outside = 1.0
  [../]
[]

#------------------------------------------------------------------------------#
[Kernels]
  # Reactants: Use Recombination kernel
  [./recomb_C]
    type = Recombination
    variable = x_C # Reactant 1
    v = x_O2 # Reactant 2
    mob_name = R_C # Reaction Rate (negative)
  [../]
  [./recomb_O2]
    type = Recombination
    variable = x_O2 # Reactant 1
    v = x_C # Reactant 2
    mob_name = R_O2 # Reaction Rate (negative)
  [../]
[]

#------------------------------------------------------------------------------#
[Materials]
  #----------------------------------------------------------------------------#
  [./R_O2] # Reactant
    type = DerivativeParsedMaterial
    f_name = R_O2
    args = 'x_O2 x_C'
    constant_names = 'L'
    constant_expressions = '-1000'
    function = 'if(x_O2<0.0,0,if(x_C<0.0,0,L))'
    derivative_order = 1
    outputs = exodus
  [../]

  [./R_C] # Reactant
    type = DerivativeParsedMaterial
    f_name = R_C
    args = 'x_O2 x_C'
    constant_names = 'L'
    constant_expressions = '-1000'
    function = 'if(x_O2<0.0,0,if(x_C<0.0,0,L))'
    derivative_order = 1
    outputs = exodus
  [../]

  #----------------------------------------------------------------------------#
  # Order parameter stuff
  [./switching]
    type = DerivativeParsedMaterial
    f_name = h
    args = 'eta'
    constant_names = 'int_w'
    constant_expressions = '0.2'
    function = '0.5*(1+tanh((eta-0.5)/int_w))'
    derivative_order = 2
    outputs = exodus
    output_properties = h
  [../]

  [./barrier]
    type = BarrierFunctionMaterial
    eta = 'eta'
    function_name = g
    g_order = SIMPLE
    outputs = exodus
    output_properties = g
  [../]

  [./constants_AC]
    # kappa units: microJ/micrometer = J/m
    type = GenericConstantMaterial
    prop_names  = 'L kappa_eta'
    prop_values = '0.1 1e-4'
    outputs = exodus
    output_properties = 'L kappa_eta'
  [../]

  #----------------------------------------------------------------------------#
  # O
  [./mobility_O2]
    # type = GenericConstantMaterial
    # prop_names = 'M_O2'
    # prop_values = '20'
    # outputs = exodus
    # output_properties = 'M_O2'

    type = ParsedMaterial
    f_name = M_O2
    constant_names =       'M_g M_s'
    constant_expressions = '20  0.1'
    args = 'eta'
    material_property_names = 'h(eta)'
    function = 'h*M_g + (1-h)*M_s'
  [../]


  [./kappa_O2]
    # Units: microJ/micrometer = J/m
    type = GenericConstantMaterial
    prop_names  = 'kappa_O2'
    prop_values = '1e-4' #O2 has a linear profile.
    outputs = exodus
    output_properties = 'kappa_O2'
  [../]

  #----------------------------------------------------------------------------#
  # C
  [./mobility_C]
    type = GenericConstantMaterial
    prop_names = 'M_C'
    prop_values = '1e-4'
    outputs = exodus
    output_properties = 'M_C'
  [../]
  [./kappa_C]
    # Units: microJ/micrometer = J/m
    type = GenericConstantMaterial
    prop_names  = 'kappa_C'
    prop_values = '1e-4'
    outputs = exodus
    output_properties = 'kappa_C'
  [../]

  #----------------------------------------------------------------------------#
  # Vacancy concentration
  [./vac_conc_mat] # Vacancy concentration in solid phase
    type = ParsedMaterial
    f_name = vac_conc
    args = 'x_C x_O2'
    material_property_names = 'h(eta)'
    function = '(1-h) * (1-x_C-x_O2)'
    outputs = exodus
    output_properties = vac_conc
  [../]

  #----------------------------------------------------------------------------#
  # Gibbs energy of the solid phase
  [./free_energy_s]
    #Units J/micron3
    type = DerivativeParsedMaterial
    derivative_order = 2
    f_name = f_s
    args = 'x_C x_O2'
    #units =            'eV/atom  eV/K-atom K        -     m3/mol      atom/mol     m3/micron3        eV/J'
    #Final unit of free_energy_s = J/micron3
    constant_names =       'Ef_v  kb        T       tol    molar_vol   Na           m_micron_conv   eV_microJ_conv'
    constant_expressions = '4.0   8.6173e-5 1000.0  1e-4   6.3208e-6   6.0221e23    1e6             1.6022e-13'

    function  = ' (Na/molar_vol)*(eV_microJ_conv/m_micron_conv^3)
                * (kb*T*x_C*plog(x_C,tol)
                + (Ef_v*(1-x_C-x_O2) + kb*T*(1-x_C-x_O2)*plog((1-x_C-x_O2),tol))
                + (2*Ef_v*x_O2 + kb*T*x_O2*plog(x_O2,tol)))'
  [../]

  #----------------------------------------------------------------------------#
  # Gibbs energy of the gas phase
  [./free_energy_g]
    #Units J/micron3
    type = DerivativeParsedMaterial
    derivative_order = 2
    f_name = f_g
    args = 'x_O2 x_C'
    constant_names =        'A_O2   A_C     O2_eq   C_eq  molar_vol   Na           m_micron_conv   eV_microJ_conv'
    constant_expressions =  '1.0    100.0    1.0     0.0   6.3208e12   6.0221e23    1e6             1.6022e-13'

    function  = ' (Na/molar_vol)*(eV_microJ_conv/m_micron_conv^3)
                * (A_O2/2.0 * (O2_eq - x_O2)^2
                + A_C/2.0 * (C_eq - x_C)^2)'
  [../]

  #----------------------------------------------------------------------------#
  # Gibbs energy density
  [./free_energy_loc]
    #Units J/micron3
    type = DerivativeParsedMaterial
    f_name = f_loc
    constant_names =       'W'
    constant_expressions = '0.1'
    args = 'x_C x_O2 eta'
    material_property_names = 'h(eta) g(eta) f_g(x_O2,x_C) f_s(x_C,x_O2)'
    function = 'h*f_g + (1-h)*f_s + W*g'
    derivative_order = 2
  [../]
[]

#------------------------------------------------------------------------------#
[BCs]
  [./x_O2_top]
    type = DirichletBC
    variable = x_O2
    value = 1.0
    boundary =  'top'
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
  scheme = 'bdf2'
  solve_type = NEWTON
  #petsc_options_iname = '-pc_type -sub_pc_type'
  #petsc_options_value = 'asm lu'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'

  l_max_its = 10
  l_tol = 1.0e-4

  nl_max_its = 20
  nl_rel_tol = 1.0e-8
  #nl_abs_tol = 1.0e-10

  dtmax = 1000
  dtmin = 1e-12
  #num_steps = 25
  end_time = 10000

  [./Adaptivity]
    max_h_level = 4
    initial_adaptivity = 2
    coarsen_fraction = 0.1
    refine_fraction = 0.8
  [../]

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e-6
    growth_factor = 10.0
    cutback_factor = 0.8
    optimal_iterations = 12
    iteration_window = 0
  [../]
[]

#------------------------------------------------------------------------------#
[Postprocessors]
  [./total_F]
    type = ElementIntegralVariablePostprocessor
    variable = f_dens
  [../]
  [./total_V]
    type = ElementIntegralVariablePostprocessor
    variable = x_V
  [../]
  [./total_C]
    type = ElementIntegralVariablePostprocessor
    variable = x_C
  [../]
  [./mesh_volume]
    type = VolumePostprocessor
  [../]

  # Stats
  [./dt]
    type = TimestepSize
  [../]
  [./alive_time]
    type = PerformanceData
    event = ALIVE
  [../]
  [./mem_usage]
    type = MemoryUsage
    mem_type = physical_memory
  [../]
[]

#------------------------------------------------------------------------------#
[Outputs]
  perf_graph = true
  file_base = ./results_v8/RZ_fiber_v8_out

  [./exodus]
    type = Exodus
    execute_on = 'INITIAL TIMESTEP_END'
  [../]

  [./csv]
    type = CSV
    execute_on = 'INITIAL TIMESTEP_END'
  [../]

   [./vector]
     type = CSV
     execute_on = 'INITIAL TIMESTEP_END'
     file_base = ./results_v8/vector_PP/vector
   [../]
[]

#------------------------------------------------------------------------------#
[Debug]
  show_var_residual_norms = true
[]

#------------------------------------------------------------------------------#
[VectorPostprocessors]
  [./line_4.0]
    type = LineValueSampler
    start_point = '0.0 4.0 0.0'
    end_point   = '2.0 4.0 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.9]
    type = LineValueSampler
    start_point = '0.0 3.9 0.0'
    end_point   = '2.0 3.9 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.8]
    type = LineValueSampler
    start_point = '0.0 3.8 0.0'
    end_point   = '2.0 3.8 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.7]
    type = LineValueSampler
    start_point = '0.0 3.7 0.0'
    end_point   = '2.0 3.7 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.6]
    type = LineValueSampler
    start_point = '0.0 3.6 0.0'
    end_point   = '2.0 3.6 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.5]
    type = LineValueSampler
    start_point = '0.0 3.5 0.0'
    end_point   = '2.0 3.5 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.4]
    type = LineValueSampler
    start_point = '0.0 3.4 0.0'
    end_point   = '2.0 3.4 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.3]
    type = LineValueSampler
    start_point = '0.0 3.3 0.0'
    end_point   = '2.0 3.3 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.2]
    type = LineValueSampler
    start_point = '0.0 3.2 0.0'
    end_point   = '2.0 3.2 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.1]
    type = LineValueSampler
    start_point = '0.0 3.1 0.0'
    end_point   = '2.0 3.1 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_3.0]
    type = LineValueSampler
    start_point = '0.0 3.0 0.0'
    end_point   = '2.0 3.0 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_2.8]
    type = LineValueSampler
    start_point = '0.0 2.8 0.0'
    end_point   = '2.0 2.8 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_2.6]
    type = LineValueSampler
    start_point = '0.0 2.6 0.0'
    end_point   = '2.0 2.6 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_2.4]
    type = LineValueSampler
    start_point = '0.0 2.4 0.0'
    end_point   = '2.0 2.4 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_2.2]
    type = LineValueSampler
    start_point = '0.0 2.2 0.0'
    end_point   = '2.0 2.2 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_2.0]
    type = LineValueSampler
    start_point = '0.0 2.0 0.0'
    end_point   = '2.0 2.0 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_1.8]
    type = LineValueSampler
    start_point = '0.0 1.8 0.0'
    end_point   = '2.0 1.8 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_1.6]
    type = LineValueSampler
    start_point = '0.0 1.6 0.0'
    end_point   = '2.0 1.6 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_1.4]
    type = LineValueSampler
    start_point = '0.0 1.4 0.0'
    end_point   = '2.0 1.4 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_1.2]
    type = LineValueSampler
    start_point = '0.0 1.2 0.0'
    end_point   = '2.0 1.2 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]

  [./line_1.0]
    type = LineValueSampler
    start_point = '0.0 1.0 0.0'
    end_point   = '2.0 1.0 0.0'
    variable    = 'x_C f_dens eta'
    execute_on  = 'INITIAL TIMESTEP_END'
    outputs     = vector
  [../]
[]
