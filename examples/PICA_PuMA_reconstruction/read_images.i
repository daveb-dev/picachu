[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 200
  ny = 200
  nz = 200
[]

[Variables]
  [./u]
  [../]
[]

[Functions]
  [./image_func]
    type = ImageFunction
    file_base = images/segmentedTomography
    file_suffix = png
  [../]
[]

[ICs]
  [./u_ic]
    type = FunctionIC
    function = image_func
    variable = u
  [../]
[]

[Problem]
  type = FEProblem
  solve = false
[../]

[Executioner]
  type = Transient
  num_steps = 1
  dt = 0.1
[]

[Outputs]
  exodus = true
[]
