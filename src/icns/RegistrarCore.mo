import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import P "mo:base/Prelude";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Registry "./Registry";

actor class RegistrarCore(owner: Principal, registry: Principal, root_entity: Text) {

    stable var grace_period: Time.Time = 1000000;
    stable var owners: [Principal] = [owner];
    stable var persisted_expiries: [(Text, Time.Time)] = [];
    stable var ROOT = "";

    let REGISTRY = actor (Principal.toText(registry)) : Registry.Registry;
    var expiries = HashMap.HashMap<Text.Text, Time.Time>(0, Text.equal, Text.hash);

    public query func getRoot() : async Text.Text {
        ROOT
    };

    public query func available(entity: Text) : async Bool {
        _available(entity)
    };

    public query func getExpiry(entity: Text) : async ?Time.Time {
        expiries.get(entity)
    };

    public func registerEntity(entity: Text, owner: Principal, duration: Time.Time) : async () {
        if (_available(entity)) {
            let expiry = Time.now() + duration;
            expiries.put(entity, expiry);
            ignore await REGISTRY.createSubRecord(Text.hash(root_entity), entity, owner, expiry);
        };
    };

    public func renew(entity: Text, duration: Time.Time) : async ?Time.Time {
        if (duration > 0 and not _available(entity)) {
            let new_expiry = switch (expiries.get(entity)) {
                case (?exp) { exp };
                case (_) { P.unreachable() };
            };
            expiries.put(entity, new_expiry);
            ignore await REGISTRY.updateRecordResolverOrExpiry(Text.hash(entity), null, ?new_expiry);
            return expiries.get(entity);
        };
        null
    };

    public shared(msg) func registerRoot(root: Text, resolver: Principal, duration: Time.Time) : async Bool {
        // if (onlyOwners(msg.caller)) {
            let response = await REGISTRY.createTopLevelRecord(root, resolver, Time.now() + duration);
            if (response) { ROOT := root; };
            response
        // };
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
            return await REGISTRY.transferRecord(Text.hash(root_entity), new_registrar);
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

    func _available(entity: Text) : Bool {
        switch (expiries.get(entity)) {
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
