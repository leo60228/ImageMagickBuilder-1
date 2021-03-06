# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ImageMagick"
version = v"6.9.10-12"
# Collection of sources required to build imagemagick
sources = [
    "https://github.com/ImageMagick/ImageMagick6.git" =>
    "d9d6f94ba8a40ca50d3b2fb748c1ec3014e335ef",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ImageMagick6/
./configure --prefix=$prefix --host=$target --disable-openmp --disable-install --disable-dependency-tracking --without-frozenpaths --without-perl
make -j${ncore}
make install

if [[ ${target} == "x86_64-apple-darwin14" ]]; then
    echo "-- Modifying link references for ImageMagick libraries"
    opts=""
    # for some reason libtiff and libpng don't need help?
    for XLIB in libMagick++-6.Q16.8 libMagickCore-6.Q16.6 libMagickWand-6.Q16.6 libjpeg.9 libz.1
    do
  	  opts="${opts} -change ${WORKSPACE}/destdir/lib/${XLIB}.dylib @rpath/${XLIB}.dylib"
    done
    for YLIB in libMagickWand-6.Q16.6 libMagickCore-6.Q16.6 libMagick++-6.Q16.8
    do
	  install_name_tool ${opts} ${prefix}/lib/${YLIB}.dylib
    done
fi
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libMagickWand", :libwand),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.2/build_Zlib.v1.2.11.jl",
    "https://github.com/SimonDanisch/LibpngBuilder/releases/download/v1.0.1/build_libpng.v1.6.31.jl",
    "https://github.com/SimonDanisch/LibJPEGBuilder/releases/download/v9b/build_libjpeg.v9.0.0-b.jl",
    "https://github.com/SimonDanisch/LibTIFFBuilder/releases/download/v1.0.0/build_libtiff.v4.0.9.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
