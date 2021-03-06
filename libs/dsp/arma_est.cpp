//
//  File = arma_est.cpp
//
#include <fstream>
#include <iostream>
#include <stdlib.h>

#include "arma_est.h"
#include "gausrand.h"
#include "mod_yuwa.h"
#include "yulewalk.h"

using namespace std;

//============================================================
//  ArmaEstimate - subclass of ArmaProcess for the case where
//                 ARMA coefficients must be estimated from
//                 observed data

template<class T>
ArmaEstimate<T>::ArmaEstimate(int est_ar_order,
                              int est_ma_order,
                              int durbin_ar_order,
                              T* sig_seq,
                              int seq_len)
  : ArmaProcess<T>()
{
  int i, j, k, err_stat;
  T *a_coeffs, *ar_out_seq;
  T sum;
  YuleWalker<T>* yw_ptr;
  ModYuleWalker<T>* mod_yw_ptr;

  this->Ar_Order = est_ar_order;
  this->Ma_Order = est_ma_order;
  this->Noise_Seed = 31415927; // arbitrary default

  this->Old_Input = new T[est_ma_order + 1];
  for (i = 0; i <= est_ma_order; i++)
    this->Old_Input[i] = 0.0;

  this->Old_Output = new T[est_ar_order];
  for (i = 0; i < est_ar_order; i++)
    this->Old_Output[i] = 0.0;
  //------------------------------------------------------
  //  Fit AR model of specified order to the data
  std::cout << "in ArmaModel, sig_seq[0] = " << sig_seq[0] << std::endl;
  std::cout << "in ArmaModel, sig_seq[1] = " << sig_seq[1] << std::endl;
  mod_yw_ptr =
    new ModYuleWalker<T>(sig_seq, seq_len, est_ar_order, est_ma_order);

  this->A_Coeffs = mod_yw_ptr->GetCoeffs();
  this->Drv_Noise_Var = mod_yw_ptr->GetDrivingVariance();

  delete mod_yw_ptr;

  //---------------------------------------
  //  Moving Average Section
  if (est_ma_order > 0) {
    //---------------------------------------------------
    //  Apply AR filter to the original data sequence

    ar_out_seq = new T[seq_len];

    for (k = est_ar_order; k < seq_len; k++) {
      sum = sig_seq[k];
      for (j = 1; j <= est_ar_order; j++) {
        sum = sum + (this->A_Coeffs[j] * sig_seq[k - j]);
      }
      ar_out_seq[k - est_ar_order] = sum;
    }

    //--------------------------------------------------
    //  Durbin's method starts here for MA portion.
    //  Fit high-order AR model to the output of the
    //  AR portion.

    a_coeffs = new T[durbin_ar_order + 1];
    yw_ptr = new YuleWalker<T>(ar_out_seq,
                               seq_len - est_ar_order,
                               durbin_ar_order,
                               a_coeffs,
                               &(this->Drv_Noise_Var),
                               &err_stat);

    delete yw_ptr;
    delete[] ar_out_seq;

    //-----------------------------------------------------
    //  Use high-order AR coefficients in place of data
    //  to fit desired order MA model

    double dummy_var;
    this->B_Coeffs = new T[est_ma_order + 1];
    yw_ptr = new YuleWalker<T>(a_coeffs,
                               durbin_ar_order + 1,
                               est_ma_order,
                               this->B_Coeffs,
                               &dummy_var,
                               &err_stat);
    std::cout << "B_Coeffs[1] = " << this->B_Coeffs[1] << std::endl;
    std::cout << "B_Coeffs[2] = " << this->B_Coeffs[2] << std::endl;

    delete yw_ptr;
    delete[] a_coeffs;
  }
  return;
}

template class ArmaEstimate<double>;
template class ArmaEstimate<complex>;
