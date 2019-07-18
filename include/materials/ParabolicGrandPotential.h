//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "DerivativeFunctionMaterialBase.h"

// Forward Declarations
class ParabolicGrandPotential;

template <>
InputParameters validParams<ParabolicGrandPotential>();

class ParabolicGrandPotential : public DerivativeFunctionMaterialBase
{
public:
  ParabolicGrandPotential(const InputParameters & parameters);

protected:
  virtual Real computeF() override;
  virtual Real computeDF(unsigned int i_var) override;
  virtual Real computeD2F(unsigned int i_var, unsigned int j_var) override;


  const VariableValue & _w;

  Real _A;
  Real _Va;
  Real _c_eq;

};
