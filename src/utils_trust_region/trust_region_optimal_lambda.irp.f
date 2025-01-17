! Newton's method to find the optimal lambda

! *Compute the lambda value for the trust region*

! This subroutine uses the Newton method in order to find the optimal
! lambda. This constant is added on the diagonal of the hessian to shift
! the eiganvalues. It has a double role:
! - ensure that the resulting hessian is positive definite for the
!   Newton method
! - constrain the step in the trust region, i.e.,
!   $||\textbf{x}(\lambda)|| \leq \Delta$, where $\Delta$ is the radius
!   of the trust region.
! We search $\lambda$ which minimizes
! \begin{align*}
!   f(\lambda) = (||\textbf{x}_{(k+1)}(\lambda)||^2 -\Delta^2)^2
! \end{align*}
! or
! \begin{align*}
!   \tilde{f}(\lambda) = (\frac{1}{||\textbf{x}_{(k+1)}(\lambda)||^2}-\frac{1}{\Delta^2})^2
! \end{align*}
! and gives obviously 0 in both cases. \newline

! There are several cases:
! - If $\textbf{H}$ is positive definite the interval containing the
!   solution is $\lambda \in (0, \infty)$ (and $-h_1 < 0$). 
! - If $\textbf{H}$ is indefinite ($h_1 < 0$) and $\textbf{w}_1^T \cdot
!   \textbf{g} \neq 0$ then the interval containing
!   the solution is  $\lambda \in (-h_1, \infty)$.
! - If $\textbf{H}$ is indefinite ($h_1 < 0$) and $\textbf{w}_1^T \cdot
!   \textbf{g} = 0$ then the interval containing the solution is
!   $\lambda \in (-h_1, \infty)$. The terms where $|h_i - \lambda| <
!   10^{-12}$ are not computed, so the term where $i = 1$ is
!   automatically removed and this case becomes similar to the previous one.

! So to avoid numerical problems (cf. trust_region) we start the
! algorithm at $\lambda=\max(0 + \epsilon,-h_1 + \epsilon)$,
! with $\epsilon$ a little constant.
! The research must be restricted to the interval containing the
! solution. For that reason a little trust region in 1D is used.  

! The Newton method to find the optimal $\lambda$ is :
! \begin{align*}
!   \lambda_{(l+1)} &= \lambda_{(l)} - f^{''}(\lambda)_{(l)}^{-1} f^{'}(\lambda)_{(l)}^{} \\
! \end{align*}
! $f^{'}(\lambda)_{(l)}$: the first derivative of $f$ with respect to
! $\lambda$ at the l-th iteration,
! $f^{''}(\lambda)_{(l)}$: the second derivative of $f$ with respect to
! $\lambda$ at the l-th iteration.\newline

! Noting the Newton step $y = - f^{''}(\lambda)_{(l)}^{-1}
! f^{'}(\lambda)_{(l)}^{}$ we constrain $y$ such as 
! \begin{align*}
!   y \leq \alpha
! \end{align*}
! with $\alpha$ a scalar representing the trust length (trust region in
! 1D) where the function $f$ or $\tilde{f}$ is correctly describe by the
! Taylor series truncated at the second order. Thus, if $y > \alpha$,
! the constraint is applied as  
! \begin{align*}
!   y^* = \alpha \frac{y}{|y|}
! \end{align*}
! with $y^*$ the solution in the trust region. 

! The size of the trust region evolves in function of $\rho$ as for the
! trust region seen previously cf. trust_region, rho_model.
! The prediction of the value of $f$ or $\tilde{f}$ is done using the
! Taylor series truncated at the second order cf. "trust_region",
! "trust_e_model". 

! The first and second derivatives of $f(\lambda) = (||\textbf{x}(\lambda)||^2 -
! \Delta^2)^2$ with respect to $\lambda$ are:
! \begin{align*}
!   \frac{\partial }{\partial \lambda} (||\textbf{x}(\lambda)||^2 - \Delta^2)^2 
!   = 2 \left(\sum_{i=1}^n \frac{-2(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \right)
!   \left( - \Delta^2 + \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i+ \lambda)^2} \right)
! \end{align*}
! \begin{align*}
! \frac{\partial^2}{\partial \lambda^2} (||\textbf{x}(\lambda)||^2 - \Delta^2)^2 
! = 2 \left[ \left( \sum_{i=1}^n 6 \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^4} \right) \left( - \Delta^2 + \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \right) + \left( \sum_{i=1}^n -2 \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \right)^2 \right]
! \end{align*}

! The first and second derivatives of $\tilde{f}(\lambda) = (1/||\textbf{x}(\lambda)||^2 -
! 1/\Delta^2)^2$ with respect to $\lambda$ are:
! \begin{align*}
!   \frac{\partial}{\partial \lambda} (1/||\textbf{x}(\lambda)||^2 - 1/\Delta^2)^2 
!   &= 4 \frac{\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3}}
!        {(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3} 
!      - \frac{4}{\Delta^2} \frac{\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3)}}
!        {(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \\
!   &= 4 \sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3}
!        \left( \frac{1}{(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3}
!       - \frac{1}{\Delta^2 (\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \right)
! \end{align*}

! \begin{align*}
!   \frac{\partial^2}{\partial \lambda^2} (1/||\textbf{x}(\lambda)||^2 - 1/\Delta^2)^2 
!   &= 4 \left[ \frac{(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3)})^2}
!    {(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^4} 
!   - 3 \frac{\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^4}}
!    {(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3} \right] \\
!   &- \frac{4}{\Delta^2} \left[ \frac{(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}
!    {(h_i + \lambda)^3)})^2}{(\sum_ {i=1}^n\frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3}
!   - 3 \frac{\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^4}}
!    {(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \right]
! \end{align*}

! Provided in qp_edit:
! | thresh_rho_2          |
! | thresh_cc             |
! | nb_it_max_lambda      |
! | version_lambda_search |
! | nb_it_max_pre_search  |
! see qp_edit for more details

! Input:
! | n          | integer          | m*(m-1)/2                  |
! | e_val(n)   | double precision | eigenvalues of the hessian |
! | tmp_wtg(n) | double precision | w_i^T.v_grad(i)            |
! | delta      | double precision | delta for the trust region |

! Output:
! | lambda | double precision | Lagrange multiplier to constrain the norm of the size of the Newton step |
! |        |                  | lambda > 0                                                               |

! Internal:
! | d1_N        | double precision | value of d1_norm_trust_region                                        |
! | d2_N        | double precision | value of d2_norm_trust_region                                        |
! | f_N         | double precision | value of f_norm_trust_region                                         |
! | prev_f_N    | double precision | previous value of f_norm_trust_region                                |
! | f_R         | double precision | (norm(x)^2 - delta^2)^2 or (1/norm(x)^2 - 1/delta^2)^2               |
! | prev_f_R    | double precision | previous value of f_R                                                |
! | model       | double precision | predicted value of f_R from prev_f_R and y                           |
! | d_1         | double precision | value of the first derivative                                        |
! | d_2         | double precision | value of the second derivative                                       |
! | y           | double precision | Newton's step, y = -f''^-1 . f' = lambda - prev_lambda               |
! | prev_lambda | double precision | previous value of lambda                                             |
! | t1,t2,t3    | double precision | wall time                                                            |
! | i           | integer          | index                                                                |
! | epsilon     | double precision | little constant to avoid numerical problem                           |
! | rho_2       | double precision | (prev_f_R - f_R)/(prev_f_R - model), agreement between model and f_R |
! | version     | integer          | version of the root finding method                                   |

! Function:
! | d1_norm_trust_region         | double precision | first derivative with respect to lambda of  (norm(x)^2 - Delta^2)^2     |
! | d2_norm_trust_region         | double precision | first derivative with respect to lambda of  (norm(x)^2 - Delta^2)^2     |
! | d1_norm_inverse_trust_region | double precision | first derivative with respect to lambda of  (1/norm(x)^2 - 1/Delta^2)^2 |
! | d2_norm_inverse_trust_region | double precision | second derivative with respect to lambda of (1/norm(x)^2 - 1/Delta^2)^2 |
! | f_norm_trust_region          | double precision | value of norm(x)^2                                                      |



subroutine trust_region_optimal_lambda(n,e_val,tmp_wtg,delta,lambda)

  include 'pi.h'

  BEGIN_DOC
  ! Research the optimal lambda to constrain the step size in the trust region
  END_DOC

  implicit none
  
  ! Variables
  
  ! in
  integer, intent(in)             :: n
  double precision, intent(inout) :: e_val(n)
  double precision, intent(in)    :: delta
  double precision, intent(in)    :: tmp_wtg(n)

  ! out
  double precision, intent(out)   :: lambda

  ! Internal
  double precision                :: d1_N, d2_N, f_N, prev_f_N
  double precision                :: prev_f_R, f_R
  double precision                :: model
  double precision                :: d_1, d_2
  double precision                :: t1,t2,t3
  integer                         :: i
  double precision                :: epsilon
  double precision                :: y
  double precision                :: prev_lambda
  double precision                :: rho_2
  double precision                :: alpha
  integer                         :: version

  ! Functions
  double precision                :: d1_norm_trust_region,d1_norm_trust_region_omp
  double precision                :: d2_norm_trust_region, d2_norm_trust_region_omp
  double precision                :: f_norm_trust_region, f_norm_trust_region_omp
  double precision                :: d1_norm_inverse_trust_region
  double precision                :: d2_norm_inverse_trust_region
  double precision                :: d1_norm_inverse_trust_region_omp
  double precision                :: d2_norm_inverse_trust_region_omp

  print*,''
  print*,'---Trust_newton---'
  print*,''

  call wall_time(t1)

  ! version_lambda_search
  ! 1 -> ||x||^2 - delta^2 = 0,
  ! 2 -> 1/||x||^2 - 1/delta^2 = 0 (better)
  if (version_lambda_search == 1) then
    print*, 'Research of the optimal lambda by solving ||x||^2 - delta^2 = 0'
  else
    print*, 'Research of the optimal lambda by solving 1/||x||^2 - 1/delta^2 = 0'
  endif
  ! Version 2 is normally better



! Resolution with the Newton method:


  ! Initialization
  epsilon = 1d-4
  lambda =MAX(0d0, -e_val(1))
  
  ! Pre research of lambda to start near the optimal lambda
  ! by adding a constant epsilon and changing the constant to
  ! have ||x(lambda + epsilon)|| ~ delta, before setting
  ! lambda = lambda + epsilon 
  print*, 'Pre research of lambda:'
  print*,'Initial lambda =', lambda
  f_N = f_norm_trust_region_omp(n,e_val,tmp_wtg,lambda + epsilon)
  print*,'||x(lambda)||=', dsqrt(f_N),'delta=',delta 
  i = 1
  
  ! To increase lambda
  if (f_N > delta**2) then
    print*,'Increasing lambda...'
    do while (f_N > delta**2 .and. i <= nb_it_max_pre_search)

      ! Update the previous norm
      prev_f_N = f_N
      ! New epsilon
      epsilon = epsilon * 2d0
      ! New norm
      f_N = f_norm_trust_region_omp(n,e_val,tmp_wtg,lambda + epsilon)

      print*, 'lambda', lambda + epsilon, '||x||', dsqrt(f_N), 'delta', delta
      
      ! Security
      if (prev_f_N < f_N) then
        print*,'WARNING, error: prev_f_N < f_N, exit'
        epsilon = epsilon * 0.5d0
        i = nb_it_max_pre_search + 1
      endif

      i = i + 1
    enddo
  
  ! To reduce lambda
  else
     print*,'Reducing lambda...'
     do while (f_N < delta**2 .and. i <= nb_it_max_pre_search)

       ! Update the previous norm
       prev_f_N = f_N  
       ! New epsilon
       epsilon = epsilon * 0.5d0
       ! New norm
       f_N = f_norm_trust_region_omp(n,e_val,tmp_wtg,lambda + epsilon)

       print*, 'lambda', lambda + epsilon, '||x||', dsqrt(f_N), 'delta', delta

       ! Security
       if (prev_f_N > f_N) then
         print*,'WARNING, error: prev_f_N > f_N, exit'
         epsilon = epsilon * 2d0
         i = nb_it_max_pre_search + 1
      endif

      i = i + 1
    enddo
  endif

  print*,'End of the pre research of lambda'
  
  ! New value of lambda
  lambda = lambda + epsilon

  print*, 'e_val(1):', e_val(1)
  print*, 'Staring point, lambda =', lambda
  
  ! thresh_cc, threshold for the research of the optimal lambda
  ! Leaves the loop when ABS(1d0-||x||^2/delta^2) > thresh_cc
  ! thresh_rho_2, threshold to cancel the step in the research
  ! of the optimal lambda, the step is cancelled if rho_2 < thresh_rho_2
  print*,'Threshold for the CC:', thresh_cc
  print*,'Threshold for rho_2:', thresh_rho_2  

  print*, 'w_1^T . g =', tmp_wtg(1)

  ! Debug
  !if (debug) then
  !    print*, 'Iteration    rho_2    lambda    delta  ||x||  |1-(||x||^2/delta^2)|'
  !endif

  ! Initialization  
  i = 1
  f_N = f_norm_trust_region_omp(n,e_val,tmp_wtg,lambda) ! Value of the ||x(lambda)||^2
  model = 0d0           ! predicted value of (||x||^2 - delta^2)^2
  prev_f_N = 0d0    ! previous value of ||x||^2
  prev_f_R = 0d0    ! previous value of (||x||^2 - delta^2)^2
  f_R = 0d0         ! value of (||x||^2 - delta^2)^2
  rho_2 = 0d0       ! (prev_f_R - f_R)/(prev_f_R - m)
  y = 0d0           ! step size
  prev_lambda = 0d0 ! previous lambda

    ! Derivatives
    if (version_lambda_search == 1) then
      d_1 = d1_norm_trust_region_omp(n,e_val,tmp_wtg,lambda,delta) ! first derivative of (||x(lambda)||^2 - delta^2)^2
      d_2 = d2_norm_trust_region_omp(n,e_val,tmp_wtg,lambda,delta) ! second derivative of (||x(lambda)||^2 - delta^2)^2
    else
      d_1 = d1_norm_inverse_trust_region_omp(n,e_val,tmp_wtg,lambda,delta) ! first derivative of (1/||x(lambda)||^2 - 1/delta^2)^2
      d_2 = d2_norm_inverse_trust_region_omp(n,e_val,tmp_wtg,lambda,delta) ! second derivative of (1/||x(lambda)||^2 - 1/delta^2)^2
    endif

    ! Trust length
    alpha = DABS((1d0/d_2)*d_1)

    ! Newton's method
    do while (i <= 100 .and. DABS(1d0-f_N/delta**2) > thresh_cc)
      print*,'--------------------------------------'
      print*,'Research of lambda, iteration:', i
      print*,'--------------------------------------'

      ! Update of f_N, f_R and the derivatives
      prev_f_N = f_N 
      if (version_lambda_search == 1) then
        prev_f_R = (prev_f_N - delta**2)**2
        d_1 = d1_norm_trust_region_omp(n,e_val,tmp_wtg,lambda,delta) ! first derivative of (||x(lambda)||^2 - delta^2)^2
        d_2 = d2_norm_trust_region_omp(n,e_val,tmp_wtg,lambda,delta) ! second derivative of (||x(lambda)||^2 - delta^2)^2
      else
        prev_f_R = (1d0/prev_f_N - 1d0/delta**2)**2
        d_1 = d1_norm_inverse_trust_region_omp(n,e_val,tmp_wtg,lambda,delta) ! first derivative of (1/||x(lambda)||^2 - 1/delta^2)^2
        d_2 = d2_norm_inverse_trust_region_omp(n,e_val,tmp_wtg,lambda,delta) ! second derivative of (1/||x(lambda)||^2 - 1/delta^2)^2
      endif
      write(*,'(a,E12.5,a,E12.5)') ' 1st and 2nd derivative: ', d_1,', ', d_2  

      ! Newton's step
      y = -(1d0/DABS(d_2))*d_1

      ! Constraint on y (the newton step)
      if (DABS(y) > alpha) then
        y = alpha * (y/DABS(y)) ! preservation of the sign of y
      endif
      write(*,'(a,E12.5)') ' Step length: ', y

      ! Predicted value of (||x(lambda)||^2 - delta^2)^2, Taylor series
      model = prev_f_R + d_1 * y + 0.5d0 * d_2 * y**2    

      ! Updates lambda
      prev_lambda = lambda
      lambda = prev_lambda + y
      print*,'prev lambda:', prev_lambda
      print*,'new lambda:', lambda

      ! Checks if lambda is in (-h_1, \infty)
      if (lambda > MAX(0d0, -e_val(1))) then
        ! New value of ||x(lambda)||^2
        f_N = f_norm_trust_region_omp(n,e_val,tmp_wtg,lambda)

        ! New f_R
        if (version_lambda_search == 1) then
          f_R = (f_N - delta**2)**2          ! new value of (||x(lambda)||^2 - delta^2)^2
        else
          f_R = (1d0/f_N - 1d0/delta**2)**2  ! new value of (1/||x(lambda)||^2 -1/delta^2)^2
        endif
        
        if (version_lambda_search == 1) then
          print*,'Previous value of (||x(lambda)||^2 - delta^2)^2:', prev_f_R
          print*,'Actual value of (||x(lambda)||^2 - delta^2)^2:', f_R
          print*,'Predicted value of (||x(lambda)||^2 - delta^2)^2:', model
        else
          print*,'Previous value of (1/||x(lambda)||^2 - 1/delta^2)^2:', prev_f_R
          print*,'Actual value of (1/||x(lambda)||^2 - 1/delta^2)^2:', f_R
          print*,'Predicted value of (1/||x(lambda)||^2 - 1/delta^2)^2:', model
        endif

        print*,'previous - actual:', prev_f_R - f_R
        print*,'previous - model:', prev_f_R - model

        ! Check the gain
        if (DABS(prev_f_R - model) < thresh_model_2) then
          print*,''
          print*,'WARNING: ABS(previous - model) <', thresh_model_2, 'rho_2 will tend toward infinity'
          print*,''
        endif        

        ! Will be deleted
        !if (prev_f_R - f_R <= 1d-16 .or. prev_f_R - model <= 1d-16) then
        !  print*,''
        !  print*,'WARNING: ABS(previous - model) <= 1d-16, exit'
        !  print*,''
        !  exit
        !endif

        ! Computes rho_2
        rho_2 = (prev_f_R - f_R)/(prev_f_R - model)
        print*,'rho_2:', rho_2               
      else
        rho_2 = 0d0 ! in order to reduce the size of the trust region, alpha, until lambda is in (-h_1, \infty)
        print*,'lambda < -e_val(1) ===> rho_2 = 0'
      endif

      ! Evolution of the trust length, alpha
      if (rho_2 >= 0.75d0) then
        alpha = 2d0 * alpha
      elseif (rho_2 >= 0.5d0) then
        alpha = alpha
      elseif (rho_2 >= 0.25d0) then
        alpha = 0.5d0 * alpha
      else 
        alpha = 0.25d0 * alpha
      endif
      write(*,'(a,E12.5)') ' New trust length alpha: ', alpha

      ! cancellaion of the step if rho < 0.1
      if (rho_2 < thresh_rho_2) then !0.1d0) then
        lambda = prev_lambda
        f_N = prev_f_N
        print*,'Rho_2 <', thresh_rho_2,', cancellation of the step: lambda = prev_lambda'
      endif

      print*,''
      print*,'lambda, ||x||, delta:'
      print*, lambda, dsqrt(f_N), delta
      print*,'CC:', DABS(1d0 - f_N/delta**2)
      print*,''
      
      i = i + 1
    enddo

  ! if trust newton failed
  if (i > nb_it_max_lambda) then
    print*,''
    print*,'######################################################'
    print*,'WARNING: i >', nb_it_max_lambda,'for the trust Newton'
    print*,'The research of the optimal lambda has failed'
    print*,'######################################################'
    print*,''
  endif

  print*,'Number of iterations :', i
  print*,'Value of lambda :', lambda
  print*,'Error on the trust region (1d0-f_N/delta**2) (Convergence criterion) :', 1d0-f_N/delta**2
  print*,'Error on the trust region (||x||^2 - delta^2)^2) :', (f_N - delta**2)**2
  print*,'Error on the trust region (1/||x||^2 - 1/delta^2)^2)', (1d0/f_N - 1d0/delta**2)**2

  ! Time
  call wall_time(t2)
  t3 = t2 - t1
  print*,'Time in trust_newton:', t3

  print*,'' 
  print*,'---End trust_newton---'
  print*,''

end subroutine

! OMP: First derivative of (||x||^2 - Delta^2)^2

! *Function to compute the first derivative of (||x||^2 - Delta^2)^2*

! This function computes the first derivative of (||x||^2 - Delta^2)^2
! with respect to lambda.

! \begin{align*}
! \frac{\partial }{\partial \lambda} (||\textbf{x}(\lambda)||^2 - \Delta^2)^2 
! = -4 \left(\sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3} \right)
! \left( - \Delta^2 + \sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i+ \lambda)^2} \right)
! \end{align*}

! \begin{align*}
!   \text{accu1} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2} \\
!   \text{accu2} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3}
! \end{align*}

! Provided:
! | mo_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | accu1      | double precision | first sum of the formula           |
! | accu2      | double precision | second sum of the formula          |
! | tmp_accu1  | double precision | temporary array for the first sum  |
! | tmp_accu2  | double precision | temporary array for the second sum |
! | tmp_wtg(n) | double precision | temporary array for W^t.v_grad     |
! | i,j        | integer          | indexes                            |

! Function:
! | d1_norm_trust_region | double precision | first derivative with respect to lambda of (norm(x)^2 - Delta^2)^2 |


function d1_norm_trust_region_omp(n,e_val,tmp_wtg,lambda,delta)
  
  use omp_lib
  include 'pi.h'

  BEGIN_DOC
  ! Compute the first derivative with respect to lambda of (||x(lambda)||^2 - Delta^2)^2
  END_DOC

  implicit none

  ! in
  integer, intent(in)           :: n
  double precision, intent(in)  :: e_val(n)
  double precision, intent(in)  :: tmp_wtg(n)
  double precision, intent(in)  :: lambda
  double precision, intent(in)  :: delta
   
  ! Internal
  double precision              :: wtg,accu1,accu2
  integer                       :: i,j
  double precision, allocatable :: tmp_accu1(:), tmp_accu2(:)

  ! Functions
  double precision              :: d1_norm_trust_region_omp

  ! Allocation
  allocate(tmp_accu1(n), tmp_accu2(n))

  ! OMP
  call omp_set_max_active_levels(1)

  ! OMP 
  !$OMP PARALLEL                                         &
      !$OMP PRIVATE(i,j)                                 &
      !$OMP SHARED(n,lambda, e_val, thresh_eig,&
      !$OMP tmp_accu1, tmp_accu2, tmp_wtg, accu1,accu2)  &
      !$OMP DEFAULT(NONE)

  !$OMP MASTER
  accu1 = 0d0
  accu2 = 0d0
  !$OMP END MASTER

  !$OMP DO
  do i = 1, n
    tmp_accu1(i) = 0d0
  enddo
  !$OMP END DO

  !$OMP DO
  do i = 1, n
    tmp_accu2(i) = 0d0
  enddo
  !$OMP END DO

  !$OMP DO
  do i = 1, n
    if (ABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu1(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**2 
    endif
  enddo
  !$OMP END DO
 
  !$OMP MASTER
  do i = 1, n 
    accu1 = accu1 + tmp_accu1(i)
  enddo
  !$OMP END MASTER

  !$OMP DO
  do i = 1, n
    if (ABS(e_val(i)) > thresh_eig) then
      tmp_accu2(i) =  tmp_wtg(i)**2 / (e_val(i) + lambda)**3 
    endif
  enddo
  !$OMP END DO

  !$OMP MASTER
  do i = 1, n
    accu2 = accu2 + tmp_accu2(i)
  enddo
  !$OMP END MASTER

  !$OMP END PARALLEL

  call omp_set_max_active_levels(4)

  d1_norm_trust_region_omp = -4d0 * accu2 * (accu1 - delta**2)

  deallocate(tmp_accu1, tmp_accu2)

end function

! OMP: Second derivative of (||x||^2 - Delta^2)^2

! *Function to compute the second derivative of (||x||^2 - Delta^2)^2*

! This function computes the second derivative of (||x||^2 - Delta^2)^2
! with respect to lambda.
! \begin{align*}
! \frac{\partial^2 }{\partial \lambda^2} (||\textbf{x}(\lambda)||^2 - \Delta^2)^2 
! = 2 \left[ \left( \sum_{i=1}^n 6 \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^4} \right) \left( - \Delta^2 + \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \right) + \left( \sum_{i=1}^n -2 \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \right)^2 \right]
! \end{align*}

! \begin{align*}
!   \text{accu1} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \\
!   \text{accu2} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \\
!   \text{accu3} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^4} 
! \end{align*}

! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | accu1      | double precision | first sum of the formula           |
! | accu2      | double precision | second sum of the formula          |
! | accu3      | double precision | third sum of the formula           |
! | tmp_accu1  | double precision | temporary array for the first sum  |
! | tmp_accu2  | double precision | temporary array for the second sum |
! | tmp_accu2  | double precision | temporary array for the third sum  |
! | tmp_wtg(n) | double precision | temporary array for W^t.v_grad     |
! | i,j        | integer          | indexes                            |

! Function:
! | d2_norm_trust_region | double precision | second derivative with respect to lambda of (norm(x)^2 - Delta^2)^2 |


function d2_norm_trust_region_omp(n,e_val,tmp_wtg,lambda,delta)
  
  use omp_lib
  include 'pi.h'

  BEGIN_DOC
  ! Compute the second derivative with respect to lambda of (||x(lambda)||^2 - Delta^2)^2
  END_DOC
  
  implicit none

  ! Variables

  ! in
  integer, intent(in)           :: n
  double precision, intent(in)  :: e_val(n)
  double precision, intent(in)  :: tmp_wtg(n)
  double precision, intent(in)  :: lambda
  double precision, intent(in)  :: delta

  ! Functions
  double precision              :: d2_norm_trust_region_omp
  double precision              :: ddot

  ! Internal
  double precision              :: accu1,accu2,accu3
  double precision, allocatable :: tmp_accu1(:), tmp_accu2(:), tmp_accu3(:)
  integer :: i, j
  
  ! Allocation
  allocate(tmp_accu1(n), tmp_accu2(n), tmp_accu3(n))

  call omp_set_max_active_levels(1)

  ! OMP 
  !$OMP PARALLEL                                         &
      !$OMP PRIVATE(i,j)                                 &
      !$OMP SHARED(n,lambda, e_val, thresh_eig,&
      !$OMP tmp_accu1, tmp_accu2, tmp_accu3, tmp_wtg,    &
      !$OMP accu1, accu2, accu3)                         &
      !$OMP DEFAULT(NONE)

  ! Initialization

  !$OMP MASTER
  accu1 = 0d0
  accu2 = 0d0
  accu3 = 0d0 
  !$OMP END MASTER

  !$OMP DO
  do i = 1, n 
    tmp_accu1(i) = 0d0
  enddo
  !$OMP END DO
  !$OMP DO
  do i = 1, n
    tmp_accu2(i) = 0d0
  enddo
  !$OMP END DO
  !$OMP DO
  do i = 1, n
    tmp_accu3(i) = 0d0
  enddo
  !$OMP END DO

  ! Calculations

  ! accu1
  !$OMP DO
  do i = 1, n
    if (ABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu1(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**2
    endif
  enddo
  !$OMP END DO

  !$OMP MASTER
  do i = 1, n
    accu1 = accu1 + tmp_accu1(i)
  enddo
  !$OMP END MASTER

  ! accu2
  !$OMP DO
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu2(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**3
    endif
  enddo
  !$OMP END DO
 
  ! accu3
  !$OMP MASTER
  do i = 1, n
    accu2 = accu2 + tmp_accu2(i)
  enddo
  !$OMP END MASTER

  !$OMP DO
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu3(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**4
    endif
  enddo
  !$OMP END DO

  !$OMP MASTER
  do i = 1, n
    accu3 = accu3 + tmp_accu3(i)
  enddo
  !$OMP END MASTER

  !$OMP END PARALLEL

  d2_norm_trust_region_omp = 2d0 * (6d0 * accu3 * (- delta**2 + accu1) + (-2d0 * accu2)**2)

  deallocate(tmp_accu1, tmp_accu2, tmp_accu3)

end function

! OMP: Function value of ||x||^2

! *Compute the value of ||x||^2*

! This function computes the value of ||x(lambda)||^2

! \begin{align*}
! ||\textbf{x}(\lambda)||^2 = \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2}
! \end{align*}

! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |

! Internal:
! | tmp_wtg(n) | double precision | temporary array for W^T.v_grad   |
! | tmp_fN     | double precision | temporary array for the function |
! | i,j        | integer          | indexes                          |


function f_norm_trust_region_omp(n,e_val,tmp_wtg,lambda)

  use omp_lib

  include 'pi.h'

  BEGIN_DOC
  ! Compute ||x(lambda)||^2
  END_DOC
  
  implicit none

  ! Variables

  ! in
  integer, intent(in)           :: n
  double precision, intent(in)  :: e_val(n)
  double precision, intent(in)  :: tmp_wtg(n)
  double precision, intent(in)  :: lambda
 
  ! functions
  double precision              :: f_norm_trust_region_omp
 
  ! internal
  double precision, allocatable :: tmp_fN(:)
  integer                       :: i,j

  ! Allocation
  allocate(tmp_fN(n))

  call omp_set_max_active_levels(1)

  ! OMP 
  !$OMP PARALLEL                                         &
      !$OMP PRIVATE(i,j)                                 &
      !$OMP SHARED(n,lambda, e_val, thresh_eig,&
      !$OMP tmp_fN, tmp_wtg, f_norm_trust_region_omp)    &
      !$OMP DEFAULT(NONE)

  ! Initialization

  !$OMP MASTER
  f_norm_trust_region_omp = 0d0
  !$OMP END MASTER

  !$OMP DO
  do i = 1, n
    tmp_fN(i) = 0d0
  enddo
  !$OMP END DO

  ! Calculations 
  !$OMP DO
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
       tmp_fN(i) = tmp_wtg(i)**2 / (e_val(i) + lambda)**2
    endif
  enddo
  !$OMP END DO
  
  !$OMP MASTER
  do i = 1, n
    f_norm_trust_region_omp =  f_norm_trust_region_omp + tmp_fN(i)
  enddo
  !$OMP END MASTER

  !$OMP END PARALLEL

  deallocate(tmp_fN)

end function

! First derivative of (||x||^2 - Delta^2)^2
! Version without omp

! *Function to compute the first derivative of ||x||^2 - Delta*

! This function computes the first derivative of (||x||^2 - Delta^2)^2
! with respect to lambda.

! \begin{align*}
! \frac{\partial }{\partial \lambda} (||\textbf{x}(\lambda)||^2 - \Delta^2)^2 
! = 2 \left(-2\sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \right)
! \left( - \Delta^2 + \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i+ \lambda)^2} \right)
! \end{align*}

! \begin{align*}
! \text{accu1} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \\
! \text{accu2} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3}
! \end{align*}

! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | accu1 | double precision | first sum of the formula               |
! | accu2 | double precision | second sum of the formula              |
! | wtg   | double precision | temporary variable to store W^T.v_grad |
! | i,j   | integer          | indexes                                |

! Function:
! | d1_norm_trust_region | double precision | first derivative with respect to lambda of (norm(x)^2 - Delta^2)^2 |
! | ddot                 | double precision | blas dot product                                                   |


function d1_norm_trust_region(n,e_val,w,v_grad,lambda,delta)

  include 'pi.h'

  BEGIN_DOC
  ! Compute the first derivative with respect to lambda of (||x(lambda)||^2 - Delta^2)^2 
  END_DOC
  
  implicit none

  ! Variables
  
  ! in
  integer, intent(in)          :: n
  double precision, intent(in) :: e_val(n)
  double precision, intent(in) :: w(n,n)
  double precision, intent(in) :: v_grad(n)
  double precision, intent(in) :: lambda
  double precision, intent(in) :: delta

  ! Internal
  double precision             :: wtg, accu1, accu2
  integer                      :: i, j

  ! Functions
  double precision             :: d1_norm_trust_region
  double precision             :: ddot

  ! Initialization
  accu1 = 0d0
  accu2 = 0d0

  do i = 1, n
    wtg = 0d0
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      !wtg = ddot(n,w(:,i),1,v_grad,1)
      accu1 = accu1 + wtg**2 / (e_val(i) + lambda)**2 
    endif
  enddo

  do i = 1, n
    wtg = 0d0
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      !wtg = ddot(n,w(:,i),1,v_grad,1)
      accu2 = accu2 - 2d0 * wtg**2 / (e_val(i) + lambda)**3 
    endif
  enddo

  d1_norm_trust_region = 2d0 * accu2 * (accu1 - delta**2)

end function

! Second derivative of (||x||^2 - Delta^2)^2
! Version without OMP

! *Function to compute the second derivative of ||x||^2 - Delta*


! \begin{equation}
! \frac{\partial^2 }{\partial \lambda^2} (||\textbf{x}(\lambda)||^2 - \Delta^2)^2 
! = 2 \left[ \left( \sum_{i=1}^n 6 \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^4} \right) \left( - \Delta^2 + \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \right) + \left( \sum_{i=1}^n -2 \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \right)^2 \right]
! \end{equation}

! \begin{align*}
! \text{accu1} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \\
! \text{accu2} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \\
! \text{accu3} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^4}
! \end{align*}
! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | accu1 | double precision | first sum of the formula               |
! | accu2 | double precision | second sum of the formula              |
! | accu3 | double precision | third sum of the formula                |
! | wtg   | double precision | temporary variable to store W^T.v_grad |
! | i,j   | integer          | indexes                                |

! Function:
! | d2_norm_trust_region | double precision | second derivative with respect to lambda of norm(x)^2 - Delta^2       |
! | ddot                 | double precision | blas dot product                                               |


function d2_norm_trust_region(n,e_val,w,v_grad,lambda,delta)

  include 'pi.h'

  BEGIN_DOC
  ! Compute the second derivative with respect to lambda of (||x(lambda)||^2 - Delta^2)^2 
  END_DOC

  implicit none

  ! Variables

  ! in
  integer, intent(in) :: n
  double precision, intent(in) :: e_val(n)
  double precision, intent(in) :: w(n,n)
  double precision, intent(in) :: v_grad(n)
  double precision, intent(in) :: lambda
  double precision, intent(in) :: delta

  ! Functions
  double precision :: d2_norm_trust_region
  double precision :: ddot

  ! Internal
  double precision :: wtg,accu1,accu2,accu3
  integer :: i, j

  ! Initialization
  accu1 = 0d0
  accu2 = 0d0
  accu3 = 0d0

  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      wtg = 0d0
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      !wtg = ddot(n,w(:,i),1,v_grad,1)
      accu1 = accu1 + wtg**2 / (e_val(i) + lambda)**2 !4
    endif
  enddo

  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      wtg = 0d0
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      !wtg = ddot(n,w(:,i),1,v_grad,1)
      accu2 = accu2 - 2d0 * wtg**2 / (e_val(i) + lambda)**3 !2
    endif
  enddo

  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      wtg = 0d0
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      !wtg = ddot(n,w(:,i),1,v_grad,1)
      accu3 = accu3 + 6d0 * wtg**2 / (e_val(i) + lambda)**4 !3
    endif
  enddo

  d2_norm_trust_region = 2d0 * (accu3 * (- delta**2 + accu1) + accu2**2)

end function

! Function value of ||x||^2
! Version without OMP

! *Compute the value of ||x||^2*

! This function computes the value of ||x(lambda)||^2

! \begin{align*}
! ||\textbf{x}(\lambda)||^2 = \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2}
! \end{align*}

! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | wtg   | double precision | temporary variable to store W^T.v_grad |
! | i,j   | integer          | indexes                                |

! Function:
! | f_norm_trust_region | double precision | value of norm(x)^2 |
! | ddot                | double precision | blas dot product   |



function f_norm_trust_region(n,e_val,tmp_wtg,lambda)

  include 'pi.h'

  BEGIN_DOC
  ! Compute ||x(lambda)||^2
  END_DOC
  
  implicit none

  ! Variables

  ! in
  integer, intent(in)          :: n
  double precision, intent(in) :: e_val(n)
  double precision, intent(in) :: tmp_wtg(n)
  double precision, intent(in) :: lambda
  
  ! function
  double precision             :: f_norm_trust_region
  double precision             :: ddot

  ! internal
  integer                      :: i,j

  ! Initialization
  f_norm_trust_region = 0d0

  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then    
      f_norm_trust_region = f_norm_trust_region + tmp_wtg(i)**2 / (e_val(i) + lambda)**2
    endif
  enddo

end function

! OMP: First derivative of (1/||x||^2 - 1/Delta^2)^2
! Version with OMP

! *Compute the first derivative of (1/||x||^2 - 1/Delta^2)^2*

! This function computes the value of (1/||x(lambda)||^2 - 1/Delta^2)^2

! \begin{align*}
!   \frac{\partial}{\partial \lambda} (1/||\textbf{x}(\lambda)||^2 - 1/\Delta^2)^2 
!   &= 4 \frac{\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3}}
!        {(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3} 
!      - \frac{4}{\Delta^2} \frac{\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3)}}
!        {(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \\
!   &= 4 \sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3}
!        \left( \frac{1}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3}
!       - \frac{1}{\Delta^2 (\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \right)
! \end{align*}

! \begin{align*}
! \text{accu1} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \\
! \text{accu2} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3}
! \end{align*}

! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | wtg        | double precision | temporary variable to store W^T.v_grad |
! | tmp_accu1  | double precision | temporary array for the first sum      |
! | tmp_accu2  | double precision | temporary array for the second sum     |
! | tmp_wtg(n) | double precision | temporary array for W^t.v_grad         |
! | i,j        | integer          | indexes                                |

! Function:
! | d1_norm_inverse_trust_region | double precision | value of the first derivative |


function d1_norm_inverse_trust_region_omp(n,e_val,tmp_wtg,lambda,delta)

  use omp_lib
  include 'pi.h'

  BEGIN_DOC
  ! Compute the first derivative of (1/||x||^2 - 1/Delta^2)^2
  END_DOC

  implicit none

  ! Variables
  
  ! in
  integer, intent(in)           :: n
  double precision, intent(in)  :: e_val(n)
  double precision, intent(in)  :: tmp_wtg(n)
  double precision, intent(in)  :: lambda
  double precision, intent(in)  :: delta

  ! Internal
  double precision              :: accu1, accu2
  integer                       :: i,j
  double precision, allocatable :: tmp_accu1(:), tmp_accu2(:)

  ! Functions
  double precision              :: d1_norm_inverse_trust_region_omp

  ! Allocation
  allocate(tmp_accu1(n), tmp_accu2(n))

  ! OMP
  call omp_set_max_active_levels(1)

  ! OMP 
  !$OMP PARALLEL                                         &
      !$OMP PRIVATE(i,j)                                 &
      !$OMP SHARED(n,lambda, e_val, thresh_eig,&
      !$OMP tmp_accu1, tmp_accu2, tmp_wtg, accu1, accu2) &
      !$OMP DEFAULT(NONE)
  
  !$OMP MASTER
  accu1 = 0d0
  accu2 = 0d0
  !$OMP END MASTER

  !$OMP DO 
  do i = 1, n
    tmp_accu1(i) = 0d0
  enddo
  !$OMP END DO

  !$OMP DO 
  do i = 1, n
    tmp_accu2(i) = 0d0
  enddo
  !$OMP END DO

!  !$OMP MASTER
!  do i = 1, n
!    if (ABS(e_val(i)+lambda) > 1d-12) then
!      tmp_accu1(i) = tmp_wtg(i)**2 / (e_val(i) + lambda)**2
!    endif
!  enddo
!  !$OMP END MASTER

  !$OMP DO
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu1(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**2 
    endif
  enddo
  !$OMP END DO

  !$OMP MASTER
  do i = 1, n
    accu1 = accu1 + tmp_accu1(i)
  enddo  
  !$OMP END MASTER

!  !$OMP MASTER
!  do i = 1, n
!    if (ABS(e_val(i)+lambda) > 1d-12) then
!      tmp_accu2(i) = tmp_wtg(i)**2 / (e_val(i) + lambda)**3
!    endif
!  enddo
!  !$OMP END MASTER

  !$OMP DO
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu2(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**3 
    endif
  enddo
  !$OMP END DO

  !$OMP MASTER
  do i = 1, n
    accu2 = accu2 + tmp_accu2(i)
  enddo  
  !$OMP END MASTER
  
  !$OMP END PARALLEL

  call omp_set_max_active_levels(4)

  d1_norm_inverse_trust_region_omp = 4d0 * accu2 * (1d0/accu1**3 - 1d0/(delta**2 * accu1**2))

  deallocate(tmp_accu1, tmp_accu2)
 
end

! OMP: Second derivative of (1/||x||^2 - 1/Delta^2)^2
! Version with OMP

! *Compute the first derivative of (1/||x||^2 - 1/Delta^2)^2*

! This function computes the value of (1/||x(lambda)||^2 - 1/Delta^2)^2

! \begin{align*}
!   \frac{\partial^2}{\partial \lambda^2} (1/||\textbf{x}(\lambda)||^2 - 1/\Delta^2)^2 
!   &= 4 \left[ \frac{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3)})^2}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^4} 
!   - 3 \frac{\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^4}}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3} \right] \\
!   &- \frac{4}{\Delta^2} \left[ \frac{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3)})^2}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3}
!   - 3 \frac{\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^4}}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \right]
! \end{align*}


! \begin{align*}
! \text{accu1} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \\
! \text{accu2} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \\
! \text{accu3} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^4}
! \end{align*}

! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | wtg        | double precision | temporary variable to store W^T.v_grad |
! | tmp_accu1  | double precision | temporary array for the first sum      |
! | tmp_accu2  | double precision | temporary array for the second sum     |
! | tmp_wtg(n) | double precision | temporary array for W^t.v_grad         |
! | i,j        | integer          | indexes                                |

! Function:
! | d1_norm_inverse_trust_region | double precision | value of the first derivative |


function d2_norm_inverse_trust_region_omp(n,e_val,tmp_wtg,lambda,delta)

  use omp_lib
  include 'pi.h'

  BEGIN_DOC
  ! Compute the second derivative of (1/||x||^2 - 1/Delta^2)^2
  END_DOC

  implicit none

  ! Variables
  
  ! in
  integer, intent(in)          :: n
  double precision, intent(in) :: e_val(n)
  double precision, intent(in) :: tmp_wtg(n)
  double precision, intent(in) :: lambda
  double precision, intent(in) :: delta

  ! Internal
  double precision :: accu1, accu2, accu3
  integer          :: i,j
  double precision, allocatable :: tmp_accu1(:), tmp_accu2(:), tmp_accu3(:)

  ! Functions
  double precision :: d2_norm_inverse_trust_region_omp

  ! Allocation
  allocate(tmp_accu1(n), tmp_accu2(n), tmp_accu3(n))

  ! OMP
  call omp_set_max_active_levels(1)

  ! OMP 
  !$OMP PARALLEL                                         &
      !$OMP PRIVATE(i,j)                                 &
      !$OMP SHARED(n,lambda, e_val, thresh_eig,&
      !$OMP tmp_accu1, tmp_accu2, tmp_accu3, tmp_wtg,    &
      !$OMP accu1, accu2, accu3)                         &
      !$OMP DEFAULT(NONE)
  
  !$OMP MASTER
  accu1 = 0d0
  accu2 = 0d0
  accu3 = 0d0
  !$OMP END MASTER

  !$OMP DO 
  do i = 1, n
    tmp_accu1(i) = 0d0
  enddo
  !$OMP END DO

  !$OMP DO 
  do i = 1, n
    tmp_accu2(i) = 0d0
  enddo
  !$OMP END DO

  !$OMP DO
  do i = 1, n
    tmp_accu3(i) = 0d0
  enddo
  !$OMP END DO

  !$OMP DO
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu1(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**2 
    endif
  enddo
  !$OMP END DO

  !$OMP MASTER
  do i = 1, n
    accu1 = accu1 + tmp_accu1(i)
  enddo  
  !$OMP END MASTER

  !$OMP DO
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu2(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**3 
    endif
  enddo
  !$OMP END DO

  !$OMP MASTER
  do i = 1, n
    accu2 = accu2 + tmp_accu2(i)
  enddo  
  !$OMP END MASTER

  !$OMP DO
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      tmp_accu3(i) = tmp_wtg(i)**2 /  (e_val(i) + lambda)**4
    endif
  enddo
  !$OMP END DO

  !$OMP MASTER
  do i = 1, n
    accu3 = accu3 + tmp_accu3(i)
  enddo  
  !$OMP END MASTER
  
  !$OMP END PARALLEL

  call omp_set_max_active_levels(4)

   d2_norm_inverse_trust_region_omp = 4d0 * (6d0 * accu2**2/accu1**4 - 3d0 * accu3/accu1**3) &
    - 4d0/delta**2 * (4d0 * accu2**2/accu1**3 - 3d0 * accu3/accu1**2)

  deallocate(tmp_accu1,tmp_accu2,tmp_accu3)
 
end

! First derivative of (1/||x||^2 - 1/Delta^2)^2
! Version without OMP

! *Compute the first derivative of (1/||x||^2 - 1/Delta^2)^2*

! This function computes the value of (1/||x(lambda)||^2 - 1/Delta^2)^2

! \begin{align*}
!   \frac{\partial}{\partial \lambda} (1/||\textbf{x}(\lambda)||^2 - 1/\Delta^2)^2 
!   &= 4 \frac{\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3}}
!        {(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3} 
!      - \frac{4}{\Delta^2} \frac{\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3)}}
!        {(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \\
!   &= 4 \sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3}
!        \left( \frac{1}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3}
!       - \frac{1}{\Delta^2 (\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \right)
! \end{align*}
! \begin{align*}
! \text{accu1} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \\
! \text{accu2} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} 
! \end{align*}
! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | wtg   | double precision | temporary variable to store W^T.v_grad |
! | i,j   | integer          | indexes                                |

! Function:
! | d1_norm_inverse_trust_region | double precision | value of the first derivative |


function d1_norm_inverse_trust_region(n,e_val,w,v_grad,lambda,delta)

  include 'pi.h'

  BEGIN_DOC
  ! Compute the first derivative of (1/||x||^2 - 1/Delta^2)^2
  END_DOC

  implicit none

  ! Variables
  
  ! in
  integer, intent(in)          :: n
  double precision, intent(in) :: e_val(n)
  double precision, intent(in) :: w(n,n)
  double precision, intent(in) :: v_grad(n)
  double precision, intent(in) :: lambda
  double precision, intent(in) :: delta

  ! Internal
  double precision             :: wtg, accu1, accu2
  integer                      :: i,j

  ! Functions
  double precision             :: d1_norm_inverse_trust_region
  
  accu1 = 0d0
  accu2 = 0d0

  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      wtg = 0d0
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      accu1 = accu1 + wtg**2 / (e_val(i) + lambda)**2
    endif
  enddo
  
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      wtg = 0d0
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      accu2 = accu2 + wtg**2 / (e_val(i) + lambda)**3
    endif
  enddo

  d1_norm_inverse_trust_region = 4d0 * accu2 * (1d0/accu1**3 - 1d0/(delta**2 * accu1**2))
 
end

! Second derivative of (1/||x||^2 - 1/Delta^2)^2
! Version without OMP

! *Compute the second derivative of (1/||x||^2 - 1/Delta^2)^2*

! This function computes the value of (1/||x(lambda)||^2 - 1/Delta^2)^2

! \begin{align*}
!   \frac{\partial^2}{\partial \lambda^2} (1/||\textbf{x}(\lambda)||^2 - 1/\Delta^2)^2 
!   &= 4 \left[ \frac{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3)})^2}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^4} 
!   - 3 \frac{\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^4}}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3} \right] \\
!   &- \frac{4}{\Delta^2} \left[ \frac{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^3)})^2}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^3}
!   - 3 \frac{\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^4}}{(\sum_i \frac{(\textbf{w}_i^T \cdot \textbf{g})^2}{(h_i + \lambda)^2})^2} \right]
! \end{align*}

! \begin{align*}
! \text{accu1} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^2} \\
! \text{accu2} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^3} \\
! \text{accu3} &= \sum_{i=1}^n \frac{(\textbf{w}_i^T \textbf{g})^2}{(h_i + \lambda)^4}
! \end{align*}

! Provided:
! | m_num | integer | number of MOs |

! Input:
! | n         | integer          | mo_num*(mo_num-1)/2         |
! | e_val(n)  | double precision | eigenvalues of the hessian  |
! | W(n,n)    | double precision | eigenvectors of the hessian |
! | v_grad(n) | double precision | gradient                    |
! | lambda    | double precision | Lagrange multiplier         |
! | delta     | double precision | Delta of the trust region   |

! Internal:
! | wtg   | double precision | temporary variable to store W^T.v_grad |
! | i,j   | integer          | indexes                                |

! Function:
! | d2_norm_inverse_trust_region | double precision | value of the first derivative |


function d2_norm_inverse_trust_region(n,e_val,w,v_grad,lambda,delta)

  include 'pi.h'

  BEGIN_DOC
  ! Compute the second derivative of (1/||x||^2 - 1/Delta^2)^2
  END_DOC

  implicit none

  ! Variables
  
  ! in
  integer, intent(in)          :: n
  double precision, intent(in) :: e_val(n)
  double precision, intent(in) :: w(n,n)
  double precision, intent(in) :: v_grad(n)
  double precision, intent(in) :: lambda
  double precision, intent(in) :: delta

  ! Internal
  double precision             :: wtg, accu1, accu2, accu3
  integer                      :: i,j

  ! Functions
  double precision             :: d2_norm_inverse_trust_region
  
  accu1 = 0d0
  accu2 = 0d0
  accu3 = 0d0

  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      wtg = 0d0
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      accu1 = accu1 + wtg**2 / (e_val(i) + lambda)**2
    endif
  enddo
  
  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      wtg = 0d0
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      accu2 = accu2 + wtg**2 / (e_val(i) + lambda)**3
    endif
  enddo

  do i = 1, n
    if (DABS(e_val(i)) > thresh_eig .and. DABS(e_val(i)+lambda) > thresh_eig) then
      wtg = 0d0
      do j = 1, n
        wtg = wtg + w(j,i) * v_grad(j)
      enddo
      accu3 = accu3 + wtg**2 / (e_val(i) + lambda)**4
    endif
  enddo

  d2_norm_inverse_trust_region = 4d0 * (6d0 * accu2**2/accu1**4 - 3d0 * accu3/accu1**3) &
    - 4d0/delta**2 * (4d0 * accu2**2/accu1**3 - 3d0 * accu3/accu1**2)
  
end
