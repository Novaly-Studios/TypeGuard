# TableUtil

An extensive library for Luau table data manipulation. Details of specific functions are given in their respective modules.

## Features

The library supports turning on and off "features", which are wrapper functions over the core functions. Call `TableUtil.WithFeatures("FeatureName1", "FeatureName2", ...)` to return a copy of the library with specific features enabled or disabled, or pass nothing to return a copy with all features disabled.

These options allow the consumer to determine the appropriate tradeoff between security and performance. By default, all features are enabled for maximum security, with some cost to performance. The features are as follows...

### Assert

Enables or disables assertions. This makes sure all the function inputs are correct.

### Freeze

Where applicable, the resulting table will be frozen, meaning it can't be written to. In cases where functions can return tables passed in arguments for re-use and avoiding extra allocations, this will also freeze a copy of said table unless it is already frozen, avoiding unintended side effects. When this is enabled, it is more performant to pass frozen tables in as arguments, not mutable tables.
