from util import test_deploy, call_function, wrong, prettify_args, transact_function, get_event
import random


def deploy(w3, owner, contract_path, contract_name):

    contract = test_deploy(w3, owner, contract_path, contract_name)
    return contract
