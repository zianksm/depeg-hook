#! usr/bin/bash

# needed because for some reason it doesn't refer to the correct upgradeable contracts
forge test -R @openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/ $1
