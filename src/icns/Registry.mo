import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import P "mo:base/Prelude";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Types "./Types";

actor class Registry() {

    type Record = Types.Record;

    stable var persisted_records : [(Hash.Hash, Record)] = [];
    stable var persisted_top_level_approvals : [(Principal, [Hash.Hash])] = [];

    var records = HashMap.HashMap<Hash.Hash, Record>(0, Hash.equal, func (x) { x });
    var top_level_approvals = HashMap.HashMap<Principal, [Hash.Hash]>(0, Principal.equal, Principal.hash);

    /// List all records in a human-readable way
    public query func listRecords() : async Text {
        if (records.size() == 0) {
            return "{}";
        };
        var retval = "\n{\n";
        for ((k, v) in records.entries()) {
            retval #= "  " # Nat32.toText(k) # ": " # Types.recordHumanReadable(v) # ",\n";
        };
        retval #= "}\n";
        retval
    };

    public query func getResolver(entity: Text) : async ?Principal {
        switch (records.get(entityToRecordHash(entity))) {
            case (?record) { ?record.resolver };
            case (_) { null };
        }
    };

    // TODO: revisit permissions!
    public func approve(registrar: Principal, top_level_entry: Text) : async () {
        let record_hash = Text.hash(top_level_entry);
        let existing_approvals = switch (top_level_approvals.get(registrar)) {
            case (?approved_hashes) { approved_hashes };
            case (null) { [] };
        };
        top_level_approvals.put(registrar, Array.append<Hash.Hash>(existing_approvals, [record_hash]));
    };

    public shared(msg) func createTopLevelRecord(entry: Text, resolver: Principal, expiry: Time.Time) : async Bool {
        switch (top_level_approvals.get(msg.caller)) {
            case (?approved_hashes) {
                let record_hash = Text.hash(entry);
                if (Option.isNull(Array.find<Hash.Hash>(approved_hashes, func (x) { x == record_hash }))) {
                    return false;
                };
                setRecord(record_hash, msg.caller, resolver, expiry);
                top_level_approvals.put(msg.caller, Array.filter<Hash.Hash>(approved_hashes, func (x) { x != record_hash }));
                return true;
            };
            case (_) {};
        };
        false
    };

    public shared(msg) func createSubRecord(parent_record_hash: Hash.Hash, entry: Text, owner: Principal, expiry: Time.Time) : async Bool {
        if (onlyRecordOwner(parent_record_hash, msg.caller)) {
            let resolver = switch (records.get(parent_record_hash)) {
                case (?p_rec) { p_rec.resolver };
                case (_) { P.unreachable() };
            };
            let sub_record_hash = Text.hash(Nat32.toText(parent_record_hash) # entry);
            setRecord(sub_record_hash, owner, resolver, expiry);
            return true;
        };
        false
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
    
    func setRecord(record_hash: Hash.Hash, owner: Principal, resolver: Principal, expiry: Time.Time) {
        records.put(record_hash, { owner; resolver; expiry; });
    };

    func onlyRecordOwner(record_hash: Hash.Hash, caller: Principal) : Bool {
        switch (records.get(record_hash)) {
            case (?record) { caller == record.owner };
            case (_) { false };
        }
    };

    func entityToRecordHash(entity: Text) : Hash.Hash {
        let sub_entities = Text.split(entity, #char('.'));
        var record_hash = Text.hash("");
        var flag = true;
        for (sub_entity in sub_entities) {
            if (flag) {
                record_hash := Text.hash(sub_entity);
                flag := false;
            } else {
                record_hash := Text.hash(Nat32.toText(record_hash) # sub_entity);
            };
        };

        record_hash
    };

    system func preupgrade() {
        persisted_records := Iter.toArray(records.entries());
        persisted_top_level_approvals := Iter.toArray(top_level_approvals.entries());
    };

    system func postupgrade() {
        records := HashMap.fromIter(persisted_records.vals(), persisted_records.size(), Hash.equal, Types.hashForHashes);
        top_level_approvals := HashMap.fromIter(
            persisted_top_level_approvals.vals(),
            persisted_top_level_approvals.size(),
            Principal.equal,
            Principal.hash
        );
        persisted_records := [];
        persisted_top_level_approvals := [];
    };

};
