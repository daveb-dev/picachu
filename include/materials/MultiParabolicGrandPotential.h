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
class MultiParabolicGrandPotential;

template <>
InputParameters validParams<MultiParabolicGrandPotential>();

class MultiParabolicGrandPotential : public DerivativeFunctionMaterialBase
{
public:
  MultiParabolicGrandPotential(const InputParameters & parameters);

protected:
  virtual Real computeF() override;
  virtual Real computeDF(unsigned int i_var) override;
  virtual Real computeD2F(unsigned int i_var, unsigned int j_var) override;

private:
  /// Components chemical potential in phase
  const unsigned int _num_w_p;
  std::vector<const VariableValue *> _w_p;

  std::vector<Real> _A;
  std::vector<Real> _Va;
  std::vector<Real> _c_eq;

};
