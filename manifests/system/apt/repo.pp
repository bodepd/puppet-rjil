define rjil::system::apt::repo(
  $location,
  $release,
  $repos,
  $include_src,
  $key         = undef,
  $key_content = undef
) {
  ::apt::source { $name:
    location    => $location,
    release     => $release,
    repos       => $repos,
    include_src => $include_src,
    key         => $key,
    key_content => $key_content
  }
}
