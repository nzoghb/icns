import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import P "mo:base/Prelude";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./Types";

actor class Registry() {

    type Record = Types.Record;

    stable var persisted_records : [(Hash.Hash, Record)] = [];

    var records = HashMap.HashMap<Hash.Hash, Record>(0, Hash.equal, func (x) { x });

    /// List all records in a human-readable way
    public query func listRecords() : async Text {
        var retval = "{\n";
        for ((k, v) in records.entries()) {
            retval #= "  " # Nat32.toText(k) # ": " # Types.recordHumanReadable(v) # ",\n";
        };
        retval #= "}\n";
        retval
    };

    public shared(msg) func transferRecord(record_hash: Hash.Hash, new_owner: Principal) : async Bool {
        if (onlyRecordOwner(record_hash, msg.caller)) {
            let record = switch (records.get(record_hash)) {
                case (?rec) { rec };
                case (_) { P.unreachable() };
            };
            setRecord(record_hash, new_owner, record.resolver, record.expiry);
            return true;
        };
        false
    };

    public shared(msg) func createSubRecord(parent_record_hash: Hash.Hash, node: Text, owner: Principal, expiry: Time.Time) : async Bool {
        if (onlyRecordOwner(parent_record_hash, msg.caller)) {
            let resolver = switch (records.get(parent_record_hash)) {
                case (?p_rec) { p_rec.resolver };
                case (_) { P.unreachable() };
            };
            let sub_record_hash = Text.hash(Nat32.toText(parent_record_hash) # node);
            setRecord(sub_record_hash, owner, resolver, expiry);
            return true;
        };
        false
    };

    public shared(msg) func updateRecordResolverOrExpiry(record_hash: Hash.Hash, resolver: ?Principal, expiry: ?Time.Time) : async Bool {
        if (onlyRecordOwner(record_hash, msg.caller)) {
            let record = switch (records.get(record_hash)) {
                case (?rec) { rec };
                case (_) { P.unreachable() };
            };
            let new_resolver = Option.get(resolver, record.resolver);
            let new_expiry = Option.get(expiry, record.expiry);
            setRecord(record_hash, record.owner, new_resolver, new_expiry);
            return true;
        };
        false
    };

    func onlyRecordOwner(record_hash: Hash.Hash, caller: Principal) : Bool {
        switch (records.get(record_hash)) {
            case (?record) { caller == record.owner };
            case (_) { false };
        }
    };

    func setRecord(record_hash: Hash.Hash, owner: Principal, resolver: Principal, expiry: Time.Time) {
        records.put(record_hash, { owner; resolver; expiry; });
    };

    system func preupgrade() {
        persisted_records := Iter.toArray(records.entries());
    };

    system func postupgrade() {
        records := HashMap.fromIter(persisted_records.vals(), persisted_records.size(), Hash.equal, Types.hashForHashes);
        persisted_records := [];
    };

};
