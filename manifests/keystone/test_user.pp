class rjil::keystone::test_user(
  $password,
  $username     = 'test_user',
  $tenant_name  = 'test_tenant',
) {

  keystone_tenant { $tenant_name:
    ensure      => present,
    enabled     => true,
    description => 'default tenant',
  }
  keystone_user { $username:
    ensure      => present,
    enabled     => true,
    tenant      => $tenant_name,
    password    => $password,
  }

}
