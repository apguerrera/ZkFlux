from brownie import *


def main():
    # Deploy Members library first, it is needed by ZkFluxBallot
    Members.deploy({'from': accounts[0]})

    # Deploy ZkFluxBallot with externalNullifier = 123
    ZkFluxBallot.deploy(123, {'from': accounts[0]})
