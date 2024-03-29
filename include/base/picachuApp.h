//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#ifndef PICACHUAPP_H
#define PICACHUAPP_H

#include "MooseApp.h"

class picachuApp;

template <>
InputParameters validParams<picachuApp>();

class picachuApp : public MooseApp
{
public:
  picachuApp(InputParameters parameters);
  virtual ~picachuApp();

  static void registerApps();
  static void registerAll(Factory & f, ActionFactory & af, Syntax & s);
};

#endif /* PICACHUAPP_H */
