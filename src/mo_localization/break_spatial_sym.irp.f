! ! A small program to break the spatial symmetry of the MOs.

! ! You have to defined your MO classes or set security_mo_class to false
! ! with:
! ! qp set orbital_optimization security_mo_class false

! ! The default angle for the rotations is too big for this kind of
! ! application, a value between 1e-3 and 1e-6 should break the spatial
! ! symmetry with just a small change in the energy. 


program break_spatial_sym

  !BEGIN_DOC
  ! Break the symmetry of the MOs with a rotation
  !END_DOC

  implicit none

  kick_in_mos = .True.
  TOUCH kick_in_mos

  print*, 'Security mo_class:', security_mo_class

  ! The default mo_classes are setted only if the MOs to localize are not specified
  if (security_mo_class .and. (dim_list_act_orb == mo_num .or. &
      dim_list_core_orb + dim_list_act_orb == mo_num)) then

    print*, 'WARNING'
    print*, 'You must set different mo_class with qp set_mo_class'
    print*, 'If you want to kick all the orbitals:'
    print*, 'qp set orbital_optimization security_mo_class false'
    print*, ''
    print*, 'abort'

    call abort
  
  endif
  
  call apply_pre_rotation
  
end
