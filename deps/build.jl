@unix_only begin
    cd(joinpath(dirname(@__FILE__), "src", "CSoM", "4th_ed"))
    suffix = @osx? "dylib" : "so"
    run(`make clean`)
    run(`make FC=gfortran SUFFIX=$suffix`)
    cd(joinpath(dirname(@__FILE__), "src", "CSoM", "5th_ed", "source", "library", "main"))
    suffix = @osx? "dylib" : "so"
    run(`make FC=gfortran SUFFIX=$suffix`)
    cd(joinpath(dirname(@__FILE__), "src", "CSoM", "5th_ed", "source", "library", "geom"))
    suffix = @osx? "dylib" : "so"
    run(`make FC=gfortran SUFFIX=$suffix`)
end

@windows_only begin
    # these binaries were cross-compiled from Cygwin via the following steps:
    # mkdir -p bin32 && mkdir -p bin64
    # i686-w64-mingw32-gfortran -o bin32/libddierckx.dll -O3 -shared \
    #   -static-libgfortran -static-libgcc src/ddierckx/*.f
    # x86_64-w64-mingw32-gfortran -o bin64/libddierckx.dll -O3 -shared \
    #   -static-libgfortran -static-libgcc src/ddierckx/*.f
    #run(`curl -LO http://sourceforge.net/projects/juliadeps-win/files/ddierckx.7z`)
    #run(`7z x -y ddierckx.7z`)
end