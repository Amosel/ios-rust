# Examples of iOS/XCode Project with Rust Libraries

## Background
This work is based on the following articles, incorporating elements from each to achieve the final result:

1. [Older piece about Xcode from Mozilla](https://mozilla.github.io/firefox-browser-architecture/experiments/2017-09-06-rust-on-ios.html)
2. [More contemporary piece about Xcode integration with a simpler shared lib directory structure](https://blog.mozilla.org/data/2022/01/31/this-week-in-glean-building-and-deploying-a-rust-library-on-ios/#fn1)
3. [Another insightful but slightly outdated Medium post from 2019. I found this while searching for a method to automatically generate the C header file and discovered `cbindgen`](https://medium.com/visly/rust-on-ios-39f799b3c1dd)

## iOS Setup

1. Ensure you have the Xcode command line tools installed: `xcode-select --install`

## Rust Setup

1. Install rustup: `curl https://sh.rustup.rs -sSf | sh`
2. Add required libraries and targets: `rustup target add aarch64-apple-ios x86_64-apple-ios`
3. Install `cbindgen`: `cargo install cbindgen`

## Xcode Integration

To link our Rust library to Xcode, follow these steps:

1. Link function signatures to Xcode/Clang using a header (`.h`) file.
2. Link Swift to this `.h` file by specifying a bridging header.
3. Execute a script as part of the Xcode build phase that runs the Rust command. This should match the Rust `profile` with a build variant (`release`/`debug`) and architecture (provided as env var `$ARCH`).
4. Specify a statically linked library (`*.a`) to be linked at build time.
5. Adjust XCode's library search paths to find the appropriate Rust build artifact (`*.a`) for each architecture and build variant. For example, `$(PROJECT_DIR)/target/aarch64-apple-ios/debug`.
6. Ensure all the above steps occur before Xcode starts compiling the Swift/Objective-C files. Make sure the build phase order is logical.

### Linking Headers

Headers provide the C interface declaration that Xcode/Clang uses during the linking phase of compilation. At this stage, clang does not need architecture-specific knowledge. However, C macros might be conditionally applied based on build variants, such as `#ifdef DEBUG`.

1. Create a C header that includes the `extern "C"` function signatures and instruct Clang within Xcode to bridge these functions to Swift and Objective-C. 
2. Generate the header file with: `cbindgen shipping-rust-ffi/src/lib.rs -l c > rust.h` in the root folder. Alternatively, add this command as a build phase in Xcode. Navigate to `target => build phases` and add the `Run Script Phase`. Ensure it's at the beginning of the phase list. An example is provided in the project, calling `bin/create-header.sh`.
3. Add `rust.h` to the headers in `Xcode => target => build phases` as a project header.
4. [Create a bridging header in Xcode](https://developer.apple.com/documentation/swift/importing-objective-c-into-swift). Within this bridging header, import `rust.h`. Ensure the target's build configuration bridging header points to the root directory: `$(PROJECT_DIR)/BridgingHeader.h`.

### Linking Library

The library is the binary that Xcode/Clang uses to generate its build artifacts. This will be based on the architecture (ARM/Intel) and build variant (release/debug).

Add `libtest_rust.a` to `Xcode => target => build phases => link binary with libraries`. Then open `<ProjectName>.xcodeproj/project.xcproj` and search for `LIBRARY_SEARCH_PATHS`. Replace the `Debug` configuration with:

```javascript
"LIBRARY_SEARCH_PATHS[sdk=iphoneos*][arch=arm64]" = "$(PROJECT_DIR)/target/aarch64-apple-ios/debug";
"LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*][arch=arm64]" = "$(PROJECT_DIR)/target/aarch64-apple-ios-sim/debug";
"LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*][arch=x86_64]" = "$(PROJECT_DIR)/target/x86_64-apple-ios/debug";
```

And for the Release configuration:

```javascript
"LIBRARY_SEARCH_PATHS[sdk=iphoneos*][arch=arm64]" = "$(PROJECT_DIR)/target/aarch64-apple-ios/release";
"LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*][arch=arm64]" = "$(PROJECT_DIR)/target/aarch64-apple-ios-sim/release";
"LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*][arch=x86_64]" = "$(PROJECT_DIR)/target/x86_64-apple-ios/release";
```

# XCode Compilation
1. Ensure everything is set up correctly on the Rust side and that it compiles without errors: `cargo build`.
2. Add a `User Defined Setting` in `Xcode => target => Build Setting`. Name it `buildvariant`. Set the value to `release` under the `Release` configuration and `debug` under the `Debug` configuration.
3. In `Xcode => target => Build Phases`, add a script named `Build Rust Library`. This script will compile the Rust library. Use the following command: `bash ${PROJECT_DIR}/bin/compile-library.sh shipping-rust-ffi $buildvariant`. This will use the Xcode build configuration (variant, architecture, etc.)(variant, arch etc)
4. Ensure the build phase order is logical.
5. Compile the project using any of the device targets or variants.
