@echo off

cd %APPVEYOR_BUILD_FOLDER%
dir patches
where git
git config -l
goto call_submodule

if "%APPVEYOR_REPO_TAG_NAME%"=="" (
  if "%1_%ARCH%"=="build_x64" (
    goto update_repo
  )
  echo Build skipped.
  appveyor exit
) else (
  goto call_submodule
)
goto :eof


:call_submodule
echo on

if "%1"=="build" (
  git config --local core.autocrlf false
  git submodule init
  git submodule update
  cd ag
  git config -l
  for %%I in (..\patches\*.patch) do git apply -3 --whitespace=nowarn %%I || exit 1
  cd ..
  appveyor exit
  exit
)
set OLD_APPVEYOR_BUILD_FOLDER=%APPVEYOR_BUILD_FOLDER%
set APPVEYOR_BUILD_FOLDER=%APPVEYOR_BUILD_FOLDER%\ag
call ag\win32\appveyor.bat %1
set APPVEYOR_BUILD_FOLDER=%OLD_APPVEYOR_BUILD_FOLDER%

@echo off
goto :eof


:update_repo
echo on
path C:\%MSYS2_DIR%\usr\bin;%PATH%
set CHERE_INVOKING=yes

@git config user.name "%DEPLOY_USER_NAME%"
@git config user.email "%DEPLOY_USER_EMAIL%"
git remote set-url --push origin "git@github.com:%APPVEYOR_REPO_NAME%.git"

if not "%APPVEYOR_SCHEDULED_BUILD%"=="True" (
  @rem Skip if the commit is tagged.
  git describe --tags --exact-match > NUL 2>&1
  if not ERRORLEVEL 1 (
    @echo Build skipped.
    goto end_update
  )
)

set MSYSTEM=MSYS
bash -lc "mkdir -p ~/.ssh; sh ./scripts/install_sshkey_github.sh ./scripts/ci-ag-win32.enc ~/.ssh/ci-ag-win32"
bash -lc "sh ./scripts/update-repo.sh"

:end_update
appveyor exit
@echo off
goto :eof
