export supported_platforms, platform_triplet, platform_key

const platform_to_triplet_mapping = Dict(
    :linux64 => "x86_64-linux-gnu",
    :linux32 => "i686-linux-gnu",
    :linuxaarch64 => "aarch64-linux-gnu",
    :linuxarmv7l => "arm-linux-gnueabihf",
    :linuxppc64le => "powerpc64le-linux-gnu",
    :mac64 => "x86_64-apple-darwin14",
    :win64 => "x86_64-w64-mingw32",
    :win32 => "i686-w64-mingw32"
)

"""
`supported_platforms()`

Return the list of supported platforms as an array of Symbols.
"""
function supported_platforms()
    global platform_to_triplet_mapping
    return keys(platform_to_triplet_mapping)
end

"""
`platform_triplet(platform::Symbol = platform_key())`

Return the canonical platform triplet for the given platform, defaulting to the
currently running platform.  E.g. returns "x86_64-linux-gnu" for `:linux64`.
"""
function platform_triplet(platform::Symbol = platform_key())
    global platform_to_triplet_mapping
    return platform_to_triplet_mapping[platform]
end

"""
`platform_key(machine::AbstractString = Sys.MACHINE)`

Returns the platform key for the current platform, or any other though the
the use of the `machine` parameter.
"""
function platform_key(machine::AbstractString = Sys.MACHINE)
    global platform_to_triplet_mapping

    # First, off, if `machine` is literally one of the values of our mapping
    # above, just return the relevant key
    for key in supported_platforms()
        if machine == platform_triplet(key)
            return key
        end
    end
    
    # Otherwise, try to parse the machine into one of our keys
    if startswith(machine, "x86_64-apple-darwin")
        return :mac64
    end
    if ismatch(r"x86_64-(pc-)?(unknown-)?linux-gnu", machine)
        return :linux64
    end
    if ismatch(r"i\d86-(pc-)?(unknown-)?linux-gnu", machine)
        return :linux32
    end

    error("Platform `$(machine)` is not an officially supported platform")
end


# Helpful routines to abstract-away
const platform_to_dlext_mapping = Dict(
    :linux64 => "so",
    :linex32 => "so",
    :linuxaarch64 => "so",
    :linuxarmv7l => "so",
    :linuxppc64le => "so",
    :mac64 => "dylib",
    :win64 => "dll",
    :win32 => "dll"
)

"""
`platform_dlext(platform::Symbol = platform_key())`

Return the dynamic library extension for the given platform, defaulting to the
currently running platform.  E.g. returns "so" for a Linux-based platform,
"dll" for a Windows-based platform, etc...
"""
function platform_dlext(platform::Symbol = platform_key())
    global platform_to_dlext_mapping
    return platform_to_dlext_mapping[platform]
end

"""
`valid_dl_path(path::AbstractString)`

Return `true` if the given `path` ends in a valid dynamic library filename.
E.g. returns `true` for a path like `"usr/lib/libfoo.so.3.5"`, but returns
`false` for a path like `"libbar.so.f.a"`.
"""
function valid_dl_path(path::AbstractString)
    const dlext_regexes = [
        # On Linux, libraries look like `libnettle.so.6.3.0`
        r"^(.*).so(\.[\d]+){0,3}$",
        # On OSX, libraries look like `libnettle.6.3.dylib`
        r"^(.*).dylib$",
        # On Windows, libraries look like `libnettle-6.dylib`
        r"^(.*).dll$"
    ]

    # If any of these match, we're happy
    return any(ismatch(dlregex, basename(path)) for dlregex in dlext_regexes)
end