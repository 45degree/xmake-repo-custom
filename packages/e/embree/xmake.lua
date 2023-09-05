---@diagnostic disable: undefined-global

package("embree", function()
    set_homepage("https://www.embree.org/")
    set_description("Intel® Embree is a collection of high-performance ray tracing kernels, developed at Intel.")
    set_license("Apache-2.0")

    add_urls("https://github.com/embree/embree/archive/$(version).tar.gz", "https://github.com/embree/embree.git")
    add_versions("v3.12.1", "0c9e760b06e178197dd29c9a54f08ff7b184b0487b5ba8b8be058e219e23336e")
    add_versions("v3.13.0", "4d86a69508a7e2eb8710d571096ad024b5174834b84454a8020d3a910af46f4f")
    add_versions("v3.13.3", "74ec785afb8f14d28ea5e0773544572c8df2e899caccdfc88509f1bfff58716f")
    add_versions("v3.13.4", "e6a8d1d4742f60ae4d936702dd377bc4577a3b034e2909adb2197d0648b1cb35")
    add_versions("v3.13.5", "b8c22d275d9128741265537c559d0ea73074adbf2f2b66b0a766ca52c52d665b")
    add_versions("v4.2.0", "b0479ce688045d17aa63ce6223c84b1cdb5edbf00d7eda71c06b7e64e21f53a0")

    -- Not recommanded to build embree as a static library.
    add_configs("shared", { description = "Build shared library.", default = true, type = "boolean" })
    add_configs("sse2", { description = "ISA SSE2", default = false, type = "boolean" })
    add_configs("sse42", { description = "ISA SSE42", default = false, type = "boolean" })
    add_configs("avx", { description = "ISA AVX", default = false, type = "boolean" })
    add_configs("avx2", { description = "ISA AVX2", default = true, type = "boolean" })
    add_configs("avx512", { description = "ISA AVX512", default = false, type = "boolean" })

    add_deps("cmake", "tbb")

    if is_plat("windows") then
        add_syslinks("advapi32")
    end

    on_load(function(package)
        local version = package:version()

        local major = 4 -- the master branch major version is 4
        if version ~= nil then
            major = version:major()
        end
        package:add(
            "links",
            "embree" .. major,
            "embree_sse42",
            "embree_avx",
            "embree_avx2",
            "embree_avx512",
            "tasking",
            "simd",
            "lexers",
            "math",
            "sys"
        )
    end)

    on_install(function(package)
        local configs = {
            "-DBUILD_TESTING=OFF",
            "-DBUILD_DOC=OFF",
            "-DEMBREE_TUTORIALS=OFF",
            "-DEMBREE_ISPC_SUPPORT=OFF",
            "-DEMBREE_MAX_ISA=NONE",
        }
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DEMBREE_STATIC_LIB=" .. (package:config("shared") and "OFF" or "ON"))

        if package:is_plat("windows") then
            table.insert(
                configs,
                "-DUSE_STATIC_RUNTIME=" .. (package:config("vs_runtime"):startswith("MT") and "ON" or "OFF")
            )
        end

        table.insert(configs, "-DEMBREE_ISA_SSE2=" .. (package:config("sse2") and "ON" or "OFF"))
        table.insert(configs, "-DEMBREE_ISA_SSE42=" .. (package:config("sse42") and "ON" or "OFF"))
        table.insert(configs, "-DEMBREE_ISA_AVX=" .. (package:config("avx") and "ON" or "OFF"))
        table.insert(configs, "-DEMBREE_ISA_AVX2=" .. (package:config("avx2") and "ON" or "OFF"))
        table.insert(configs, "-DEMBREE_ISA_AVX512=" .. (package:config("avx512") and "ON" or "OFF"))

        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function(package)
        local version = package:version()

        local major = 4 -- the master branch major version is 4
        if version ~= nil then
            major = version:major()
        end
        assert(package:check_cxxsnippets({
            test = [[
            #include <cassert>
            void test() {
                RTCDevice device = rtcNewDevice(NULL);
                assert(device != NULL);
            }
        ]],
        }, { configs = { languages = "c++11" }, includes = "embree" .. major .. "/rtcore.h" }))
    end)
end)
