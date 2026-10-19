# Package

version       = "0.3.0"
author        = "Threading contributors"
description   = "New threading primitives for --mm:arc/orc: atomics, channels, smart pointers and wait groups."
license       = "MIT"

# Dependencies

# `createShared` unusable in earlier releases: https://github.com/nim-lang/Nim/issues/26014
requires "nim >= 2.2.12"
