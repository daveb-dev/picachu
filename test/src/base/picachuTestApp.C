//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "picachuTestApp.h"
#include "picachuApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"
#include "ModulesApp.h"

template <>
InputParameters
validParams<picachuTestApp>()
{
  InputParameters params = validParams<picachuApp>();
  return params;
}

picachuTestApp::picachuTestApp(InputParameters parameters) : MooseApp(parameters)
{
  picachuTestApp::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

picachuTestApp::~picachuTestApp() {}

void
picachuTestApp::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  picachuApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"picachuTestApp"});
    Registry::registerActionsTo(af, {"picachuTestApp"});
  }
}

void
picachuTestApp::registerApps()
{
  registerApp(picachuApp);
  registerApp(picachuTestApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
picachuTestApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  picachuTestApp::registerAll(f, af, s);
}
extern "C" void
picachuTestApp__registerApps()
{
  picachuTestApp::registerApps();
}
