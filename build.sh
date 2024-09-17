#! usr/bin/bash

# needed because for some reason it doesn't refer to the correct upgradeable contracts
forge build -R @openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/
