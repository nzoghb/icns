import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";

import Registrar "./RegistrarCore";
import Registry "./Registry";
import Resolver "./ResolverNeuron";

actor {

    let TLD = "icp";

    public shared(msg) func init() : async (Principal, Principal, Principal) {
        let init_cycles = Cycles.balance() / 10;
        Cycles.add(init_cycles);
        let registry = Principal.fromActor(await Registry.Registry());
        Cycles.add(init_cycles);
        let registrar = Principal.fromActor(await Registrar.RegistrarCore(msg.caller, registry, TLD));
        Cycles.add(init_cycles);
        let resolver = Principal.fromActor(await Resolver.ResolverNeuron(msg.caller));

        (registry, registrar, resolver)
    };

};
