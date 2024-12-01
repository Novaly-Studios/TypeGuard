# Random notes on things to do

## Short Term Work

- Get all tests to pass, create any tests which are missing for modules.
- Write tests for every constraint and tag.
  - Test for type checking.
  - Test for serialization and deserialization.
- Weed out any bugs / unexpected behavior.
- Revamp Enum: currently it's hacked together and if Roblox adds any new Enums, they won't deserialize to the same Enum.
- Add chunking option to ByteSerializer and BitSerializer so we can send chunks of 900 bytes over unreliable remotes & allow Checker:Serialize(...) to chunk as a param.
- Versioning...
  - Sometimes we are going to change how the serialization works internally (e.g. potentially adding fields to Roblox types, changing dynamic int format, and so on), so if we are saving player data, this may break if we update the library and they load in.
  - We can fix this by creating a library independent of TypeGuard which writes a version number to the beginning of the buffer.
  - The library should ideally automatically pull in all releases of TypeGuard as they are released (some github CI stuff?).
  - All serialization and deserialization should go through the versioned library.
  - If we pull from player data and see version 2, but the user requests version 4, it will deserialize using version 2 to load it and reserialize using version 4 when the data is saved later.

## Longer Term Work

- Serialization parallelization points: if a table or Instance has more than say 100 elements, we can spin off new threads to serialize the sub-elements in parallel and re-combine at the end. Can dramatically speed up player data saving.
  - The challenge here is Roblox being extremely restrictive on what data can be passed across threads, how to recursively serialize TypeCheckers themselves to pass copies of them to the workers? Can't directly pass metatable copies.
  - Currently I added a more method where you can run Any:Serialize(...) calls in their own thread each & they're split up between frames. But it can still take a long time to deal with player data.
- Should think of ways to make ByteSerializer as fast as HttpService.JSONEncode +-20%. Currently it's a third as fast. I expect it's all the unavoidable cross-module non-inlined function call chains but maybe there's other ways to optimize.
- Waiting on Luau type checker improvements to get these started:
  - Allow `TypeGuard.Params`, `TypeGuard.Variadic`, etc. types to propagate up to the containing function.
  - When constraint functions are called, inject addtl. data into type function which applies those constraints to pre-runtime checking too.
