#!/usr/bin/env bash

if [ "$#" -ne 2 ]
then
    echo "Usage (note: only call inside xcode!):"
    echo "create-header.sh <FFI_TARGET> <HEADER_FILE>"
    exit 1
fi


# what to pass to cargo build -p, e.g. your_lib_ffi
FFI_TARGET=$1 # i.e shipping-rust-ffi/src/lib.rs
# buildvariant from our xcconfigs
HEADER_FILE=$2

$HOME/.cargo/bin/cbindgen ${PROJECT_DIR}/${FFI_TARGET} -l c > ${PROJECT_DIR}/${HEADER_FILE}

