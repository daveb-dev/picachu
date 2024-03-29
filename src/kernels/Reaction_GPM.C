//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "Reaction_GPM.h"

registerMooseObject("PhaseFieldApp", Reaction_GPM);

template <>
InputParameters
validParams<Reaction_GPM>()
{
  InputParameters params = validParams<Kernel>();
  params.addRequiredCoupledVar("v", "1st coupled nonlinear variable");
  params.addRequiredCoupledVar("w", "2nd coupled nonlinear variable");
  params.addClassDescription(
      "Kernel to add (-R*u*v), where the variables are number densities, R=reaction rate, v = coupled density variable, and w = coupled density variable");
  params.addParam<MaterialPropertyName>("atomic_vol", "Va", "The atomic volume (as a Material property) to be used");
  params.addParam<MaterialPropertyName>("mob_name", "R", "The reaction rate used with the kernel");
  params.addCoupledVar("args", "Vector of nonlinear variable arguments this object depends on");
  return params;
}

Reaction_GPM::Reaction_GPM(const InputParameters & parameters)
  : DerivativeMaterialInterface<JvarMapKernelInterface<Kernel>>(parameters),
    _v_name(getVar("v", 0)->name()),
    _v(coupledValue("v")),
    _v_var(coupled("v")),
    _w_name(getVar("w", 0)->name()),
    _w(coupledValue("w")),
    _w_var(coupled("w")),
    _Va(getMaterialProperty<Real>("Va")),
    _R(getMaterialProperty<Real>("mob_name")),
    _dRdu(getMaterialPropertyDerivative<Real>("mob_name", _var.name())),
    _dRdv(getMaterialPropertyDerivative<Real>("mob_name", _v_name)),
    _dRdw(getMaterialPropertyDerivative<Real>("mob_name", _w_name)),
    _nvar(_coupled_moose_vars.size()),
    _dRdarg(_nvar)
{
  // Get reaction rate derivatives
  for (unsigned int i = 0; i < _nvar; ++i)
    _dRdarg[i] = &getMaterialPropertyDerivative<Real>("mob_name", _coupled_moose_vars[i]->name());
}

void
Reaction_GPM::initialSetup()
{
  validateNonlinearCoupling<Real>("mob_name");
}

Real
Reaction_GPM::computeQpResidual()
{
    Real tol = 0.01;

    if ( (_w[_qp] <= tol) || (_v[_qp] <= tol)){
    return 0;
    } else {
    return -_R[_qp] * _Va[_qp] * _test[_i][_qp] * _v[_qp] * _w[_qp];
    }
}

Real
Reaction_GPM::computeQpJacobian()
{
    Real tol = 0.01;
    //Real tol = -_R[_qp] * _Va[_qp] * _test[_i][_qp] * _v[_qp] * _w[_qp];

    if ( (_w[_qp] <= tol) || (_v[_qp] <= tol)){
    return 0;
    } else {
    return -_dRdu[_qp] * _Va[_qp] * _v[_qp] * _w[_qp] * _phi[_j][_qp]  * _test[_i][_qp];
    }

}

Real
Reaction_GPM::computeQpOffDiagJacobian(unsigned int jvar)
{
  Real tol = 0.01;
  //Real tol = -_R[_qp] * _Va[_qp] * _test[_i][_qp] * _v[_qp] * _w[_qp];

  // first handle the case where jvar is a coupled variable v being added to residual
  // the first term in the sum just multiplies by L which is always needed
  // the second term accounts for cases where L depends on v
  if (jvar == _v_var){
    
    if ( (_w[_qp] <= tol) || (_v[_qp] <= tol)){
    return 0;
    } else {
    return -(_R[_qp] + _dRdv[_qp] * _v[_qp]) * _Va[_qp] * _w[_qp] * _phi[_j][_qp] * _test[_i][_qp];
    }

  }
  if (jvar == _w_var){

    if ( (_w[_qp] <= tol) || (_v[_qp] <= tol)){
    return 0;
    } else {
    return -(_R[_qp] + _dRdw[_qp] * _w[_qp]) * _Va[_qp] * _v[_qp] * _phi[_j][_qp] * _test[_i][_qp];
    }

  }
  //  for all other vars get the coupled variable jvar is referring to
  const unsigned int cvar = mapJvarToCvar(jvar);

  return -(*_dRdarg[cvar])[_qp] * _phi[_j][_qp] * _Va[_qp] * _u[_qp] * _v[_qp] * _test[_i][_qp];
}
