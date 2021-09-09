import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import P "mo:base/Prelude";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Registry "./Registry";

actor class RegistrarCore(owner: Principal, registry: Principal, my_node: Text) {

    stable var grace_period: Time.Time = 1000000;
    stable var owners: [Principal] = [owner];
    stable var persisted_expiries: [(Text, Time.Time)] = [];

    let REGISTRY = actor (Principal.toText(registry)) : Registry.Registry;
    var expiries = HashMap.HashMap<Text.Text, Time.Time>(0, Text.equal, Text.hash);

    public query func available(node: Text) : async Bool {
        _available(node)
    };
    
    public query func getExpiry(node: Text) : async ?Time.Time {
        expiries.get(node)
    };

    public func registerNode(node: Text, owner: Principal, duration: Time.Time) : async () {
        if (_available(node)) {
            let expiry = Time.now() + duration;
            expiries.put(node, Time.now() + duration);
            ignore await REGISTRY.createSubRecord(Text.hash(my_node), node, owner, expiry);
        };
    };

    public func renew(node: Text, duration: Time.Time) : async ?Time.Time {
        if (duration > 0 and not _available(node)) {
            let new_expiry = switch (expiries.get(node)) {
                case (?exp) { exp };
                case (_) { P.unreachable() };
            };
            expiries.put(node, new_expiry);
            ignore await REGISTRY.updateRecordResolverOrExpiry(Text.hash(node), null, ?new_expiry);
            return expiries.get(node);
        };
        null
    };

    public shared(msg) func setGracePeriod(new_grace_period: Time.Time) : async Bool {
        if (onlyOwners(msg.caller)) {
            grace_period := new_grace_period;
            return true;
        };
        false
    };

    public shared(msg) func addOwner(new_owner: Principal) : async Bool {
        if (onlyOwners(msg.caller)) {
            owners := Array.append(owners, [new_owner]);
            return true;
        };
        false
    };

    public shared(msg) func removeOwner(owner: Principal) : async Bool {
        if (owners.size() > 1 and onlyOwners(msg.caller)) {
            owners := Array.filter(owners, func(x: Principal) : Bool { x != owner });
            return true;
        };
        false
    };

    public shared(msg) func migrateRegistrar(new_registrar: Principal) : async Bool {
        if (onlyOwners(msg.caller)) {
            return await REGISTRY.transferRecord(Text.hash(my_node), new_registrar);
        };
        false
    };

    func onlyOwners(caller: Principal) : Bool {
        for (owner in owners.vals()) {
            if (owner == caller) {
                return true;
            };
        };
        false
    };

    func _available(node: Text) : Bool {
        switch (expiries.get(node)) {
            case (?expiry) {
                (expiry + grace_period) < Time.now()
            };
            case (_) true;
        }
    };

    system func preupgrade() {
        persisted_expiries := Iter.toArray(expiries.entries());
    };

    system func postupgrade() {
        expiries := HashMap.fromIter(persisted_expiries.vals(), persisted_expiries.size(), Text.equal, Text.hash);
        persisted_expiries := [];
    };

};
