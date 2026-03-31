@echo off
setlocal enabledelayedexpansion

if not defined VBENCH_CACHE_DIR (
    set VBENCH_CACHE_DIR=%USERPROFILE%\.cache\vbench
)
echo Cache dir: %VBENCH_CACHE_DIR%

:: ---- helpers ----
:: download if missing: call :fetch <url> <dest_file>
goto :main

:fetch
set _url=%~1
set _dst=%~2
if exist "%_dst%" (
    echo   skip  %_dst%
    exit /b 0
)
echo   curl  %_dst%
curl -L --create-dirs -o "%_dst%" "%_url%"
exit /b %ERRORLEVEL%

:mkd
if not exist "%~1" mkdir "%~1"
exit /b 0

:main

:: ---- DINO ViT-B/16  (i2v_subject, subject_consistency) ----
call :mkd "%VBENCH_CACHE_DIR%\dino_model"
call :fetch ^
    "https://dl.fbaipublicfiles.com/dino/dino_vitbase16_pretrain/dino_vitbase16_pretrain.pth" ^
    "%VBENCH_CACHE_DIR%\dino_model\dino_vitbase16_pretrain.pth"

if not exist "%VBENCH_CACHE_DIR%\dino_model\facebookresearch_dino_main" (
    echo   clone facebookresearch/dino
    git clone https://github.com/facebookresearch/dino ^
        "%VBENCH_CACHE_DIR%\dino_model\facebookresearch_dino_main"
) else (
    echo   skip  dino repo
)

:: ---- CLIP ViT-B/32  (background_consistency) ----
call :mkd "%VBENCH_CACHE_DIR%\clip_model"
call :fetch ^
    "https://openaipublic.azureedge.net/clip/models/40d365715913c9da98579312b702a82c18be219cc2a73407c4526f58eba950af/ViT-B-32.pt" ^
    "%VBENCH_CACHE_DIR%\clip_model\ViT-B-32.pt"

:: ---- CLIP ViT-L/14  (aesthetic_quality) ----
call :fetch ^
    "https://openaipublic.azureedge.net/clip/models/b8cca3fd41ae0c99ba7e8951adf17d267cdb84cd88be6f7c2e0eca1737a03836/ViT-L-14.pt" ^
    "%VBENCH_CACHE_DIR%\clip_model\ViT-L-14.pt"

:: ---- AMT-S  (motion_smoothness) ----
call :mkd "%VBENCH_CACHE_DIR%\amt_model"
call :fetch ^
    "https://huggingface.co/lalala125/AMT/resolve/main/amt-s.pth" ^
    "%VBENCH_CACHE_DIR%\amt_model\amt-s.pth"

:: ---- RAFT  (dynamic_degree) ----
call :mkd "%VBENCH_CACHE_DIR%\raft_model"
if not exist "%VBENCH_CACHE_DIR%\raft_model\models\raft-things.pth" (
    echo   curl  raft models.zip
    curl -L -o "%VBENCH_CACHE_DIR%\raft_model\models.zip" ^
        "https://dl.dropboxusercontent.com/s/4j4z58wuv8o0mfz/models.zip"
    echo   unzip raft
    tar -xf "%VBENCH_CACHE_DIR%\raft_model\models.zip" -C "%VBENCH_CACHE_DIR%\raft_model\"
    del /f "%VBENCH_CACHE_DIR%\raft_model\models.zip"
) else (
    echo   skip  raft models
)

:: ---- MUSIQ-SPAQ  (imaging_quality) ----
call :mkd "%VBENCH_CACHE_DIR%\pyiqa_model"
call :fetch ^
    "https://github.com/chaofengc/IQA-PyTorch/releases/download/v0.1-weights/musiq_spaq_ckpt-358bb6af.pth" ^
    "%VBENCH_CACHE_DIR%\pyiqa_model\musiq_spaq_ckpt-358bb6af.pth"

:: ---- CoTracker2  (camera_motion) ----
:: torch.hub auto-downloads cotracker2; optionally pre-cache it:
call :mkd "%VBENCH_CACHE_DIR%\cotracker_model"
call :fetch ^
    "https://huggingface.co/facebook/cotracker/resolve/main/cotracker2.pth" ^
    "%VBENCH_CACHE_DIR%\cotracker_model\cotracker2.pth"

echo.
echo Done. Models in: %VBENCH_CACHE_DIR%
endlocal
