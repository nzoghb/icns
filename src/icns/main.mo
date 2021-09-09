import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import AID "AccountIdentifier";
import ExtCore "Core";
import ExtCommon "Common";
import ExtAllowance "Allowance";
import ExtNonFungible "NonFungible";

/*
Features:
* Put - Allows user to associate a canister_id with a name. if the canister_id or name already 
        exists, throw
* Get - Allows user to query the canister by canister_id or name
* List - List all the canisters
* Search - Search on pattern
* Delete - Delete a canister

TODO:
* Auto discover all canisters, uploader, name
* Update dfx tool, to update ICNS canister when a new canister deployed in network
* Access privilege - who can update ICNS for which entries
*/

///
/// initial_minter: The very first minter who can mint an IC canister name token
///
shared (install) actor class ICNS(initial_minter: Principal) = this {

    // Types
    type AccountIdentifier = ExtCore.AccountIdentifier;
    type SubAccount = ExtCore.SubAccount;
    type User = ExtCore.User;
    type Balance = ExtCore.Balance;
    type TokenIdentifier = ExtCore.TokenIdentifier;
    type TokenIndex  = ExtCore.TokenIndex ;
    type Extension = ExtCore.Extension;
    type CommonError = ExtCore.CommonError;
    type BalanceRequest = ExtCore.BalanceRequest;
    type BalanceResponse = ExtCore.BalanceResponse;
    type TransferRequest = ExtCore.TransferRequest;
    type TransferResponse = ExtCore.TransferResponse;
    type AllowanceRequest = ExtAllowance.AllowanceRequest;
    type ApproveRequest = ExtAllowance.ApproveRequest;
    type Metadata = ExtCommon.Metadata;
    type MintRequest  = ExtNonFungible.MintRequest ;

    stable var persisted : [(Text, Text)] = [];
    var minters = [initial_minter];
    var purchased_domains = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
    var domain_owner_map = HashMap.HashMap<Principal, Text>(0, Text.equal, Text.hash);

    /// Show extension methods supported in this canister
    /// Per standard, this function should return all Extension methods being supported 
    /// by canister, as our canister do not support other Extension methods, it returns
    /// an empty array.
    public query func extensions() : async [Extension] {
        return [];
    };

    /// This method lets caller to buy a domain name if it's still available
    /// This method calls mint() method internally, to make a domain_name minted/registered
    /// before making it availabe for caller's purchase
    public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
        
    };

    /// Show domain names by Principal
    public query func balance(request : BalanceRequest) : async BalanceResponse {
        if (TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = TokenIdentifier.getIndex(request.token);
        let aid = User.toAID(request.user);
        switch (purchased_domains.get(token)) {
            case (?token_owner) {
				if (AID.equal(aid, token_owner) == true) {
					return #ok(1);
				} else {					
					return #ok(0);
				};
            };
            case (_) {
                return #err(#InvalidToken(request.token));
            };
        };
    };

    /// Let the initial minter to create more minters
    public shared(msg) func setMinter(minter : Principal) : async Text {
		if (not minters.contains(msg.caller)){
            return "Caller " # msg.caller # " is not authorized to add new minters."
        };
		minters := Array.append(minters, [msg.caller]);
	};

    /// Set the NFT token
    public func put(canister_id: Text, domain_name: Text) : async Text {
        map.put(domain_name, canister_id);
        return await printPair(canister_id, domain_name);
    };

    // /// Fetch all domain_name -> canister_id mappings owned by current principal
    // public func get(domain_name: Text) : async Text {
    //     let canister_id = map.get(domain_name);
    //     return Option.get(canister_id, "");
    // };

    /// Prints all domain names taken, and their owners
    public func list(): async Text {
        return await printHashmap(map);
    };

    /// Answers the question of whether a domain name is still available for purchase or not
    public func check_availability(searched_domain: Text): async (bool, Text) {
        
        let outputMap = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
        let pat: Text.Pattern = #text (Option.get(searched_domain, ""));
        for ((domain_name, canister_id) in map.entries()) {
            // TODO: make the comparison case insensitive
            if (Text.equal(domain_name, searched_domain)) {
                return (fasle, "Domain name " # searched_domain # " is no longer available.");
            };
        };

        // Domain name not mapped to any canister_id yet. Available for purchase.
        return (true, "Domain name " # searched_domain # " is still available.");
    };

    /// Answers the question of what the canister_id a domain_name maps to, 
    /// or what domain_name a canister_id maps to
    /// Input:
    /// search: Text - either a canister_id, or a domain_keyword
    /// This method will use the input for fuzz matching with all canister_ids and all domain_names in registry, and return all items that are relevant
    /// This method helps user look for the other half of the information when they know half
    public func look_up(search: Text): async HashMap.HashMap<Text, Text> {

        let outputMap = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
        let pat: Text.Pattern = #text (Option.get(search, ""));
        for ((domain_name, canister_id) in map.entries()) {
            // TODO: make the comparison case insensitive
            if (Text.contains(domain_name, search) or Text.equal(canister_id, search)) {
                outputMap.put(domain_name, canister_id);
            };
        };

        return outputMap;
    };

    // public func delete(domain_name: Text): async Text {
    //     let v = Option.get(map.get(domain_name), "");
    //     switch(map.remove(domain_name)) {
    //         case (null) { assert false; return ""; };
    //         case (?_) { return (await printPair(domain_name, v)) # " deleted!" };
    //     };
    // };

    private func printHashmap(hashmap: HashMap.HashMap<Text, Text>): async Text {
        // Flatten the hashmap to string
        var entries = "[";
        for ((domain_name, canister_id) in hashmap.entries()) {
            entries := entries # (await printPair(domain_name, canister_id)) # ", ";
        };
        if (entries.size() == 1) {
            // Outputing (null) if empty hashmap
            return "";
        }
        else {
            // Forming output format
            let pat : Text.Pattern = #text ", ";
            return Text.trimEnd(entries, pat) # "]";
        };
    };

    private func printPair(domain_name: Text, canister_id: Text): async Text {
        return "(" # domain_name # ", " # canister_id # ")";
    };

    system func preupgrade() {
        persisted := Iter.toArray(map.entries());
    };

    system func postupgrade() {
        map := HashMap.fromIter(Iter.fromArray<(Text, Text)>(persisted), persisted.size(), Text.equal, Text.hash);
        persisted := [];
    };
};
