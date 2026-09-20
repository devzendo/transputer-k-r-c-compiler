/*
** Compilador de C para el G10
**
** por Oscar Toledo Gutiérrez.
**
** (c) Oscar Toledo G.1995.
**
** Creación: 26 de junio de 1995.
** Revisión: 27 de julio de 1995. Agrego comillas a los nombres, gracias a la
**                                nueva ampliación del compilador.
** Revisión: 23 de agosto de 1995. Incluyo el camino al directorio /c/.
** Revisión: 22 de noviembre de 1995. Incluyo el camino a la unidad c:
*/

#include <stdio.h>

#include "CCVARS.C"    /* Variables y definiciones.           */
#include "CCINTER.C"   /* Interfaz con el usuario.            */
#include "CCANASIN.C"  /* Análisis sintáctico de alto nivel.  */
#include "CCVARIOS.C"  /* Funciones de soporte.               */
#include "CCEXPR.C"    /* Análisis sintáctico de expresiones. */
#include "CCGENCOD.C"  /* Generador de codigo.                */
