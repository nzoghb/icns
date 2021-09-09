import Principal "mo:base/Principal";

import Registrar "./RegistrarCore";
import Registry "./Registry";
import Resolver "./ResolverText";

actor {

    let TLD = "icp";

    public shared(msg) func init() : async (Principal, Principal, Principal) {
        let registry = Principal.fromActor(await Registry.Registry());
        let registrar = Principal.fromActor(await Registrar.RegistrarCore(msg.caller, registry, TLD));
        let resolver = Principal.fromActor(await Resolver.ResolverText(msg.caller));

        (registry, registrar, resolver)
    };

};
