{ lib
, user
, ...
}: {
  users.users.${user}.initialHashedPassword = lib.mkForce "$y$j9T$BnqJw6E2eOpZ0taJi1ofx/$skkrnHXgSLJgEeQGTi7XJ9fJAdhwauXxKtT9d6AWwQ"; # rescue
}