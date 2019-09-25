
include "../circomlib/circuits/mimc.circom";

template Hash2() {
    signal private input a;
    signal private input b;

    signal output o;
    component m = MultiMiMC7(2, 91);
    m.in[0] <== a;
    m.in[1] <== b;
    m.out ==> o;

}

component main = Hash2();
