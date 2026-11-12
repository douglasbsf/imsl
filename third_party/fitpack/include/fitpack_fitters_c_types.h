/***************************************************************************************************
!                                ____________________  ___   ________ __
!                               / ____/  _/_  __/ __ \/   | / ____/ //_/
!                              / /_   / /  / / / /_/ / /| |/ /   / ,<
!                             / __/ _/ /  / / / ____/ ___ / /___/ /| |
!                            /_/   /___/ /_/ /_/   /_/  |_\____/_/ |_|
!
!                                     A Curve Fitting Package
!
!   fitpack_fitters_c_types.h (module fitpack_fitters)
!> @brief C type definitions for fitpack_fitters
!
!   @author Federico Perini
!   @date   2026-08-27
!
!   References :
!     - C. De Boor, "On calculating with b-splines", J Approx Theory 6 (1972) 50-62
!     - M. G. Cox, "The numerical evaluation of b-splines", J Inst Maths Applics 10 (1972) 134-149
!     - P. Dierckx, "Curve and surface fitting with splines", Monographs on numerical analysis,
!                    Oxford university press, 1993.
!
! **************************************************************************************************/

#ifndef FITPACK_FITTERS_C_TYPES_H_INCLUDED
#define FITPACK_FITTERS_C_TYPES_H_INCLUDED

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque C wrapper for fitpack_fitter. */
typedef struct fitpack_fitter_c {
    void* cptr;
    bool is_pointer;
    const char* name_cptr;
} fitpack_fitter_c;

extern const char fitpack_fitter_c_typename[];

static const fitpack_fitter_c fitpack_fitter_c_null = { NULL, false, NULL };

const char* fitpack_fitter_c_fortran_type_name(fitpack_fitter_c self);

/* Return the static null-terminated C wrapper type name (e.g. "fitpack_fitter_c"). */
const char* fitpack_fitter_c_c_type_name(fitpack_fitter_c self);

#ifdef __cplusplus
}
#endif

#endif /* FITPACK_FITTERS_C_TYPES_H_INCLUDED */
