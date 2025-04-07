import Result "mo:base/Result";
import Text "mo:base/Text";
import Map "mo:map/Map";
import Vector "mo:vector";
import {phash; nhash} "mo:map/Map";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

actor {
    
    stable var nextId : Nat = 0;
    stable var userIdMap : Map.Map<Principal, Nat> = Map.new<Principal, Nat>();
    stable var userProfileMap : Map.Map<Nat, Text> = Map.new<Nat, Text>();
    stable var userResultsMap : Map.Map<Nat, Vector.Vector<Text>> = Map.new<Nat, Vector.Vector<Text>>();

    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text }, Text> {
        let userId = switch
            (Map.get(userIdMap, phash, caller)) {
                case (?found) {
                    found
                };
                case (_) {
                    return #err("User not found");
                }
            };
        let name = switch   
            (Map.get(userProfileMap, nhash, userId)) {
                case (?found) {
                    found
                };
                case (_) {
                    return #err("User not found");
                }
            };
        return #ok({ id = userId; name = name });
    };

    public shared ({ caller }) func setUserProfile(name : Text) : async Result.Result<{ id : Nat; name : Text }, Text> {
        
        var IdRecorder = 0;
        
        switch (Map.get(userIdMap, phash, caller)) {
            case (?IdFound) {
                Map.set(userIdMap, phash, caller, IdFound);
                Map.set(userProfileMap, nhash, IdFound, name);
                IdRecorder := IdFound;

            };
            case (_) {
                Map.set(userIdMap, phash, caller, nextId);
                Map.set(userProfileMap, nhash, nextId, name);
                IdRecorder := nextId;
                nextId += 1;

            }
        };

        return #ok({ id = IdRecorder; name = name })
    };

    public shared ({ caller }) func addUserResult(result : Text) : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        let userId = switch (Map.get(userIdMap, phash, caller)) {
            case (?found) {
                found
            };
            case (_) {
                return #err("User not found");
            }
        };

        let currentResults = switch (Map.get(userResultsMap, nhash, userId)) {
            case (?found) {
                found
            };
            case (_) {
                Vector.fromArray<Text>([])
            }
        };
        Vector.add(currentResults, result);
        Map.set(userResultsMap, nhash, userId, currentResults);

        return #ok({ id = userId; results = Vector.toArray(currentResults) });
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        let userId = switch (Map.get(userIdMap, phash, caller)) {
            case (?found) {
                found
            };
            case (_) {
                return #err("User not found");
            }
        };

        let results = switch (Map.get(userResultsMap, nhash, userId)) {
            case (?found) {
                found
            };
            case (_) {
                Vector.fromArray<Text>([])
            }
        };

        return #ok({ id = userId; results = Vector.toArray(results) });
    };
};
