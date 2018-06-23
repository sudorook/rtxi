//
// File = goldsrch.h
//

#ifndef _GOLDSRCH_H_
#define _GOLDSRCH_H_

#include "fs_resp.h"
#include "fs_spec.h"

double
GoldenSearch(double tol,
             FreqSampFilterSpec* filt_config,
             FreqSampFilterDesign* filt_design,
             FreqSampFilterResponse* filt_resp,
             long design_quan_factor,
             double* fmin);
#endif
