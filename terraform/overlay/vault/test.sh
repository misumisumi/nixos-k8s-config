KEYS=(
  "N5f6JHheL0EMlTUek87mBfg2huy0vJQ4FRgOitXSl5D/"
  "pDNrTnBPPRa2zlmoHZhJzqRvKy/b4TFTsuRsiMJagzn8"
  "smO7dU4mZDrlUsINqtDtbmv0xE5djCDhWtNuzWxIHxTO"
  # "rfdBT/WB3qng96Ce0lCxI69NvRexToA50p8DK06pDdn+"
  # "mRIDM/xcbscd1PBqVeNM+qYeTqZ5eoybPwiQ8iIf9xBo"
)

for key in ${KEYS[@]}; do
  # incus exec vault1 -- vault operator unseal "$key"
  incus exec vault2 -- vault operator unseal "$key"
  incus exec vault3 -- vault operator unseal "$key"
done
