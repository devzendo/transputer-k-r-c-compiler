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

#include "ccvars.c"    /* Variables y definiciones.           */
#include "ccinter.c"   /* Interfaz con el usuario.            */
#include "ccanasin.c"  /* Análisis sintáctico de alto nivel.  */
#include "ccvarios.c"  /* Funciones de soporte.               */
#include "ccexpr.c"    /* Análisis sintáctico de expresiones. */
#include "ccgencod.c"  /* Generador de codigo.                */
