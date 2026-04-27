{
  lib,
  stdenv,
  fetchFromGitHub,
  ffmpeg-headless,
  pipewire,
  python312Packages,
  qt6,
  ripgrep,
  wrapGAppsHook3,
}:

python312Packages.buildPythonApplication (finalAttrs: {
  pname = "tagstudio";
  version = "9.5.6";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "TagStudioDev";
    repo = "TagStudio";
    rev = "v${finalAttrs.version}";
    hash = "sha256-RWxj5ILRtg7LMuDnuB0k1XoVB3jFCjNdBze5e3zjpM8=";
  };

  nativeBuildInputs = [
    python312Packages.pythonRelaxDepsHook
    qt6.wrapQtAppsHook
    wrapGAppsHook3
  ];

  build-system = with python312Packages; [
    hatchling
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
  ];

  postPatch = ''
    substituteInPlace src/tagstudio/qt/previews/renderer.py \
      --replace-fail \
        'import pillow_avif  # noqa: F401 # pyright: ignore[reportUnusedImport]' \
        'try:\n    import pillow_avif  # noqa: F401 # pyright: ignore[reportUnusedImport]\nexcept ImportError:\n    pillow_avif = None'
  '';

  dependencies = with python312Packages; [
    chardet
    ffmpeg-python
    humanfriendly
    mutagen
    numpy
    opencv-python
    pillow
    pillow-heif
    py7zr
    pydantic
    pydub
    pyside6
    rarfile
    rawpy
    send2trash
    sqlalchemy
    srctools
    structlog
    toml
    typing-extensions
    ujson
    wcmatch
  ];

  nativeCheckInputs = with python312Packages; [
    pytestCheckHook
    pytest-qt
    pytest-xdist
    syrupy
  ];

  pythonRemoveDeps = [
    "pillow-avif-plugin"
    "pillow-jxl-plugin"
  ];

  pythonRelaxDeps = [
    "numpy"
    "pillow"
    "pillow-heif"
    "py7zr"
    "pyside6"
    "rarfile"
    "structlog"
    "typing-extensions"
  ];

  pythonImportsCheck = [ "tagstudio" ];

  disabledTests = [
    "test_badge_visual_state"
    "test_browsing_state_update"
    "test_close_library"
    "test_flow_layout_happy_path"
    "test_get"
    "test_json_migration"
    "test_library_migrations"
    "test_update_tags"
  ];

  disabledTestPaths = [
    "tests/qt/test_build_tag_panel.py"
    "tests/qt/test_field_containers.py"
    "tests/qt/test_file_path_options.py"
    "tests/qt/test_preview_panel.py"
    "tests/qt/test_tag_panel.py"
    "tests/qt/test_tag_search_panel.py"
    "tests/test_library.py"
  ];

  preCheck = ''
    export HOME=$(mktemp -d)
    export QT_QPA_PLATFORM=offscreen
  '';

  postInstall = ''
    install -Dm644 src/tagstudio/resources/tagstudio.desktop $out/share/applications/tagstudio.desktop
    install -Dm644 src/tagstudio/resources/icon.png $out/share/icons/hicolor/512x512/apps/tagstudio.png
  '';

  dontWrapQtApps = true;
  dontWrapGApps = true;
  makeWrapperArgs = [
    "--suffix PATH : ${
      lib.makeBinPath [
        ffmpeg-headless
        ripgrep
      ]
    }"
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    "--suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pipewire ]}"
  ]
  ++ [
    "\${gappsWrapperArgs[@]}"
    "\${qtWrapperArgs[@]}"
  ];

  meta = {
    description = "User-focused photo and file management system";
    homepage = "https://docs.tagstud.io/";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ WitteShadovv ];
    mainProgram = "tagstudio";
    platforms = lib.platforms.unix;
  };
})
