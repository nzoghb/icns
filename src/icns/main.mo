import Principal "mo:base/Principal";

import Registrar "./RegistrarCore";
import Registry "./Registry";
import Resolver "./ResolverText";

actor {

    let TLD = "icp";

    public shared(msg) func init() : async () {
        let registry = await Registry.Registry();
        let registrar = await Registrar.RegistrarCore(msg.caller, Principal.fromActor(registry), TLD);
        let resolver = await Resolver.ResolverText(msg.caller);
    };

};
