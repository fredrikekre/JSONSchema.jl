using JSONSchema
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

tsurl = "https://github.com/json-schema-org/JSON-Schema-Test-Suite/archive/master.zip"

using BinDeps
@BinDeps.setup

destdir = mktempdir()
dwnldfn = joinpath(destdir, "test-suite.zip")
unzipdir = joinpath(destdir, "test-suite")
run(@build_steps begin
    CreateDirectory(destdir, true)
    FileDownloader(tsurl, dwnldfn)
    CreateDirectory(unzipdir, true)
    FileUnpacker(dwnldfn, unzipdir, "JSON-Schema-Test-Suite-master/tests")
end)

######## Source = https://github.com/json-schema-org/JSON-Schema-Test-Suite.git  #######

tsdir = joinpath(unzipdir, "JSON-Schema-Test-Suite-master/tests/draft4")
@testset "JSON schema test suite (draft 4)" begin
    @testset "$tfn" for tfn in filter(n -> ismatch(r"\.json$",n), readdir(tsdir))[1:24]
        fn = joinpath(tsdir, tfn)
        schema = JSON.parsefile(fn)
        @testset "- $(subschema["description"])" for subschema in (schema)
            spec = Schema(subschema["schema"])
            @testset "* $(subtest["description"])" for subtest in subschema["tests"]
                @test check(subtest["data"], spec) == subtest["valid"]
            end
        end
    end
end

#  MAP
fn = joinpath(tsdir, "ref.json")
schema = JSON.parsefile(fn)
subschema = schema[6]
spec = Schema(subschema["schema"])
for subtest in subschema["tests"]
    info("- ", subtest["description"],
         " : ", check(subtest["data"], spec),
         " / ", subtest["valid"])
end

subtest = subschema["tests"][3]
x = subtest["data"]
s = spec
check(x, s)
subtest["valid"]

s0 = spec
s = spec.asserts["items"][2]

asserts = copy(s.asserts)

macroexpand( quote @doassert asserts "not" begin
    check(x, keyval) && return "satisfies 'not' assertion $notassert"
end end)


s = spec.asserts["anyOf"][1]
evaluate(x,s)
