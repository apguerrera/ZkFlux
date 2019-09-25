from web3 import Web3
from web3.middleware import geth_poa_middleware
import subprocess
import os
import sys


from settings import *
from util import test_w3_connected, unlock_and_fund_accounts, print_break
from flatten import flatten_contracts

# Cotnract
import mixer


if __name__ == '__main__':
    #f = open("01_test_output.txt", 'w')

    #--------------------------------------------------------------
    # Initialisation
    #--------------------------------------------------------------
    w3 = Web3(Web3.IPCProvider('../testchain/geth.ipc'))
    w3.middleware_stack.inject(geth_poa_middleware, layer=0)
    # w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7545'))
    # w3 = Web3(Web3.HTTPProvider('http://localhost:8646'))
    test_w3_connected(w3)

    accounts = w3.eth.accounts[:6]
    default_password = ''
    funder = accounts[0]
    owner = accounts[0]
    # Contract variables
    fund_amount = w3.toWei(1000, 'ether')
    unlock_and_fund_accounts(w3, accounts, default_password, funder, fund_amount)
    #--------------------------------------------------------------
    # Deploy and test contracts
    #--------------------------------------------------------------
    print_break('Flattening Contracts')
    flatten_contracts()
    mixer_contract = mixer.deploy(w3, owner, os.path.join(CONTRACT_DIR, MIXER_PATH), MIXER_NAME)
    print(mixer_contract.address)

    # Print to file
    #sys.stdout = f
    #f.close()
