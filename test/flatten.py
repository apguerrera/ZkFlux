
import subprocess

from settings import *
from util import print_break

def flatten(mainsol, outputsol):
    pipe = subprocess.call("../scripts/solidityFlattener.pl --contractsdir={} --mainsol={} --outputsol={} --verbose"
                           .format(CONTRACT_DIR, mainsol, outputsol), shell=True)
    print(pipe)

def flatten_contracts():
    flatten(OPERATED_PATH, "../flattened/{}_flattened.sol".format(OPERATED_NAME))
    flatten(MIMC_PATH, "../flattened/{}_flattened.sol".format(MIMC_NAME))
