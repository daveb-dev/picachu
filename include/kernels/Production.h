//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#ifndef PRODUCTION_H
#define PRODUCTION_H

#include "Kernel.h"
#include "JvarMapInterface.h"
#include "DerivativeMaterialInterface.h"

// Forward Declaration
class Production;

template <>
InputParameters validParams<Production>();

/**
 * This kernel adds to the residual a contribution of \f$ -L*u*v \f$ where \f$ L \f$ is a material
 * property, \f$ u \f$ is the variable, and \f$ v \f$ is a coupled variable.
 */
class Production : public DerivativeMaterialInterface<JvarMapKernelInterface<Kernel>>
{
public:
  Production(const InputParameters & parameters);
  virtual void initialSetup();

protected:
  virtual Real computeQpResidual();
  virtual Real computeQpJacobian();
  virtual Real computeQpOffDiagJacobian(unsigned int jvar);

  /// Coupled variables
  const VariableName _v_name;
  const VariableValue & _v;
  const unsigned int _v_var;

  const VariableName _w_name;
  const VariableValue & _w;
  const unsigned int _w_var;

  /// Reaction rate
  const MaterialProperty<Real> & _L;

  ///  Reaction rate derivative w.r.t. u
  const MaterialProperty<Real> & _dLdu;

  ///  Reaction rate derivative w.r.t. v
  const MaterialProperty<Real> & _dLdv;

  ///  Reaction rate derivative w.r.t. w
  const MaterialProperty<Real> & _dLdw;

  /// number of coupled variables
  const unsigned int _nvar;

  ///  Reaction rate derivatives w.r.t. other coupled variables
  std::vector<const MaterialProperty<Real> *> _dLdarg;
};

#endif // PRODUCTION_H
