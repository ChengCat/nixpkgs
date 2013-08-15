{ stdenv, fetchurl
, pkgconfig, mesa
, SDL, SDL_image, libpng, zlib, libvorbis, libogg, libmikmod, unzip
, use3DOVideos ? false, requireFile ? null, writeText ? null
, haskellPackages ? null
}:

assert use3DOVideos -> requireFile != null && writeText != null
                    && haskellPackages != null;

let
  videos = import ./3dovideo.nix {
    inherit stdenv requireFile writeText fetchurl haskellPackages;
  };
in stdenv.mkDerivation rec {
  name = "uqm-${version}";
  version = "0.7.0";

  src = fetchurl {
    url = "mirror://sourceforge/sc2/uqm-${version}-source.tgz";
    sha256 = "08dj7fsvflxx69an6vpf3wx050mk0ycmdv401yffrrqbgxgmqsd3";
  };

  content = fetchurl {
    url = "mirror://sourceforge/sc2/uqm-${version}-content.uqm";
    sha256 = "1gx39ns698hyczd4nx73mr0z86bbi4q3h8sw3pxjh1lzla5xpxmq";
  };

  voice = fetchurl {
    url = "mirror://sourceforge/sc2/uqm-${version}-voice.uqm";
    sha256 = "0yf9ff5sxk229202gsa7ski6wn7a8hkjjyr1yr7mjdxsnh0zik5w";
  };

  music = fetchurl {
    url = "mirror://sourceforge/sc2/uqm-${version}-3domusic.uqm";
    sha256 = "10nbvcrr0lc0mxivxfkcbxnibwk3vwmamabrlvwdsjxd9pk8aw65";
  };


 /* uses pthread_cancel(), which requires libgcc_s.so.1 to be
    loadable at run-time. Adding the flag below ensures that the
    library can be found. Obviously, though, this is a hack. */
  NIX_LDFLAGS="-lgcc_s";

  buildInputs = [SDL SDL_image libpng libvorbis libogg libmikmod unzip pkgconfig mesa];

  postUnpack = ''
    mkdir -p uqm-${version}/content/packages
    mkdir -p uqm-${version}/content/addons
    cp $content uqm-${version}/content/packages/uqm-0.7.0-content.uqm
    cp $music uqm-${version}/content/addons/uqm-0.7.0-3domusic.uqm
    cp $voice uqm-${version}/content/addons/uqm-0.7.0-voice.uqm
  '' + stdenv.lib.optionalString use3DOVideos ''
    ln -s "${videos}" "uqm-${version}/content/addons/3dovideo"
  '';

  /* uqm has a 'unique' build system with a root script incidentally called
 * 'build.sh'. */

  configurePhase = ''
    echo "INPUT_install_prefix_VALUE='$out'" >> config.state
    echo "INPUT_install_bindir_VALUE='$out/bin'" >> config.state
    echo "INPUT_install_libdir_VALUE='$out/lib'" >> config.state
    echo "INPUT_install_sharedir_VALUE='$out/share'" >> config.state
    PREFIX=$out ./build.sh uqm config
  '';

  buildPhase = ''
    ./build.sh uqm
  '';

  installPhase = ''
    ./build.sh uqm install
    sed -i $out/bin/uqm -e "s%/usr/local/games/%$out%g"
  '';

  meta = {
    description = "Remake of Star Control II";
    longDescription = ''
    The goals for the The Ur-Quan Masters project are:
      - to bring Star Control II to modern platforms, thereby making a lot of people happy
      - to make game translations easy, thereby making even more people happy
      - to adapt the code so that people can more easily make their own spin-offs, thereby making zillions more people happy!
    '';
    homepage = http://sc2.sourceforge.net/;
    license = "GPLv2";
    maintainers = with stdenv.lib.maintainers; [ jcumming ];
  };
}
